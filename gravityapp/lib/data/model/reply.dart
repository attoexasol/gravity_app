import 'post_user.dart';

/// Reply model for comments
/// Represents a reply to a comment
class Reply {
  final int id;
  final PostUser user;
  final String text;
  final String timestamp;
  /// User ID who wrote the reply (for edit/delete permission). From API comment_by.
  final int? replyBy;

  Reply({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
    this.replyBy,
  });

  Reply copyWith({
    int? id,
    PostUser? user,
    String? text,
    String? timestamp,
    int? replyBy,
  }) {
    return Reply(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replyBy: replyBy ?? this.replyBy,
    );
  }
}

