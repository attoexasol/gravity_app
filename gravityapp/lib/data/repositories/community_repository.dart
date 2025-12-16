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
}

