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
        'like_count': likeCount,
        'thumsup_count': thumbsUpCount,
        'other_count': otherCount,
      };

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
}

