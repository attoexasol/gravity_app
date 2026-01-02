import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';

/// AI Coach Repository - Handles AI Coach API calls
class AiCoachRepository {
  final ApiService _apiService = ApiService();

  /// Get AI Coach reply
  /// API: POST https://gravity.attoexasolutions.com/api/ai_coach/reply
  /// Request (text only): { "api_token": string, "message": string }
  /// Request (with image): { "api_token": string, "message": string, "image_base64": "data:image/png;base64,..." }
  /// Response: { "success": true, "data": { "from_user": number, "user_message": string, "ai_coach_reply": string } }
  Future<ApiResponse<Map<String, dynamic>>> getAiCoachReply({
    required String apiToken,
    required String message,
    File? imageFile,
  }) async {
    try {
      debugPrint('🔄 Getting AI Coach reply...');
      debugPrint('   - Message: $message');
      debugPrint('   - Has Image: ${imageFile != null}');

      // Build request body conditionally
      final Map<String, dynamic> requestBody = {
        'api_token': apiToken,
        'message': message,
      };

      // Add image_base64 only if image file is provided
      if (imageFile != null) {
        try {
          // Read image file as bytes
          final imageBytes = await imageFile.readAsBytes();
          
          // Determine image MIME type from file extension
          String mimeType = 'image/png'; // Default
          final extension = imageFile.path.split('.').last.toLowerCase();
          if (extension == 'jpg' || extension == 'jpeg') {
            mimeType = 'image/jpeg';
          } else if (extension == 'png') {
            mimeType = 'image/png';
          } else if (extension == 'gif') {
            mimeType = 'image/gif';
          } else if (extension == 'webp') {
            mimeType = 'image/webp';
          }
          
          // Convert to Base64 with data URI prefix
          final base64Image = base64Encode(imageBytes);
          final imageBase64 = 'data:$mimeType;base64,$base64Image';
          
          requestBody['image_base64'] = imageBase64;
          debugPrint('   - Image Base64 size: ${base64Image.length} chars');
          debugPrint('   - Image MIME type: $mimeType');
        } catch (e) {
          debugPrint('⚠️ Error converting image to Base64: $e');
          // Continue without image if conversion fails
        }
      }

      final response = await _apiService.post(
        '/ai_coach/reply',
        body: requestBody,
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

