import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/api_service.dart';
import '../model/api_response.dart';
import '../model/message.dart';

/// Messages Repository - Handles Messages API calls and Firestore real-time streams
class MessagesRepository {
  final ApiService _apiService = ApiService();

  /// Get single message conversation with a specific user
  /// API: POST /single_message
  Future<ApiResponse<List<Map<String, dynamic>>>> getSingleMessage({
    required String apiToken,
    required int toUserId,
  }) async {
    try {
      debugPrint('📤 GET Single Message Request: To User ID=$toUserId');

      final body = {
        'api_token': apiToken,
        'to_user_id': toUserId,
      };

      final response = await _apiService.post(
        '/single_message',
        body: body,
      );

      debugPrint('📥 GET Single Message Response Status: ${response['status']}');
      debugPrint('📥 GET Single Message Updated Count: ${response['updated'] ?? 0}');

      List<Map<String, dynamic>> messages = [];
      if (response['data'] != null && response['data'] is List) {
        messages = (response['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      return ApiResponse<List<Map<String, dynamic>>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: messages,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetSingleMessage API Error: ${e.message}');
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSingleMessage Unknown Error: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get all messages with a specific user
  /// API: GET /all_messages?id={user_id}
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllMessages({
    required int otherUserId,
  }) async {
    try {
      debugPrint('📤 GET ALL Messages Request: User ID=$otherUserId');

      final response = await _apiService.get(
        '/all_messages?id=$otherUserId',
      );

      debugPrint('📥 GET ALL Messages Response Status: ${response['status']}');

      List<Map<String, dynamic>> messages = [];
      if (response['data'] != null && response['data'] is List) {
        messages = (response['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      return ApiResponse<List<Map<String, dynamic>>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: messages,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetAllMessages API Error: ${e.message}');
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetAllMessages Unknown Error: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Create a new message
  /// API: POST /create_message
  Future<ApiResponse<Map<String, dynamic>>> createMessage({
    required String apiToken,
    required int toUserId,
    required String message,
    required String messageContent,
  }) async {
    try {
      final body = {
        'api_token': apiToken,
        'to_user_id': toUserId,
        'message': message,
        'message_content': messageContent,
      };
      debugPrint('📤 CREATE Message Request: To User ID=$toUserId');

      final response = await _apiService.post(
        '/create_message',
        body: body,
      );

      debugPrint('📥 CREATE Message Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreateMessage API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreateMessage Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get all users (coaches or customers) based on role
  /// API: POST /all_users or GET /users?role=coach (adjust endpoint if different)
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllUsers({
    required String role, // 'coach' or 'customer'
  }) async {
    try {
      // Try POST first
      final body = {'role': role};
      debugPrint('📤 GET ALL Users Request: Role=$role');

      ApiResponse<List<Map<String, dynamic>>> response;
      
      try {
        final postResponse = await _apiService.post(
          '/all_users',
          body: body,
        );

        debugPrint('📥 GET ALL Users Response Status: ${postResponse['status']}');

        List<Map<String, dynamic>> users = [];
        if (postResponse['data'] != null && postResponse['data'] is List) {
          users = (postResponse['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else if (postResponse['users'] != null && postResponse['users'] is List) {
          users = (postResponse['users'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }

        response = ApiResponse<List<Map<String, dynamic>>>(
          status: postResponse['status'] ?? false,
          message: postResponse['message'] ?? '',
          data: users,
        );
      } catch (e) {
        // If POST fails, try GET
        debugPrint('⚠️ POST /all_users failed, trying GET /users?role=$role');
        try {
          final getResponse = await _apiService.get('/users?role=$role');
          
          List<Map<String, dynamic>> users = [];
          if (getResponse['data'] != null && getResponse['data'] is List) {
            users = (getResponse['data'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
          } else if (getResponse['users'] != null && getResponse['users'] is List) {
            users = (getResponse['users'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
          }

          response = ApiResponse<List<Map<String, dynamic>>>(
            status: getResponse['status'] ?? true,
            message: getResponse['message'] ?? '',
            data: users,
          );
        } catch (e2) {
          // If both fail, return empty list (will build from messages)
          debugPrint('⚠️ GET /users also failed, will build conversations from messages');
          return ApiResponse<List<Map<String, dynamic>>>(
            status: false,
            message: 'Could not fetch users list. Will build from existing messages.',
            data: [],
          );
        }
      }

      return response;
    } on ApiException catch (e) {
      debugPrint('❌ GetAllUsers API Error: ${e.message}');
      // Return empty list instead of error - we'll build from messages
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: e.message,
        data: [],
      );
    } catch (e) {
      debugPrint('❌ GetAllUsers Unknown Error: $e');
      // Return empty list instead of error - we'll build from messages
      return ApiResponse<List<Map<String, dynamic>>>(
        status: false,
        message: 'An unexpected error occurred. Will build from existing messages.',
        data: [],
      );
    }
  }

  /// Update a message
  /// API: POST /update_message
  Future<ApiResponse<Map<String, dynamic>>> updateMessage({
    required String apiToken,
    required int messageId,
    required String message,
    required String messageContent,
  }) async {
    try {
      final body = {
        'api_token': apiToken,
        'id': messageId,
        'message': message,
        'message_content': messageContent,
      };
      debugPrint('📤 UPDATE Message Request: Message ID=$messageId');

      final response = await _apiService.post(
        '/update_message',
        body: body,
      );

      debugPrint('📥 UPDATE Message Response Status: ${response['status']}');

      return ApiResponse<Map<String, dynamic>>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: response['data'] != null && response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ UpdateMessage API Error: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ UpdateMessage Unknown Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Delete a message
  /// API: POST /delete_message
  Future<ApiResponse<void>> deleteMessage({
    required int messageId,
  }) async {
    try {
      final body = {'id': messageId};
      debugPrint('📤 DELETE Message Request: Message ID=$messageId');

      final response = await _apiService.post(
        '/delete_message',
        body: body,
      );

      debugPrint('📥 DELETE Message Response Status: ${response['status']}');

      return ApiResponse<void>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ DeleteMessage API Error: ${e.message}');
      return ApiResponse<void>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ DeleteMessage Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Real-time stream of messages for a conversation from Firestore.
  /// Use this instead of polling; Laravel remains the source for creating messages.
  Stream<List<Message>> listenToMessages(String conversationId) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('created_at')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }
}

