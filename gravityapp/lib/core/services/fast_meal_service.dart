import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'preferences_service.dart';

/// Fast Meal API - https://gravity.attoexasolutions.com/api/fast-meal/
///
/// GET /fast-meal/get - Request: { api_token, date (YYYY-MM-DD) }
///   Response: { date, fast_meal_category (1=Normal, 2=OMAD), meal1_done (0|1), meal2_done (0|1), status }
///
/// UPDATE /fast-meal/update - Request: { api_token, date, fast_meal_category, meal_number (1|2) }
///   Response: { date, fast_meal_category, meal1_done, meal2_done, status }

/// Response model for fast-meal API (get and update)
class FastMealResponse {
  final int fastMealCategory; // 1 = Normal, 2 = OMAD
  final bool meal1Done;
  final bool meal2Done;
  final String status; // 'partial' | 'complete'

  FastMealResponse({
    required this.fastMealCategory,
    required this.meal1Done,
    required this.meal2Done,
    required this.status,
  });

  factory FastMealResponse.fromJson(Map<String, dynamic> json) {
    final cat = json['fast_meal_category'];
    return FastMealResponse(
      fastMealCategory: cat is int ? cat : (cat is num ? cat.toInt() : 1),
      meal1Done: json['meal1_done'] == true || json['meal1_done'] == 1,
      meal2Done: json['meal2_done'] == true || json['meal2_done'] == 1,
      status: (json['status'] as String?) ?? 'partial',
    );
  }

  /// Progress value for ring: Normal = (m1+m2)/2, OMAD = m1/1
  double get progressValue =>
      fastMealCategory == 2 ? (meal1Done ? 1.0 : 0.0) : (meal1Done ? 1 : 0) + (meal2Done ? 1 : 0).toDouble();

  /// Max for ring: Normal = 2, OMAD = 1
  double get progressMax => fastMealCategory == 2 ? 1.0 : 2.0;

  /// Display string e.g. "1/2" or "1/1"
  String get progressLabel =>
      fastMealCategory == 2
          ? '${meal1Done ? 1 : 0}/1'
          : '${(meal1Done ? 1 : 0) + (meal2Done ? 1 : 0)}/2';
}

/// Service for fast-meal API - logs fasting meals to backend
class FastMealService {
  final ApiService _apiService = ApiService();

  /// Update fast meal - logs Meal 1 or Meal 2 based on user tap
  /// [fastMealCategory] 1 = Normal Mode (2 meals), 2 = O.M.A.D Mode (1 meal)
  /// [mealNumber] 1 or 2 - which meal tile user tapped
  Future<FastMealResponse?> updateFastMeal({
    required int fastMealCategory,
    required int mealNumber,
    required String date,
  }) async {
    try {
      // Read token from existing auth/session - do NOT hardcode
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ FastMealService: No api_token available');
        return null;
      }

      final body = <String, dynamic>{
        'api_token': apiToken,
        'date': date,
        'fast_meal_category': fastMealCategory,
        'meal_number': mealNumber,
      };

      debugPrint('📤 Fast Meal API Request:');
      debugPrint('   - fast_meal_category: $fastMealCategory');
      debugPrint('   - meal_number: $mealNumber');
      debugPrint('   - date: $date');

      // Endpoint: /fast-meal/update - baseUrl/api/fast-meal/update
      final response = await _apiService.post(
        '/fast-meal/update',
        body: body,
      );

      // API returns: { date, fast_meal_category, meal1_done (0|1), meal2_done (0|1), status ("partial"|"complete") }
      if (response.containsKey('meal1_done') || response.containsKey('meal2_done')) {
        return FastMealResponse.fromJson(response);
      }
      // Handle wrapped response: { status: true, data: {...} }
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && (data.containsKey('meal1_done') || data.containsKey('meal2_done'))) {
        return FastMealResponse.fromJson(data);
      }

      debugPrint('⚠️ Fast Meal API: Unexpected response format');
      return null;
    } on ApiException catch (e) {
      debugPrint('❌ Fast Meal API Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Fast Meal API Unknown Error: $e');
      rethrow;
    }
  }

  /// Get fast meal for date - fetches meal1_done, meal2_done, fast_meal_category from API
  Future<FastMealResponse?> getFastMeal({required String date}) async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ FastMealService: No api_token for getFastMeal');
        return null;
      }

      final body = <String, dynamic>{
        'api_token': apiToken,
        'date': date,
      };

      debugPrint('📤 Fast Meal GET Request: date=$date');

      final response = await _apiService.post(
        '/fast-meal/get',
        body: body,
      );

      if (response.containsKey('meal1_done') || response.containsKey('meal2_done')) {
        return FastMealResponse.fromJson(response);
      }
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && (data.containsKey('meal1_done') || data.containsKey('meal2_done'))) {
        return FastMealResponse.fromJson(data);
      }

      debugPrint('⚠️ Fast Meal GET: Unexpected response format');
      return null;
    } on ApiException catch (e) {
      debugPrint('❌ Fast Meal GET Error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Fast Meal GET Unknown Error: $e');
      return null;
    }
  }
}
