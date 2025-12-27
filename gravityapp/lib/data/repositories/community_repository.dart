import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';

/// Community Repository - Handles community API calls
class CommunityRepository {
  final ApiService _apiService = ApiService();

  /// Get all communities
  Future<ApiResponse<List<dynamic>>> getAllCommunities() async {
    try {
      final response = await _apiService.get('/all_communities');

      return ApiResponse<List<dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is List
            ? response['data'] as List<dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetAllCommunities API Error: ${e.message}');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetAllCommunities Unknown Error: $e');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get single community by ID
  Future<ApiResponse<Map<String, dynamic>>> getSingleCommunity({
    required int communityId,
  }) async {
    try {
      final response = await _apiService.post(
        '/single_communities',
        body: {
          'community_id': communityId,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetSingleCommunity API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSingleCommunity Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Create a new community
  Future<ApiResponse<Map<String, dynamic>>> createCommunity({
    required String communityName,
    required String communityDescription,
  }) async {
    try {
      final response = await _apiService.post(
        '/create_communities',
        body: {
          'community_name': communityName,
          'community_description': communityDescription,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreateCommunity API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreateCommunity Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Update an existing community
  Future<ApiResponse<Map<String, dynamic>>> updateCommunity({
    required int communityId,
    required String communityName,
    required String communityDescription,
  }) async {
    try {
      final response = await _apiService.post(
        '/update_communities',
        body: {
          'community_id': communityId,
          'community_name': communityName,
          'community_description': communityDescription,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ UpdateCommunity API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ UpdateCommunity Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Delete a community by ID
  Future<ApiResponse<Map<String, dynamic>>> deleteCommunity({
    required int communityId,
  }) async {
    try {
      final response = await _apiService.post(
        '/delete_communities',
        body: {
          'community_id': communityId,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ DeleteCommunity API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ DeleteCommunity Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get all posts
  Future<ApiResponse<List<dynamic>>> getAllPosts() async {
    try {
      final response = await _apiService.get('/all_posts');

      return ApiResponse<List<dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is List
            ? response['data'] as List<dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetAllPosts API Error: ${e.message}');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetAllPosts Unknown Error: $e');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get single post by ID
  /// API: POST https://gravity.attoexasolutions.com/api/single_post
  Future<ApiResponse<Map<String, dynamic>>> getSinglePost({
    required int postId,
  }) async {
    try {
      final response = await _apiService.post(
        '/single_post',
        body: {
          'post_id': postId,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetSinglePost API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSinglePost Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Create a new post
  /// API: POST https://gravity.attoexasolutions.com/api/create_post
  Future<ApiResponse<Map<String, dynamic>>> createPost({
    required String apiToken,
    required int communityId,
    required String postText,
    String postStatus = 'published',
    int likeCount = 0,
    int thumbsUpCount = 0,
    int otherCount = 0,
    String? postImageBase64,
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
        'community_id': communityId,
        'post_text': postText,
        'post_status': postStatus,
        'like_count': likeCount,
        'thumsup_count': thumbsUpCount,
        'other_count': otherCount,
      };

      // Add post_image if provided
      if (postImageBase64 != null && postImageBase64.isNotEmpty) {
        body['post_image'] = postImageBase64;
      }

      debugPrint('🔄 Creating post with body: ${body.keys}');

      final response = await _apiService.post(
        '/create_post',
        body: body,
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreatePost API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreatePost Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Update an existing post
  /// API: POST https://gravity.attoexasolutions.com/api/update_post
  /// Note: Only include reaction fields that have a value > 0 (Facebook-like behavior)
  Future<ApiResponse<Map<String, dynamic>>> updatePost({
    required String apiToken,
    required int postId,
    required int communityId,
    required String postText,
    String postStatus = 'published',
    int likeCount = 0,
    int thumbsUpCount = 0,
    int otherCount = 0,
    String? postImageBase64,
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
        'post_id': postId,
        'community_id': communityId,
        'post_text': postText,
        'post_status': postStatus,
      };

      // Only include reaction fields that have a value > 0 (Facebook-like: only send selected reaction)
      if (likeCount > 0) {
        body['like_count'] = likeCount;
      }
      if (thumbsUpCount > 0) {
        body['thumsup_count'] = thumbsUpCount;
      }
      if (otherCount > 0) {
        body['other_count'] = otherCount;
      }

      // Add post_image if provided
      if (postImageBase64 != null && postImageBase64.isNotEmpty) {
        body['post_image'] = postImageBase64;
      }

      debugPrint('🔄 Updating post (ID: $postId) with body: ${body.keys}');

      final response = await _apiService.post(
        '/update_post',
        body: body,
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ UpdatePost API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ UpdatePost Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Delete a post by ID
  /// API: POST https://gravity.attoexasolutions.com/api/delete_post
  Future<ApiResponse<Map<String, dynamic>>> deletePost({
    required int postId,
  }) async {
    try {
      debugPrint('🔄 Deleting post (ID: $postId)...');

      final response = await _apiService.post(
        '/delete_post',
        body: {
          'post_id': postId,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ DeletePost API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ DeletePost Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Create a comment on a post
  /// API: POST https://gravity.attoexasolutions.com/api/create_post_comment
  /// 
  /// Parameters:
  /// - apiToken: User's authentication token
  /// - postId: The ID of the post to comment on
  /// - comments: The comment text
  /// - commentId: Parent comment ID for replies (null or 0 for top-level comments)
  Future<ApiResponse<Map<String, dynamic>>> createPostComment({
    required String apiToken,
    required int postId,
    required String comments,
    int? commentId,
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
        'post_id': postId,
        'comments': comments,
      };

      // Add comment_id for replies (parent comment)
      if (commentId != null && commentId > 0) {
        body['comment_id'] = commentId;
      }

      debugPrint('🔄 Creating comment with body: ${body.keys}');
      debugPrint('   - Post ID: $postId');
      debugPrint('   - Comment text: $comments');
      debugPrint('   - Parent Comment ID: $commentId');

      final response = await _apiService.post(
        '/create_post_comment',
        body: body,
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreatePostComment API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreatePostComment Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get all comments for a post
  /// API: POST https://gravity.attoexasolutions.com/api/all_post_comments
  Future<ApiResponse<List<dynamic>>> getAllPostComments({
    required int postId,
  }) async {
    try {
      debugPrint('🔄 Fetching all comments for post (ID: $postId)...');

      final response = await _apiService.post(
        '/all_post_comments',
        body: {
          'post_id': postId,
        },
      );

      return ApiResponse<List<dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is List
            ? response['data'] as List<dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetAllPostComments API Error: ${e.message}');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetAllPostComments Unknown Error: $e');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get single comment with replies
  /// API: POST https://gravity.attoexasolutions.com/api/single_post_comment
  Future<ApiResponse<Map<String, dynamic>>> getSinglePostComment({
    required int commentId,
  }) async {
    try {
      debugPrint('🔄 Fetching single comment (ID: $commentId)...');

      final response = await _apiService.post(
        '/single_post_comment',
        body: {
          'comment_id': commentId,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetSinglePostComment API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSinglePostComment Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Update a comment
  /// API: POST https://gravity.attoexasolutions.com/api/update_post_comment
  Future<ApiResponse<Map<String, dynamic>>> updatePostComment({
    required String apiToken,
    required int postId,
    required int commentId,
    required String comments,
  }) async {
    try {
      debugPrint('🔄 Updating comment (ID: $commentId)...');

      final response = await _apiService.post(
        '/update_post_comment',
        body: {
          'api_token': apiToken,
          'post_id': postId,
          'comment_id': commentId,
          'comments': comments,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ UpdatePostComment API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ UpdatePostComment Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Delete a comment
  /// API: POST https://gravity.attoexasolutions.com/api/delete_post_comment
  Future<ApiResponse<Map<String, dynamic>>> deletePostComment({
    required String apiToken,
    required int commentId,
  }) async {
    try {
      debugPrint('🔄 Deleting comment (ID: $commentId)...');

      final response = await _apiService.post(
        '/delete_post_comment',
        body: {
          'api_token': apiToken,
          'comment_id': commentId,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ DeletePostComment API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ DeletePostComment Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// React to a post
  /// API: POST https://gravity.attoexasolutions.com/api/post/react
  /// 
  /// IMPORTANT: Backend expects only ONE reaction field to be sent at a time (not all three).
  /// When a user switches reactions, the backend should:
  /// 1. Set the previous reaction status to 0 (inactive)
  /// 2. Set the new reaction status to 1 (active)
  /// 3. Update counts accordingly
  /// 
  /// Request format (only send the selected reaction):
  /// - For like: { "api_token": string, "post_id": number, "like": true }
  /// - For thumbs up: { "api_token": string, "post_id": number, "thumsup": true }
  /// - For fire: { "api_token": string, "post_id": number, "other": true }
  /// - To remove: { "api_token": string, "post_id": number } (no reaction field)
  /// 
  /// Response: { "status": true, "message": "...", "data": { "like_count": number, "thumsup_count": number, "other_count": number } }
  Future<ApiResponse<Map<String, dynamic>>> reactToPost({
    required String apiToken,
    required int postId,
    required bool like,
    required bool thumsup,
    required bool other,
  }) async {
    try {
      debugPrint('🔄 Reacting to post (Post ID: $postId)...');
      debugPrint('   - like: $like, thumsup: $thumsup, other: $other');

      // Based on Postman testing, backend expects only ONE field to be sent
      // Send only the selected reaction field, omit others
      final requestBody = <String, dynamic>{
        'api_token': apiToken,
        'post_id': postId,
      };
      
      // Only include the field that is true (only one should be true at a time)
      if (like) {
        requestBody['like'] = true;
      } else if (thumsup) {
        requestBody['thumsup'] = true;
      } else if (other) {
        requestBody['other'] = true;
      }
      // If all are false, send nothing (removes reaction)
      
      debugPrint('📤 Request body: ${requestBody.keys}');
      debugPrint('📤 Request body values: ${requestBody.toString()}');

      final response = await _apiService.post(
        '/post/react',
        body: requestBody,
      );

      debugPrint('📥 ReactToPost Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ ReactToPost API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ ReactToPost Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get user-wise reactions for all posts
  /// API: POST https://gravity.attoexasolutions.com/api/user_wise_react
  /// Request: { "api_token": string }
  /// Response: { "status": true, "data": [{ "id": number, "post": { "id": number, "post_text": string }, "like": boolean, "thumsup": boolean, "other": boolean, "token": string }] }
  Future<ApiResponse<List<dynamic>>> getUserWiseReact({
    required String apiToken,
  }) async {
    try {
      debugPrint('🔄 Fetching user-wise reactions...');

      final response = await _apiService.post(
        '/user_wise_react',
        body: {
          'api_token': apiToken,
        },
      );

      debugPrint('📥 GetUserWiseReact Response Status: ${response['status']}');

      return ApiResponse<List<dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is List
            ? response['data'] as List<dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetUserWiseReact API Error: ${e.message}');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetUserWiseReact Unknown Error: $e');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Pin a community post
  /// API: POST https://gravity.attoexasolutions.com/api/pin_community_post
  /// Request: { "api_token": string, "post_id": number, "community_id": number }
  /// Response: { "status": true, "message": "Post pinned successfully", "data": { "id": number, "post_id": number, "community_id": number, "is_pin_post": true } }
  Future<ApiResponse<Map<String, dynamic>>> pinCommunityPost({
    required String apiToken,
    required int postId,
    required int communityId,
  }) async {
    try {
      debugPrint('📌 Pinning post $postId in community $communityId...');

      final response = await _apiService.post(
        '/pin_community_post',
        body: {
          'api_token': apiToken,
          'post_id': postId,
          'community_id': communityId,
        },
      );

      debugPrint('📥 PinCommunityPost Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ PinCommunityPost API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ PinCommunityPost Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Unpin a community post
  /// API: POST https://gravity.attoexasolutions.com/api/unpin_community_post
  /// Request: { "api_token": string, "post_id": number, "community_id": number }
  /// Response: { "status": true, "message": "Post unpinned successfully" }
  Future<ApiResponse<Map<String, dynamic>>> unpinCommunityPost({
    required String apiToken,
    required int postId,
    required int communityId,
  }) async {
    try {
      debugPrint('📌 Unpinning post $postId in community $communityId...');

      final response = await _apiService.post(
        '/unpin_community_post',
        body: {
          'api_token': apiToken,
          'post_id': postId,
          'community_id': communityId,
        },
      );

      debugPrint('📥 UnpinCommunityPost Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ UnpinCommunityPost API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ UnpinCommunityPost Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get user-wise pinned posts
  /// API: POST https://gravity.attoexasolutions.com/api/user_wise_pinned_posts
  /// Request: { "api_token": string }
  /// Response: { "status": true, "message": "Pined Post get successfully", "data": [{ "id": number, "post": { "id": number, "post_text": string }, "community": { "id": number, "name": string }, "is_pin_post": boolean }] }
  Future<ApiResponse<List<dynamic>>> getUserWisePinnedPosts({
    required String apiToken,
  }) async {
    try {
      debugPrint('🔄 Fetching user-wise pinned posts...');

      final response = await _apiService.post(
        '/user_wise_pinned_posts',
        body: {
          'api_token': apiToken,
        },
      );

      debugPrint('📥 GetUserWisePinnedPosts Response Status: ${response['status']}');

      return ApiResponse<List<dynamic>>(
        status: response['status'] ?? true,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is List
            ? response['data'] as List<dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetUserWisePinnedPosts API Error: ${e.message}');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetUserWisePinnedPosts Unknown Error: $e');
      return ApiResponse<List<dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}

