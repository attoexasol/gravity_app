import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';

/// Goals Repository - Handles goals API calls
class GoalsRepository {
  final ApiService _apiService = ApiService();

  /// Create user goals
  Future<ApiResponse<Map<String, dynamic>>> createGoals({
    required String token,
    required String currentWeight,
    required String targetWeight,
    required String stepGoal,
    required String dailyWaterIntake,
    required String sleepHours,
    required String aiTone,
  }) async {
    try {
      final response = await _apiService.post(
        '/goals/create',
        body: {
          'token': token,
          'current_weight': currentWeight,
          'target_weight': targetWeight,
          'step_goal': stepGoal,
          'daily_water_intake': dailyWaterIntake,
          'sleep_hours': sleepHours,
          'ai_tone': aiTone,
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
      debugPrint('❌ CreateGoals API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreateGoals Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get single user goal
  Future<ApiResponse<Map<String, dynamic>>> getSingleGoal({
    required String token,
  }) async {
    try {
      final response = await _apiService.post(
        '/get_single_goal',
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
      debugPrint('❌ GetSingleGoal API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSingleGoal Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}

