import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../core/services/preferences_service.dart';
import '../model/api_response.dart';
import '../model/daily_summary.dart';

/// Daily Summary Repository - Handles Daily Summary API calls
class DailySummaryRepository {
  final ApiService _apiService = ApiService();

  /// Generate daily summary for a specific date
  Future<ApiResponse<DailySummary>> generateDailySummary({
    required String date, // yyyy-MM-dd format
  }) async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        return ApiResponse<DailySummary>(
          status: false,
          message: 'Authentication required. Please login again.',
          error: 'No API token found',
        );
      }

      final body = <String, dynamic>{
        'date': date,
      };

      debugPrint('📤 Generate Daily Summary Request:');
      debugPrint('   Date: $date');

      final response = await _apiService.post(
        '/daily-summary/generate',
        body: body,
        headers: {
          'Authorization': 'Bearer $apiToken',
        },
      );

      debugPrint('📥 Generate Daily Summary Response Status: ${response['status']}');

      return ApiResponse<DailySummary>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? DailySummary.fromJson(response['data'] as Map<String, dynamic>)
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GenerateDailySummary API Error: ${e.message}');
      return ApiResponse<DailySummary>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GenerateDailySummary Unknown Error: $e');
      return ApiResponse<DailySummary>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}

