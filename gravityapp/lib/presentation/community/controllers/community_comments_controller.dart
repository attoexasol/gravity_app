import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/model/post.dart';
import '../../../data/model/post_user.dart';
import '../../../data/model/reply.dart';
import '../../../data/model/comment.dart';

/// Mixin that holds all comment and reply related state and logic for the community feature.
/// Use with: class CommunityController extends GetxController with CommunityCommentsController
mixin CommunityCommentsController on GetxController {
  // Dependencies provided by the host controller
  CommunityRepository get communityRepository;
  RxList<Post> get posts;
  Rx<Post?> get singlePost;
  int get currentUserId;
  String get currentUserName;
  String get currentUserProfileImage;

  // Create comment state
  final RxBool isCreatingComment = false.obs;
  final RxBool isCreatingReply = false.obs;
  final RxString createCommentError = ''.obs;

  // Comments list from API
  final RxList<Comment> postComments = <Comment>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxString commentsError = ''.obs;

  // Single comment state (for fetching replies)
  final RxBool isLoadingSingleComment = false.obs;

  // Update comment state
  final RxBool isUpdatingComment = false.obs;
  final RxString updateCommentError = ''.obs;
  final RxInt editingCommentId = 0.obs;
  /// When non-zero, we're editing a reply; value is the parent comment id.
  final RxInt editingReplyParentCommentId = 0.obs;
  final RxString editCommentText = ''.obs;
  final RxInt editCommentPostId = 0.obs;
  final TextEditingController editCommentTextController =
      TextEditingController();

  // Delete comment state
  final RxBool isDeletingComment = false.obs;
  final RxString deleteCommentError = ''.obs;

  // UI state for comments
  final RxString newComment = ''.obs;
  final RxString newReply = ''.obs;
  final RxInt replyingToPostId = 0.obs;
  final RxInt replyingToCommentId = 0.obs;

  final TextEditingController commentTextController = TextEditingController();
  final TextEditingController replyTextController = TextEditingController();

  /// Live total comment count (top-level + replies) for the current post from loaded postComments.
  int get currentPostCommentsTotalFromList =>
      postComments.fold<int>(0, (sum, c) => sum + 1 + c.replies.length);

  /// Call from host controller's onClose to dispose comment text controllers.
  void disposeCommentControllers() {
    commentTextController.dispose();
    replyTextController.dispose();
    editCommentTextController.dispose();
  }

  bool isCurrentUserComment(Comment comment) {
    return currentUserId > 0 && comment.commentBy == currentUserId;
  }

  bool isCurrentUserReply(Reply reply) {
    if (currentUserId <= 0) return false;
    if (reply.replyBy != null) return reply.replyBy == currentUserId;
    final name = PreferencesService.getUserName() ?? '';
    return name.isNotEmpty && reply.user.name == name;
  }

  void showCommentActions(int postId, Comment comment) {
    if (!isCurrentUserComment(comment)) return;

    Get.bottomSheet(
      Builder(
        builder: (BuildContext bottomSheetContext) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2342).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Comment Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2342),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          openEditComment(postId, comment);
                        });
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B8A9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 32,
                              color: Color(0xFF00B8A9),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0A2342),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          confirmDeleteComment(postId, comment.id);
                        });
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.delete_outlined,
                              size: 32,
                              color: Color(0xFFE53935),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0A2342),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void showReplyActions(int postId, Comment parentComment, Reply reply) {
    if (!isCurrentUserReply(reply)) return;

    Get.bottomSheet(
      Builder(
        builder: (BuildContext bottomSheetContext) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2342).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reply Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2342),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          openEditReply(postId, parentComment, reply);
                        });
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B8A9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 32,
                              color: Color(0xFF00B8A9),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0A2342),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          confirmDeleteReply(postId, parentComment, reply);
                        });
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.delete_outlined,
                              size: 32,
                              color: Color(0xFFE53935),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0A2342),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> addComment(int postId) async {
    if (newComment.value.trim().isEmpty) return;
    if (isCreatingComment.value) return;

    isCreatingComment.value = true;
    createCommentError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        createCommentError.value =
            'Authentication required. Please login again.';
        debugPrint('❌ AddComment Error: No auth token found');
        isCreatingComment.value = false;

        Get.snackbar(
          'Error',
          createCommentError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
        return;
      }

      debugPrint('🔄 Creating comment via API...');
      debugPrint('   - Post ID: $postId');
      debugPrint('   - Comment: ${newComment.value}');

      final response = await communityRepository.createPostComment(
        apiToken: apiToken,
        postId: postId,
        comments: newComment.value,
        commentId: null,
      );

      if (response.isSuccess) {
        debugPrint('✅ Comment created successfully: ${response.message}');

        final commentUserName = currentUserName;
        final commentUserAvatar = currentUserProfileImage;

        int commentId = 0;
        if (response.data != null && response.data!['id'] != null) {
          commentId = response.data!['id'] is int
              ? response.data!['id']
              : int.tryParse(response.data!['id'].toString()) ??
                    DateTime.now().millisecondsSinceEpoch;
        } else {
          commentId = DateTime.now().millisecondsSinceEpoch;
        }

        int commentByUserId = response.data?['comment_by'] is int
            ? response.data!['comment_by']
            : (PreferencesService.getUserId() ?? 0);

        final newCommentObj = Comment(
          id: commentId,
          commentBy: commentByUserId,
          user: PostUser(name: commentUserName, avatar: commentUserAvatar),
          text: response.data?['comments']?.toString() ?? newComment.value,
          timestamp: 'Just now',
          replies: [],
        );

        postComments.add(newCommentObj);
        postComments.refresh();

        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final updatedComments = [...posts[postIndex].comments, newCommentObj];
          posts[postIndex] = posts[postIndex].copyWith(
            comments: updatedComments,
          );
          posts.refresh();
        }

        if (singlePost.value != null && singlePost.value!.id == postId) {
          final updatedComments = [
            ...singlePost.value!.comments,
            newCommentObj,
          ];
          singlePost.value = singlePost.value!.copyWith(
            comments: updatedComments,
          );
        }

        newComment.value = '';
        commentTextController.clear();

        debugPrint('✅ Comment added to post $postId');
      } else {
        createCommentError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to create comment';
        debugPrint('❌ Failed to create comment: ${response.message}');

        Get.snackbar(
          'Error',
          createCommentError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      createCommentError.value = 'An error occurred while creating comment';
      debugPrint('❌ Error creating comment: $e');

      Get.snackbar(
        'Error',
        createCommentError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isCreatingComment.value = false;
    }
  }

  Future<void> addReply(int postId, int commentId) async {
    if (newReply.value.trim().isEmpty) return;
    if (isCreatingReply.value) return;

    isCreatingReply.value = true;
    createCommentError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        createCommentError.value =
            'Authentication required. Please login again.';
        debugPrint('❌ AddReply Error: No auth token found');
        isCreatingReply.value = false;

        Get.snackbar(
          'Error',
          createCommentError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
        return;
      }

      debugPrint('🔄 Creating reply via API...');
      debugPrint('   - Post ID: $postId');
      debugPrint('   - Parent Comment ID: $commentId');
      debugPrint('   - Reply: ${newReply.value}');

      final response = await communityRepository.createPostComment(
        apiToken: apiToken,
        postId: postId,
        comments: newReply.value,
        commentId: commentId,
      );

      if (response.isSuccess) {
        debugPrint('✅ Reply created successfully: ${response.message}');

        final replyUserName = currentUserName;
        final replyUserAvatar = currentUserProfileImage;

        int replyId = 0;
        if (response.data != null && response.data!['id'] != null) {
          replyId = response.data!['id'] is int
              ? response.data!['id']
              : int.tryParse(response.data!['id'].toString()) ??
                    DateTime.now().millisecondsSinceEpoch;
        } else {
          replyId = DateTime.now().millisecondsSinceEpoch;
        }

        final replyByUserId = response.data?['comment_by'] is int
            ? response.data!['comment_by'] as int
            : (PreferencesService.getUserId() ?? 0);
        final newReplyObj = Reply(
          id: replyId,
          user: PostUser(name: replyUserName, avatar: replyUserAvatar),
          text: response.data?['comments']?.toString() ?? newReply.value,
          timestamp: 'Just now',
          replyBy: replyByUserId,
        );

        final commentIndex = postComments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          final updatedReplies = [
            ...postComments[commentIndex].replies,
            newReplyObj,
          ];
          postComments[commentIndex] = postComments[commentIndex].copyWith(
            replies: updatedReplies,
          );
          postComments.refresh();
        }

        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final postCommentIndex = posts[postIndex].comments.indexWhere(
            (c) => c.id == commentId,
          );
          if (postCommentIndex != -1) {
            final updatedReplies = [
              ...posts[postIndex].comments[postCommentIndex].replies,
              newReplyObj,
            ];
            final updatedComment = posts[postIndex].comments[postCommentIndex]
                .copyWith(replies: updatedReplies);
            final updatedComments = [...posts[postIndex].comments];
            updatedComments[postCommentIndex] = updatedComment;

            posts[postIndex] = posts[postIndex].copyWith(
              comments: updatedComments,
            );
            posts.refresh();
          }
        }

        if (singlePost.value != null && singlePost.value!.id == postId) {
          final singlePostCommentIndex = singlePost.value!.comments.indexWhere(
            (c) => c.id == commentId,
          );
          if (singlePostCommentIndex != -1) {
            final updatedReplies = [
              ...singlePost.value!.comments[singlePostCommentIndex].replies,
              newReplyObj,
            ];
            final updatedComment = singlePost
                .value!
                .comments[singlePostCommentIndex]
                .copyWith(replies: updatedReplies);
            final updatedComments = [...singlePost.value!.comments];
            updatedComments[singlePostCommentIndex] = updatedComment;

            singlePost.value = singlePost.value!.copyWith(
              comments: updatedComments,
            );
          }
        }

        newReply.value = '';
        replyTextController.clear();
        replyingToPostId.value = 0;
        replyingToCommentId.value = 0;

        debugPrint('✅ Reply added to comment $commentId on post $postId');
      } else {
        createCommentError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to create reply';
        debugPrint('❌ Failed to create reply: ${response.message}');

        Get.snackbar(
          'Error',
          createCommentError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      createCommentError.value = 'An error occurred while creating reply';
      debugPrint('❌ Error creating reply: $e');

      Get.snackbar(
        'Error',
        createCommentError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isCreatingReply.value = false;
    }
  }

  Future<void> fetchAllPostComments(int postId) async {
    isLoadingComments.value = true;
    commentsError.value = '';

    try {
      debugPrint('🔄 Fetching all comments for post (ID: $postId)...');
      final response = await communityRepository.getAllPostComments(
        postId: postId,
      );

      if (response.isSuccess && response.data != null) {
        final List<Comment> fetchedComments = _mapApiResponseToComments(
          response.data!,
        );
        postComments.value = fetchedComments;

        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          posts[postIndex] = posts[postIndex].copyWith(
            comments: fetchedComments,
          );
          posts.refresh();
        }

        if (singlePost.value != null && singlePost.value!.id == postId) {
          singlePost.value = singlePost.value!.copyWith(
            comments: fetchedComments,
          );
        }

        debugPrint('✅ Successfully loaded ${fetchedComments.length} comments');
      } else {
        commentsError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load comments';
        debugPrint('❌ Failed to load comments: ${response.message}');
      }
    } catch (e) {
      commentsError.value = 'An error occurred while loading comments';
      debugPrint('❌ Error fetching comments: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  /// Public for use when loading posts with comments (e.g. in fetchPosts).
  List<Comment> mapApiResponseToComments(List<dynamic> data) =>
      _mapApiResponseToComments(data);

  List<Comment> _mapApiResponseToComments(List<dynamic> data) {
    try {
      final topLevelComments = data.where((item) {
        final commentId = item['comment_id'];
        return commentId == null || commentId == 0;
      }).toList();

      return topLevelComments.map((item) {
        final Map<String, dynamic> commentData = item is Map<String, dynamic>
            ? item
            : {};

        final userData = commentData['user'] ?? {};
        final userName = userData is Map
            ? (userData['name']?.toString() ?? 'Unknown User')
            : 'Unknown User';
        final userProfileImage = userData is Map
            ? (userData['profile_image']?.toString() ?? '')
            : '';

        String userAvatarUrl = '';
        if (userProfileImage.isNotEmpty) {
          if (userProfileImage.startsWith('http')) {
            userAvatarUrl = userProfileImage;
          } else {
            userAvatarUrl =
                'https://gravity.attoexasolutions.com/storage/$userProfileImage';
          }
        }

        final commentId = commentData['id'] is int
            ? commentData['id']
            : int.tryParse(commentData['id'].toString()) ?? 0;
        final commentBy = commentData['comment_by'] is int
            ? commentData['comment_by']
            : int.tryParse(commentData['comment_by'].toString()) ?? 0;
        final commentText = commentData['comments']?.toString() ?? '';

        final createdAt = commentData['created_at']?.toString() ?? '';
        final timestamp = _formatTimestamp(createdAt);

        final repliesData = commentData['replies'] ?? [];
        final List<Reply> replies = (repliesData is List)
            ? repliesData
                  .map((replyItem) => _mapApiResponseToReply(replyItem))
                  .toList()
            : [];

        return Comment(
          id: commentId,
          commentBy: commentBy,
          user: PostUser(name: userName, avatar: userAvatarUrl),
          text: commentText,
          timestamp: timestamp,
          replies: replies,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error mapping API response to comments: $e');
      return [];
    }
  }

  Reply _mapApiResponseToReply(dynamic replyData) {
    final Map<String, dynamic> data = replyData is Map<String, dynamic>
        ? replyData
        : {};

    final userData = data['user'] ?? {};
    final userName = userData is Map
        ? (userData['name']?.toString() ?? 'Unknown User')
        : 'Unknown User';
    final userProfileImage = userData is Map
        ? (userData['profile_image']?.toString() ?? '')
        : '';

    String userAvatarUrl = '';
    if (userProfileImage.isNotEmpty) {
      if (userProfileImage.startsWith('http')) {
        userAvatarUrl = userProfileImage;
      } else {
        userAvatarUrl =
            'https://gravity.attoexasolutions.com/storage/$userProfileImage';
      }
    }

    final replyId = data['id'] is int
        ? data['id']
        : int.tryParse(data['id'].toString()) ?? 0;
    final replyText = data['comments']?.toString() ?? '';
    final createdAt = data['created_at']?.toString() ?? '';
    final timestamp = _formatTimestamp(createdAt);
    final replyBy = data['comment_by'] is int
        ? data['comment_by'] as int
        : int.tryParse(data['comment_by']?.toString() ?? '');

    return Reply(
      id: replyId,
      user: PostUser(name: userName, avatar: userAvatarUrl),
      text: replyText,
      timestamp: timestamp,
      replyBy: replyBy,
    );
  }

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

  Future<void> fetchSingleComment(int postId, int commentId) async {
    isLoadingSingleComment.value = true;

    try {
      debugPrint('🔄 Fetching single comment (ID: $commentId) with replies...');
      final response = await communityRepository.getSinglePostComment(
        commentId: commentId,
      );

      if (response.isSuccess && response.data != null) {
        final commentData = response.data!;

        final repliesData = commentData['replies'] ?? [];
        final List<Reply> replies = (repliesData is List)
            ? repliesData
                  .map((replyItem) => _mapApiResponseToReply(replyItem))
                  .toList()
            : [];

        final commentIndex = postComments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          postComments[commentIndex] = postComments[commentIndex].copyWith(
            replies: replies,
          );
          postComments.refresh();
        }

        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final postCommentIndex = posts[postIndex].comments.indexWhere(
            (c) => c.id == commentId,
          );
          if (postCommentIndex != -1) {
            final updatedComments = [...posts[postIndex].comments];
            updatedComments[postCommentIndex] =
                updatedComments[postCommentIndex].copyWith(replies: replies);
            posts[postIndex] = posts[postIndex].copyWith(
              comments: updatedComments,
            );
            posts.refresh();
          }
        }

        if (singlePost.value != null && singlePost.value!.id == postId) {
          final postCommentIndex = singlePost.value!.comments.indexWhere(
            (c) => c.id == commentId,
          );
          if (postCommentIndex != -1) {
            final updatedComments = [...singlePost.value!.comments];
            updatedComments[postCommentIndex] =
                updatedComments[postCommentIndex].copyWith(replies: replies);
            singlePost.value = singlePost.value!.copyWith(
              comments: updatedComments,
            );
          }
        }

        debugPrint(
          '✅ Successfully loaded comment with ${replies.length} replies',
        );
      } else {
        debugPrint('❌ Failed to load single comment: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching single comment: $e');
    } finally {
      isLoadingSingleComment.value = false;
    }
  }

  Future<bool> updateComment() async {
    if (editCommentText.value.trim().isEmpty) return false;
    if (editingCommentId.value == 0) return false;

    isUpdatingComment.value = true;
    updateCommentError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        updateCommentError.value =
            'Authentication required. Please login again.';
        debugPrint('❌ UpdateComment Error: No auth token found');
        isUpdatingComment.value = false;
        return false;
      }

      debugPrint('🔄 Updating comment via API...');
      debugPrint('   - Comment ID: ${editingCommentId.value}');
      debugPrint('   - Post ID: ${editCommentPostId.value}');
      debugPrint('   - New text: ${editCommentText.value}');

      final response = await communityRepository.updatePostComment(
        apiToken: apiToken,
        postId: editCommentPostId.value,
        commentId: editingCommentId.value,
        comments: editCommentText.value,
      );

      if (response.isSuccess) {
        debugPrint('✅ Comment updated successfully: ${response.message}');

        final isEditingReply = editingReplyParentCommentId.value != 0;
        final replyId = editingCommentId.value;
        final newText = editCommentText.value;

        if (isEditingReply) {
          final parentId = editingReplyParentCommentId.value;
          final updateReplyInComment = (Comment c) {
            if (c.id != parentId) return c;
            final newReplies = c.replies.map((r) {
              if (r.id == replyId) return r.copyWith(text: newText);
              return r;
            }).toList();
            return c.copyWith(replies: newReplies);
          };

          final commentIndex = postComments.indexWhere((c) => c.id == parentId);
          if (commentIndex != -1) {
            postComments[commentIndex] =
                updateReplyInComment(postComments[commentIndex]);
            postComments.refresh();
          }

          final postIndex = posts.indexWhere(
            (p) => p.id == editCommentPostId.value,
          );
          if (postIndex != -1) {
            final postCommentIndex = posts[postIndex].comments.indexWhere(
              (c) => c.id == parentId,
            );
            if (postCommentIndex != -1) {
              final updatedComments = [...posts[postIndex].comments];
              updatedComments[postCommentIndex] =
                  updateReplyInComment(updatedComments[postCommentIndex]);
              posts[postIndex] = posts[postIndex].copyWith(
                comments: updatedComments,
              );
              posts.refresh();
            }
          }

          if (singlePost.value != null &&
              singlePost.value!.id == editCommentPostId.value) {
            final postCommentIndex = singlePost.value!.comments.indexWhere(
              (c) => c.id == parentId,
            );
            if (postCommentIndex != -1) {
              final updatedComments = [...singlePost.value!.comments];
              updatedComments[postCommentIndex] =
                  updateReplyInComment(updatedComments[postCommentIndex]);
              singlePost.value = singlePost.value!.copyWith(
                comments: updatedComments,
              );
            }
          }
        } else {
          final commentIndex = postComments.indexWhere(
            (c) => c.id == replyId,
          );
          if (commentIndex != -1) {
            postComments[commentIndex] = postComments[commentIndex].copyWith(
              text: newText,
            );
            postComments.refresh();
          }

          final postIndex = posts.indexWhere(
            (p) => p.id == editCommentPostId.value,
          );
          if (postIndex != -1) {
            final postCommentIndex = posts[postIndex].comments.indexWhere(
              (c) => c.id == replyId,
            );
            if (postCommentIndex != -1) {
              final updatedComments = [...posts[postIndex].comments];
              updatedComments[postCommentIndex] =
                  updatedComments[postCommentIndex].copyWith(
                    text: newText,
                  );
              posts[postIndex] = posts[postIndex].copyWith(
                comments: updatedComments,
              );
              posts.refresh();
            }
          }

          if (singlePost.value != null &&
              singlePost.value!.id == editCommentPostId.value) {
            final postCommentIndex = singlePost.value!.comments.indexWhere(
              (c) => c.id == replyId,
            );
            if (postCommentIndex != -1) {
              final updatedComments = [...singlePost.value!.comments];
              updatedComments[postCommentIndex] =
                  updatedComments[postCommentIndex].copyWith(
                    text: newText,
                  );
              singlePost.value = singlePost.value!.copyWith(
                comments: updatedComments,
              );
            }
          }
        }

        closeEditComment();

        Get.snackbar(
          'Success',
          response.message.isNotEmpty
              ? response.message
              : (isEditingReply ? 'Reply updated' : 'Comment updated successfully'),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );

        return true;
      } else {
        updateCommentError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to update comment';
        debugPrint('❌ Failed to update comment: ${response.message}');

        Get.snackbar(
          'Error',
          updateCommentError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );

        return false;
      }
    } catch (e) {
      updateCommentError.value = 'An error occurred while updating comment';
      debugPrint('❌ Error updating comment: $e');

      Get.snackbar(
        'Error',
        updateCommentError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );

      return false;
    } finally {
      isUpdatingComment.value = false;
    }
  }

  void openEditComment(int postId, Comment comment) {
    editingReplyParentCommentId.value = 0;
    editingCommentId.value = comment.id;
    editCommentPostId.value = postId;
    editCommentText.value = comment.text;
    editCommentTextController.text = comment.text;
  }

  void openEditReply(int postId, Comment parentComment, Reply reply) {
    editingReplyParentCommentId.value = parentComment.id;
    editingCommentId.value = reply.id;
    editCommentPostId.value = postId;
    editCommentText.value = reply.text;
    editCommentTextController.text = reply.text;
  }

  void closeEditComment() {
    editingCommentId.value = 0;
    editingReplyParentCommentId.value = 0;
    editCommentPostId.value = 0;
    editCommentText.value = '';
    editCommentTextController.clear();
    updateCommentError.value = '';
  }

  Future<bool> deleteComment(int postId, int commentId) async {
    isDeletingComment.value = true;
    deleteCommentError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        deleteCommentError.value =
            'Authentication required. Please login again.';
        debugPrint('❌ DeleteComment Error: No auth token found');
        isDeletingComment.value = false;
        return false;
      }

      debugPrint('🔄 Deleting comment via API...');
      debugPrint('   - Comment ID: $commentId');

      final response = await communityRepository.deletePostComment(
        apiToken: apiToken,
        commentId: commentId,
      );

      if (response.isSuccess) {
        debugPrint('✅ Comment deleted successfully: ${response.message}');

        postComments.removeWhere((c) => c.id == commentId);
        postComments.refresh();

        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final updatedComments = posts[postIndex].comments
              .where((c) => c.id != commentId)
              .toList();
          posts[postIndex] = posts[postIndex].copyWith(
            comments: updatedComments,
          );
          posts.refresh();
        }

        if (singlePost.value != null && singlePost.value!.id == postId) {
          final updatedComments = singlePost.value!.comments
              .where((c) => c.id != commentId)
              .toList();
          singlePost.value = singlePost.value!.copyWith(
            comments: updatedComments,
          );
        }

        Get.snackbar(
          'Success',
          response.message.isNotEmpty
              ? response.message
              : 'Comment deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );

        return true;
      } else {
        deleteCommentError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to delete comment';
        debugPrint('❌ Failed to delete comment: ${response.message}');

        Get.snackbar(
          'Error',
          deleteCommentError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );

        return false;
      }
    } catch (e) {
      deleteCommentError.value = 'An error occurred while deleting comment';
      debugPrint('❌ Error deleting comment: $e');

      Get.snackbar(
        'Error',
        deleteCommentError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );

      return false;
    } finally {
      isDeletingComment.value = false;
    }
  }

  void confirmDeleteComment(int postId, int commentId) {
    Get.dialog(
      Builder(
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Delete Comment',
              style: TextStyle(
                color: Color(0xFF0A2342),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to delete this comment? This action cannot be undone.',
              style: TextStyle(color: Color(0xFF0A2342)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF0A2342)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    deleteComment(postId, commentId);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void confirmDeleteReply(int postId, Comment parentComment, Reply reply) {
    Get.dialog(
      Builder(
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Delete Reply',
              style: TextStyle(
                color: Color(0xFF0A2342),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to delete this reply? This action cannot be undone.',
              style: TextStyle(color: Color(0xFF0A2342)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF0A2342)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    deleteReply(postId, parentComment.id, reply.id);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> deleteReply(int postId, int parentCommentId, int replyId) async {
    isDeletingComment.value = true;
    deleteCommentError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        deleteCommentError.value =
            'Authentication required. Please login again.';
        isDeletingComment.value = false;
        return false;
      }

      final response = await communityRepository.deletePostComment(
        apiToken: apiToken,
        commentId: replyId,
      );

      if (response.isSuccess) {
        final removeReplyFromComment = (Comment c) {
          if (c.id != parentCommentId) return c;
          return c.copyWith(
            replies: c.replies.where((r) => r.id != replyId).toList(),
          );
        };

        final commentIndex = postComments.indexWhere((c) => c.id == parentCommentId);
        if (commentIndex != -1) {
          postComments[commentIndex] =
              removeReplyFromComment(postComments[commentIndex]);
          postComments.refresh();
        }

        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final postCommentIndex = posts[postIndex].comments.indexWhere(
            (c) => c.id == parentCommentId,
          );
          if (postCommentIndex != -1) {
            final updatedComments = [...posts[postIndex].comments];
            updatedComments[postCommentIndex] =
                removeReplyFromComment(updatedComments[postCommentIndex]);
            posts[postIndex] = posts[postIndex].copyWith(
              comments: updatedComments,
            );
            posts.refresh();
          }
        }

        if (singlePost.value != null && singlePost.value!.id == postId) {
          final postCommentIndex = singlePost.value!.comments.indexWhere(
            (c) => c.id == parentCommentId,
          );
          if (postCommentIndex != -1) {
            final updatedComments = [...singlePost.value!.comments];
            updatedComments[postCommentIndex] =
                removeReplyFromComment(updatedComments[postCommentIndex]);
            singlePost.value = singlePost.value!.copyWith(
              comments: updatedComments,
            );
          }
        }

        Get.snackbar(
          'Success',
          response.message.isNotEmpty
              ? response.message
              : 'Reply deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        deleteCommentError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to delete reply';
        Get.snackbar(
          'Error',
          deleteCommentError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
        return false;
      }
    } catch (e) {
      deleteCommentError.value = 'An error occurred while deleting reply';
      Get.snackbar(
        'Error',
        deleteCommentError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
      return false;
    } finally {
      isDeletingComment.value = false;
    }
  }

  void startReply(int postId, int commentId) {
    replyingToPostId.value = postId;
    replyingToCommentId.value = commentId;
    fetchSingleComment(postId, commentId);
  }

  void cancelReply() {
    replyingToPostId.value = 0;
    replyingToCommentId.value = 0;
    newReply.value = '';
    replyTextController.clear();
  }
}
