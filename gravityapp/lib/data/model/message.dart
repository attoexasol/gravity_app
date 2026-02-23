import 'package:cloud_firestore/cloud_firestore.dart';

/// Message doc: conversations/{conversationId}/messages/{messageId}
/// Fields: senderId, text, type, createdAt, isRead, readAt (optional), editedAt, deletedAt (optional).
class Message {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final bool isSent;
  final DateTime? readAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = 'text',
    required this.timestamp,
    required this.isRead,
    required this.isSent,
    this.readAt,
    this.editedAt,
    this.deletedAt,
  });

  /// Create a [Message] from a Firestore document snapshot.
  /// Handles null createdAt safely; do not filter out or crash on null timestamp.
  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ??
        (data['created_at'] as Timestamp?)?.toDate();
    final DateTime timestamp = createdAt ?? DateTime.now();
    final readAtRaw = data['readAt'] ?? data['read_at'];
    final DateTime? readAt = readAtRaw is Timestamp
        ? readAtRaw.toDate()
        : (readAtRaw is DateTime)
            ? readAtRaw
            : null;
    final editedAtRaw = data['editedAt'];
    final DateTime? editedAt = editedAtRaw is Timestamp
        ? editedAtRaw.toDate()
        : (editedAtRaw is DateTime)
            ? editedAtRaw
            : null;
    final deletedAtRaw = data['deletedAt'];
    final DateTime? deletedAt = deletedAtRaw is Timestamp
        ? deletedAtRaw.toDate()
        : (deletedAtRaw is DateTime)
            ? deletedAtRaw
            : null;

    return Message(
      id: doc.id,
      senderId: (data['sender_id'] ?? data['senderId'] ?? '').toString(),
      text: (data['message'] ?? data['message_content'] ?? data['text'] ?? '').toString(),
      type: (data['type'] ?? 'text').toString(),
      timestamp: timestamp,
      isRead: (data['is_read'] ?? data['isRead'] ?? false) as bool,
      isSent: (data['is_sent'] ?? data['isSent'] ?? false) as bool,
      readAt: readAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
    );
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isSent,
    DateTime? readAt,
    DateTime? editedAt,
    DateTime? deletedAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
      readAt: readAt ?? this.readAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
