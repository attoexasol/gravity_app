import 'post_user.dart';
import 'reply.dart';

/// Comment model for posts
/// Represents a comment on a post with its replies
class Comment {
  final int id;
  final int commentBy; // User ID who created the comment
  final PostUser user;
  final String text;
  final String timestamp;
  final List<Reply> replies;

  Comment({
    required this.id,
    required this.commentBy,
    required this.user,
    required this.text,
    required this.timestamp,
    required this.replies,
  });

  Comment copyWith({
    int? id,
    int? commentBy,
    PostUser? user,
    String? text,
    String? timestamp,
    List<Reply>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      commentBy: commentBy ?? this.commentBy,
      user: user ?? this.user,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replies: replies ?? this.replies,
    );
  }
}

