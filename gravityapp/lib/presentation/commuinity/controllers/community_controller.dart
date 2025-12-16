import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/community_repository.dart';

class CommunityController extends GetxController {
  // Repository for API calls
  final CommunityRepository _communityRepository = CommunityRepository();

  // Communities from API
  final RxList<Map<String, dynamic>> communities = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingCommunities = false.obs;

  // Single community from API
  final Rx<Map<String, dynamic>?> singleCommunity = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoadingSingleCommunity = false.obs;
  final RxString singleCommunityError = ''.obs;

  // Create community state
  final RxBool isCreatingCommunity = false.obs;
  final RxString createCommunityError = ''.obs;
  final Rx<Map<String, dynamic>?> createdCommunity = Rx<Map<String, dynamic>?>(null);

  // Update community state
  final RxBool isUpdatingCommunity = false.obs;
  final RxString updateCommunityError = ''.obs;
  final Rx<Map<String, dynamic>?> updatedCommunity = Rx<Map<String, dynamic>?>(null);

  // Delete community state
  final RxBool isDeletingCommunity = false.obs;
  final RxString deleteCommunityError = ''.obs;

  // Posts list
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoadingPosts = false.obs;
  final RxString postsError = ''.obs;

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
    _fetchCommunities();
    _fetchAllPosts();
  }

  /// Fetch communities from API
  Future<void> _fetchCommunities() async {
    isLoadingCommunities.value = true;
    try {
      debugPrint('🔄 Fetching communities from API...');
      final response = await _communityRepository.getAllCommunities();
      
      if (response.isSuccess && response.data != null) {
        communities.value = response.data!
            .map((item) => item as Map<String, dynamic>)
            .toList();
        debugPrint('✅ Successfully loaded ${communities.length} communities');
      } else {
        debugPrint('❌ Failed to load communities: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching communities: $e');
    } finally {
      isLoadingCommunities.value = false;
    }
  }

  /// Fetch single community by ID from API
  Future<void> fetchSingleCommunity(int communityId) async {
    isLoadingSingleCommunity.value = true;
    singleCommunityError.value = '';
    singleCommunity.value = null;

    try {
      debugPrint('🔄 Fetching single community (ID: $communityId) from API...');
      final response = await _communityRepository.getSingleCommunity(
        communityId: communityId,
      );

      if (response.isSuccess && response.data != null) {
        singleCommunity.value = response.data!;
        debugPrint('✅ Successfully loaded community: ${response.data!['community_name']}');
      } else {
        singleCommunityError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load community';
        debugPrint('❌ Failed to load community: ${response.message}');
      }
    } catch (e) {
      singleCommunityError.value = 'An error occurred while loading community';
      debugPrint('❌ Error fetching single community: $e');
    } finally {
      isLoadingSingleCommunity.value = false;
    }
  }

  /// Create a new community
  Future<bool> createCommunity({
    required String communityName,
    required String communityDescription,
  }) async {
    isCreatingCommunity.value = true;
    createCommunityError.value = '';
    createdCommunity.value = null;

    try {
      debugPrint('🔄 Creating community: $communityName...');
      final response = await _communityRepository.createCommunity(
        communityName: communityName,
        communityDescription: communityDescription,
      );

      if (response.isSuccess && response.data != null) {
        createdCommunity.value = response.data!;
        debugPrint('✅ Successfully created community: ${response.data!['community_name']}');
        // Optionally refresh the communities list
        _fetchCommunities();
        return true;
      } else {
        createCommunityError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to create community';
        debugPrint('❌ Failed to create community: ${response.message}');
        return false;
      }
    } catch (e) {
      createCommunityError.value = 'An error occurred while creating community';
      debugPrint('❌ Error creating community: $e');
      return false;
    } finally {
      isCreatingCommunity.value = false;
    }
  }

  /// Update an existing community
  Future<bool> updateCommunity({
    required int communityId,
    required String communityName,
    required String communityDescription,
  }) async {
    isUpdatingCommunity.value = true;
    updateCommunityError.value = '';
    updatedCommunity.value = null;

    try {
      debugPrint('🔄 Updating community (ID: $communityId): $communityName...');
      final response = await _communityRepository.updateCommunity(
        communityId: communityId,
        communityName: communityName,
        communityDescription: communityDescription,
      );

      if (response.isSuccess && response.data != null) {
        updatedCommunity.value = response.data!;
        debugPrint('✅ Successfully updated community: ${response.data!['community_name']}');
        // Update the community in the list if it exists
        final index = communities.indexWhere((c) => c['id'] == communityId);
        if (index != -1) {
          communities[index] = response.data!;
        }
        // Optionally refresh the communities list
        _fetchCommunities();
        return true;
      } else {
        updateCommunityError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to update community';
        debugPrint('❌ Failed to update community: ${response.message}');
        return false;
      }
    } catch (e) {
      updateCommunityError.value = 'An error occurred while updating community';
      debugPrint('❌ Error updating community: $e');
      return false;
    } finally {
      isUpdatingCommunity.value = false;
    }
  }

  /// Delete a community by ID
  Future<bool> deleteCommunity(int communityId) async {
    isDeletingCommunity.value = true;
    deleteCommunityError.value = '';

    try {
      debugPrint('🔄 Deleting community (ID: $communityId)...');
      final response = await _communityRepository.deleteCommunity(
        communityId: communityId,
      );

      if (response.isSuccess) {
        debugPrint('✅ Successfully deleted community: ${response.message}');
        // Remove the community from the local list
        communities.removeWhere((c) => c['id'] == communityId);
        // Optionally refresh the communities list
        _fetchCommunities();
        return true;
      } else {
        deleteCommunityError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to delete community';
        debugPrint('❌ Failed to delete community: ${response.message}');
        return false;
      }
    } catch (e) {
      deleteCommunityError.value = 'An error occurred while deleting community';
      debugPrint('❌ Error deleting community: $e');
      return false;
    } finally {
      isDeletingCommunity.value = false;
    }
  }

  /// Fetch all posts from API
  Future<void> _fetchAllPosts() async {
    isLoadingPosts.value = true;
    postsError.value = '';

    try {
      debugPrint('🔄 Fetching posts from API...');
      final response = await _communityRepository.getAllPosts();

      if (response.isSuccess && response.data != null) {
        final List<Post> fetchedPosts = _mapApiResponseToPosts(response.data!);
        if (fetchedPosts.isNotEmpty) {
          posts.value = fetchedPosts;
          debugPrint('✅ Successfully loaded ${fetchedPosts.length} posts from API');
        } else {
          debugPrint('⚠️ No posts found in API response, keeping initial posts');
        }
      } else {
        postsError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load posts';
        debugPrint('❌ Failed to load posts: ${response.message}');
      }
    } catch (e) {
      postsError.value = 'An error occurred while loading posts';
      debugPrint('❌ Error fetching posts: $e');
    } finally {
      isLoadingPosts.value = false;
    }
  }

  /// Map API response to Post models
  List<Post> _mapApiResponseToPosts(List<dynamic> data) {
    try {
      return data.map((item) {
        final Map<String, dynamic> postData = item is Map<String, dynamic>
            ? item
            : {};

        // Extract user information
        final userData = postData['user'] ?? {};
        final userName = userData is Map
            ? (userData['name']?.toString() ?? 'Unknown User')
            : 'Unknown User';
        final userProfileImage = userData is Map
            ? (userData['profile_image']?.toString() ?? '')
            : '';
        
        // Construct full image URL if post_image exists
        String postImageUrl = '';
        if (postData['post_image'] != null && postData['post_image'].toString().isNotEmpty) {
          final imagePath = postData['post_image'].toString();
          if (imagePath.startsWith('http')) {
            postImageUrl = imagePath;
          } else {
            // Construct full URL
            postImageUrl = 'https://gravity.attoexasolutions.com/storage/$imagePath';
          }
        }

        // Extract post information
        final postId = postData['id'] is int ? postData['id'] : int.tryParse(postData['id'].toString()) ?? 0;
        final postText = postData['post_text']?.toString() ?? '';
        
        // Format timestamp
        final createdAt = postData['created_at']?.toString() ?? '';
        final timestamp = _formatTimestamp(createdAt);

        // Extract reactions
        final heartCount = postData['like_count'] is int 
            ? postData['like_count'] 
            : int.tryParse(postData['like_count'].toString()) ?? 0;
        final thumbsUpCount = postData['thumsup_count'] is int
            ? postData['thumsup_count']
            : int.tryParse(postData['thumsup_count'].toString()) ?? 0;
        final fireCount = postData['other_count'] is int
            ? postData['other_count']
            : int.tryParse(postData['other_count'].toString()) ?? 0;

        // Construct user avatar URL if profile_image exists
        String userAvatarUrl = '';
        if (userProfileImage.isNotEmpty) {
          if (userProfileImage.startsWith('http')) {
            userAvatarUrl = userProfileImage;
          } else {
            userAvatarUrl = 'https://gravity.attoexasolutions.com/storage/$userProfileImage';
          }
        } else {
          // Default avatar if no profile image
          userAvatarUrl = 'https://i.pravatar.cc/150?img=${postId % 10}';
        }

        return Post(
          id: postId,
          user: User(
            name: userName,
            avatar: userAvatarUrl,
          ),
          image: postImageUrl,
          text: postText,
          timestamp: timestamp,
          reactions: Reactions(
            heart: heartCount,
            thumbsUp: thumbsUpCount,
            fire: fireCount,
          ),
          comments: [], // API response doesn't include comments
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error mapping API response to posts: $e');
      return [];
    }
  }

  /// Format timestamp to relative time
  String _formatTimestamp(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
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

  // Match React: User can only have ONE reaction per post
  // If clicking the same reaction, remove it (toggle off)
  // If clicking a different reaction, remove previous and add new one
  void toggleReaction(int postId, String reaction) {
    final postReactions = Set<String>.from(activeReactions[postId] ?? <String>{});
    
    // Check if user already has this exact reaction
    final hasThisReaction = postReactions.contains(reaction);
    
    // Get the previous reaction if user had one (can only have one at a time)
    final previousReaction = postReactions.isNotEmpty ? postReactions.first : null;
    
    // Clear all reactions for this post (since user can only have one)
    postReactions.clear();
    
    // If clicking the same reaction, remove it (toggle off)
    // If clicking a different reaction, add the new one
    if (!hasThisReaction) {
      postReactions.add(reaction);
    }
    
    activeReactions[postId] = postReactions;
    activeReactions.refresh();

    // Update post reactions count
    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = posts[postIndex];
      final currentReactions = post.reactions;
      
      // Start with current reaction counts
      int newHeart = currentReactions.heart;
      int newThumbsUp = currentReactions.thumbsUp;
      int newFire = currentReactions.fire;
      
      // Decrement previous reaction if user had one
      if (previousReaction != null) {
        if (previousReaction == 'heart') {
          newHeart = (newHeart - 1).clamp(0, double.infinity).toInt();
        } else if (previousReaction == 'thumbsUp') {
          newThumbsUp = (newThumbsUp - 1).clamp(0, double.infinity).toInt();
        } else if (previousReaction == 'fire') {
          newFire = (newFire - 1).clamp(0, double.infinity).toInt();
        }
      }
      
      // Increment new reaction if user is adding one (not removing)
      if (!hasThisReaction) {
        if (reaction == 'heart') {
          newHeart = newHeart + 1;
        } else if (reaction == 'thumbsUp') {
          newThumbsUp = newThumbsUp + 1;
        } else if (reaction == 'fire') {
          newFire = newFire + 1;
        }
      }
      
      // Create updated reactions with new counts
      final updatedReactions = currentReactions.copyWith(
        heart: newHeart,
        thumbsUp: newThumbsUp,
        fire: newFire,
      );

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