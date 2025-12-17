import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../core/services/preferences_service.dart';

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
  final RxString editPostImagePath = ''.obs; // Local file path for picked edit image
  final RxInt editPostCommunityId = 2.obs;

  // Delete post state
  final RxBool isDeletingPost = false.obs;
  final RxString deletePostError = ''.obs;

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

  // Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  // Reactions tracking
  final RxMap<int, Set<String>> activeReactions = <int, Set<String>>{}.obs;

  // User profile info
  final RxString userProfileImage = ''.obs;
  final RxString userName = ''.obs;

  /// Load user profile data from storage
  void _loadUserProfile() {
    // Load user name
    userName.value = PreferencesService.getUserName() ?? 'You';
    
    // Load profile image - prefer API URL over local path
    final profileImageUrl = PreferencesService.getStorage().read('user_profile_image_url') as String?;
    final profileImagePath = PreferencesService.getStorage().read('user_profile_image') as String?;
    
    userProfileImage.value = profileImageUrl ?? profileImagePath ?? '';
    
    debugPrint('👤 User profile loaded:');
    debugPrint('   - Name: ${userName.value}');
    debugPrint('   - Profile Image: ${userProfileImage.value}');
  }

  /// Get user profile image URL or empty string
  String get currentUserProfileImage => userProfileImage.value;
  
  /// Get current user name
  String get currentUserName => userName.value.isNotEmpty ? userName.value : 'You';

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
  void showImageSourcePicker() {
    Get.bottomSheet(
      Container(
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
                    Get.back();
                    pickImageFromGallery();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    pickImageFromCamera();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF00B8A9),
            ),
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

  /// Fetch single post by ID from API
  /// API: POST https://gravity.attoexasolutions.com/api/single_post
  Future<void> fetchSinglePost(int postId) async {
    isLoadingSinglePost.value = true;
    singlePostError.value = '';
    singlePost.value = null;

    try {
      debugPrint('🔄 Fetching single post (ID: $postId) from API...');
      final response = await _communityRepository.getSinglePost(
        postId: postId,
      );

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
        userAvatarUrl = 'https://gravity.attoexasolutions.com/storage/$userProfileImage';
      }
    } else {
      // Default avatar if no profile image
      userAvatarUrl = 'https://i.pravatar.cc/150?img=${postId % 10}';
    }

    debugPrint('📊 Single Post Details:');
    debugPrint('   - ID: $postId');
    debugPrint('   - Text: $postText');
    debugPrint('   - Status: $postStatus');
    debugPrint('   - Image: $postImageUrl');
    debugPrint('   - User: $userName');
    debugPrint('   - Community: $communityName (ID: $communityId)');
    debugPrint('   - Reactions: ❤️$heartCount 👍$thumbsUpCount 🔥$fireCount');

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
      debugPrint('   - Token: ${apiToken.substring(0, apiToken.length > 20 ? 20 : apiToken.length)}... (${apiToken.length} chars)');
      debugPrint('   - Text: ${newPostText.value}');
      debugPrint('   - Community ID: ${selectedCommunityId.value}');
      debugPrint('   - Has Image: ${selectedImage.value.isNotEmpty}');
      debugPrint('   - Image Path: ${selectedImagePath.value}');

      // Prepare image data if selected
      // API expects full data URL format: data:image/png;base64,...
      String? postImageBase64;
      if (selectedImage.value.isNotEmpty && selectedImage.value.startsWith('data:image')) {
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
            postImageUrl = 'https://gravity.attoexasolutions.com/storage/$imagePath';
          }
        }

        // Get post ID from response or generate a temporary one
        int postId = 0;
        if (createdPostData != null && createdPostData['id'] != null) {
          postId = createdPostData['id'] is int 
              ? createdPostData['id'] 
              : int.tryParse(createdPostData['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch;
        } else {
          postId = DateTime.now().millisecondsSinceEpoch;
        }

        final newPost = Post(
          id: postId,
          user: User(
            name: postUserName,
            avatar: postUserAvatar,
          ),
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
        showCreatePost.value = false;

        // Close dialog first, then show success message
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        
        // Show success message with safe context
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            response.message.isNotEmpty ? response.message : 'Post created successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF00B8A9),
            colorText: const Color(0xFFFFFFFF),
            duration: const Duration(seconds: 2),
          );
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
          createPostError.value = 'Your session has expired. Please login again.';
          
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
      Container(
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
                    Get.back();
                    pickImageFromGalleryForEdit();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    pickImageFromCameraForEdit();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
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
      final currentPost = posts.firstWhereOrNull((p) => p.id == editingPostId.value);

      debugPrint('🔄 Updating post via API...');
      debugPrint('   - Post ID: ${editingPostId.value}');
      debugPrint('   - Text: ${editPostText.value}');
      debugPrint('   - Community ID: ${editPostCommunityId.value}');
      debugPrint('   - Has Image: ${editPostImage.value.isNotEmpty}');

      // Prepare image data if changed
      // API expects full data URL format: data:image/png;base64,...
      String? postImageBase64;
      if (editPostImage.value.isNotEmpty && editPostImage.value.startsWith('data:image')) {
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
        final userName = currentPost?.user.name ?? PreferencesService.getUserName() ?? 'You';
        final userAvatar = currentPost?.user.avatar ?? 'https://i.pravatar.cc/150?img=1';
        
        // Construct full image URL if post_image exists
        String postImageUrl = '';
        if (updatedPostData['post_image'] != null && 
            updatedPostData['post_image'].toString().isNotEmpty) {
          final imagePath = updatedPostData['post_image'].toString();
          if (imagePath.startsWith('http')) {
            postImageUrl = imagePath;
          } else {
            postImageUrl = 'https://gravity.attoexasolutions.com/storage/$imagePath';
          }
        }

        final updatedPost = Post(
          id: updatedPostData['id'] is int 
              ? updatedPostData['id'] 
              : int.tryParse(updatedPostData['id'].toString()) ?? editingPostId.value,
          user: User(
            name: userName,
            avatar: userAvatar,
          ),
          image: postImageUrl,
          text: updatedPostData['post_text']?.toString() ?? editPostText.value,
          timestamp: currentPost?.timestamp ?? 'Just now',
          reactions: Reactions(
            heart: updatedPostData['like_count'] ?? currentPost?.reactions.heart ?? 0,
            thumbsUp: updatedPostData['thumsup_count'] ?? currentPost?.reactions.thumbsUp ?? 0,
            fire: updatedPostData['other_count'] ?? currentPost?.reactions.fire ?? 0,
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
          response.message.isNotEmpty ? response.message : 'Post updated successfully',
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

      final response = await _communityRepository.deletePost(
        postId: postId,
      );

      if (response.isSuccess) {
        debugPrint('✅ Post deleted successfully: ${response.message}');
        
        // Remove the post from the local list
        posts.removeWhere((p) => p.id == postId);
        posts.refresh();

        // Show success message
        Get.snackbar(
          'Success',
          response.message.isNotEmpty ? response.message : 'Post deleted successfully',
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Post',
          style: TextStyle(
            color: Color(0xFF0A2342),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(
            color: Color(0xFF0A2342),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF0A2342),
              ),
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
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openComments(int postId) {
    selectedPostId.value = postId;
    // Fetch the latest post data from API
    fetchSinglePost(postId);
  }

  void closeComments() {
    selectedPostId.value = 0;
    // Clear single post data
    singlePost.value = null;
    singlePostError.value = '';
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
    // Use single post from API if available, otherwise fallback to local posts list
    if (singlePost.value != null && singlePost.value!.id == selectedPostId.value) {
      return singlePost.value;
    }
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