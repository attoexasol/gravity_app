import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';

/// Consent Repository - Handles consent API calls
class ConsentRepository {
  final ApiService _apiService = ApiService();

  /// Create or update user consent
  Future<ApiResponse<Map<String, dynamic>>> createConsent({
    required String token,
    required int isAiFeatures,
    required int isDataPreferences,
    required int isDeleteMyData,
  }) async {
    try {
      final response = await _apiService.post(
        '/consent/create',
        body: {
          'token': token,
          'is_ai_features': isAiFeatures,
          'is_data_preferences': isDataPreferences,
          'is_delete_my_data': isDeleteMyData,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreateConsent API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreateConsent Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get single user consent
  Future<ApiResponse<Map<String, dynamic>>> getSingleConsent({
    required String token,
  }) async {
    try {
      final response = await _apiService.post(
        '/get_single_consent',
        body: {
          'token': token,
        },
      );

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetSingleConsent API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSingleConsent Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}

