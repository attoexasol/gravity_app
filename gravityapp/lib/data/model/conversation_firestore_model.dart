// lib/data/model/conversation_firestore_model.dart
// Firestore conversation document schema: unread, typing, lastReadAt.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation doc: conversations/{conversationId}
/// Fields: members, createdAt, lastMessage, lastMessageTime, lastMessageSenderId,
/// unreadCount Map<String,int>, lastReadAt Map<String,Timestamp>, typing Map<String,bool>, typingUpdatedAt Map<String,Timestamp>.
class ConversationFirestoreModel {
  final String id;
  final List<String> members;
  final DateTime? createdAt;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSenderId;
  /// unreadCount[uid] = count for that user. Do not use expensive count queries.
  final Map<String, int> unreadCount;
  /// lastReadAt[uid] = timestamp when user last read.
  final Map<String, Timestamp> lastReadAt;
  /// typing[uid] = true if user is typing.
  final Map<String, bool> typing;
  /// typingUpdatedAt[uid] for TTL / staleness.
  final Map<String, Timestamp> typingUpdatedAt;

  const ConversationFirestoreModel({
    required this.id,
    required this.members,
    this.createdAt,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSenderId = '',
    this.unreadCount = const {},
    this.lastReadAt = const {},
    this.typing = const {},
    this.typingUpdatedAt = const {},
  });

  int unreadFor(String uid) => unreadCount[uid] ?? 0;
  bool isTyping(String uid) => typing[uid] == true;

  factory ConversationFirestoreModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    List<String> members = [];
    if (d['members'] is List) {
      members = (d['members'] as List).map((e) => e.toString()).toList();
    }
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
    final lastMessageTime = (d['lastMessageTime'] as Timestamp?)?.toDate();
    Map<String, int> unreadCount = {};
    if (d['unreadCount'] is Map) {
      (d['unreadCount'] as Map).forEach((k, v) {
        if (k != null && v != null) unreadCount[k.toString()] = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
      });
    }
    Map<String, Timestamp> lastReadAt = {};
    if (d['lastReadAt'] is Map) {
      (d['lastReadAt'] as Map).forEach((k, v) {
        if (k != null && v is Timestamp) lastReadAt[k.toString()] = v;
      });
    }
    Map<String, bool> typing = {};
    if (d['typing'] is Map) {
      (d['typing'] as Map).forEach((k, v) {
        if (k != null && v != null) typing[k.toString()] = v == true;
      });
    }
    Map<String, Timestamp> typingUpdatedAt = {};
    if (d['typingUpdatedAt'] is Map) {
      (d['typingUpdatedAt'] as Map).forEach((k, v) {
        if (k != null && v is Timestamp) typingUpdatedAt[k.toString()] = v;
      });
    }
    return ConversationFirestoreModel(
      id: doc.id,
      members: members,
      createdAt: createdAt,
      lastMessage: (d['lastMessage'] ?? '').toString(),
      lastMessageTime: lastMessageTime,
      lastMessageSenderId: (d['lastMessageSenderId'] ?? d['lastSenderId'] ?? '').toString(),
      unreadCount: unreadCount,
      lastReadAt: lastReadAt,
      typing: typing,
      typingUpdatedAt: typingUpdatedAt,
    );
  }
}
