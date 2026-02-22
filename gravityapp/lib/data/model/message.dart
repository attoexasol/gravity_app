import 'package:cloud_firestore/cloud_firestore.dart';

/// Message doc: conversations/{conversationId}/messages/{messageId}
/// Fields: senderId, text, type, createdAt, isRead, readAt (optional).
class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final bool isSent;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.isSent,
    this.readAt,
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

    return Message(
      id: doc.id,
      senderId: (data['sender_id'] ?? data['senderId'] ?? '').toString(),
      text: (data['message'] ?? data['message_content'] ?? data['text'] ?? '').toString(),
      timestamp: timestamp,
      isRead: (data['is_read'] ?? data['isRead'] ?? false) as bool,
      isSent: (data['is_sent'] ?? data['isSent'] ?? false) as bool,
      readAt: readAt,
    );
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    bool? isSent,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
      readAt: readAt ?? this.readAt,
    );
  }
}
