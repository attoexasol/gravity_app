import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/model/post.dart';
import 'community_comments_controller.dart';
import 'community_posts_controller.dart';

class CommunityController extends GetxController with CommunityCommentsController {
  // Repository for API calls
  final CommunityRepository _communityRepository = CommunityRepository();

  @override
  CommunityRepository get communityRepository => _communityRepository;

  // Posts controller (dependency injection)
  late final CommunityPostsController postsController;

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

  // Post state delegated to postsController (same API for UI)
  @override
  RxList<Post> get posts => postsController.posts;
  @override
  Rx<Post?> get singlePost => postsController.singlePost;
  RxBool get isLoadingPosts => postsController.isLoadingPosts;
  RxString get postsError => postsController.postsError;
  RxBool get isLoadingSinglePost => postsController.isLoadingSinglePost;
  RxString get singlePostError => postsController.singlePostError;
  RxBool get isCreatingPost => postsController.isCreatingPost;
  RxString get createPostError => postsController.createPostError;
  RxInt get selectedCommunityId => postsController.selectedCommunityId;
  RxBool get isUpdatingPost => postsController.isUpdatingPost;
  RxString get updatePostError => postsController.updatePostError;
  RxBool get showEditPost => postsController.showEditPost;
  RxInt get editingPostId => postsController.editingPostId;
  RxString get editPostText => postsController.editPostText;
  RxString get editPostImage => postsController.editPostImage;
  RxString get editPostImagePath => postsController.editPostImagePath;
  RxInt get editPostCommunityId => postsController.editPostCommunityId;
  RxBool get isDeletingPost => postsController.isDeletingPost;
  RxString get deletePostError => postsController.deletePostError;
  RxBool get showCreatePost => postsController.showCreatePost;
  RxString get newPostText => postsController.newPostText;
  RxString get selectedImage => postsController.selectedImage;
  RxString get selectedImagePath => postsController.selectedImagePath;
  RxBool get isPickingImage => postsController.isPickingImage;
  TextEditingController get createPostTextController =>
      postsController.createPostTextController;
  TextEditingController get editPostTextController =>
      postsController.editPostTextController;
  RxMap<int, Set<String>> get activeReactions => postsController.activeReactions;

  // UI state (comment bridge)
  final RxInt selectedPostId = 0.obs;

  // User profile info
  final RxString userProfileImage = ''.obs;
  final RxString userName = ''.obs;

  // Scroll controller for Community page
  ItemScrollController? _itemScrollController;

  /// Post to focus/highlight when opened from push (e.g. post_reaction). Cleared after ~3s.
  final Rx<String?> focusPostId = Rx<String?>(null);

  static const String _kFocusPostIdStorage = 'focus_post_id';

  /// Load user profile data from storage
  void _loadUserProfile() {
    // Load user name
    userName.value = PreferencesService.getUserName() ?? 'You';

    // Load profile image - prefer API URL over local path
    // Use PreferencesService methods for consistency
    final profileImageUrl = PreferencesService.getProfileImageUrl();
    final profileImagePath = PreferencesService.getProfileImagePath();

    // Only set profile image if it exists, otherwise use empty string
    // This ensures new users don't see old cached images
    userProfileImage.value = profileImageUrl ?? profileImagePath ?? '';

    debugPrint('👤 User profile loaded:');
    debugPrint('   - Name: ${userName.value}');
    debugPrint('   - Profile Image: ${userProfileImage.value.isEmpty ? "None" : userProfileImage.value}');
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

  void resetCreatePostState() => postsController.resetCreatePostState();
  void closeCreatePostDialog() => postsController.closeCreatePostDialog();

  /// Get user profile image URL or empty string
  @override
  String get currentUserProfileImage => userProfileImage.value;

  /// Get current user name
  @override
  String get currentUserName =>
      userName.value.isNotEmpty ? userName.value : 'You';

  /// Get current user ID
  @override
  int get currentUserId => PreferencesService.getUserId() ?? 0;

  Future<void> pickImageFromGallery() => postsController.pickImageFromGallery();
  Future<void> pickImageFromCamera() => postsController.pickImageFromCamera();
  void clearSelectedImage() => postsController.clearSelectedImage();
  void showImageSourcePicker() => postsController.showImageSourcePicker();

  @override
  void onInit() {
    super.onInit();
    _loadUserProfile();
    _fetchCommunities();
    postsController = Get.put(
      CommunityPostsController(commentMapper: mapApiResponseToComments),
    );
    postsController.onPostsLoadedCallback = _applyPendingFocusPost;
    postsController.loadUserPinnedPostsCallback = () =>
        postsController.loadUserPinnedPosts();
    postsController.refreshPosts();
  }

  @override
  void onReady() {
    super.onReady();
    postsController.loadUserReactions();
    postsController.loadUserPinnedPosts();
  }

  @override
  void onClose() {
    disposeCommentControllers();
    super.onClose();
  }

  Future<void> loadUserReactions() => postsController.loadUserReactions();
  Future<void> loadUserPinnedPosts() =>
      postsController.loadUserPinnedPosts();

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

  Future<void> refreshPosts() => postsController.refreshPosts();

  Future<void> pinPost(int postId, int communityId) =>
      postsController.pinPost(postId, communityId);

  Future<void> fetchSinglePost(int postId) =>
      postsController.fetchSinglePost(postId);

  Future<void> toggleReaction(int postId, String reaction) =>
      postsController.toggleReaction(postId, reaction);

  Future<bool> createPost() => postsController.createPost();

  void openEditPost(Post post) => postsController.openEditPost(post);

  void closeEditPost() => postsController.closeEditPost();  Future<void> pickImageFromGalleryForEdit() =>
      postsController.pickImageFromGalleryForEdit();

  Future<void> pickImageFromCameraForEdit() =>
      postsController.pickImageFromCameraForEdit();

  void clearEditSelectedImage() => postsController.clearEditSelectedImage();

  void showImageSourcePickerForEdit() =>
      postsController.showImageSourcePickerForEdit();

  Future<bool> updatePost() => postsController.updatePost();

  Future<bool> deletePost(int postId) => postsController.deletePost(postId);

  void confirmDeletePost(int postId) =>
      postsController.confirmDeletePost(postId);

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

  Post? get selectedPost {
    if (selectedPostId.value == 0) return null;
    // Use single post from API if available, otherwise fallback to local posts list
    if (singlePost.value != null &&
        singlePost.value!.id == selectedPostId.value) {
      return singlePost.value;
    }
    return posts.firstWhereOrNull((p) => p.id == selectedPostId.value);
  }

  /// Comment count for the current post: backend count if available, else null (for initial display before comments are loaded).
  int? get currentPostCommentsCount => selectedPost?.commentsCount;

  /// Set the scroll controller for the Community page
  void setScrollController(ItemScrollController controller) {
    _itemScrollController = controller;
    _applyPendingFocusPost();
  }

  /// Apply pending focus_post_id from push (e.g. post_reaction). Scroll to post and highlight for ~3s.
  void _applyPendingFocusPost() {
    final storage = GetStorage();
    final postIdStr = storage.read(_kFocusPostIdStorage) as String?;
    if (postIdStr == null || postIdStr.isEmpty) return;
    final postIdInt = int.tryParse(postIdStr);
    if (postIdInt == null || posts.isEmpty || _itemScrollController == null) return;
    final index = posts.indexWhere((p) => p.id == postIdInt);
    if (index < 0) return;
    storage.remove(_kFocusPostIdStorage);
    focusPostId.value = postIdStr;
    _itemScrollController!.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (focusPostId.value == postIdStr) focusPostId.value = null;
    });
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
