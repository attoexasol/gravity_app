import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/model/post.dart';
import '../../../data/model/post_user.dart';
import '../../../data/model/reactions.dart';
import '../../../data/model/comment.dart';
import 'package:image_picker/image_picker.dart';

/// Controller for all post-related state and logic (CRUD, reactions, pinning, mapping).
/// Used by CommunityController via dependency injection.
class CommunityPostsController extends GetxController {
  CommunityPostsController({
    List<Comment> Function(List<dynamic>)? commentMapper,
  }) : _commentMapper = commentMapper;

  final CommunityRepository _communityRepository = CommunityRepository();
  final ImagePicker _imagePicker = ImagePicker();

  /// Set by CommunityController after creation so comment counts can be loaded for posts.
  void setCommentMapper(List<Comment> Function(List<dynamic>) fn) {
    _commentMapper = fn;
  }

  List<Comment> Function(List<dynamic>)? _commentMapper;

  // Posts list
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoadingPosts = false.obs;
  final RxString postsError = ''.obs;

  // Single post from API
  final Rx<Post?> singlePost = Rx<Post?>(null);
  final RxBool isLoadingSinglePost = false.obs;
  final RxString singlePostError = ''.obs;

  // Create post state
  final RxBool isCreatingPost = false.obs;
  final RxString createPostError = ''.obs;
  final RxInt selectedCommunityId = 2.obs;

  // Update post state
  final RxBool isUpdatingPost = false.obs;
  final RxString updatePostError = ''.obs;
  final RxBool showEditPost = false.obs;
  final RxInt editingPostId = 0.obs;
  final RxString editPostText = ''.obs;
  final RxString editPostImage = ''.obs;
  final RxString editPostImagePath = ''.obs;
  final RxInt editPostCommunityId = 2.obs;

  // Delete post state
  final RxBool isDeletingPost = false.obs;
  final RxString deletePostError = ''.obs;

  // UI state
  final RxBool showCreatePost = false.obs;
  final RxString newPostText = ''.obs;
  final RxString selectedImage = ''.obs;
  final RxString selectedImagePath = ''.obs;
  final RxBool isPickingImage = false.obs;

  final TextEditingController createPostTextController =
      TextEditingController();
  final TextEditingController editPostTextController = TextEditingController();

  // Reactions tracking
  final RxMap<int, Set<String>> activeReactions = <int, Set<String>>{}.obs;

  // API call control flags
  bool _isFetching = false;
  DateTime? _lastReload;

  @override
  void onClose() {
    editPostTextController.dispose();
    createPostTextController.dispose();
    super.onClose();
  }

  String get _currentUserName =>
      PreferencesService.getUserName()?.isNotEmpty == true
          ? PreferencesService.getUserName()!
          : 'You';

  String get _currentUserProfileImage =>
      PreferencesService.getProfileImageUrl() ??
      PreferencesService.getProfileImagePath() ??
      '';

  void resetCreatePostState() {
    newPostText.value = '';
    selectedImage.value = '';
    selectedImagePath.value = '';
    isPickingImage.value = false;
    createPostError.value = '';
    isCreatingPost.value = false;
    createPostTextController.clear();
    debugPrint('🔄 Create post state reset');
  }

  void closeCreatePostDialog() {
    resetCreatePostState();
    showCreatePost.value = false;

    bool dialogClosed = false;
    try {
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        dialogClosed = true;
        debugPrint('✅ Dialog closed via Navigator.pop()');
      }
    } catch (e) {
      debugPrint('⚠️ Navigator.pop() failed: $e');
    }

    if (!dialogClosed) {
      try {
        if (Get.isDialogOpen == true) {
          Get.back();
          dialogClosed = true;
          debugPrint('✅ Dialog closed via Get.back()');
        }
      } catch (e) {
        debugPrint('⚠️ Get.back() failed: $e');
      }
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      isPickingImage.value = true;
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImagePath.value = pickedFile.path;
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(pickedFile.path);
        selectedImage.value = 'data:$mimeType;base64,$base64Image';
        debugPrint('✅ Image picked from gallery: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('❌ Error picking image from gallery: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image from gallery',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isPickingImage.value = false;
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      isPickingImage.value = true;
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImagePath.value = pickedFile.path;
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(pickedFile.path);
        selectedImage.value = 'data:$mimeType;base64,$base64Image';
        debugPrint('✅ Image captured from camera: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('❌ Error capturing image from camera: $e');
      Get.snackbar(
        'Error',
        'Failed to capture image from camera',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isPickingImage.value = false;
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void clearSelectedImage() {
    selectedImage.value = '';
    selectedImagePath.value = '';
  }

  Widget buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF00B8A9).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF00B8A9)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0A2342),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showImageSourcePicker() {
    isPickingImage.value = false;
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
                    color: Color(0xFF0A2342).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Image Source',
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
                    buildImageSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          pickImageFromGallery();
                        });
                      },
                    ),
                    buildImageSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          pickImageFromCamera();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      isDismissible: true,
      enableDrag: true,
    ).then((_) {
      isPickingImage.value = false;
    });
  }

  Future<void> loadUserReactions() async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ Cannot load user reactions: No auth token');
        return;
      }

      debugPrint('🔄 Loading user reactions from API...');
      final response = await _communityRepository.getUserWiseReact(
        apiToken: apiToken,
      ).timeout(const Duration(seconds: 15));

      if (response.isSuccess && response.data != null) {
        activeReactions.clear();
        for (final item in response.data!) {
          if (item is Map<String, dynamic>) {
            final postData = item['post'];
            if (postData is Map<String, dynamic>) {
              final postId = postData['id'];
              if (postId is int) {
                final Set<String> reactions = <String>{};
                if (item['like'] == true) {
                  reactions.add('heart');
                } else if (item['thumsup'] == true) {
                  reactions.add('thumbsUp');
                } else if (item['other'] == true) {
                  reactions.add('fire');
                }
                if (reactions.length > 1) {
                  reactions.clear();
                  if (item['like'] == true) {
                    reactions.add('heart');
                  } else if (item['thumsup'] == true) {
                    reactions.add('thumbsUp');
                  } else if (item['other'] == true) {
                    reactions.add('fire');
                  }
                }
                if (reactions.isNotEmpty) {
                  activeReactions[postId] = reactions;
                } else {
                  activeReactions.remove(postId);
                }
              }
            }
          }
        }
        activeReactions.refresh();
        debugPrint(
          '✅ Loaded ${activeReactions.length} user reactions from API',
        );
        _saveActiveReactionsToStorage();
      } else {
        debugPrint('⚠️ Failed to load user reactions: ${response.message}');
        _loadActiveReactionsFromStorage();
      }
    } catch (e) {
      debugPrint('❌ Error loading user reactions: $e');
      _loadActiveReactionsFromStorage();
    }
  }

  void _loadActiveReactionsFromStorage() {
    try {
      final storage = PreferencesService.getStorage();
      final reactionsJson = storage.read('user_active_reactions') as String?;
      if (reactionsJson != null && reactionsJson.isNotEmpty) {
        final Map<String, dynamic> reactionsMap = jsonDecode(reactionsJson);
        activeReactions.clear();
        reactionsMap.forEach((postIdStr, reactionsList) {
          final postId = int.tryParse(postIdStr);
          if (postId != null && reactionsList is List) {
            activeReactions[postId] = Set<String>.from(
              reactionsList.map((r) => r.toString()),
            );
          }
        });
        activeReactions.refresh();
        debugPrint(
          '✅ Loaded ${activeReactions.length} active reactions from storage',
        );
      } else {
        debugPrint('ℹ️ No active reactions found in storage');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading active reactions from storage: $e');
    }
  }

  void _saveActiveReactionsToStorage() {
    try {
      final storage = PreferencesService.getStorage();
      final reactionsMap = <String, dynamic>{};
      activeReactions.forEach((postId, reactions) {
        reactionsMap[postId.toString()] = reactions.toList();
      });
      final reactionsJson = jsonEncode(reactionsMap);
      storage.write('user_active_reactions', reactionsJson);
      debugPrint(
        '✅ Saved ${activeReactions.length} active reactions to storage',
      );
    } catch (e) {
      debugPrint('⚠️ Error saving active reactions to storage: $e');
    }
  }

  Future<void> loadUserPinnedPosts() async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ Cannot load user pinned posts: No auth token');
        return;
      }
      final now = DateTime.now();
      if (_lastReload != null &&
          now.difference(_lastReload!) < const Duration(seconds: 2)) {
        debugPrint('⏸️ Pinned posts reload debounced');
        return;
      }

      debugPrint('🔄 Loading user pinned posts from API...');
      final response = await _communityRepository.getUserWisePinnedPosts(
        apiToken: apiToken,
      ).timeout(const Duration(seconds: 15));

      if (response.isSuccess && response.data != null) {
        final Set<int> pinnedPostIds = <int>{};
        for (final item in response.data!) {
          if (item is Map<String, dynamic>) {
            final postData = item['post'];
            if (postData is Map<String, dynamic>) {
              final postId = postData['id'];
              if (postId is int) {
                final isPinned =
                    item['is_pin_post'] == true ||
                    item['is_pin_post'] == 1 ||
                    (item['is_pin_post']?.toString().toLowerCase() == 'true');
                if (isPinned) pinnedPostIds.add(postId);
              }
            }
          }
        }
        debugPrint('✅ Found ${pinnedPostIds.length} pinned posts by user');
        if (pinnedPostIds.isNotEmpty) {
          final updatedPosts = posts.map((post) {
            if (pinnedPostIds.contains(post.id)) {
              return post.copyWith(isPinned: true);
            }
            return post;
          }).toList();
          posts.value = updatedPosts;
          debugPrint('✅ Updated ${pinnedPostIds.length} posts as pinned');
        }
      } else {
        debugPrint('⚠️ Failed to load user pinned posts: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error loading user pinned posts: $e');
    }
  }

  Future<void> _fetchAllPosts() async {
    if (_lastReload != null &&
        DateTime.now().difference(_lastReload!) < const Duration(seconds: 3)) {
      debugPrint('⏸️ Reload debounced - too soon since last reload');
      return;
    }
    if (_isFetching) {
      debugPrint('⏸️ Already fetching posts, skipping duplicate call');
      return;
    }

    _isFetching = true;
    _lastReload = DateTime.now();
    isLoadingPosts.value = true;
    postsError.value = '';

    try {
      debugPrint('🔄 Fetching posts from API...');
      final response = await _communityRepository.getAllPosts();

      if (response.isSuccess && response.data != null) {
        final List<Post> fetchedPosts = _mapApiResponseToPosts(response.data!);
        if (fetchedPosts.isNotEmpty) {
          // if (_commentMapper != null) {
          //   await _fetchCommentCountsForPosts(fetchedPosts);
          // }
          if (fetchedPosts.isNotEmpty) {
              posts.value = fetchedPosts;

              if (onPostsLoadedCallback != null) {
                onPostsLoadedCallback!();
              }

              if (loadUserPinnedPostsCallback != null) {
                await loadUserPinnedPostsCallback!();
              }
            }
          posts.value = fetchedPosts;
          if (onPostsLoadedCallback != null) {
            onPostsLoadedCallback!();
          }
          if (loadUserPinnedPostsCallback != null) {
            await loadUserPinnedPostsCallback!();
          }
          debugPrint(
            '✅ Successfully loaded ${fetchedPosts.length} posts from API',
          );
        } else {
          debugPrint(
            '⚠️ No posts found in API response, keeping initial posts',
          );
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
      _isFetching = false;
    }
  }

  /// Called after fetch so main controller can run focus/scroll logic. Set by CommunityController.
  void Function()? onPostsLoadedCallback;

  /// Called to load pinned posts after fetch (avoids circular call). Set by CommunityController.
  Future<void> Function()? loadUserPinnedPostsCallback;

  Future<void> refreshPosts() async {
    await _fetchAllPosts();
  }

  List<Post> _sortPostsWithPinnedFirst(List<Post> postsList) {
    final List<Post> pinnedPosts = [];
    final List<Post> unpinnedPosts = [];
    for (final post in postsList) {
      if (post.isPinned) {
        pinnedPosts.add(post);
      } else {
        unpinnedPosts.add(post);
      }
    }
    return [...pinnedPosts, ...unpinnedPosts];
  }

  Future<void> pinPost(int postId, int communityId) async {
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      Get.snackbar(
        'Error',
        'Please login to pin/unpin posts',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) {
      Get.snackbar(
        'Error',
        'Post not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final post = posts[postIndex];
    final isCurrentlyPinned = post.isPinned;
    final newPinnedState = !isCurrentlyPinned;

    final updatedPosts = posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(isPinned: newPinnedState);
      }
      return p;
    }).toList();
    posts.value = updatedPosts;

    try {
      if (isCurrentlyPinned) {
        debugPrint('📌 Unpinning post $postId in community $communityId...');
        final response = await _communityRepository.unpinCommunityPost(
          apiToken: apiToken,
          postId: postId,
          communityId: communityId,
        );

        if (response.isSuccess) {
          if (loadUserPinnedPostsCallback != null) {
            await loadUserPinnedPostsCallback!();
          }
          Get.snackbar(
            'Success',
            response.message.isNotEmpty
                ? response.message
                : 'Post unpinned successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF00B8A9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          debugPrint('✅ Post unpinned successfully');
        } else {
          posts.value = posts.map((p) {
            if (p.id == postId) return p.copyWith(isPinned: true);
            return p;
          }).toList();
          Get.snackbar(
            'Error',
            response.message.isNotEmpty
                ? response.message
                : 'Failed to unpin post',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE53935),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          debugPrint('❌ Failed to unpin post: ${response.message}');
        }
      } else {
        debugPrint('📌 Pinning post $postId in community $communityId...');
        final response = await _communityRepository.pinCommunityPost(
          apiToken: apiToken,
          postId: postId,
          communityId: communityId,
        );

        if (response.isSuccess) {
          if (loadUserPinnedPostsCallback != null) {
            await loadUserPinnedPostsCallback!();
          }
          Get.snackbar(
            'Success',
            response.message.isNotEmpty
                ? response.message
                : 'Post pinned successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF00B8A9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          debugPrint('✅ Post pinned successfully');
        } else {
          posts.value = posts.map((p) {
            if (p.id == postId) return p.copyWith(isPinned: false);
            return p;
          }).toList();
          Get.snackbar(
            'Error',
            response.message.isNotEmpty
                ? response.message
                : 'Failed to pin post',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE53935),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          debugPrint('❌ Failed to pin post: ${response.message}');
        }
      }
    } catch (e) {
      posts.value = posts.map((p) {
        if (p.id == postId) return p.copyWith(isPinned: isCurrentlyPinned);
        return p;
      }).toList();
      Get.snackbar(
        'Error',
        isCurrentlyPinned
            ? 'An error occurred while unpinning the post'
            : 'An error occurred while pinning the post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      debugPrint(
        '❌ Error ${isCurrentlyPinned ? "unpinning" : "pinning"} post: $e',
      );
    }
  }

  Future<void> _fetchCommentCountsForPosts(List<Post> postsList) async {
    if (postsList.isEmpty || _commentMapper == null) return;

    debugPrint(
      '🔄 Fetching comments for ${postsList.length} posts sequentially...',
    );

    for (int index = 0; index < postsList.length; index++) {
      final post = postsList[index];
      try {
        final commentsResponse = await _communityRepository
            .getAllPostComments(postId: post.id)
            .timeout(const Duration(seconds: 15));

        if (commentsResponse.isSuccess && commentsResponse.data != null) {
          final comments = _commentMapper!(commentsResponse.data!);
          postsList[index] = postsList[index].copyWith(comments: comments);
          if (comments.isNotEmpty) {
            debugPrint(
              '✅ Loaded ${comments.length} comments for post ${post.id}',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch comments for post ${post.id}: $e');
      }
      if (index < postsList.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    debugPrint('✅ Finished loading comments for all posts');
  }

  Future<void> fetchSinglePost(int postId) async {
    isLoadingSinglePost.value = true;
    singlePostError.value = '';
    singlePost.value = null;

    try {
      debugPrint('🔄 Fetching single post (ID: $postId) from API...');
      final response = await _communityRepository.getSinglePost(postId: postId);

      if (response.isSuccess && response.data != null) {
        final postData = response.data!;
        final mappedPost = _mapSinglePostFromApi(postData);
        singlePost.value = mappedPost;
        debugPrint('✅ Successfully loaded post: ${postData['post_text']}');
      } else {
        singlePostError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load post';
        debugPrint('❌ Failed to load post: ${response.message}');
      }
    } catch (e) {
      singlePostError.value = 'An error occurred while loading post';
      debugPrint('❌ Error fetching single post: $e');
    } finally {
      isLoadingSinglePost.value = false;
    }
  }

  Post _mapSinglePostFromApi(Map<String, dynamic> postData) {
    final userData = postData['user'] ?? {};
    final userName = userData is Map
        ? (userData['name']?.toString() ?? 'Unknown User')
        : 'Unknown User';
    final userProfileImage = userData is Map
        ? (userData['profile_image']?.toString() ?? '')
        : '';

    final communityData = postData['community'] ?? {};
    final communityName = communityData is Map
        ? (communityData['community_name']?.toString() ?? '')
        : '';

    String postImageUrl = '';
    if (postData['post_image'] != null &&
        postData['post_image'].toString().isNotEmpty) {
      final imagePath = postData['post_image'].toString();
      postImageUrl = imagePath.startsWith('http')
          ? imagePath
          : 'https://gravity.attoexasolutions.com/storage/$imagePath';
    }

    final postId = postData['id'] is int
        ? postData['id']
        : int.tryParse(postData['id'].toString()) ?? 0;
    final postText = postData['post_text']?.toString() ?? '';
    final postStatus = postData['post_status']?.toString() ?? '';
    final communityId = postData['community_id'] is int
        ? postData['community_id']
        : int.tryParse(postData['community_id'].toString()) ?? 0;

    final createdAt = postData['created_at']?.toString() ?? '';
    final timestamp = _formatTimestamp(createdAt);

    final heartCount = postData['like_count'] is int
        ? postData['like_count']
        : int.tryParse(postData['like_count'].toString()) ?? 0;
    final thumbsUpCount = postData['thumsup_count'] is int
        ? postData['thumsup_count']
        : int.tryParse(postData['thumsup_count'].toString()) ?? 0;
    final fireCount = postData['other_count'] is int
        ? postData['other_count']
        : int.tryParse(postData['other_count'].toString()) ?? 0;

    String userAvatarUrl = '';
    if (userProfileImage.isNotEmpty) {
      userAvatarUrl = userProfileImage.startsWith('http')
          ? userProfileImage
          : 'https://gravity.attoexasolutions.com/storage/$userProfileImage';
    }

    final isPinned =
        postData['is_pin_post'] == true ||
        postData['is_pin_post'] == 1 ||
        (postData['is_pin_post']?.toString().toLowerCase() == 'true');

    return Post(
      id: postId,
      user: PostUser(name: userName, avatar: userAvatarUrl),
      image: postImageUrl,
      text: postText,
      timestamp: timestamp,
      reactions: Reactions(
        heart: heartCount,
        thumbsUp: thumbsUpCount,
        fire: fireCount,
      ),
      comments: [],
      isPinned: isPinned,
      communityId: communityId,
      commentsCount: postData['comments_count'] is int
          ? postData['comments_count'] as int
          : (int.tryParse(postData['comments_count']?.toString() ?? '')),
    );
  }

  List<Post> _mapApiResponseToPosts(List<dynamic> data) {
    try {
      return data.map((item) {
        final Map<String, dynamic> postData = item is Map<String, dynamic>
            ? item
            : {};

        final userData = postData['user'] ?? {};
        final userName = userData is Map
            ? (userData['name']?.toString() ?? 'Unknown User')
            : 'Unknown User';
        final userProfileImage = userData is Map
            ? (userData['profile_image']?.toString() ?? '')
            : '';

        String postImageUrl = '';
        if (postData['post_image'] != null &&
            postData['post_image'].toString().isNotEmpty) {
          final imagePath = postData['post_image'].toString();
          postImageUrl = imagePath.startsWith('http')
              ? imagePath
              : 'https://gravity.attoexasolutions.com/storage/$imagePath';
        }

        final postId = postData['id'] is int
            ? postData['id']
            : int.tryParse(postData['id'].toString()) ?? 0;
        final postText = postData['post_text']?.toString() ?? '';

        final isPinned =
            postData['is_pin_post'] == true ||
            postData['is_pin_post'] == 1 ||
            (postData['is_pin_post']?.toString().toLowerCase() == 'true');

        final communityId = postData['community_id'] is int
            ? postData['community_id']
            : int.tryParse(postData['community_id'].toString()) ?? 0;

        final createdAt = postData['created_at']?.toString() ?? '';
        final timestamp = _formatTimestamp(createdAt);

        final heartCount = postData['like_count'] is int
            ? postData['like_count']
            : int.tryParse(postData['like_count'].toString()) ?? 0;
        final thumbsUpCount = postData['thumsup_count'] is int
            ? postData['thumsup_count']
            : int.tryParse(postData['thumsup_count'].toString()) ?? 0;
        final fireCount = postData['other_count'] is int
            ? postData['other_count']
            : int.tryParse(postData['other_count'].toString()) ?? 0;

        String userAvatarUrl = '';
        if (userProfileImage.isNotEmpty) {
          userAvatarUrl = userProfileImage.startsWith('http')
              ? userProfileImage
              : 'https://gravity.attoexasolutions.com/storage/$userProfileImage';
        }

        return Post(
          id: postId,
          user: PostUser(name: userName, avatar: userAvatarUrl),
          image: postImageUrl,
          text: postText,
          timestamp: timestamp,
          reactions: Reactions(
            heart: heartCount,
            thumbsUp: thumbsUpCount,
            fire: fireCount,
          ),
          comments: [],
          isPinned: isPinned,
          communityId: communityId,
          commentsCount: postData['comments_count'] is int
              ? postData['comments_count'] as int
              : int.tryParse(postData['comments_count']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error mapping API response to posts: $e');
      return [];
    }
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

  Future<void> toggleReaction(int postId, String reaction) async {
    final postReactions = Set<String>.from(
      activeReactions[postId] ?? <String>{},
    );

    if (postReactions.length > 1) {
      postReactions.clear();
    }

    final hasThisReaction = postReactions.contains(reaction);
    final previousReaction =
        postReactions.isNotEmpty ? postReactions.first : null;

    postReactions.clear();
    if (!hasThisReaction) {
      postReactions.add(reaction);
    }

    activeReactions[postId] = postReactions;
    activeReactions.refresh();
    _saveActiveReactionsToStorage();

    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = posts[postIndex];
      final currentReactions = post.reactions;

      int newHeart = currentReactions.heart;
      int newThumbsUp = currentReactions.thumbsUp;
      int newFire = currentReactions.fire;

      if (previousReaction != null) {
        if (previousReaction == 'heart') {
          newHeart = (newHeart - 1).clamp(0, double.infinity).toInt();
        } else if (previousReaction == 'thumbsUp') {
          newThumbsUp = (newThumbsUp - 1).clamp(0, double.infinity).toInt();
        } else if (previousReaction == 'fire') {
          newFire = (newFire - 1).clamp(0, double.infinity).toInt();
        }
      }

      if (!hasThisReaction) {
        if (reaction == 'heart') {
          newHeart = newHeart + 1;
        } else if (reaction == 'thumbsUp') {
          newThumbsUp = newThumbsUp + 1;
        } else if (reaction == 'fire') {
          newFire = newFire + 1;
        }
      }

      final updatedReactions = currentReactions.copyWith(
        heart: newHeart,
        thumbsUp: newThumbsUp,
        fire: newFire,
      );

      posts[postIndex] = post.copyWith(reactions: updatedReactions);
      posts.refresh();

      final currentReaction = !hasThisReaction ? reaction : null;
      bool like = false;
      bool thumsup = false;
      bool other = false;

      if (currentReaction != null) {
        if (currentReaction == 'heart') like = true;
        else if (currentReaction == 'thumbsUp') thumsup = true;
        else if (currentReaction == 'fire') other = true;
      }

      await _saveReactionToBackend(postId, like, thumsup, other);
    }
  }

  Future<void> _saveReactionToBackend(
    int postId,
    bool like,
    bool thumsup,
    bool other,
  ) async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ Cannot save reaction: No auth token');
        return;
      }

      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) {
        debugPrint('⚠️ Cannot save reaction: Post not found');
        return;
      }

      final post = posts[postIndex];

      final response = await _communityRepository.reactToPost(
        apiToken: apiToken,
        postId: postId,
        like: like,
        thumsup: thumsup,
        other: other,
      );

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        final updatedReactions = Reactions(
          heart: responseData['like_count'] ?? post.reactions.heart,
          thumbsUp: responseData['thumsup_count'] ?? post.reactions.thumbsUp,
          fire: responseData['other_count'] ?? post.reactions.fire,
        );
        posts[postIndex] = post.copyWith(reactions: updatedReactions);
        posts.refresh();
      }
    } catch (e) {
      debugPrint('❌ Error saving reaction to backend: $e');
    }
  }

  Future<bool> createPost() async {
    final hasText = newPostText.value.trim().isNotEmpty;
    final hasImage = selectedImage.value.isNotEmpty;
    if (!hasText && !hasImage) return false;

    isCreatingPost.value = true;
    createPostError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        createPostError.value = 'Authentication required. Please login again.';
        debugPrint('❌ CreatePost Error: No auth token found');
        isCreatingPost.value = false;
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAllNamed('/login');
        });
        return false;
      }

      String? postImageBase64;
      if (selectedImage.value.isNotEmpty &&
          selectedImage.value.startsWith('data:image')) {
        postImageBase64 = selectedImage.value;
      }

      final response = await _communityRepository.createPost(
        apiToken: apiToken,
        communityId: selectedCommunityId.value,
        postText: newPostText.value,
        postStatus: 'published',
        likeCount: 0,
        thumbsUpCount: 0,
        otherCount: 0,
        postImageBase64: postImageBase64,
      );

      if (response.isSuccess) {
        final postUserName = _currentUserName;
        final postUserAvatar = _currentUserProfileImage;
        final createdPostData = response.data;

        String postImageUrl = '';
        if (createdPostData != null &&
            createdPostData['post_image'] != null &&
            createdPostData['post_image'].toString().isNotEmpty) {
          final imagePath = createdPostData['post_image'].toString();
          postImageUrl = imagePath.startsWith('http')
              ? imagePath
              : 'https://gravity.attoexasolutions.com/storage/$imagePath';
        }

        int postId = 0;
        if (createdPostData != null && createdPostData['id'] != null) {
          postId = createdPostData['id'] is int
              ? createdPostData['id']
              : int.tryParse(createdPostData['id'].toString()) ??
                    DateTime.now().millisecondsSinceEpoch;
        } else {
          postId = DateTime.now().millisecondsSinceEpoch;
        }

        final newPost = Post(
          id: postId,
          user: PostUser(name: postUserName, avatar: postUserAvatar),
          image: postImageUrl,
          text: createdPostData?['post_text']?.toString() ?? newPostText.value,
          timestamp: 'Just now',
          reactions: Reactions(
            heart: createdPostData?['like_count'] ?? 0,
            thumbsUp: createdPostData?['thumsup_count'] ?? 0,
            fire: createdPostData?['other_count'] ?? 0,
          ),
          comments: [],
        );

        posts.insert(0, newPost);
        posts.refresh();

        newPostText.value = '';
        selectedImage.value = '';
        selectedImagePath.value = '';
        closeCreatePostDialog();

        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final context = Get.context;
            if (context != null) {
              try {
                Overlay.of(context);
                Get.snackbar(
                  'Success',
                  response.message.isNotEmpty
                      ? response.message
                      : 'Post created successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF00B8A9),
                  colorText: const Color(0xFFFFFFFF),
                  duration: const Duration(seconds: 2),
                );
              } catch (_) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  Get.snackbar(
                    'Success',
                    response.message.isNotEmpty
                        ? response.message
                        : 'Post created successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF00B8A9),
                    colorText: const Color(0xFFFFFFFF),
                    duration: const Duration(seconds: 2),
                  );
                });
              }
            }
          } catch (_) {}
        });

        return true;
      } else {
        createPostError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to create post';
        if (response.message.toLowerCase().contains('token') ||
            response.message.toLowerCase().contains('invalid') ||
            response.message.toLowerCase().contains('unauthorized')) {
          createPostError.value =
              'Your session has expired. Please login again.';
          await PreferencesService.clearAuthToken();
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAllNamed('/login');
          });
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.isDialogOpen == false) {
            Get.snackbar(
              'Error',
              createPostError.value,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFE53935),
              colorText: const Color(0xFFFFFFFF),
              duration: const Duration(seconds: 3),
            );
          }
        });
        return false;
      }
    } catch (e) {
      createPostError.value = 'An error occurred while creating post';
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isDialogOpen == false) {
          Get.snackbar(
            'Error',
            createPostError.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE53935),
            colorText: const Color(0xFFFFFFFF),
            duration: const Duration(seconds: 3),
          );
        }
      });
      return false;
    } finally {
      isCreatingPost.value = false;
    }
  }

  void openEditPost(Post post) {
    editingPostId.value = post.id;
    editPostText.value = post.text;
    editPostTextController.text = post.text;
    editPostTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: post.text.length),
    );
    editPostImage.value = post.image;
    editPostCommunityId.value =
        post.communityId != 0 ? post.communityId : selectedCommunityId.value;
    showEditPost.value = true;
  }

  void closeEditPost() {
    showEditPost.value = false;
    editingPostId.value = 0;
    editPostText.value = '';
    editPostTextController.clear();
    editPostImage.value = '';
    editPostImagePath.value = '';
    updatePostError.value = '';
  }

  Future<void> pickImageFromGalleryForEdit() async {
    try {
      isPickingImage.value = true;
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        editPostImagePath.value = pickedFile.path;
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(pickedFile.path);
        editPostImage.value = 'data:$mimeType;base64,$base64Image';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image from gallery',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isPickingImage.value = false;
    }
  }

  Future<void> pickImageFromCameraForEdit() async {
    try {
      isPickingImage.value = true;
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        editPostImagePath.value = pickedFile.path;
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(pickedFile.path);
        editPostImage.value = 'data:$mimeType;base64,$base64Image';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to capture image from camera',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isPickingImage.value = false;
    }
  }

  void clearEditSelectedImage() {
    editPostImage.value = '';
    editPostImagePath.value = '';
  }

  void showImageSourcePickerForEdit() {
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
                    color: Color(0xFF0A2342).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Image Source',
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
                    buildImageSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          pickImageFromGalleryForEdit();
                        });
                      },
                    ),
                    buildImageSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          pickImageFromCameraForEdit();
                        });
                      },
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

  Future<bool> updatePost() async {
    if (editPostTextController.text.trim().isEmpty) return false;
    if (editingPostId.value == 0) return false;

    isUpdatingPost.value = true;
    updatePostError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        updatePostError.value = 'Authentication required. Please login again.';
        isUpdatingPost.value = false;
        return false;
      }

      final currentPost =
          posts.firstWhereOrNull((p) => p.id == editingPostId.value);

      String? postImageBase64;
      if (editPostImage.value.isNotEmpty &&
          editPostImage.value.startsWith('data:image')) {
        postImageBase64 = editPostImage.value;
      }

      final response = await _communityRepository.updatePost(
        apiToken: apiToken,
        postId: editingPostId.value,
        communityId: editPostCommunityId.value,
        postText: editPostTextController.text,
        postStatus: 'published',
        likeCount: currentPost?.reactions.heart ?? 0,
        thumbsUpCount: currentPost?.reactions.thumbsUp ?? 0,
        otherCount: currentPost?.reactions.fire ?? 0,
        postImageBase64: postImageBase64,
      );

      if (response.isSuccess && response.data != null) {
        final updatedPostData = response.data!;
        final userName =
            currentPost?.user.name ?? PreferencesService.getUserName() ?? 'You';
        final userAvatar = currentPost?.user.avatar ?? '';

        String postImageUrl = '';
        if (updatedPostData['post_image'] != null &&
            updatedPostData['post_image'].toString().isNotEmpty) {
          final imagePath = updatedPostData['post_image'].toString();
          postImageUrl = imagePath.startsWith('http')
              ? imagePath
              : 'https://gravity.attoexasolutions.com/storage/$imagePath';
        }

        final updatedPost = Post(
          id: updatedPostData['id'] is int
              ? updatedPostData['id']
              : int.tryParse(updatedPostData['id'].toString()) ??
                    editingPostId.value,
          user: PostUser(name: userName, avatar: userAvatar),
          image: postImageUrl,
          text: updatedPostData['post_text']?.toString() ??
              editPostTextController.text,
          timestamp: currentPost?.timestamp ?? 'Just now',
          reactions: Reactions(
            heart: updatedPostData['like_count'] ??
                currentPost?.reactions.heart ??
                0,
            thumbsUp: updatedPostData['thumsup_count'] ??
                currentPost?.reactions.thumbsUp ??
                0,
            fire: updatedPostData['other_count'] ??
                currentPost?.reactions.fire ??
                0,
          ),
          comments: currentPost?.comments ?? [],
        );

        final postIndex = posts.indexWhere((p) => p.id == editingPostId.value);
        if (postIndex != -1) {
          posts[postIndex] = updatedPost;
          posts.refresh();
        }
        closeEditPost();
        Get.snackbar(
          'Success',
          response.message.isNotEmpty
              ? response.message
              : 'Post updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        updatePostError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to update post';
        Get.snackbar(
          'Error',
          updatePostError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      updatePostError.value = 'An error occurred while updating post';
      Get.snackbar(
        'Error',
        updatePostError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isUpdatingPost.value = false;
    }
  }

  Future<bool> deletePost(int postId) async {
    isDeletingPost.value = true;
    deletePostError.value = '';

    try {
      final response = await _communityRepository.deletePost(postId: postId);

      if (response.isSuccess) {
        posts.removeWhere((p) => p.id == postId);
        posts.refresh();
        Get.snackbar(
          'Success',
          response.message.isNotEmpty
              ? response.message
              : 'Post deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        deletePostError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to delete post';
        Get.snackbar(
          'Error',
          deletePostError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      deletePostError.value = 'An error occurred while deleting post';
      Get.snackbar(
        'Error',
        deletePostError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isDeletingPost.value = false;
    }
  }

  void confirmDeletePost(int postId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Post',
          style: TextStyle(
            color: Color(0xFF0A2342),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF0A2342)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF0A2342)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              deletePost(postId);
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
      ),
    );
  }
}
