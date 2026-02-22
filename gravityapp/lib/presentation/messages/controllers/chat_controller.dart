// lib/presentation/messages/controllers/chat_controller.dart
// Realtime stream bound immediately; auto-scroll; no .get(); Firestore cache-friendly.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/model/message.dart';
import '../../../data/services/firestore_chat_service.dart';

/// Chat screen controller: conversationId built immediately; stream attached before getOrCreateConversation.
class ChatController extends GetxController {
  final FirestoreChatService _firestoreChat = FirestoreChatService();

  final String otherFirebaseUid;
  final String otherUserName;
  final String? otherUserAvatar;

  ChatController({
    required this.otherFirebaseUid,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  /// Set immediately in onInit from buildConversationId(myUid, otherUid).
  final Rx<String?> conversationId = Rx<String?>(null);

  /// Main message list bound to Firestore snapshots (latest 30). Realtime updates.
  final RxList<Message> streamMessagesList = <Message>[].obs;

  /// Older messages loaded via pagination (prepended).
  final RxList<Message> olderMessages = <Message>[].obs;

  List<Message> get allMessages => [...olderMessages, ...streamMessagesList];

  final RxBool isLoadingOlder = false.obs;
  final RxBool hasMoreOlder = true.obs;
  final RxBool isOtherTyping = false.obs;
  /// From Firestore users/{otherUid} isOnline field.
  final RxBool isOtherOnline = false.obs;
  /// From Firestore users/{otherUid} lastSeen / LastSeen.
  final Rx<DateTime?> otherLastSeen = Rx<DateTime?>(null);
  final RxString messageInput = ''.obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  static const int _pageSize = 30;
  DocumentSnapshot<Map<String, dynamic>>? _oldestMessageDoc;
  StreamSubscription<({List<Message> messages, DocumentSnapshot<Map<String, dynamic>>? oldestDoc})>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>?>? _typingSub;
  StreamSubscription<({bool isOnline, DateTime? lastSeen})>? _presenceSub;
  Timer? _typingDebounce;
  static const Duration _typingDebounceDuration = Duration(milliseconds: 400);

  /// When true, new messages trigger scroll to bottom. False when user has scrolled up (offset > 200).
  bool _shouldAutoScroll = true;

  /// Last message count from stream; used to scroll only when count increases (new message from other).
  int _lastStreamMessageCount = 0;

  DateTime? _lastMarkReadAt;
  static const Duration _markReadThrottle = Duration(seconds: 2);

  String? get currentUid => _firestoreChat.currentUid;

  @override
  void onInit() {
    super.onInit();
    final uid = currentUid;
    if (uid == null || uid.isEmpty || otherFirebaseUid.isEmpty) {
      debugPrint('❌ ChatController: missing uid or otherUid');
      return;
    }

    // 1) Build conversationId immediately
    final cid = FirestoreChatService.buildConversationId(uid, otherFirebaseUid);
    conversationId.value = cid;

    // 2) Attach message stream BEFORE getOrCreateConversation (realtime from cache/server)
    _bindMessageStream();

    // 3) Scroll listener for auto-scroll behavior (reverse list: bottom = 0)
    scrollController.addListener(_onScroll);

    // 4) Create conversation if missing + mark read (non-blocking)
    _ensureConversationAndMarkRead();

    // 5) Typing indicator
    _listenTyping(cid);

    // 6) Other user presence (isOnline, lastSeen) from Firestore users/{uid}
    _presenceSub?.cancel();
    _presenceSub = _firestoreChat.userPresenceStream(otherFirebaseUid).listen((p) {
      isOtherOnline.value = p.isOnline;
      otherLastSeen.value = p.lastSeen;
    }, onError: (e) => debugPrint('❌ ChatController presence: $e'));
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final offset = scrollController.offset;
    if (offset > 200) {
      _shouldAutoScroll = false;
    } else {
      _shouldAutoScroll = true;
    }
  }

  /// Bind Firestore snapshots to streamMessagesList. Replaces only the "current page" with server state;
  /// olderMessages is preserved. Scroll to bottom only when message count increases (new message sent or received).
  void _bindMessageStream() {
    final cid = conversationId.value;
    if (cid == null || cid.isEmpty) return;
    _messagesSub?.cancel();
    _messagesSub = _firestoreChat.streamMessagesWithOldestDoc(cid, limit: _pageSize).listen(
      (data) {
        final newCount = data.messages.length;
        streamMessagesList.assignAll(data.messages);
        _oldestMessageDoc = data.oldestDoc;
        _markReadIfNeeded();
        // Scroll to bottom only when a NEW message from the other user arrives (not after our send - we already scroll for optimistic)
        if (_shouldAutoScroll && newCount > _lastStreamMessageCount) {
          _lastStreamMessageCount = newCount;
          final lastFromOther = data.messages.isNotEmpty &&
              data.messages.last.senderId != currentUid;
          if (lastFromOther) {
            WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
          }
        } else {
          _lastStreamMessageCount = newCount;
        }
      },
      onError: (e) => debugPrint('❌ ChatController stream: $e'),
    );
  }

  /// Mark conversation read (updates unreadCount + lastReadAt so other user sees "seen"). Throttled to avoid excessive writes.
  void _markReadIfNeeded() {
    final now = DateTime.now();
    if (_lastMarkReadAt != null && now.difference(_lastMarkReadAt!) < _markReadThrottle) return;
    _lastMarkReadAt = now;
    final uid = currentUid;
    final cid = conversationId.value;
    if (uid == null || cid == null) return;
    _firestoreChat.markConversationRead(conversationId: cid, myUid: uid);
  }

  Future<void> _ensureConversationAndMarkRead() async {
    final uid = currentUid;
    final cid = conversationId.value;
    if (uid == null || cid == null) return;
    try {
      await _firestoreChat.getOrCreateConversation(
        myUid: uid,
        otherUid: otherFirebaseUid,
        otherUserPreview: {'name': otherUserName, 'avatar': otherUserAvatar},
      );
      await _firestoreChat.markConversationRead(conversationId: cid, myUid: uid);
    } catch (e) {
      debugPrint('❌ ChatController ensureConversation: $e');
    }
  }

  void _listenTyping(String cid) {
    _typingSub?.cancel();
    _typingSub = _firestoreChat.conversationStream(cid).listen((snap) {
      if (snap == null || !snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final typing = data['typing'] is Map ? data['typing'] as Map : null;
      isOtherTyping.value = typing?[otherFirebaseUid] == true;
    });
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    _typingDebounce?.cancel();
    _messagesSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    textController.dispose();
    scrollController.dispose();
    _setTyping(false);
    super.onClose();
  }

  void _setTyping(bool value) {
    final cid = conversationId.value;
    final uid = currentUid;
    if (cid == null || uid == null) return;
    _firestoreChat.setTyping(conversationId: cid, myUid: uid, isTyping: value);
  }

  void onTextChanged(String text) {
    messageInput.value = text;
    _typingDebounce?.cancel();
    if (text.trim().isEmpty) {
      _typingDebounce = Timer(_typingDebounceDuration, () => _setTyping(false));
    } else {
      _setTyping(true);
      _typingDebounce = Timer(_typingDebounceDuration, () => _setTyping(false));
    }
  }

  /// Scroll to bottom (reverse list: offset 0 = bottom).
  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> sendMessage() async {
    final text = messageInput.value.trim();
    if (text.isEmpty) return;
    final uid = currentUid;
    if (uid == null) {
      Get.snackbar('Error', 'You must be signed in to send messages.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final cid = conversationId.value;
    if (cid == null) {
      Get.snackbar('Error', 'Could not start conversation.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    // Clear input immediately for responsive UX
    messageInput.value = '';
    textController.clear();
    _setTyping(false);

    // Optimistic append: add message to list so it appears instantly; stream will replace with server copy
    final optimisticId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: optimisticId,
      senderId: uid,
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
      isSent: false,
    );
    streamMessagesList.add(optimisticMessage);
    if (_shouldAutoScroll) {
      // Wait for list to lay out with the new item so scroll shows full history, not only latest
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
      });
    }

    try {
      await _firestoreChat.sendMessage(
        conversationId: cid,
        myUid: uid,
        otherUid: otherFirebaseUid,
        text: text,
      );
    } catch (e) {
      debugPrint('❌ ChatController sendMessage: $e');
      // Remove optimistic message on failure so user can retry
      streamMessagesList.removeWhere((m) => m.id == optimisticId);
      Get.snackbar('Error', 'Failed to send message.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> loadOlder() async {
    final cid = conversationId.value;
    if (cid == null || isLoadingOlder.value || !hasMoreOlder.value) return;
    if (_oldestMessageDoc == null) return;
    isLoadingOlder.value = true;
    try {
      final result = await _firestoreChat.fetchOlderMessages(
        conversationId: cid,
        oldestDoc: _oldestMessageDoc!,
        limit: _pageSize,
      );
      if (result.messages.length < _pageSize) hasMoreOlder.value = false;
      if (result.messages.isNotEmpty) {
        olderMessages.insertAll(0, result.messages);
        _oldestMessageDoc = result.lastDoc;
      }
    } catch (e) {
      debugPrint('❌ loadOlder: $e');
    } finally {
      isLoadingOlder.value = false;
    }
  }
}
