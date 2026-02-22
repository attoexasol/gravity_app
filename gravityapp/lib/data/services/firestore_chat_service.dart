// lib/data/services/firestore_chat_service.dart
// Production real-time chat: deterministic conversationId, unread map, typing, message pagination.
//
// Required Firestore composite index (create in Firebase Console when prompted):
//   Collection: conversations
//   Fields: members (array-contains), lastMessageTime (descending)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/message.dart';
import '../model/conversation_firestore_model.dart';

/// Firestore: users/{uid}, conversations/{conversationId}, conversations/{id}/messages/{messageId}.
/// conversationId = smallerUid + "_" + largerUid (deterministic for 1:1).
class FirestoreChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Deterministic 1:1 conversation id: smallerUid + "_" + largerUid.
  static String buildConversationId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  static String conversationIdFor(String uidA, String uidB) =>
      buildConversationId(uidA, uidB);

  static String getConversationId(String uid1, String uid2) =>
      buildConversationId(uid1, uid2);

  /// Real-time stream of a single conversation doc (for inbox row preview).
  /// Returns null in stream if doc does not exist.
  Stream<DocumentSnapshot<Map<String, dynamic>>?> conversationStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((snap) => snap.exists ? snap : null);
  }

  /// Create/update user profile in Firestore (call after signInWithCustomToken).
  /// users/{uid} with merge: true.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String role,
    String? profileImageUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'role': role,
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) 'profileImage': profileImageUrl,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('✅ Firestore users/$uid updated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firestore updateUserProfile: $e');
      }
      rethrow;
    }
  }

  /// Ensure other user's Firestore doc exists (e.g. when opening chat).
  /// Creates/merges users/{uid} so chat is not blocked by missing doc.
  Future<void> ensureUserDoc({
    required String uid,
    required String name,
    required String role,
    String? profileImageUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'role': role,
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) 'profileImage': profileImageUrl,
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('✅ Firestore users/$uid ensured (merge) for messaging');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firestore ensureUserDoc: $e');
      }
      rethrow;
    }
  }

  /// Set user offline and lastSeen (logout or app pause).
  Future<void> setUserOffline(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firestore setUserOffline: $e');
      }
    }
  }

  /// Update lastSeen only (e.g. on app pause).
  Future<void> updateLastSeen(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firestore updateLastSeen: $e');
      }
    }
  }

  /// Get or create conversation. Returns conversationId.
  /// Schema: members, createdAt, lastMessage, lastMessageTime, lastMessageSenderId,
  /// unreadCount Map, lastReadAt Map, typing Map, typingUpdatedAt Map.
  Future<String> getOrCreateConversation({
    required String myUid,
    required String otherUid,
    Map<String, dynamic>? otherUserPreview,
  }) async {
    if (myUid.isEmpty || otherUid == myUid) {
      throw ArgumentError('Invalid myUid or otherUid');
    }
    final cid = buildConversationId(myUid, otherUid);
    final ref = _firestore.collection('conversations').doc(cid);
    final doc = await ref.get();
    if (doc.exists) return cid;

    final members = [myUid, otherUid]..sort();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'members': members,
      'createdAt': now,
      'lastMessage': '',
      'lastMessageTime': now,
      'lastMessageSenderId': '',
      'unreadCount': {myUid: 0, otherUid: 0},
      'lastReadAt': {myUid: now, otherUid: now},
      'typing': {myUid: false, otherUid: false},
      'typingUpdatedAt': {myUid: now, otherUid: now},
    });
    if (kDebugMode) debugPrint('✅ Firestore conversation created: $cid');
    return cid;
  }

  /// Send message: add message doc + update conversation (lastMessage, unreadCount, typing).
  /// Increment unreadCount[otherUid], set unreadCount[myUid]=0, typing[myUid]=false.
  Future<void> sendMessage({
    required String conversationId,
    required String myUid,
    required String otherUid,
    required String text,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final messagesRef = convRef.collection('messages');
    final newMsgRef = messagesRef.doc();
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    batch.set(newMsgRef, {
      'senderId': myUid,
      'text': text,
      'type': 'text',
      'createdAt': now,
      'isRead': false,
    });

    final convDoc = await convRef.get();
    final data = convDoc.exists ? convDoc.data() ?? {} : {};
    final unreadCount = Map<String, int>.from(data['unreadCount'] is Map
        ? (data['unreadCount'] as Map).map((k, v) => MapEntry(k.toString(), (v is int) ? v : int.tryParse(v.toString()) ?? 0))
        : {});
    unreadCount[otherUid] = (unreadCount[otherUid] ?? 0) + 1;
    unreadCount[myUid] = 0;

    batch.set(convRef, {
      'lastMessage': text,
      'lastMessageTime': now,
      'lastMessageSenderId': myUid,
      'unreadCount': unreadCount,
      'typing.$myUid': false,
      'typingUpdatedAt.$myUid': now,
    }, SetOptions(merge: true));

    await batch.commit();
    if (kDebugMode) debugPrint('✅ Firestore message sent in $conversationId');
  }

  /// Stream inbox: conversations where members arrayContains myUid, orderBy lastMessageTime desc.
  /// Pagination via startAfter. Required index: (members array-contains, lastMessageTime desc).
  Stream<List<ConversationFirestoreModel>> streamInbox({
    required String myUid,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('conversations')
        .where('members', arrayContains: myUid)
        .orderBy('lastMessageTime', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.snapshots().map((snap) =>
        snap.docs.map((doc) => ConversationFirestoreModel.fromFirestore(doc)).toList());
  }

  /// Stream latest messages: orderBy createdAt desc limit [limit]. Chronological order in list (oldest first).
  /// Oldest doc (for pagination) is the last in snapshot.docs since query is desc.
  Stream<List<Message>> streamMessages(String conversationId, {int limit = 30}) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  /// Like streamMessages but also yields the oldest DocumentSnapshot for loadOlder pagination.
  Stream<({List<Message> messages, DocumentSnapshot<Map<String, dynamic>>? oldestDoc})> streamMessagesWithOldestDoc(
    String conversationId, {
    int limit = 30,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final oldestDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      return (messages: list, oldestDoc: oldestDoc);
    });
  }

  /// Load older messages: startAfterDocument(oldestDoc), orderBy createdAt desc, limit.
  /// Returns (messages in chronological order, lastDoc for next page).
  Future<({List<Message> messages, DocumentSnapshot<Map<String, dynamic>>? lastDoc})> fetchOlderMessages({
    required String conversationId,
    required DocumentSnapshot<Map<String, dynamic>> oldestDoc,
    required int limit,
  }) async {
    final snapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(oldestDoc)
        .limit(limit)
        .get();
    final list = snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (messages: list, lastDoc: lastDoc);
  }

  /// Mark conversation read: unreadCount[myUid]=0, lastReadAt[myUid]=now.
  /// Optionally mark recent messages isRead (orderBy createdAt desc limit 50, filter in memory); wrapped in try/catch.
  Future<void> markConversationRead({
    required String conversationId,
    required String myUid,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.set({
      'unreadCount.$myUid': 0,
      'lastReadAt.$myUid': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final messagesRef = convRef.collection('messages');
      final snapshot = await messagesRef
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      final batch = _firestore.batch();
      int count = 0;
      for (final doc in snapshot.docs) {
        final d = doc.data();
        if ((d['senderId'] ?? '') != myUid && (d['isRead'] != true)) {
          batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
          count++;
        }
      }
      if (count > 0) await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ markConversationRead (messages): $e');
    }
  }

  /// Set typing state for myUid. Debounce in controller (300–500ms).
  Future<void> setTyping({
    required String conversationId,
    required String myUid,
    required bool isTyping,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).set({
      'typing.$myUid': isTyping,
      'typingUpdatedAt.$myUid': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Real-time stream of conversations where members array-contains currentUid.
  /// orderBy lastMessageTime descending.
  /// Note: Firestore requires a composite index on (members, lastMessageTime). Create it in Firebase Console when prompted.
  Stream<List<Map<String, dynamic>>> streamConversations() {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('conversations')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Get single user doc (e.g. for other participant name/avatar).
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['uid'] = doc.id;
    return data;
  }

  /// Real-time stream of user presence from users/{uid}: isOnline and lastSeen.
  /// Use for chat header "Online" / "Last seen ...". uid can be Firebase UID or Laravel id (string).
  Stream<({bool isOnline, DateTime? lastSeen})> userPresenceStream(String uid) {
    if (uid.isEmpty) return Stream.value((isOnline: false, lastSeen: null));
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return (isOnline: false, lastSeen: null);
      final d = snap.data() ?? {};
      final isOnline = (d['isOnline'] ?? d['IsOnline'] ?? false) as bool;
      final lastSeenRaw = d['lastSeen'] ?? d['LastSeen'];
      final DateTime? lastSeen = lastSeenRaw is Timestamp
          ? lastSeenRaw.toDate()
          : (lastSeenRaw is DateTime)
              ? lastSeenRaw
              : null;
      return (isOnline: isOnline, lastSeen: lastSeen);
    });
  }

  /// Legacy: mark messages as read. Uses orderBy createdAt desc limit 50 only (no composite index).
  /// Filter in memory; do not use where isRead + where senderId to avoid index. Wrapped in try/catch.
  Future<void> markMessagesAsRead(String conversationId) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final d = doc.data();
        if ((d['senderId'] ?? '') != uid && (d['isRead'] != true)) {
          batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
        }
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ markMessagesAsRead: $e');
    }
  }
}
