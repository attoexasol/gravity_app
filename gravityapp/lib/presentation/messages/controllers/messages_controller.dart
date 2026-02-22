import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/model/message_user_model.dart';
import '../../../data/services/firestore_chat_service.dart';
import '../../../data/services/user_api_service.dart';

/// Inbox controller: owns conversation stream subscriptions. UI is READ-ONLY.
/// Sort ONLY in onNewMessageReceived(). No state updates from build/postFrameCallback.
class InboxController extends GetxController {
  final UserApiService _userApi = UserApiService();
  final FirestoreChatService _firestoreChat = FirestoreChatService();

  final RxList<MessageUserModel> users = <MessageUserModel>[].obs;
  final RxMap<int, ({String? lastMessage, DateTime? lastMessageTime})> conversationPreviews = <int, ({String? lastMessage, DateTime? lastMessageTime})>{}.obs;

  /// Per-user state for UI (read-only from view). Updated only from stream callbacks.
  final RxMap<int, int> unreadCountByUser = <int, int>{}.obs;
  final RxMap<int, bool> typingByUser = <int, bool>{}.obs;

  final RxList<MessageUserModel> sortedUsersList = <MessageUserModel>[].obs;

  final Map<int, int> _lastProcessedTimestamp = {};
  final Map<int, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>?>> _conversationSubs = {};

  bool _hasNewMessage = false;
  bool _scrollScheduled = false;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  int currentPage = 1;
  static const int perPage = 10;
  bool hasMore = true;
  final RxString searchQuery = ''.obs;

  String? _currentUserRole;
  String? get currentUserRole => _currentUserRole;
  String? get currentFirebaseUid => _firestoreChat.currentUid;

  Timer? _searchDebounce;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 500);

  final ScrollController scrollController = ScrollController();
  static const double _loadMoreThreshold = 200;

  @override
  void onInit() {
    super.onInit();
    final stored = PreferencesService.getUserType()?.trim().toLowerCase();
    _currentUserRole = (stored != null && stored.isNotEmpty && (stored == 'coach' || stored == 'customer'))
        ? stored
        : 'customer';
    debugPrint('Current Role: $_currentUserRole');
    debugPrint('Fetching Opposite Role: $targetRole');
    scrollController.addListener(_onScroll);
    loadFirstPage();
  }

  @override
  void onClose() {
    _cancelAllConversationSubs();
    scrollController.removeListener(_onScroll);
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  void _cancelAllConversationSubs() {
    for (final sub in _conversationSubs.values) {
      sub.cancel();
    }
    _conversationSubs.clear();
  }

  void _onScroll() {
    if (!scrollController.hasClients || !hasMore || isLoading.value || isLoadingMore.value) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  /// Opposite role for API: Coach sees customers; Customer sees coaches.
  String get targetRole =>
      _currentUserRole == 'coach' ? 'customer' : 'coach';

  /// Refresh role from storage (so we always use latest after login).
  void _refreshStoredRole() {
    final stored = PreferencesService.getUserType()?.trim().toLowerCase();
    _currentUserRole = (stored != null && stored.isNotEmpty && (stored == 'coach' || stored == 'customer'))
        ? stored
        : 'customer';
  }

  Future<void> loadFirstPage() async {
    if (isLoading.value) return;
    _refreshStoredRole();
    isLoading.value = true;
    users.clear();
    currentPage = 1;
    hasMore = true;
    try {
      await _fetchAndAppend(search: searchQuery.value, resetPage: true);
    } catch (e) {
      debugPrint('❌ MessagesController loadFirstPage: $e');
      Get.snackbar(
        'Error',
        'Failed to load users. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      await _fetchAndAppend(search: searchQuery.value, resetPage: false);
    } catch (e) {
      debugPrint('❌ MessagesController loadMore: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _fetchAndAppend({
    required String search,
    required bool resetPage,
  }) async {
    if (resetPage) {
      currentPage = 1;
      hasMore = true;
    }
    debugPrint('Current Role: $_currentUserRole');
    debugPrint('Fetching Opposite Role: $targetRole');
    final result = await _userApi.fetchUsers(
      role: targetRole,
      search: search,
      page: currentPage,
      perPage: perPage,
    );
    if (resetPage) {
      users.assignAll(result.users);
    } else {
      users.addAll(result.users);
    }
    hasMore = result.hasMore;
    currentPage++;
    _computeAndAssignSortedList();
    if (resetPage) {
      _lastProcessedTimestamp.clear();
    }
    _attachConversationStreams();
  }

  /// Controller-owned subscriptions. Updates state ONLY from stream callbacks — never from UI.
  void _attachConversationStreams() {
    _cancelAllConversationSubs();
    final myUid = currentFirebaseUid;
    if (myUid == null) return;
    for (final u in users) {
      final otherUid = (u.firebaseUid != null && u.firebaseUid!.isNotEmpty) ? u.firebaseUid! : u.id.toString();
      final cid = getConversationId(otherUid);
      if (cid == null || cid.isEmpty) continue;
      final sub = _firestoreChat.conversationStream(cid).listen(
        (snap) => _onConversationSnapshot(u.id, otherUid, snap, myUid),
        onError: (e) => debugPrint('❌ Inbox stream ${u.id}: $e'),
      );
      _conversationSubs[u.id] = sub;
    }
  }

  /// Called only from stream listener (connectionState is active when we receive data). READ-ONLY for UI.
  void _onConversationSnapshot(int userId, String otherUid, DocumentSnapshot<Map<String, dynamic>>? snap, String myUid) {
    String? lastMessage;
    DateTime? lastMessageTime;
    int unread = 0;
    bool typing = false;
    if (snap != null && snap.exists) {
      final data = snap.data();
      if (data != null) {
        lastMessage = data['lastMessage'] as String?;
        if (lastMessage != null && lastMessage.isEmpty) lastMessage = null;
        final t = data['lastMessageTime'];
        if (t is Timestamp) lastMessageTime = t.toDate();
        final uc = data['unreadCount'];
        if (uc is Map) {
          final v = uc[myUid];
          if (v != null) unread = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
        }
        final typ = data['typing'];
        if (typ is Map) typing = typ[otherUid] == true;
      }
    }
    _applyConversationUpdate(userId, lastMessage: lastMessage, lastMessageTime: lastMessageTime, unreadCount: unread, isTyping: typing);
  }

  /// State mutation ONLY here (from stream callback). Guards prevent duplicate events and unnecessary sort/scroll.
  void _applyConversationUpdate(int userId, {String? lastMessage, DateTime? lastMessageTime, int unreadCount = 0, bool isTyping = false}) {
    final incomingMillis = lastMessageTime?.millisecondsSinceEpoch;
    if (incomingMillis != null && _lastProcessedTimestamp[userId] == incomingMillis) {
      unreadCountByUser[userId] = unreadCount;
      typingByUser[userId] = isTyping;
      return;
    }
    final prev = conversationPreviews[userId];
    if (prev != null && prev.lastMessage == lastMessage && _sameDateTime(prev.lastMessageTime, lastMessageTime)) {
      unreadCountByUser[userId] = unreadCount;
      typingByUser[userId] = isTyping;
      return;
    }
    final isNewMessage = prev != null &&
        lastMessageTime != null &&
        prev.lastMessageTime != null &&
        lastMessageTime.millisecondsSinceEpoch > prev.lastMessageTime!.millisecondsSinceEpoch;
    conversationPreviews[userId] = (lastMessage: lastMessage, lastMessageTime: lastMessageTime);
    if (incomingMillis != null) _lastProcessedTimestamp[userId] = incomingMillis;
    unreadCountByUser[userId] = unreadCount;
    typingByUser[userId] = isTyping;
    _computeAndAssignSortedList();
    if (isNewMessage) onNewMessageReceived();
  }

  /// Sort runs ONLY here and after fetch. Never in UI. Do not update state if list order unchanged.
  void _computeAndAssignSortedList() {
    final list = users.map((u) {
      final preview = conversationPreviews[u.id];
      return u.copyWith(
        lastMessage: preview?.lastMessage ?? u.lastMessage,
        lastMessageTime: preview?.lastMessageTime ?? u.lastMessageTime,
      );
    }).toList();
    list.sort((a, b) {
      final aTime = a.lastMessageTime;
      final bTime = b.lastMessageTime;
      if (aTime != null && bTime != null) return bTime.compareTo(aTime);
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return 0;
    });
    if (_listOrderEquals(sortedUsersList, list)) return;
    sortedUsersList.assignAll(list);
  }

  bool _listOrderEquals(List<MessageUserModel> a, List<MessageUserModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// Search: debounce 500ms, reset pagination, reload.
  void search(String query) {
    searchQuery.value = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      loadFirstPage();
    });
  }

  /// ONLY place that triggers scroll. Sort already done in _applyConversationUpdate.
  void onNewMessageReceived() {
    _hasNewMessage = true;
    if (!_scrollScheduled) {
      _scrollScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTopOnce());
    }
  }

  bool _sameDateTime(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.millisecondsSinceEpoch == b.millisecondsSinceEpoch;
  }

  /// Run once per new message: scroll to top then reset flags. Never called from build/render.
  void _scrollToTopOnce() {
    if (!_hasNewMessage) {
      _scrollScheduled = false;
      return;
    }
    _hasNewMessage = false;
    _scrollScheduled = false;
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// conversationId for a user row (current + other firebase uid).
  String? getConversationId(String? otherFirebaseUid) {
    final uid = currentFirebaseUid;
    if (uid == null || otherFirebaseUid == null) return null;
    return FirestoreChatService.getConversationId(uid, otherFirebaseUid);
  }

  /// Stream of user presence (isOnline) for list row. READ-ONLY in UI — does not mutate controller state.
  /// uid can be Firebase UID or Laravel id string (same as used for openChat).
  Stream<bool> userPresenceStream(String uid) {
    if (uid.isEmpty) return Stream.value(false);
    return _firestoreChat.userPresenceStream(uid).map((p) => p.isOnline);
  }

  /// Navigate to chat with this user. Do NOT create conversation until first message.
  /// Chat does NOT depend on Firestore user doc existence; conversation is created on first send.
  void openChat(MessageUserModel user) {
    // Always use string UID: prefer Firebase UID from API, fallback to Laravel id for routing
    final otherUid = (user.firebaseUid != null && user.firebaseUid!.isNotEmpty)
        ? user.firebaseUid!
        : user.id.toString();
    debugPrint('Opening chat with UID: $otherUid');
    Get.toNamed(
      AppRoutes.chat,
      arguments: {
        'otherUserId': otherUid,
        'otherUserName': user.name,
        'otherUserAvatar': user.profileImage,
      },
    );
  }
}
