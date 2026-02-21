import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final bool isSent;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.isSent,
  });

  /// Create a [Message] from a Firestore document snapshot.
  /// Handles Timestamp and common field names (snake_case / camelCase).
  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['created_at'] ?? data['createdAt'];
    DateTime timestamp = DateTime.now();
    if (createdAt != null) {
      if (createdAt is Timestamp) {
        timestamp = createdAt.toDate();
      } else if (createdAt is DateTime) {
        timestamp = createdAt;
      } else if (createdAt is String) {
        timestamp = DateTime.tryParse(createdAt) ?? timestamp;
      }
    }
    return Message(
      id: doc.id,
      senderId: (data['sender_id'] ?? data['senderId'] ?? '').toString(),
      text: (data['message'] ?? data['message_content'] ?? data['text'] ?? '').toString(),
      timestamp: timestamp,
      isRead: (data['is_read'] ?? data['isRead'] ?? false) as bool,
      isSent: (data['is_sent'] ?? data['isSent'] ?? false) as bool,
    );
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    bool? isSent,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
    );
  }
}
