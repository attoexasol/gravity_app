/// User row for messaging inbox (from API + optional Firestore conversation preview).
class MessageUserModel {
  final int id;
  final String name;
  final String? profileImage;
  final String? firebaseUid;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  const MessageUserModel({
    required this.id,
    required this.name,
    this.profileImage,
    this.firebaseUid,
    this.lastMessage,
    this.lastMessageTime,
  });

  MessageUserModel copyWith({
    int? id,
    String? name,
    String? profileImage,
    String? firebaseUid,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return MessageUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }

  bool get hasConversation =>
      lastMessage != null ||
      (lastMessageTime != null && lastMessageTime!.millisecondsSinceEpoch > 0);
}
