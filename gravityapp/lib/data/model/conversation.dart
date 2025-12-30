import 'package:gravityapp/data/model/message.dart';
import 'package:gravityapp/presentation/messages/controllers/messages_controllers.dart';

enum ConversationRole {
  customer,
  coach,
}


class Conversation {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final ConversationRole role;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.role,
    required this.messages,
  });

  Conversation copyWith({
    String? id,
    String? name,
    String? avatar,
    String? lastMessage,
    DateTime? timestamp,
    int? unreadCount,
    ConversationRole? role,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      role: role ?? this.role,
      messages: messages ?? this.messages,
    );
  }
}
