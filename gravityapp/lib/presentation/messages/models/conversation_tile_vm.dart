// lib/presentation/messages/models/conversation_tile_vm.dart
// View model for one inbox row: other user + last message + unread + typing.

class ConversationTileVM {
  final String conversationId;
  final String otherUid;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;
  final bool isOtherTyping;

  const ConversationTileVM({
    required this.conversationId,
    required this.otherUid,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSenderId = '',
    this.unreadCount = 0,
    this.isOtherTyping = false,
  });

  ConversationTileVM copyWith({
    String? conversationId,
    String? otherUid,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isOtherTyping,
  }) {
    return ConversationTileVM(
      conversationId: conversationId ?? this.conversationId,
      otherUid: otherUid ?? this.otherUid,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
    );
  }
}
