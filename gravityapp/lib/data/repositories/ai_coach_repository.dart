import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';

/// AI Coach Repository - Handles AI Coach API calls
class AiCoachRepository {
  final ApiService _apiService = ApiService();

  /// Get AI Coach reply
  /// API: POST https://gravity.attoexasolutions.com/api/ai_coach/reply
  /// 
  /// Request Modes:
  /// 1) TEXT: { "api_token": string, "message": string }
  /// 2) IMAGE: { "api_token": string, "image_base64": "data:image/png;base64,..." }
  /// 
  /// Response Modes:
  /// TEXT: { "success": true, "data": { "from_user": number, "user_message": string, "ai_coach_reply": string } }
  /// IMAGE: { "success": true, "data": { "from_user": number, "ai_coach_reply": string } }
  /// 
  /// Rules:
  /// - Send EITHER "message" OR "image_base64", NEVER both
  /// - message is REQUIRED only for text mode
  /// - image_base64 is REQUIRED only for image mode
  Future<ApiResponse<Map<String, dynamic>>> getAiCoachReply({
    required String apiToken,
    String? message,
    String? imageBase64,
  }) async {
    try {
      // Validation: must have either message or imageBase64, but not both
      if (message == null && imageBase64 == null) {
        throw ArgumentError('Either message or imageBase64 must be provided');
      }
      if (message != null && imageBase64 != null) {
        throw ArgumentError('Cannot send both message and imageBase64 together');
      }

      // Determine request mode
      final isTextMode = message != null;
      final isImageMode = imageBase64 != null;

      debugPrint('🔄 Getting AI Coach reply...');
      debugPrint('   - Mode: ${isTextMode ? "TEXT" : "IMAGE"}');
      if (isTextMode) {
        debugPrint('   - Message: $message');
      } else {
        debugPrint('   - Has Image: true');
        debugPrint('   - Image Base64 size: ${imageBase64!.length} chars');
      }

      // Build request body dynamically
      // Send ONLY message OR image_base64, never both
      final Map<String, dynamic> requestBody = {
        'api_token': apiToken,
      };

      if (isTextMode) {
        requestBody['message'] = message!;
      } else {
        requestBody['image_base64'] = imageBase64!;
      }

      // Call API with 60 second timeout
      final response = await _apiService.post(
        '/ai_coach/reply',
        body: requestBody,
        timeout: const Duration(seconds: 60),
      );

      debugPrint('📥 AI Coach Reply Response Status: ${response['success']}');
      if (response['data'] != null) {
        debugPrint('📥 AI Coach Reply Response Data keys: ${(response['data'] as Map<String, dynamic>).keys}');
      }

      // Extract data from response
      // Response format varies:
      // TEXT: { "success": true, "data": { "from_user": number, "user_message": string, "ai_coach_reply": string } }
      // IMAGE: { "success": true, "data": { "from_user": number, "ai_coach_reply": string } }
      Map<String, dynamic>? responseData;
      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        responseData = response['data'] as Map<String, dynamic>;
        final aiReply = responseData['ai_coach_reply'] as String?;
        if (aiReply != null) {
          debugPrint('📥 AI Coach Reply: ${aiReply.length > 100 ? "${aiReply.substring(0, 100)}..." : aiReply}');
        } else {
          debugPrint('⚠️ AI Coach Reply is missing in response');
        }
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

