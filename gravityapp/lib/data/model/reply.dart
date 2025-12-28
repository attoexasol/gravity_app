import 'post_user.dart';

/// Reply model for comments
/// Represents a reply to a comment
class Reply {
  final int id;
  final PostUser user;
  final String text;
  final String timestamp;

  Reply({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
  });

  Reply copyWith({int? id, PostUser? user, String? text, String? timestamp}) {
    return Reply(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

