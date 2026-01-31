import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';
import '../model/user_gravity_entry.dart';
import '../model/day_wise_goal_completion.dart';

/// User Gravity Repository - Handles User Gravity API calls
class UserGravityRepository {
  final ApiService _apiService = ApiService();

  /// Create a new user gravity entry
  Future<ApiResponse<UserGravityEntry>> createUserGravity({
    required String apiToken,
    required double? weight,
    required int? steps,
    required double? sleepHours,
    required double? hydrationLiters,
    required String? nutration,
    required String dataSource,
    required String date,
  }) async {
    try {
      // Build hydration string (e.g., "3L" or "3.5L")
      final hydrationStr = hydrationLiters != null
          ? (hydrationLiters % 1 == 0
              ? '${hydrationLiters.toInt()}L'
              : '${hydrationLiters.toStringAsFixed(1)}L')
          : null;

      final body = <String, dynamic>{
        'api_token': apiToken,
        'date': date,
        'data_source': dataSource,
        'nutration': nutration ?? 'good',
      };

      // Only include fields that are not null
      if (weight != null) body['weight'] = weight;
      if (steps != null) body['steps'] = steps.toString();
      if (sleepHours != null) body['sleep_hours'] = sleepHours.toString();
      if (hydrationStr != null) body['hydration'] = hydrationStr;

      debugPrint('📤 CREATE User Gravity Request:');
      debugPrint('   Keys: ${body.keys.toList()}');
      debugPrint('   Date: $date');
      debugPrint('   Data Source: $dataSource');

      final response = await _apiService.post(
        '/create_user_gravity',
        body: body,
      );

      debugPrint('📥 CREATE User Gravity Response Status: ${response['status']}');

      return ApiResponse<UserGravityEntry>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? UserGravityEntry.fromJson(response['data'] as Map<String, dynamic>)
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreateUserGravity API Error: ${e.message}');
      return ApiResponse<UserGravityEntry>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreateUserGravity Unknown Error: $e');
      return ApiResponse<UserGravityEntry>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Update an existing user gravity entry
  Future<ApiResponse<UserGravityEntry>> updateUserGravity({
    required int id,
    required String apiToken,
    required double? weight,
    required int? steps,
    required double? sleepHours,
    required double? hydrationLiters,
    required String? nutration,
    required String dataSource,
    required String date,
  }) async {
    try {
      // Build hydration string (e.g., "3L" or "3.5L")
      final hydrationStr = hydrationLiters != null
          ? (hydrationLiters % 1 == 0
              ? '${hydrationLiters.toInt()}L'
              : '${hydrationLiters.toStringAsFixed(1)}L')
          : null;

      final body = <String, dynamic>{
        'id': id,
        'api_token': apiToken,
        'date': date,
        'data_source': dataSource,
        'nutration': nutration ?? 'good',
      };

      // Only include fields that are not null
      if (weight != null) body['weight'] = weight;
      if (steps != null) body['steps'] = steps.toString();
      if (sleepHours != null) body['sleep_hours'] = sleepHours.toString();
      if (hydrationStr != null) body['hydration'] = hydrationStr;

      debugPrint('📤 UPDATE User Gravity Request:');
      debugPrint('   ID: $id');
      debugPrint('   Keys: ${body.keys.toList()}');
      debugPrint('   Date: $date');
      debugPrint('   Data Source: $dataSource');

      final response = await _apiService.post(
        '/update_user_gravity',
        body: body,
      );

      debugPrint('📥 UPDATE User Gravity Response Status: ${response['status']}');

      return ApiResponse<UserGravityEntry>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? UserGravityEntry.fromJson(response['data'] as Map<String, dynamic>)
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ UpdateUserGravity API Error: ${e.message}');
      return ApiResponse<UserGravityEntry>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ UpdateUserGravity Unknown Error: $e');
      return ApiResponse<UserGravityEntry>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get all user gravity entries (day-wise list)
  Future<ApiResponse<List<UserGravityEntry>>> getAllUserGravity({
    required String apiToken,
  }) async {
    try {
      // Use GET with api_token as query parameter (properly URL encoded)
      final endpoint = '/all_user_gravity?api_token=${Uri.encodeComponent(apiToken)}';

      debugPrint('📤 GET ALL User Gravity Request');

      final response = await _apiService.get(
        endpoint,
      );

      debugPrint('📥 GET ALL User Gravity Response Status: ${response['status']}');

      List<UserGravityEntry> entries = [];
      if (response['data'] != null && response['data'] is List) {
        final dataList = response['data'] as List;
        entries = dataList
            .map((item) => UserGravityEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return ApiResponse<List<UserGravityEntry>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: entries,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetAllUserGravity API Error: ${e.message}');
      return ApiResponse<List<UserGravityEntry>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetAllUserGravity Unknown Error: $e');
      return ApiResponse<List<UserGravityEntry>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get single user gravity entry
  Future<ApiResponse<UserGravityEntry>> getSingleUserGravity({
    required int id,
  }) async {
    try {
      final body = <String, dynamic>{
        'id': id,
      };

      debugPrint('📤 GET SINGLE User Gravity Request: ID=$id');

      final response = await _apiService.post(
        '/single_user_gravity',
        body: body,
      );

      debugPrint('📥 GET SINGLE User Gravity Response Status: ${response['status']}');

      return ApiResponse<UserGravityEntry>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? UserGravityEntry.fromJson(response['data'] as Map<String, dynamic>)
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetSingleUserGravity API Error: ${e.message}');
      return ApiResponse<UserGravityEntry>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSingleUserGravity Unknown Error: $e');
      return ApiResponse<UserGravityEntry>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Delete user gravity entry
  Future<ApiResponse<void>> deleteUserGravity({
    required int id,
    required String apiToken,
  }) async {
    try {
      final body = <String, dynamic>{
        'id': id,
        'api_token': apiToken,
      };

      debugPrint('📤 DELETE User Gravity Request: ID=$id');

      final response = await _apiService.post(
        '/delete_user_gravity',
        body: body,
      );

      debugPrint('📥 DELETE User Gravity Response Status: ${response['status']}');

      return ApiResponse<void>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ DeleteUserGravity API Error: ${e.message}');
      return ApiResponse<void>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ DeleteUserGravity Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Create manual user gravity entry
  /// API: POST https://gravity.attoexasolutions.com/api/create_manual_user_gravity
  /// This endpoint is specifically for manual entries from Quick Actions
  Future<ApiResponse<Map<String, dynamic>>> createManualUserGravity({
    required String apiToken,
    required String date,
    required String type, // "weight", "steps", "sleep_hours", "hydration"
    required String value, // Value as string
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
        'date': date,
        'type': type,
        'value': value,
      };

      debugPrint('📤 CREATE Manual User Gravity Request:');
      debugPrint('   - Type: $type');
      debugPrint('   - Value: $value');
      debugPrint('   - Date: $date');

      final response = await _apiService.post(
        '/create_manual_user_gravity',
        body: body,
      );

      debugPrint('📥 CREATE Manual User Gravity Response Status: ${response['status']}');
      debugPrint('📥 Response Message: ${response['message'] ?? ''}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreateManualUserGravity API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreateManualUserGravity Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get date-wise gravity entry
  /// API: POST https://gravity.attoexasolutions.com/api/date_wise/gravity
  Future<ApiResponse<Map<String, dynamic>>> getDateWiseGravity({
    required String apiToken,
    required String date, // YYYY-MM-DD format
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
        'date': date,
      };

      debugPrint('📤 GET Date-Wise Gravity Request:');
      debugPrint('   Date: $date');

      final response = await _apiService.post(
        '/date_wise/gravity',
        body: body,
      );

      debugPrint('📥 GET Date-Wise Gravity Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetDateWiseGravity API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetDateWiseGravity Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get monthly gravity weight data
  /// API: POST https://gravity.attoexasolutions.com/api/monthly/gravity_weight
  Future<ApiResponse<Map<String, dynamic>>> getMonthlyGravityWeight({
    required String apiToken,
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
      };

      debugPrint('📤 GET Monthly Gravity Weight Request');

      final response = await _apiService.post(
        '/monthly/gravity_weight',
        body: body,
      );

      debugPrint('📥 GET Monthly Gravity Weight Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetMonthlyGravityWeight API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetMonthlyGravityWeight Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Create or update daily reflection
  /// API: POST /user-gravity/daily_reflection/store
  /// Request Body: { "api_token": string, "daily_reflection": string }
  Future<ApiResponse<Map<String, dynamic>>> storeDailyReflection({
    required String apiToken,
    required String dailyReflection,
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
        'daily_reflection': dailyReflection,
      };

      debugPrint('📤 Store Daily Reflection Request');

      final response = await _apiService.post(
        '/user-gravity/daily_reflection/store',
        body: body,
      );

      debugPrint('📥 Store Daily Reflection Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ StoreDailyReflection API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ StoreDailyReflection Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Fetch weekly goal completion data
  /// API: POST https://gravity.attoexasolutions.com/api/day-wise-goal-completion
  /// Request Body: { "api_token": string, "start_date": string, "end_date": string }
  /// Response: Array of day-wise goal completion objects
  Future<ApiResponse<List<DayWiseGoalCompletion>>> fetchWeeklyGoalCompletion({
    required String apiToken,
    required String startDate, // YYYY-MM-DD format
    required String endDate, // YYYY-MM-DD format
  }) async {
    try {
      final body = <String, dynamic>{
        'api_token': apiToken,
        'start_date': startDate,
        'end_date': endDate,
      };

      debugPrint('📤 GET Weekly Goal Completion Request:');
      debugPrint('   Start Date: $startDate');
      debugPrint('   End Date: $endDate');

      final response = await _apiService.post(
        '/day-wise-goal-completion',
        body: body,
      );

      debugPrint('📥 GET Weekly Goal Completion Response Status: ${response['status']}');

      List<DayWiseGoalCompletion> completions = [];
      if (response['data'] != null && response['data'] is List) {
        final dataList = response['data'] as List;
        completions = dataList
            .map((item) => DayWiseGoalCompletion.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('📥 Parsed ${completions.length} day-wise goal completion entries');
      } else {
        debugPrint('⚠️ No data array found in response or data is not a list');
      }

      return ApiResponse<List<DayWiseGoalCompletion>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: completions,
      );
    } on ApiException catch (e) {
      debugPrint('❌ FetchWeeklyGoalCompletion API Error: ${e.message}');
      return ApiResponse<List<DayWiseGoalCompletion>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ FetchWeeklyGoalCompletion Unknown Error: $e');
      return ApiResponse<List<DayWiseGoalCompletion>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}

