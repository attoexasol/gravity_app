import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../core/services/preferences_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/model/post.dart';
import '../../../data/model/post_user.dart';
import '../../../data/model/reactions.dart';
import '../../../data/model/reply.dart';
import '../../../data/model/comment.dart';

class CommunityController extends GetxController {
  // Repository for API calls
  final CommunityRepository _communityRepository = CommunityRepository();

  // Communities from API
  final RxList<Map<String, dynamic>> communities = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingCommunities = false.obs;

  // Single community from API
  final Rx<Map<String, dynamic>?> singleCommunity = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxBool isLoadingSingleCommunity = false.obs;
  final RxString singleCommunityError = ''.obs;

  // Create community state
  final RxBool isCreatingCommunity = false.obs;
  final RxString createCommunityError = ''.obs;
  final Rx<Map<String, dynamic>?> createdCommunity = Rx<Map<String, dynamic>?>(
    null,
  );

  // Update community state
  final RxBool isUpdatingCommunity = false.obs;
  final RxString updateCommunityError = ''.obs;
  final Rx<Map<String, dynamic>?> updatedCommunity = Rx<Map<String, dynamic>?>(
    null,
  );

  // Delete community state
  final RxBool isDeletingCommunity = false.obs;
  final RxString deleteCommunityError = ''.obs;

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
  final RxInt selectedCommunityId = 2.obs; // Default community ID

  // Update post state
  final RxBool isUpdatingPost = false.obs;
  final RxString updatePostError = ''.obs;
  final RxBool showEditPost = false.obs;
  final RxInt editingPostId = 0.obs;
  final RxString editPostText = ''.obs;
  final RxString editPostImage = ''.obs;
  final RxString editPostImagePath =
      ''.obs; // Local file path for picked edit image
  final RxInt editPostCommunityId = 2.obs;

  // Delete post state
  final RxBool isDeletingPost = false.obs;
  final RxString deletePostError = ''.obs;

  // Create comment state
  final RxBool isCreatingComment = false.obs;
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
  final RxString editCommentText = ''.obs;
  final RxInt editCommentPostId = 0.obs;
  final TextEditingController editCommentTextController =
      TextEditingController();

  // Delete comment state
  final RxBool isDeletingComment = false.obs;
  final RxString deleteCommentError = ''.obs;

  // UI state
  final RxInt selectedPostId = 0.obs;
  final RxString newComment = ''.obs;
  final RxString newReply = ''.obs;
  final RxInt replyingToPostId = 0.obs;
  final RxInt replyingToCommentId = 0.obs;
  final RxBool showCreatePost = false.obs;
  final RxString newPostText = ''.obs;
  final RxString selectedImage = ''.obs;
  final RxString selectedImagePath = ''.obs; // Local file path for picked image
  final RxBool isPickingImage = false.obs;

  // TextEditingController for create post text field to ensure proper state sync
  final TextEditingController createPostTextController =
      TextEditingController();

  // Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  // Text editing controllers for comments
  final TextEditingController commentTextController = TextEditingController();
  final TextEditingController replyTextController = TextEditingController();

  // Reactions tracking
  final RxMap<int, Set<String>> activeReactions = <int, Set<String>>{}.obs;

  // User profile info
  final RxString userProfileImage = ''.obs;
  final RxString userName = ''.obs;

  // API call control flags
  bool _isFetching = false;
  DateTime? _lastReload;

  // Scroll controller for Community page
  ItemScrollController? _itemScrollController;

  /// Load user profile data from storage
  void _loadUserProfile() {
    // Load user name
    userName.value = PreferencesService.getUserName() ?? 'You';

    // Load profile image - prefer API URL over local path
    final profileImageUrl =
        PreferencesService.getStorage().read('user_profile_image_url')
            as String?;
    final profileImagePath =
        PreferencesService.getStorage().read('user_profile_image') as String?;

    userProfileImage.value = profileImageUrl ?? profileImagePath ?? '';

    debugPrint('👤 User profile loaded:');
    debugPrint('   - Name: ${userName.value}');
    debugPrint('   - Profile Image: ${userProfileImage.value}');
  }

  /// Safely navigate back, handling snackbar errors
  /// Uses Navigator directly to avoid Get.back()'s internal snackbar closing logic
  void safeBack() {
    // Don't try to close snackbars - Get.back() internally calls closeCurrentSnackbar()
    // which causes LateInitializationError. Use Navigator directly instead.

    try {
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        debugPrint('✅ Navigated back via Navigator.pop()');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Navigator.pop() failed: $e');
    }

    // Fallback: try Get.back() if Navigator fails (but this may still cause errors)
    try {
      if (Get.isDialogOpen == true) {
        Get.back();
        debugPrint('✅ Navigated back via Get.back()');
      }
    } catch (e) {
      debugPrint(
        '⚠️ Get.back() also failed: $e - Navigation may have already occurred',
      );
    }
  }

  /// Close create post dialog reliably
  /// Reset all create post state to ensure fresh state every time dialog opens
  /// Root cause: State persistence was causing inconsistent behavior on subsequent post creations
  void resetCreatePostState() {
    newPostText.value = '';
    selectedImage.value = '';
    selectedImagePath.value = '';
    isPickingImage.value = false;
    createPostError.value = '';
    isCreatingPost.value = false;
    // Clear TextEditingController to ensure TextField is empty
    createPostTextController.clear();
    debugPrint('🔄 Create post state reset');
  }

  void closeCreatePostDialog() {
    // Reset state when closing dialog to ensure clean state for next open
    resetCreatePostState();

    // Set the flag first
    showCreatePost.value = false;

    // Use Navigator.pop() first to avoid Get.back()'s internal snackbar closing logic
    // which can cause LateInitializationError on subsequent calls
    bool dialogClosed = false;

    // Method 1: Try Navigator.pop() first (more reliable, doesn't interfere with snackbars)
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

    // Method 2: Fallback to Get.back() only if Navigator.pop() didn't work
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

  /// Get user profile image URL or empty string
  String get currentUserProfileImage => userProfileImage.value;

  /// Get current user name
  String get currentUserName =>
      userName.value.isNotEmpty ? userName.value : 'You';

  /// Get current user ID
  int get currentUserId => PreferencesService.getUserId() ?? 0;

  /// Check if the current user owns a comment
  bool isCurrentUserComment(Comment comment) {
    return currentUserId > 0 && comment.commentBy == currentUserId;
  }

  /// Show comment actions bottom sheet (Edit/Delete)
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
                    // Edit button
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
                    // Delete button
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

  /// Pick image from gallery
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
        // Convert to base64 for API
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

  /// Pick image from camera
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
        // Convert to base64 for API
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

  /// Get MIME type from file path
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

  /// Clear selected image
  void clearSelectedImage() {
    selectedImage.value = '';
    selectedImagePath.value = '';
  }

  /// Show image source picker dialog
  /// Root cause: Ensure isPickingImage is reset if bottom sheet is dismissed without selection
  void showImageSourcePicker() {
    // Reset picking state before showing picker to ensure clean state
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
                    color: const Color(0xFF0A2342).withOpacity(0.2),
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
                    _buildImageSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        // Close bottom sheet using its own context
                        Navigator.of(bottomSheetContext).pop();
                        // Small delay to ensure bottom sheet is fully closed
                        Future.delayed(const Duration(milliseconds: 200), () {
                          pickImageFromGallery();
                        });
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        // Close bottom sheet using its own context
                        Navigator.of(bottomSheetContext).pop();
                        // Small delay to ensure bottom sheet is fully closed
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
      // Ensure bottom sheet can be dismissed and state is reset
      isDismissible: true,
      enableDrag: true,
    ).then((_) {
      // Reset picking state if bottom sheet is dismissed without selection
      isPickingImage.value = false;
    });
  }

  /// Build image source option widget
  Widget _buildImageSourceOption({
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

  @override
  void onInit() {
    super.onInit();
    _loadUserProfile();
    // _loadInitialPosts();
    _fetchCommunities();
    _fetchAllPosts();
  }

  @override
  void onReady() {
    super.onReady();
    // Load user reactions from API
    loadUserReactions();
    // Load user pinned posts from API
    loadUserPinnedPosts();
    // Note: Removed duplicate _fetchAllPosts() call to prevent API flooding
  }

  /// Load user reactions from API
  /// API: POST /api/user_wise_react
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
                // Determine which reaction the user has (Facebook-like: only one reaction per post)
                // IMPORTANT: Backend should return only ONE active reaction per post
                // If multiple reactions are true, we take the first one found (but this shouldn't happen)
                final Set<String> reactions = <String>{};

                // Only one of these should be true based on API response
                // Backend must ensure only one reaction is active (status = 1) per user per post
                if (item['like'] == true) {
                  reactions.add('heart');
                } else if (item['thumsup'] == true) {
                  reactions.add('thumbsUp');
                } else if (item['other'] == true) {
                  reactions.add('fire');
                }

                // Validate: Only one reaction should be active
                if (reactions.length > 1) {
                  debugPrint(
                    '⚠️ Warning: Multiple active reactions found for post $postId. Taking first: ${reactions.first}',
                  );
                  reactions.clear();
                  // Take the first one found (shouldn't happen if backend is correct)
                  if (item['like'] == true) {
                    reactions.add('heart');
                  } else if (item['thumsup'] == true) {
                    reactions.add('thumbsUp');
                  } else if (item['other'] == true) {
                    reactions.add('fire');
                  }
                }

                // Only add if user has a reaction (should be exactly one or zero)
                if (reactions.isNotEmpty) {
                  activeReactions[postId] = reactions;
                } else {
                  // Ensure no reaction is stored if all are false
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

        // Save to local storage for offline access
        _saveActiveReactionsToStorage();
      } else {
        debugPrint('⚠️ Failed to load user reactions: ${response.message}');
        // Fallback to local storage if API fails
        _loadActiveReactionsFromStorage();
      }
    } catch (e) {
      debugPrint('❌ Error loading user reactions: $e');
      // Fallback to local storage if API fails
      _loadActiveReactionsFromStorage();
    }
  }

  /// Load active reactions from local storage (fallback)
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

  /// Save active reactions to local storage
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

  /// Load user pinned posts from API
  /// API: POST /api/user_wise_pinned_posts
  /// Updates the posts list to mark which posts are pinned by the user
  Future<void> loadUserPinnedPosts() async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ Cannot load user pinned posts: No auth token');
        return;
      }

      // SOLUTION 3: Debounce - Prevent rapid reloads
      final now = DateTime.now();
      if (_lastReload != null && now.difference(_lastReload!) < const Duration(seconds: 2)) {
        debugPrint('⏸️ Pinned posts reload debounced');
        return;
      }

      debugPrint('🔄 Loading user pinned posts from API...');
      final response = await _communityRepository.getUserWisePinnedPosts(
        apiToken: apiToken,
      ).timeout(const Duration(seconds: 15));

      if (response.isSuccess && response.data != null) {
        // Extract post IDs that are pinned by the user
        final Set<int> pinnedPostIds = <int>{};

        for (final item in response.data!) {
          if (item is Map<String, dynamic>) {
            final postData = item['post'];
            if (postData is Map<String, dynamic>) {
              final postId = postData['id'];
              if (postId is int) {
                // Check if is_pin_post is true
                final isPinned =
                    item['is_pin_post'] == true ||
                    item['is_pin_post'] == 1 ||
                    (item['is_pin_post']?.toString().toLowerCase() == 'true');

                if (isPinned) {
                  pinnedPostIds.add(postId);
                }
              }
            }
          }
        }

        debugPrint('✅ Found ${pinnedPostIds.length} pinned posts by user');

        // Update posts list to mark pinned posts
        if (pinnedPostIds.isNotEmpty) {
          final updatedPosts = posts.map((post) {
            if (pinnedPostIds.contains(post.id)) {
              // Mark as pinned if user has pinned it
              return post.copyWith(isPinned: true);
            }
            return post;
          }).toList();

          // Don't sort - keep posts in original order
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

  @override
  void onClose() {
    commentTextController.dispose();
    replyTextController.dispose();
    editCommentTextController.dispose();
    createPostTextController.dispose();
    super.onClose();
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
        debugPrint(
          '✅ Successfully loaded community: ${response.data!['community_name']}',
        );
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
        debugPrint(
          '✅ Successfully created community: ${response.data!['community_name']}',
        );
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
        debugPrint(
          '✅ Successfully updated community: ${response.data!['community_name']}',
        );
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
    // SOLUTION 3: Debounce - Prevent rapid reloads (minimum 3 seconds between calls)
    if (_lastReload != null &&
        DateTime.now().difference(_lastReload!) < const Duration(seconds: 3)) {
      debugPrint('⏸️ Reload debounced - too soon since last reload');
      return;
    }

    // SOLUTION 1: Prevent concurrent fetches
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
          // Fetch comment counts for each post
          await _fetchCommentCountsForPosts(fetchedPosts);
          // Don't sort - keep posts in original order from API
          posts.value = fetchedPosts;
          // Load user pinned posts to mark which posts are pinned by the user
          // This will update the posts list with correct pinned status
          await loadUserPinnedPosts();
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

  /// Public method to refresh posts (for pull-to-refresh)
  /// Uses same debounce and loading flags as _fetchAllPosts
  Future<void> refreshPosts() async {
    await _fetchAllPosts();
  }

  /// ============================================
  /// POST PINNING FEATURE (Multiple Pinned Posts)
  /// ============================================

  /// Sort posts: Pinned posts first (preserving their relative order), then normal posts
  /// This ensures all pinned posts always appear at the top of the feed
  List<Post> _sortPostsWithPinnedFirst(List<Post> postsList) {
    // Separate pinned and unpinned posts while preserving original order
    final List<Post> pinnedPosts = [];
    final List<Post> unpinnedPosts = [];

    for (final post in postsList) {
      if (post.isPinned) {
        pinnedPosts.add(post);
      } else {
        unpinnedPosts.add(post);
      }
    }

    // Combine: all pinned posts first (in their original order), then unpinned posts
    return [...pinnedPosts, ...unpinnedPosts];
  }

  /// Pin or unpin a community post (supports multiple pinned posts)
  /// - If post is pinned: Unpins it
  /// - If post is not pinned: Pins it
  /// - Calls appropriate API based on current state
  /// - On success: Updates local state, keeps other pinned posts, reorders list
  /// - On failure: Shows snackbar and rolls back
  Future<void> pinPost(int postId, int communityId) async {
    // Get auth token
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

    // Find the post
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

    // Optimistic update: Toggle pin state immediately
    // Keep all other pinned posts as they are (support multiple pinned posts)
    // Posts stay in their original position - no sorting
    final updatedPosts = posts.map((p) {
      if (p.id == postId) {
        // Toggle pin state for the selected post
        return p.copyWith(isPinned: newPinnedState);
      }
      // Keep all other posts unchanged (including other pinned posts)
      return p;
    }).toList();

    // Keep posts in original order - don't move pinned posts to top
    posts.value = updatedPosts;

    try {
      if (isCurrentlyPinned) {
        // Unpin the post
        debugPrint('📌 Unpinning post $postId in community $communityId...');

        final response = await _communityRepository.unpinCommunityPost(
          apiToken: apiToken,
          postId: postId,
          communityId: communityId,
        );

        if (response.isSuccess) {
          // API success - state already updated optimistically
          // Posts stay in original position - no sorting needed
          
          // Refresh pinned posts to ensure consistency
          loadUserPinnedPosts();

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
          // API failure - rollback optimistic update
          posts.value = posts.map((p) {
            if (p.id == postId) {
              return p.copyWith(isPinned: true); // Rollback to pinned
            }
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
        // Pin the post
        debugPrint('📌 Pinning post $postId in community $communityId...');

        final response = await _communityRepository.pinCommunityPost(
          apiToken: apiToken,
          postId: postId,
          communityId: communityId,
        );

        if (response.isSuccess) {
          // API success - state already updated optimistically
          // Posts stay in original position - no sorting needed
          
          // Refresh pinned posts to ensure consistency
          loadUserPinnedPosts();

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
          // API failure - rollback optimistic update
          posts.value = posts.map((p) {
            if (p.id == postId) {
              return p.copyWith(isPinned: false); // Rollback to unpinned
            }
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
      // Exception - rollback optimistic update
      posts.value = posts.map((p) {
        if (p.id == postId) {
          return p.copyWith(
            isPinned: isCurrentlyPinned,
          ); // Rollback to original state
        }
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

  /// Fetch comment counts for posts and update them
  /// Fetches comments sequentially to prevent API overload
  /// SOLUTION 1: Sequential loading instead of parallel to reduce backend load
  Future<void> _fetchCommentCountsForPosts(List<Post> postsList) async {
    if (postsList.isEmpty) return;

    debugPrint('🔄 Fetching comments for ${postsList.length} posts sequentially...');

    // SOLUTION 1: Fetch comments sequentially instead of parallel
    // This prevents overwhelming the backend with simultaneous requests
    for (int index = 0; index < postsList.length; index++) {
      final post = postsList[index];

      try {
        // SOLUTION 4: Add timeout to prevent hanging requests
        final commentsResponse = await _communityRepository
            .getAllPostComments(postId: post.id)
            .timeout(const Duration(seconds: 15));

        if (commentsResponse.isSuccess && commentsResponse.data != null) {
          final comments = _mapApiResponseToComments(commentsResponse.data!);
          postsList[index] = postsList[index].copyWith(comments: comments);
          if (comments.isNotEmpty) {
            debugPrint(
              '✅ Loaded ${comments.length} comments for post ${post.id}',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch comments for post ${post.id}: $e');
        // Continue with next post even if one fails
      }

      // Small delay between requests to reduce server load
      if (index < postsList.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    debugPrint('✅ Finished loading comments for all posts');
  }

  /// Fetch single post by ID from API
  /// API: POST https://gravity.attoexasolutions.com/api/single_post
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

  /// Map single post API response to Post model
  Post _mapSinglePostFromApi(Map<String, dynamic> postData) {
    // Extract user information
    final userData = postData['user'] ?? {};
    final userName = userData is Map
        ? (userData['name']?.toString() ?? 'Unknown User')
        : 'Unknown User';
    final userProfileImage = userData is Map
        ? (userData['profile_image']?.toString() ?? '')
        : '';

    // Extract community information
    final communityData = postData['community'] ?? {};
    final communityName = communityData is Map
        ? (communityData['community_name']?.toString() ?? '')
        : '';

    // Construct full image URL if post_image exists
    String postImageUrl = '';
    if (postData['post_image'] != null &&
        postData['post_image'].toString().isNotEmpty) {
      final imagePath = postData['post_image'].toString();
      if (imagePath.startsWith('http')) {
        postImageUrl = imagePath;
      } else {
        // Construct full URL
        postImageUrl =
            'https://gravity.attoexasolutions.com/storage/$imagePath';
      }
    }

    // Extract post information
    final postId = postData['id'] is int
        ? postData['id']
        : int.tryParse(postData['id'].toString()) ?? 0;
    final postText = postData['post_text']?.toString() ?? '';
    final postStatus = postData['post_status']?.toString() ?? '';
    final communityId = postData['community_id'] is int
        ? postData['community_id']
        : int.tryParse(postData['community_id'].toString()) ?? 0;

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
        userAvatarUrl =
            'https://gravity.attoexasolutions.com/storage/$userProfileImage';
      }
    } else {
      // Default avatar if no profile image
      userAvatarUrl = 'https://i.pravatar.cc/150?img=${postId % 10}';
    }

    // Extract pin status for single post
    final isPinned =
        postData['is_pin_post'] == true ||
        postData['is_pin_post'] == 1 ||
        (postData['is_pin_post']?.toString().toLowerCase() == 'true');

    debugPrint('📊 Single Post Details:');
    debugPrint('   - ID: $postId');
    debugPrint('   - Text: $postText');
    debugPrint('   - Status: $postStatus');
    debugPrint('   - Image: $postImageUrl');
    debugPrint('   - User: $userName');
    debugPrint('   - Community: $communityName (ID: $communityId)');
    debugPrint('   - Reactions: ❤️$heartCount 👍$thumbsUpCount 🔥$fireCount');
    debugPrint('   - Pinned: $isPinned');

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
      comments: [], // API response doesn't include comments
      isPinned: isPinned,
      communityId: communityId,
    );
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
        if (postData['post_image'] != null &&
            postData['post_image'].toString().isNotEmpty) {
          final imagePath = postData['post_image'].toString();
          if (imagePath.startsWith('http')) {
            postImageUrl = imagePath;
          } else {
            // Construct full URL
            postImageUrl =
                'https://gravity.attoexasolutions.com/storage/$imagePath';
          }
        }

        // Extract post information
        final postId = postData['id'] is int
            ? postData['id']
            : int.tryParse(postData['id'].toString()) ?? 0;
        final postText = postData['post_text']?.toString() ?? '';

        // Extract pin status (mapped from is_pin_post API field)
        final isPinned =
            postData['is_pin_post'] == true ||
            postData['is_pin_post'] == 1 ||
            (postData['is_pin_post']?.toString().toLowerCase() == 'true');

        // Extract community ID (required for pinning API)
        final communityId = postData['community_id'] is int
            ? postData['community_id']
            : int.tryParse(postData['community_id'].toString()) ?? 0;

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
            userAvatarUrl =
                'https://gravity.attoexasolutions.com/storage/$userProfileImage';
          }
        } else {
          // Default avatar if no profile image
          userAvatarUrl = 'https://i.pravatar.cc/150?img=${postId % 10}';
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
          comments: [], // API response doesn't include comments
          isPinned: isPinned, // Map pin status from API
          communityId: communityId, // Map community ID from API
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

  // void _loadInitialPosts() {
  //   posts.value = [
  //     Post(
  //       id: 1,
  //       user: PostUser(
  //         name: 'Sarah M.',
  //         avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400',
  //       ),
  //       image: 'https://images.unsplash.com/photo-1734989175071-fedc119fb52e?w=800',
  //       text: 'Healthy lunch today! 🥗 Feeling energized and ready to crush my afternoon goals.',
  //       timestamp: '2 hours ago',
  //       reactions: Reactions(heart: 24, thumbsUp: 18, fire: 12),
  //       comments: [
  //         Comment(
  //           id: 1,
  //           commentBy: 0,
  //           user: PostUser(name: 'Mike R.', avatar: 'https://i.pravatar.cc/150?img=12'),
  //           text: 'Looks delicious! What\'s in it?',
  //           timestamp: '1 hour ago',
  //           replies: [
  //             Reply(
  //               id: 1,
  //               user: PostUser(name: 'Sarah M.', avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400'),
  //               text: 'Quinoa, grilled chicken, avocado, and lots of veggies! 🥑',
  //               timestamp: '45 min ago',
  //             ),
  //           ],
  //         ),
  //         Comment(
  //           id: 2,
  //           commentBy: 0,
  //           user: PostUser(name: 'Emma L.', avatar: 'https://i.pravatar.cc/150?img=5'),
  //           text: 'This is inspiring! I need to meal prep better.',
  //           timestamp: '30 min ago',
  //           replies: [],
  //         ),
  //       ],
  //     ),
  //     Post(
  //       id: 2,
  //       user: PostUser(
  //         name: 'Mike R.',
  //         avatar: 'https://i.pravatar.cc/150?img=12',
  //       ),
  //       image: 'https://images.unsplash.com/photo-1522845015757-50bce044e5da?w=800',
  //       text: 'Morning workout done! ✅ 5k run + strength training. Who else got their steps in today?',
  //       timestamp: '5 hours ago',
  //       reactions: Reactions(heart: 42, thumbsUp: 31, fire: 28),
  //       comments: [
  //         Comment(
  //           id: 1,
  //           commentBy: 0,
  //           user: PostUser(name: 'Alex K.', avatar: 'https://i.pravatar.cc/150?img=8'),
  //           text: 'Beast mode! 💪 I did a 3k this morning.',
  //           timestamp: '4 hours ago',
  //           replies: [],
  //         ),
  //       ],
  //     ),
  //     Post(
  //       id: 3,
  //       user: PostUser(
  //         name: 'Emma L.',
  //         avatar: 'https://i.pravatar.cc/150?img=5',
  //       ),
  //       image: '',
  //       text: '8 hours of sleep for the first time this week! 😴 Small wins matter. Thank you Gravity for the reminder notifications!',
  //       timestamp: '8 hours ago',
  //       reactions: Reactions(heart: 35, thumbsUp: 22, fire: 15),
  //       comments: [
  //         Comment(
  //           id: 1,
  //           commentBy: 0,
  //           user: PostUser(name: 'Sarah M.', avatar: 'https://images.unsplash.com/photo-1749700332038-640b00de758c?w=400'),
  //           text: 'Sleep is so important! Great job! 🌙',
  //           timestamp: '7 hours ago',
  //           replies: [],
  //         ),
  //       ],
  //     ),
  //     Post(
  //       id: 4,
  //       user: PostUser(
  //         name: 'Alex K.',
  //         avatar: 'https://i.pravatar.cc/150?img=8',
  //       ),
  //       image: 'https://images.unsplash.com/photo-1734989175071-fedc119fb52e?w=800',
  //       text: 'Meal prep Sunday! 🍱 Planning my week ahead. Consistency is key!',
  //       timestamp: '1 day ago',
  //       reactions: Reactions(heart: 28, thumbsUp: 19, fire: 14),
  //       comments: [],
  //     ),
  //   ];
  // }

  // Match React: User can only have ONE reaction per post
  // If clicking the same reaction, remove it (toggle off)
  // If clicking a different reaction, remove previous and add new one
  //
  // IMPORTANT: Only ONE reaction should be active per user per post at any time.
  // When switching reactions, the backend must:
  // 1. Set the previous reaction status to 0 (inactive)
  // 2. Set the new reaction status to 1 (active)
  // 3. Ensure only one active reaction record exists in the database
  Future<void> toggleReaction(int postId, String reaction) async {
    // Get current reactions for this post (should be empty or contain only one reaction)
    final postReactions = Set<String>.from(
      activeReactions[postId] ?? <String>{},
    );

    // Validate: Ensure only one reaction exists (safety check)
    if (postReactions.length > 1) {
      debugPrint(
        '⚠️ Warning: Multiple reactions found for post $postId. Clearing all.',
      );
      postReactions.clear();
    }

    // Check if user already has this exact reaction
    final hasThisReaction = postReactions.contains(reaction);

    // Get the previous reaction if user had one (can only have one at a time)
    final previousReaction = postReactions.isNotEmpty
        ? postReactions.first
        : null;

    // CRITICAL: Clear ALL reactions for this post first (ensures only one active reaction)
    // This ensures the frontend state matches the backend expectation: only one active reaction
    postReactions.clear();

    // If clicking the same reaction, remove it (toggle off) - postReactions stays empty
    // If clicking a different reaction, add the new one - postReactions will have only the new reaction
    if (!hasThisReaction) {
      postReactions.add(reaction);
    }

    // Update state: Only one reaction (or none) should be stored per post
    activeReactions[postId] = postReactions;
    activeReactions.refresh();

    // Save active reactions to local storage for persistence
    _saveActiveReactionsToStorage();

    // Update post reactions count locally first (optimistic update)
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

      // Update locally first
      posts[postIndex] = post.copyWith(reactions: updatedReactions);
      posts.refresh();

      // Save to backend to persist the reaction using dedicated reaction API
      //
      // BACKEND REQUIREMENT: When this request is sent, the backend MUST:
      // 1. Set the user's previous reaction (if any) to status = 0 (inactive)
      // 2. Set the new reaction (if any) to status = 1 (active)
      // 3. Ensure only ONE active reaction record exists per user per post in the database
      // 4. Update reaction counts accordingly
      //
      // Facebook-like: Only send the user's selected reaction as true, others are omitted
      // Use the reaction parameter directly (what user just tapped) instead of reading from activeReactions
      final currentReaction = !hasThisReaction
          ? reaction
          : null; // null if removing, otherwise the reaction type

      // Determine which reaction to send to backend
      // CRITICAL: Only ONE field should be sent (or none if removing reaction)
      // The backend will handle deactivating the previous reaction
      bool like = false;
      bool thumsup = false;
      bool other = false;

      if (currentReaction != null) {
        // User has selected a reaction - send only that one as true
        // Backend must deactivate any previous reaction and activate this one
        if (currentReaction == 'heart') {
          like = true;
        } else if (currentReaction == 'thumbsUp') {
          thumsup = true;
        } else if (currentReaction == 'fire') {
          other = true;
        }
      }
      // If currentReaction is null, all remain false (user removed their reaction)
      // Backend should set all reactions to inactive (status = 0) for this user/post

      debugPrint('📤 Sending reaction to backend (Facebook-like):');
      debugPrint('   - User tapped: $reaction, isRemoving: $hasThisReaction');
      debugPrint('   - Current reaction: ${currentReaction ?? "none"}');
      debugPrint('   - like: $like, thumsup: $thumsup, other: $other');

      await _saveReactionToBackend(postId, like, thumsup, other);
    }
  }

  /// Save reaction to backend using dedicated reaction API
  /// API: POST /api/post/react
  /// Facebook-like: Only the user's selected reaction should be true, others should be false
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

      debugPrint('🔄 Saving reaction to backend for post $postId...');
      debugPrint('   - like: $like, thumsup: $thumsup, other: $other');

      // Call dedicated reaction API
      final response = await _communityRepository.reactToPost(
        apiToken: apiToken,
        postId: postId,
        like: like,
        thumsup: thumsup,
        other: other,
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Reaction saved to backend successfully');
        // Update post with response data to ensure sync
        final responseData = response.data!;
        final updatedReactions = Reactions(
          heart: responseData['like_count'] ?? post.reactions.heart,
          thumbsUp: responseData['thumsup_count'] ?? post.reactions.thumbsUp,
          fire: responseData['other_count'] ?? post.reactions.fire,
        );
        posts[postIndex] = post.copyWith(reactions: updatedReactions);
        posts.refresh();
      } else {
        debugPrint(
          '⚠️ Failed to save reaction to backend: ${response.message}',
        );
        // Revert to previous counts if save failed
        // Note: We could revert here, but for better UX, we keep the optimistic update
      }
    } catch (e) {
      debugPrint('❌ Error saving reaction to backend: $e');
      // Keep optimistic update even if save fails
    }
  }

  /// Add a new comment to a post using API
  /// API: POST https://gravity.attoexasolutions.com/api/create_post_comment
  Future<void> addComment(int postId) async {
    if (newComment.value.trim().isEmpty) return;
    if (isCreatingComment.value) return; // Prevent duplicate calls

    isCreatingComment.value = true;
    createCommentError.value = '';

    try {
      // Get auth token
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

      final response = await _communityRepository.createPostComment(
        apiToken: apiToken,
        postId: postId,
        comments: newComment.value,
        commentId: null, // Top-level comment, no parent
      );

      if (response.isSuccess) {
        debugPrint('✅ Comment created successfully: ${response.message}');

        // Get user info for the new comment
        final commentUserName = currentUserName;
        final commentUserAvatar = currentUserProfileImage.isNotEmpty
            ? currentUserProfileImage
            : 'https://i.pravatar.cc/150?img=1';

        // Get comment ID from response or generate a temporary one
        int commentId = 0;
        if (response.data != null && response.data!['id'] != null) {
          commentId = response.data!['id'] is int
              ? response.data!['id']
              : int.tryParse(response.data!['id'].toString()) ??
                    DateTime.now().millisecondsSinceEpoch;
        } else {
          commentId = DateTime.now().millisecondsSinceEpoch;
        }

        // Get comment_by from response or use current user ID
        int commentByUserId = response.data?['comment_by'] is int
            ? response.data!['comment_by']
            : (PreferencesService.getUserId() ?? 0);

        // Create the new comment object
        final newCommentObj = Comment(
          id: commentId,
          commentBy: commentByUserId,
          user: PostUser(name: commentUserName, avatar: commentUserAvatar),
          text: response.data?['comments']?.toString() ?? newComment.value,
          timestamp: 'Just now',
          replies: [],
        );

        // Update postComments list
        postComments.add(newCommentObj);
        postComments.refresh();

        // Update local post with new comment
        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final updatedComments = [...posts[postIndex].comments, newCommentObj];
          posts[postIndex] = posts[postIndex].copyWith(
            comments: updatedComments,
          );
          posts.refresh();
        }

        // Also update singlePost if it's the same post
        if (singlePost.value != null && singlePost.value!.id == postId) {
          final updatedComments = [
            ...singlePost.value!.comments,
            newCommentObj,
          ];
          singlePost.value = singlePost.value!.copyWith(
            comments: updatedComments,
          );
        }

        // Clear input
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

  /// Add a reply to a comment using API
  /// API: POST https://gravity.attoexasolutions.com/api/create_post_comment
  /// Uses comment_id parameter to specify the parent comment
  Future<void> addReply(int postId, int commentId) async {
    if (newReply.value.trim().isEmpty) return;
    if (isCreatingComment.value) return; // Prevent duplicate calls

    isCreatingComment.value = true;
    createCommentError.value = '';

    try {
      // Get auth token
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        createCommentError.value =
            'Authentication required. Please login again.';
        debugPrint('❌ AddReply Error: No auth token found');
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

      debugPrint('🔄 Creating reply via API...');
      debugPrint('   - Post ID: $postId');
      debugPrint('   - Parent Comment ID: $commentId');
      debugPrint('   - Reply: ${newReply.value}');

      final response = await _communityRepository.createPostComment(
        apiToken: apiToken,
        postId: postId,
        comments: newReply.value,
        commentId: commentId, // Parent comment ID for the reply
      );

      if (response.isSuccess) {
        debugPrint('✅ Reply created successfully: ${response.message}');

        // Get user info for the new reply
        final replyUserName = currentUserName;
        final replyUserAvatar = currentUserProfileImage.isNotEmpty
            ? currentUserProfileImage
            : 'https://i.pravatar.cc/150?img=1';

        // Get reply ID from response or generate a temporary one
        int replyId = 0;
        if (response.data != null && response.data!['id'] != null) {
          replyId = response.data!['id'] is int
              ? response.data!['id']
              : int.tryParse(response.data!['id'].toString()) ??
                    DateTime.now().millisecondsSinceEpoch;
        } else {
          replyId = DateTime.now().millisecondsSinceEpoch;
        }

        // Create the new reply object
        final newReplyObj = Reply(
          id: replyId,
          user: PostUser(name: replyUserName, avatar: replyUserAvatar),
          text: response.data?['comments']?.toString() ?? newReply.value,
          timestamp: 'Just now',
        );

        // Update postComments list
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

        // Update local post with new reply
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

        // Also update singlePost if it's the same post
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

        // Clear input and reset reply state
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
      isCreatingComment.value = false;
    }
  }

  /// Fetch all comments for a post from API
  /// API: POST https://gravity.attoexasolutions.com/api/all_post_comments
  Future<void> fetchAllPostComments(int postId) async {
    isLoadingComments.value = true;
    commentsError.value = '';

    try {
      debugPrint('🔄 Fetching all comments for post (ID: $postId)...');
      final response = await _communityRepository.getAllPostComments(
        postId: postId,
      );

      if (response.isSuccess && response.data != null) {
        final List<Comment> fetchedComments = _mapApiResponseToComments(
          response.data!,
        );
        postComments.value = fetchedComments;

        // Also update the post's comments in the posts list
        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          posts[postIndex] = posts[postIndex].copyWith(
            comments: fetchedComments,
          );
          posts.refresh();
        }

        // Update singlePost if it matches
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

  /// Map API response to Comment models
  List<Comment> _mapApiResponseToComments(List<dynamic> data) {
    try {
      // Filter out replies (comments with non-null comment_id) from top level
      final topLevelComments = data.where((item) {
        final commentId = item['comment_id'];
        return commentId == null || commentId == 0;
      }).toList();

      return topLevelComments.map((item) {
        final Map<String, dynamic> commentData = item is Map<String, dynamic>
            ? item
            : {};

        // Extract user information
        final userData = commentData['user'] ?? {};
        final userName = userData is Map
            ? (userData['name']?.toString() ?? 'Unknown User')
            : 'Unknown User';
        final userProfileImage = userData is Map
            ? (userData['profile_image']?.toString() ?? '')
            : '';

        // Construct user avatar URL
        String userAvatarUrl = '';
        if (userProfileImage.isNotEmpty) {
          if (userProfileImage.startsWith('http')) {
            userAvatarUrl = userProfileImage;
          } else {
            userAvatarUrl =
                'https://gravity.attoexasolutions.com/storage/$userProfileImage';
          }
        } else {
          final commentId = commentData['id'] is int ? commentData['id'] : 0;
          userAvatarUrl = 'https://i.pravatar.cc/150?img=${commentId % 10}';
        }

        // Extract comment information
        final commentId = commentData['id'] is int
            ? commentData['id']
            : int.tryParse(commentData['id'].toString()) ?? 0;
        final commentBy = commentData['comment_by'] is int
            ? commentData['comment_by']
            : int.tryParse(commentData['comment_by'].toString()) ?? 0;
        final commentText = commentData['comments']?.toString() ?? '';

        // Format timestamp
        final createdAt = commentData['created_at']?.toString() ?? '';
        final timestamp = _formatTimestamp(createdAt);

        // Map replies
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

  /// Map API response to Reply model
  Reply _mapApiResponseToReply(dynamic replyData) {
    final Map<String, dynamic> data = replyData is Map<String, dynamic>
        ? replyData
        : {};

    // Extract user information
    final userData = data['user'] ?? {};
    final userName = userData is Map
        ? (userData['name']?.toString() ?? 'Unknown User')
        : 'Unknown User';
    final userProfileImage = userData is Map
        ? (userData['profile_image']?.toString() ?? '')
        : '';

    // Construct user avatar URL
    String userAvatarUrl = '';
    if (userProfileImage.isNotEmpty) {
      if (userProfileImage.startsWith('http')) {
        userAvatarUrl = userProfileImage;
      } else {
        userAvatarUrl =
            'https://gravity.attoexasolutions.com/storage/$userProfileImage';
      }
    } else {
      final replyId = data['id'] is int ? data['id'] : 0;
      userAvatarUrl = 'https://i.pravatar.cc/150?img=${replyId % 10}';
    }

    final replyId = data['id'] is int
        ? data['id']
        : int.tryParse(data['id'].toString()) ?? 0;
    final replyText = data['comments']?.toString() ?? '';
    final createdAt = data['created_at']?.toString() ?? '';
    final timestamp = _formatTimestamp(createdAt);

    return Reply(
      id: replyId,
      user: PostUser(name: userName, avatar: userAvatarUrl),
      text: replyText,
      timestamp: timestamp,
    );
  }

  /// Fetch single comment with replies from API
  /// API: POST https://gravity.attoexasolutions.com/api/single_post_comment
  Future<void> fetchSingleComment(int postId, int commentId) async {
    isLoadingSingleComment.value = true;

    try {
      debugPrint('🔄 Fetching single comment (ID: $commentId) with replies...');
      final response = await _communityRepository.getSinglePostComment(
        commentId: commentId,
      );

      if (response.isSuccess && response.data != null) {
        final commentData = response.data!;

        // Map replies from the response
        final repliesData = commentData['replies'] ?? [];
        final List<Reply> replies = (repliesData is List)
            ? repliesData
                  .map((replyItem) => _mapApiResponseToReply(replyItem))
                  .toList()
            : [];

        // Update the comment's replies in postComments
        final commentIndex = postComments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          postComments[commentIndex] = postComments[commentIndex].copyWith(
            replies: replies,
          );
          postComments.refresh();
        }

        // Also update in posts list
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

        // Update singlePost if it matches
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

  /// Update a comment using API
  /// API: POST https://gravity.attoexasolutions.com/api/update_post_comment
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

      final response = await _communityRepository.updatePostComment(
        apiToken: apiToken,
        postId: editCommentPostId.value,
        commentId: editingCommentId.value,
        comments: editCommentText.value,
      );

      if (response.isSuccess) {
        debugPrint('✅ Comment updated successfully: ${response.message}');

        // Update in postComments
        final commentIndex = postComments.indexWhere(
          (c) => c.id == editingCommentId.value,
        );
        if (commentIndex != -1) {
          postComments[commentIndex] = postComments[commentIndex].copyWith(
            text: editCommentText.value,
          );
          postComments.refresh();
        }

        // Update in posts list
        final postIndex = posts.indexWhere(
          (p) => p.id == editCommentPostId.value,
        );
        if (postIndex != -1) {
          final postCommentIndex = posts[postIndex].comments.indexWhere(
            (c) => c.id == editingCommentId.value,
          );
          if (postCommentIndex != -1) {
            final updatedComments = [...posts[postIndex].comments];
            updatedComments[postCommentIndex] =
                updatedComments[postCommentIndex].copyWith(
                  text: editCommentText.value,
                );
            posts[postIndex] = posts[postIndex].copyWith(
              comments: updatedComments,
            );
            posts.refresh();
          }
        }

        // Update singlePost if it matches
        if (singlePost.value != null &&
            singlePost.value!.id == editCommentPostId.value) {
          final postCommentIndex = singlePost.value!.comments.indexWhere(
            (c) => c.id == editingCommentId.value,
          );
          if (postCommentIndex != -1) {
            final updatedComments = [...singlePost.value!.comments];
            updatedComments[postCommentIndex] =
                updatedComments[postCommentIndex].copyWith(
                  text: editCommentText.value,
                );
            singlePost.value = singlePost.value!.copyWith(
              comments: updatedComments,
            );
          }
        }

        // Close edit mode
        closeEditComment();

        Get.snackbar(
          'Success',
          response.message.isNotEmpty
              ? response.message
              : 'Comment updated successfully',
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

  /// Open edit comment mode
  void openEditComment(int postId, Comment comment) {
    editingCommentId.value = comment.id;
    editCommentPostId.value = postId;
    editCommentText.value = comment.text;
    editCommentTextController.text = comment.text;
  }

  /// Close edit comment mode
  void closeEditComment() {
    editingCommentId.value = 0;
    editCommentPostId.value = 0;
    editCommentText.value = '';
    editCommentTextController.clear();
    updateCommentError.value = '';
  }

  /// Delete a comment using API
  /// API: POST https://gravity.attoexasolutions.com/api/delete_post_comment
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

      final response = await _communityRepository.deletePostComment(
        apiToken: apiToken,
        commentId: commentId,
      );

      if (response.isSuccess) {
        debugPrint('✅ Comment deleted successfully: ${response.message}');

        // Remove from postComments
        postComments.removeWhere((c) => c.id == commentId);
        postComments.refresh();

        // Remove from posts list
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

        // Update singlePost if it matches
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

  /// Show delete comment confirmation dialog
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

  /// Create a new post using API
  /// API: POST https://gravity.attoexasolutions.com/api/create_post
  Future<bool> createPost() async {
    if (newPostText.value.trim().isEmpty) return false;

    isCreatingPost.value = true;
    createPostError.value = '';

    try {
      // Get auth token
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        createPostError.value = 'Authentication required. Please login again.';
        debugPrint('❌ CreatePost Error: No auth token found');
        isCreatingPost.value = false;

        // Navigate to login
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAllNamed('/login');
        });
        return false;
      }

      debugPrint('🔄 Creating post via API...');
      debugPrint(
        '   - Token: ${apiToken.substring(0, apiToken.length > 20 ? 20 : apiToken.length)}... (${apiToken.length} chars)',
      );
      debugPrint('   - Text: ${newPostText.value}');
      debugPrint('   - Community ID: ${selectedCommunityId.value}');
      debugPrint('   - Has Image: ${selectedImage.value.isNotEmpty}');
      debugPrint('   - Image Path: ${selectedImagePath.value}');

      // Prepare image data if selected
      // API expects full data URL format: data:image/png;base64,...
      String? postImageBase64;
      if (selectedImage.value.isNotEmpty &&
          selectedImage.value.startsWith('data:image')) {
        postImageBase64 = selectedImage.value;
        debugPrint('   - Base64 image size: ${postImageBase64.length} chars');
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
        debugPrint('✅ Post created successfully: ${response.message}');

        // Get user info for the new post
        final postUserName = currentUserName;
        final postUserAvatar = currentUserProfileImage.isNotEmpty
            ? currentUserProfileImage
            : 'https://i.pravatar.cc/150?img=1';

        // Map the response to a Post object
        final createdPostData = response.data;

        // Construct full image URL if post_image exists
        String postImageUrl = '';
        if (createdPostData != null &&
            createdPostData['post_image'] != null &&
            createdPostData['post_image'].toString().isNotEmpty) {
          final imagePath = createdPostData['post_image'].toString();
          if (imagePath.startsWith('http')) {
            postImageUrl = imagePath;
          } else {
            postImageUrl =
                'https://gravity.attoexasolutions.com/storage/$imagePath';
          }
        }

        // Get post ID from response or generate a temporary one
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

        // Add the new post to the beginning of the list
        posts.insert(0, newPost);
        posts.refresh();

        // Clear form
        newPostText.value = '';
        selectedImage.value = '';
        selectedImagePath.value = '';

        // Close dialog reliably
        closeCreatePostDialog();

        // Show success message with safe context
        // Use a longer delay to ensure dialog is fully closed and context is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final context = Get.context;
            if (context != null) {
              // Check if overlay is available before showing snackbar
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
                debugPrint('✅ Success snackbar shown');
              } catch (overlayError) {
                debugPrint(
                  '⚠️ Overlay not available for snackbar: $overlayError',
                );
                // Retry after a bit more delay
                Future.delayed(const Duration(milliseconds: 300), () {
                  try {
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
                    debugPrint('✅ Success snackbar shown (retry)');
                  } catch (e) {
                    debugPrint('⚠️ Error showing success snackbar (retry): $e');
                  }
                });
              }
            } else {
              debugPrint('⚠️ Cannot show snackbar - context unavailable');
            }
          } catch (e) {
            debugPrint('⚠️ Error showing success snackbar: $e');
          }
        });

        return true;
      } else {
        createPostError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to create post';
        debugPrint('❌ Failed to create post: ${response.message}');

        // Handle invalid token error specifically
        if (response.message.toLowerCase().contains('token') ||
            response.message.toLowerCase().contains('invalid') ||
            response.message.toLowerCase().contains('unauthorized')) {
          createPostError.value =
              'Your session has expired. Please login again.';

          // Clear invalid token
          await PreferencesService.clearAuthToken();

          // Navigate to login after a delay to allow dialog to close
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAllNamed('/login');
          });
        }

        // Show error message with safe context
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
      debugPrint('❌ Error creating post: $e');

      // Show error message with safe context
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

  /// Open edit post modal with post data
  void openEditPost(Post post) {
    editingPostId.value = post.id;
    editPostText.value = post.text;
    editPostImage.value = post.image;
    // Try to get the community ID from the post, default to selected community
    editPostCommunityId.value = selectedCommunityId.value;
    showEditPost.value = true;
  }

  /// Close edit post modal
  void closeEditPost() {
    showEditPost.value = false;
    editingPostId.value = 0;
    editPostText.value = '';
    editPostImage.value = '';
    editPostImagePath.value = '';
    updatePostError.value = '';
  }

  /// Pick image from gallery for Edit Post
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
        // Convert to base64 for API
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(pickedFile.path);
        editPostImage.value = 'data:$mimeType;base64,$base64Image';
        debugPrint('✅ Image picked from gallery for edit: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('❌ Error picking image from gallery for edit: $e');
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

  /// Pick image from camera for Edit Post
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
        // Convert to base64 for API
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(pickedFile.path);
        editPostImage.value = 'data:$mimeType;base64,$base64Image';
        debugPrint('✅ Image captured from camera for edit: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('❌ Error capturing image from camera for edit: $e');
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

  /// Clear selected edit image
  void clearEditSelectedImage() {
    editPostImage.value = '';
    editPostImagePath.value = '';
  }

  /// Show image source picker dialog for Edit Post
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
                    color: const Color(0xFF0A2342).withOpacity(0.2),
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
                    _buildImageSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        // Close bottom sheet using its own context
                        Navigator.of(bottomSheetContext).pop();
                        // Small delay to ensure bottom sheet is fully closed
                        Future.delayed(const Duration(milliseconds: 200), () {
                          pickImageFromGalleryForEdit();
                        });
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        // Close bottom sheet using its own context
                        Navigator.of(bottomSheetContext).pop();
                        // Small delay to ensure bottom sheet is fully closed
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

  /// Update an existing post using API
  /// API: POST https://gravity.attoexasolutions.com/api/update_post
  Future<bool> updatePost() async {
    if (editPostText.value.trim().isEmpty) return false;
    if (editingPostId.value == 0) return false;

    isUpdatingPost.value = true;
    updatePostError.value = '';

    try {
      // Get auth token
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        updatePostError.value = 'Authentication required. Please login again.';
        debugPrint('❌ UpdatePost Error: No auth token found');
        isUpdatingPost.value = false;
        return false;
      }

      // Get current post to preserve reaction counts
      final currentPost = posts.firstWhereOrNull(
        (p) => p.id == editingPostId.value,
      );

      debugPrint('🔄 Updating post via API...');
      debugPrint('   - Post ID: ${editingPostId.value}');
      debugPrint('   - Text: ${editPostText.value}');
      debugPrint('   - Community ID: ${editPostCommunityId.value}');
      debugPrint('   - Has Image: ${editPostImage.value.isNotEmpty}');

      // Prepare image data if changed
      // API expects full data URL format: data:image/png;base64,...
      String? postImageBase64;
      if (editPostImage.value.isNotEmpty &&
          editPostImage.value.startsWith('data:image')) {
        postImageBase64 = editPostImage.value;
        debugPrint('   - Base64 image size: ${postImageBase64.length} chars');
      }

      final response = await _communityRepository.updatePost(
        apiToken: apiToken,
        postId: editingPostId.value,
        communityId: editPostCommunityId.value,
        postText: editPostText.value,
        postStatus: 'published',
        likeCount: currentPost?.reactions.heart ?? 0,
        thumbsUpCount: currentPost?.reactions.thumbsUp ?? 0,
        otherCount: currentPost?.reactions.fire ?? 0,
        postImageBase64: postImageBase64,
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Post updated successfully: ${response.message}');

        // Map the response to update the post
        final updatedPostData = response.data!;
        final userName =
            currentPost?.user.name ?? PreferencesService.getUserName() ?? 'You';
        final userAvatar =
            currentPost?.user.avatar ?? 'https://i.pravatar.cc/150?img=1';

        // Construct full image URL if post_image exists
        String postImageUrl = '';
        if (updatedPostData['post_image'] != null &&
            updatedPostData['post_image'].toString().isNotEmpty) {
          final imagePath = updatedPostData['post_image'].toString();
          if (imagePath.startsWith('http')) {
            postImageUrl = imagePath;
          } else {
            postImageUrl =
                'https://gravity.attoexasolutions.com/storage/$imagePath';
          }
        }

        final updatedPost = Post(
          id: updatedPostData['id'] is int
              ? updatedPostData['id']
              : int.tryParse(updatedPostData['id'].toString()) ??
                    editingPostId.value,
          user: PostUser(name: userName, avatar: userAvatar),
          image: postImageUrl,
          text: updatedPostData['post_text']?.toString() ?? editPostText.value,
          timestamp: currentPost?.timestamp ?? 'Just now',
          reactions: Reactions(
            heart:
                updatedPostData['like_count'] ??
                currentPost?.reactions.heart ??
                0,
            thumbsUp:
                updatedPostData['thumsup_count'] ??
                currentPost?.reactions.thumbsUp ??
                0,
            fire:
                updatedPostData['other_count'] ??
                currentPost?.reactions.fire ??
                0,
          ),
          comments: currentPost?.comments ?? [],
        );

        // Update the post in the list
        final postIndex = posts.indexWhere((p) => p.id == editingPostId.value);
        if (postIndex != -1) {
          posts[postIndex] = updatedPost;
          posts.refresh();
        }

        // Close edit modal
        closeEditPost();

        // Show success message
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
        debugPrint('❌ Failed to update post: ${response.message}');

        // Show error message
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
      debugPrint('❌ Error updating post: $e');

      // Show error message
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

  /// Delete a post using API
  /// API: POST https://gravity.attoexasolutions.com/api/delete_post
  Future<bool> deletePost(int postId) async {
    isDeletingPost.value = true;
    deletePostError.value = '';

    try {
      debugPrint('🔄 Deleting post via API...');
      debugPrint('   - Post ID: $postId');

      final response = await _communityRepository.deletePost(postId: postId);

      if (response.isSuccess) {
        debugPrint('✅ Post deleted successfully: ${response.message}');

        // Remove the post from the local list
        posts.removeWhere((p) => p.id == postId);
        posts.refresh();

        // Show success message
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
        debugPrint('❌ Failed to delete post: ${response.message}');

        // Show error message
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
      debugPrint('❌ Error deleting post: $e');

      // Show error message
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

  /// Show delete confirmation dialog
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

  void openComments(int postId) {
    selectedPostId.value = postId;
    // Fetch comments from API
    fetchAllPostComments(postId);
  }

  void closeComments() {
    selectedPostId.value = 0;
    // Clear single post data
    singlePost.value = null;
    singlePostError.value = '';
    // Clear comments data
    postComments.clear();
    commentsError.value = '';
    newComment.value = '';
    commentTextController.clear();
    replyingToPostId.value = 0;
    replyingToCommentId.value = 0;
    newReply.value = '';
    replyTextController.clear();
    // Clear edit comment state
    closeEditComment();
  }

  void startReply(int postId, int commentId) {
    replyingToPostId.value = postId;
    replyingToCommentId.value = commentId;
    // Fetch single comment with replies from API
    fetchSingleComment(postId, commentId);
  }

  void cancelReply() {
    replyingToPostId.value = 0;
    replyingToCommentId.value = 0;
    newReply.value = '';
    replyTextController.clear();
  }

  Post? get selectedPost {
    if (selectedPostId.value == 0) return null;
    // Use single post from API if available, otherwise fallback to local posts list
    if (singlePost.value != null &&
        singlePost.value!.id == selectedPostId.value) {
      return singlePost.value;
    }
    return posts.firstWhereOrNull((p) => p.id == selectedPostId.value);
  }

  /// Set the scroll controller for the Community page
  void setScrollController(ItemScrollController controller) {
    _itemScrollController = controller;
  }

  /// Scroll to the top of the Community page
  void scrollToTop() {
    if (_itemScrollController != null && posts.isNotEmpty) {
      _itemScrollController!.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }
}
