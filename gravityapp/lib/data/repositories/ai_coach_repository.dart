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
  /// IMAGE: { "success": true, "data": { "from_user": string, "nutrition": number, "ai_coach_reply": string } }
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
        // Log nutrition value if present (image mode)
        if (isImageMode && response['data'] is Map<String, dynamic>) {
          final data = response['data'] as Map<String, dynamic>;
          final nutrition = data['nutrition'];
          if (nutrition != null) {
            debugPrint('📥 Nutrition value: $nutrition');
          }
        }
      }

      // Extract data from response
      // Response format varies:
      // TEXT: { "success": true, "data": { "from_user": number, "user_message": string, "ai_coach_reply": string } }
      // IMAGE: { "success": true, "data": { "from_user": string, "nutrition": number, "ai_coach_reply": string } }
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

  /// Get AI Coach chat history from server
  /// API: POST https://gravity.attoexasolutions.com/api/ai_coach/message/get
  /// 
  /// Request Body:
  /// { "api_token": string }
  /// 
  /// Response:
  /// {
  ///   "success": true,
  ///   "user_id": number,
  ///   "count": number,
  ///   "data": [
  ///     {
  ///       "id": number,
  ///       "user_message": string | null,
  ///       "ai_message": string,
  ///       "nutration": number,  // Note: API has typo "nutration" instead of "nutrition"
  ///       "created_at": string (ISO 8601)
  ///     }
  ///   ]
  /// }
  Future<ApiResponse<List<Map<String, dynamic>>>> getChatHistory({
    required String apiToken,
  }) async {
    try {
      debugPrint('🔄 Fetching AI Coach chat history from server...');

      final requestBody = {
        'api_token': apiToken,
      };

      // Call API with 30 second timeout
      final response = await _apiService.post(
        '/ai_coach/message/get',
        body: requestBody,
        timeout: const Duration(seconds: 30),
      );

      debugPrint('📥 Chat History Response Status: ${response['success']}');
      
      if (response['success'] == true) {
        final count = response['count'] as int? ?? 0;
        debugPrint('📥 Chat History Count: $count messages');
        
        List<Map<String, dynamic>> messagesList = [];
        if (response['data'] != null && response['data'] is List) {
          messagesList = (response['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          debugPrint('📥 Loaded ${messagesList.length} messages from server');
        }

        return ApiResponse<List<Map<String, dynamic>>>(
          status: true,
          message: response['message'] ?? 'Success',
          data: messagesList,
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          status: false,
          message: response['message'] ?? 'Failed to fetch chat history',
          data: [],
        );
      }
    } on ApiException catch (e) {
      debugPrint('❌ Chat History API Error: ${e.message}');
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: e.message,
        error: e.errors,
        data: [],
      );
    } catch (e) {
      debugPrint('❌ Chat History Unknown Error: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
        data: [],
      );
    }
  }

  /// Delete AI Coach message from server
  /// API: POST https://gravity.attoexasolutions.com/api/ai_coach/delete/message
  /// 
  /// Request Body:
  /// { "api_token": string, "id": number }
  /// 
  /// Response:
  /// {
  ///   "success": true,
  ///   "message": "AI coach message deleted successfully"
  /// }
  Future<ApiResponse<void>> deleteMessage({
    required String apiToken,
    required int messageId,
  }) async {
    try {
      debugPrint('🔄 Deleting AI Coach message from server...');
      debugPrint('   - Message ID: $messageId');

      final requestBody = {
        'api_token': apiToken,
        'id': messageId,
      };

      // Call API with 30 second timeout
      final response = await _apiService.post(
        '/ai_coach/delete/message',
        body: requestBody,
        timeout: const Duration(seconds: 30),
      );

      debugPrint('📥 Delete Message Response Status: ${response['success']}');
      debugPrint('📥 Delete Message Response: ${response['message']}');

      if (response['success'] == true) {
        return ApiResponse<void>(
          status: true,
          message: response['message'] ?? 'Message deleted successfully',
        );
      } else {
        return ApiResponse<void>(
          status: false,
          message: response['message'] ?? 'Failed to delete message',
        );
      }
    } on ApiException catch (e) {
      debugPrint('❌ Delete Message API Error: ${e.message}');
      return ApiResponse<void>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ Delete Message Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get day-wise nutrition data
  /// API: POST https://gravity.attoexasolutions.com/api/ai_coach/day_wise/nutration
  /// 
  /// Request Body:
  /// { "api_token": string, "day": string (format: "YY-MM-dd") }
  /// 
  /// Response:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "user_id": number,
  ///     "name": string,
  ///     "day": string,
  ///     "total_nutration": number
  ///   }
  /// }
  Future<ApiResponse<Map<String, dynamic>>> getDayWiseNutrition({
    required String apiToken,
    required String day, // Format: "YY-MM-dd" (e.g., "26-01-19")
  }) async {
    try {
      debugPrint('🔄 Fetching day-wise nutrition data...');
      debugPrint('   - Day: $day');

      final requestBody = {
        'api_token': apiToken,
        'day': day,
      };

      final response = await _apiService.post(
        '/ai_coach/day_wise/nutration',
        body: requestBody,
        timeout: const Duration(seconds: 30),
      );

      debugPrint('📥 Day-wise Nutrition Response Status: ${response['success']}');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final totalNutrition = data['total_nutration'] as int? ?? 0;
        debugPrint('📥 Total Nutrition: $totalNutrition calories');

        return ApiResponse<Map<String, dynamic>>(
          status: true,
          message: response['message'] ?? 'Success',
          data: data,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          status: false,
          message: response['message'] ?? 'Failed to fetch nutrition data',
          data: null,
        );
      }
    } on ApiException catch (e) {
      debugPrint('❌ Day-wise Nutrition API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ Day-wise Nutrition Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}

