import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';
import '../model/user_gravity_entry.dart';

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
}

