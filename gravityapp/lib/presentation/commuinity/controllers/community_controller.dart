import 'package:get/get.dart';

class CommunityController extends GetxController {
  // Posts list
  final RxList<Post> posts = <Post>[].obs;

  // UI state
  final RxInt selectedPostId = 0.obs;
  final RxString newComment = ''.obs;
  final RxString newReply = ''.obs;
  final RxInt replyingToPostId = 0.obs;
  final RxInt replyingToCommentId = 0.obs;
  final RxBool showCreatePost = false.obs;
  final RxString newPostText = ''.obs;
  final RxString selectedImage = ''.obs;

  // Reactions tracking
  final RxMap<int, Set<String>> activeReactions = <int, Set<String>>{}.obs;

  // Sample images for post creation
  final List<String> sampleImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
    'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadInitialPosts();
  }

  void _loadInitialPosts() {
    posts.value = [
      Post(
        id: 1,
        user: User(
          name: 'Sarah M.',
          avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400',
        ),
        image: 'https://images.unsplash.com/photo-1734989175071-fedc119fb52e?w=800',
        text: 'Healthy lunch today! 🥗 Feeling energized and ready to crush my afternoon goals.',
        timestamp: '2 hours ago',
        reactions: Reactions(heart: 24, thumbsUp: 18, fire: 12),
        comments: [
          Comment(
            id: 1,
            user: User(name: 'Mike R.', avatar: 'https://i.pravatar.cc/150?img=12'),
            text: 'Looks delicious! What\'s in it?',
            timestamp: '1 hour ago',
            replies: [
              Reply(
                id: 1,
                user: User(name: 'Sarah M.', avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400'),
                text: 'Quinoa, grilled chicken, avocado, and lots of veggies! 🥑',
                timestamp: '45 min ago',
              ),
            ],
          ),
          Comment(
            id: 2,
            user: User(name: 'Emma L.', avatar: 'https://i.pravatar.cc/150?img=5'),
            text: 'This is inspiring! I need to meal prep better.',
            timestamp: '30 min ago',
            replies: [],
          ),
        ],
      ),
      Post(
        id: 2,
        user: User(
          name: 'Mike R.',
          avatar: 'https://i.pravatar.cc/150?img=12',
        ),
        image: 'https://images.unsplash.com/photo-1522845015757-50bce044e5da?w=800',
        text: 'Morning workout done! ✅ 5k run + strength training. Who else got their steps in today?',
        timestamp: '5 hours ago',
        reactions: Reactions(heart: 42, thumbsUp: 31, fire: 28),
        comments: [
          Comment(
            id: 1,
            user: User(name: 'Alex K.', avatar: 'https://i.pravatar.cc/150?img=8'),
            text: 'Beast mode! 💪 I did a 3k this morning.',
            timestamp: '4 hours ago',
            replies: [],
          ),
        ],
      ),
      Post(
        id: 3,
        user: User(
          name: 'Emma L.',
          avatar: 'https://i.pravatar.cc/150?img=5',
        ),
        image: '',
        text: '8 hours of sleep for the first time this week! 😴 Small wins matter. Thank you Gravity for the reminder notifications!',
        timestamp: '8 hours ago',
        reactions: Reactions(heart: 35, thumbsUp: 22, fire: 15),
        comments: [
          Comment(
            id: 1,
            user: User(name: 'Sarah M.', avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400'),
            text: 'Sleep is so important! Great job! 🌙',
            timestamp: '7 hours ago',
            replies: [],
          ),
        ],
      ),
      Post(
        id: 4,
        user: User(
          name: 'Alex K.',
          avatar: 'https://i.pravatar.cc/150?img=8',
        ),
        image: 'https://images.unsplash.com/photo-1734989175071-fedc119fb52e?w=800',
        text: 'Meal prep Sunday! 🍱 Planning my week ahead. Consistency is key!',
        timestamp: '1 day ago',
        reactions: Reactions(heart: 28, thumbsUp: 19, fire: 14),
        comments: [],
      ),
    ];
  }

  void toggleReaction(int postId, String reaction) {
    final postReactions = activeReactions[postId] ?? <String>{};
    final isAdding = !postReactions.contains(reaction);

    if (postReactions.contains(reaction)) {
      postReactions.remove(reaction);
    } else {
      postReactions.add(reaction);
    }

    activeReactions[postId] = postReactions;
    activeReactions.refresh();

    // Update post reactions count
    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = posts[postIndex];
      final updatedReactions = post.reactions.copyWith();

      if (reaction == 'heart') {
        updatedReactions.heart += isAdding ? 1 : -1;
      } else if (reaction == 'thumbsUp') {
        updatedReactions.thumbsUp += isAdding ? 1 : -1;
      } else if (reaction == 'fire') {
        updatedReactions.fire += isAdding ? 1 : -1;
      }

      posts[postIndex] = post.copyWith(reactions: updatedReactions);
      posts.refresh();
    }
  }

  void addComment(int postId) {
    if (newComment.value.trim().isEmpty) return;

    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final newCommentObj = Comment(
        id: posts[postIndex].comments.length + 1,
        user: User(
          name: 'You',
          avatar: 'https://i.pravatar.cc/150?img=1',
        ),
        text: newComment.value,
        timestamp: 'Just now',
        replies: [],
      );

      final updatedComments = [...posts[postIndex].comments, newCommentObj];
      posts[postIndex] = posts[postIndex].copyWith(comments: updatedComments);
      posts.refresh();
    }

    newComment.value = '';
  }

  void addReply(int postId, int commentId) {
    if (newReply.value.trim().isEmpty) return;

    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final commentIndex = posts[postIndex].comments.indexWhere((c) => c.id == commentId);
      if (commentIndex != -1) {
        final newReplyObj = Reply(
          id: posts[postIndex].comments[commentIndex].replies.length + 1,
          user: User(
            name: 'You',
            avatar: 'https://i.pravatar.cc/150?img=1',
          ),
          text: newReply.value,
          timestamp: 'Just now',
        );

        final updatedReplies = [...posts[postIndex].comments[commentIndex].replies, newReplyObj];
        final updatedComment = posts[postIndex].comments[commentIndex].copyWith(replies: updatedReplies);
        final updatedComments = [...posts[postIndex].comments];
        updatedComments[commentIndex] = updatedComment;

        posts[postIndex] = posts[postIndex].copyWith(comments: updatedComments);
        posts.refresh();
      }
    }

    newReply.value = '';
    replyingToPostId.value = 0;
    replyingToCommentId.value = 0;
  }

  void createPost() {
    if (newPostText.value.trim().isEmpty) return;

    final newPost = Post(
      id: posts.length + 1,
      user: User(
        name: 'You',
        avatar: 'https://i.pravatar.cc/150?img=1',
      ),
      image: selectedImage.value,
      text: newPostText.value,
      timestamp: 'Just now',
      reactions: Reactions(heart: 0, thumbsUp: 0, fire: 0),
      comments: [],
    );

    posts.insert(0, newPost);
    posts.refresh();

    newPostText.value = '';
    selectedImage.value = '';
    showCreatePost.value = false;
  }

  void openComments(int postId) {
    selectedPostId.value = postId;
  }

  void closeComments() {
    selectedPostId.value = 0;
    newComment.value = '';
    replyingToPostId.value = 0;
    replyingToCommentId.value = 0;
    newReply.value = '';
  }

  void startReply(int postId, int commentId) {
    replyingToPostId.value = postId;
    replyingToCommentId.value = commentId;
  }

  void cancelReply() {
    replyingToPostId.value = 0;
    replyingToCommentId.value = 0;
    newReply.value = '';
  }

  Post? get selectedPost {
    if (selectedPostId.value == 0) return null;
    return posts.firstWhereOrNull((p) => p.id == selectedPostId.value);
  }
}

// Models
class User {
  final String name;
  final String avatar;

  User({required this.name, required this.avatar});
}

class Reactions {
  late final int heart;
  late final int thumbsUp;
  late final int fire;

  Reactions({required this.heart, required this.thumbsUp, required this.fire});

  Reactions copyWith({int? heart, int? thumbsUp, int? fire}) {
    return Reactions(
      heart: heart ?? this.heart,
      thumbsUp: thumbsUp ?? this.thumbsUp,
      fire: fire ?? this.fire,
    );
  }
}

class Reply {
  final int id;
  final User user;
  final String text;
  final String timestamp;

  Reply({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
  });

  Reply copyWith({int? id, User? user, String? text, String? timestamp}) {
    return Reply(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class Comment {
  final int id;
  final User user;
  final String text;
  final String timestamp;
  final List<Reply> replies;

  Comment({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
    required this.replies,
  });

  Comment copyWith({
    int? id,
    User? user,
    String? text,
    String? timestamp,
    List<Reply>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replies: replies ?? this.replies,
    );
  }
}

class Post {
  final int id;
  final User user;
  final String image;
  final String text;
  final String timestamp;
  final Reactions reactions;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.user,
    required this.image,
    required this.text,
    required this.timestamp,
    required this.reactions,
    required this.comments,
  });

  Post copyWith({
    int? id,
    User? user,
    String? image,
    String? text,
    String? timestamp,
    Reactions? reactions,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      user: user ?? this.user,
      image: image ?? this.image,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
    );
  }
}