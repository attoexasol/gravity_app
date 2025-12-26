import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';

/// AI Coach Repository - Handles AI Coach API calls
class AiCoachRepository {
  final ApiService _apiService = ApiService();

  /// Get AI Coach reply
  /// API: POST https://gravity.attoexasolutions.com/api/ai_coach/reply
  /// Request: { "api_token": string, "message": string }
  /// Response: { "success": true, "data": { "from_user": number, "user_message": string, "ai_coach_reply": string } }
  Future<ApiResponse<Map<String, dynamic>>> getAiCoachReply({
    required String apiToken,
    required String message,
  }) async {
    try {
      debugPrint('🔄 Getting AI Coach reply...');
      debugPrint('   - Message: $message');

      final response = await _apiService.post(
        '/ai_coach/reply',
        body: {
          'api_token': apiToken,
          'message': message,
        },
      );

      debugPrint('📥 AI Coach Reply Response Status: ${response['success']}');
      debugPrint('📥 AI Coach Reply Response Data: ${response['data']}');

      // Extract data from response
      // API Response format: { "success": true, "data": { "from_user": number, "user_message": string, "ai_coach_reply": string } }
      Map<String, dynamic>? responseData;
      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        responseData = response['data'] as Map<String, dynamic>;
        debugPrint('📥 AI Coach Reply: ${responseData['ai_coach_reply']}');
      }

      return ApiResponse<Map<String, dynamic>>(
        status: response['success'] ?? false,
        message: response['message'] ?? (response['success'] == true ? 'Success' : 'Failed to get AI response'),
        data: responseData,
      );
    } on ApiException catch (e) {
      debugPrint('❌ AI Coach Reply API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ AI Coach Reply Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}

