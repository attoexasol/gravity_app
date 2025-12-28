import 'post_user.dart';
import 'reactions.dart';
import 'comment.dart';

class Post {
  final int id;
  final PostUser user;
  final String image;
  final String text;
  final String timestamp;
  final Reactions reactions;
  final List<Comment> comments;
  final bool isPinned; // WhatsApp-style pinning: true if post is pinned
  final int communityId; // Required for pinning API call

  Post({
    required this.id,
    required this.user,
    required this.image,
    required this.text,
    required this.timestamp,
    required this.reactions,
    required this.comments,
    this.isPinned = false, // Default to false if not provided
    this.communityId = 0, // Default to 0 if not provided
  });

  Post copyWith({
    int? id,
    PostUser? user,
    String? image,
    String? text,
    String? timestamp,
    Reactions? reactions,
    List<Comment>? comments,
    bool? isPinned,
    int? communityId,
  }) {
    return Post(
      id: id ?? this.id,
      user: user ?? this.user,
      image: image ?? this.image,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      isPinned: isPinned ?? this.isPinned,
      communityId: communityId ?? this.communityId,
    );
  }
}
