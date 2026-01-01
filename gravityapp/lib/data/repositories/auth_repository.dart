import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/services/api_service.dart';
import '../../core/services/preferences_service.dart';
import '../model/api_response.dart';
import '../model/user_model.dart';

/// Auth Repository - Handles authentication API calls
class AuthRepository {
  final ApiService _apiService = ApiService();

  /// Create new user account
  Future<ApiResponse<UserModel>> createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    try {
      final response = await _apiService.post(
        '/user/create',
        body: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        },
      );

      return ApiResponse<UserModel>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data:
            response['user'] != null && response['user'] is Map<String, dynamic>
            ? UserModel.fromJson(response['user'] as Map<String, dynamic>)
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CreateUser API Error: ${e.message}');
      return ApiResponse<UserModel>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ CreateUser Unknown Error: $e');
      return ApiResponse<UserModel>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Login user
  /// Returns a map with 'response' (ApiResponse), 'token' (String?), 'user_id' (int?), 'user_name' (String?), and 'email' (String?)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/user/login',
        body: {'email': email, 'password': password},
      );

      // Extract token from root level
      final token = response['token'] as String?;

      // Extract user object from response
      final userData = response['user'] as Map<String, dynamic>?;

      // Extract user_id, user_name, and email from user object
      final userId = userData != null
          ? (userData['user_id'] as int? ?? userData['user_id'] as num?)
                ?.toInt()
          : null;
      final userName = userData != null
          ? (userData['user_name'] as String?)
          : null;
      final userEmail = userData != null
          ? (userData['email'] as String?)
          : null;

      debugPrint('🔍 Login Response Debug:');
      debugPrint('  - Token: ${token != null ? "Present" : "Missing"}');
      debugPrint('  - User Data: ${userData != null ? "Present" : "Missing"}');
      if (userData != null) {
        debugPrint('  - User ID: $userId');
        debugPrint('  - User Name: $userName');
        debugPrint('  - User Email: $userEmail');
      }

      final apiResponse = ApiResponse<UserModel>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: userData != null ? UserModel.fromJson(userData) : null,
      );

      return {
        'response': apiResponse,
        'token': token,
        'user_id': userId,
        'user_name': userName,
        'email': userEmail,
      };
    } on ApiException catch (e) {
      debugPrint('❌ Login API Error: ${e.message}');
      return {
        'response': ApiResponse<UserModel>(
          status: false,
          message: e.message,
          error: e.errors,
        ),
        'token': null,
        'user_id': null,
        'user_name': null,
        'email': null,
      };
    } catch (e) {
      debugPrint('❌ Login Unknown Error: $e');
      return {
        'response': ApiResponse<UserModel>(
          status: false,
          message: 'An unexpected error occurred. Please try again.',
          error: e.toString(),
        ),
        'token': null,
        'user_id': null,
        'user_name': null,
        'email': null,
      };
    }
  }

  /// Get user profile
  /// This method can be called after login to get full user information including user_id
  Future<ApiResponse<UserModel>> getUserProfile() async {
    try {
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw ApiException(
          message: 'Authentication token not found',
          statusCode: 401,
        );
      }

      final response = await _apiService.get(
        '/user/profile',
        headers: {'Authorization': 'Bearer $token'},
      );

      return ApiResponse<UserModel>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data:
            response['user'] != null && response['user'] is Map<String, dynamic>
            ? UserModel.fromJson(response['user'] as Map<String, dynamic>)
            : response['data'] != null &&
                  response['data'] is Map<String, dynamic>
            ? UserModel.fromJson(response['data'] as Map<String, dynamic>)
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetUserProfile API Error: ${e.message}');
      return ApiResponse<UserModel>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetUserProfile Unknown Error: $e');
      return ApiResponse<UserModel>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Get single user details
  /// API: POST /single_user with token in body
  Future<ApiResponse<UserModel>> getSingleUser() async {
    try {
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw ApiException(
          message: 'Authentication token not found',
          statusCode: 401,
        );
      }

      final response = await _apiService.post(
        '/single_user',
        body: {'token': token},
      );

      return ApiResponse<UserModel>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data:
            response['user'] != null && response['user'] is Map<String, dynamic>
            ? UserModel.fromJson(response['user'] as Map<String, dynamic>)
            : null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ GetSingleUser API Error: ${e.message}');
      return ApiResponse<UserModel>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ GetSingleUser Unknown Error: $e');
      return ApiResponse<UserModel>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Logout user
  /// Note: Using POST with body since GET requests don't support request bodies in standard HTTP
  /// If the API specifically requires GET, the token would need to be passed as a query parameter
  Future<ApiResponse<void>> logout({required String token}) async {
    try {
      // Using POST with token in body as specified in the request format
      // If API requires GET, we would use: '/user/logout?token=$token'
      final response = await _apiService.post(
        '/user/logout',
        body: {'token': token},
      );

      return ApiResponse<void>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ Logout API Error: ${e.message}');
      return ApiResponse<void>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ Logout Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Google Sign-In
  /// Sends Google ID token to backend for authentication
  /// Google Sign-In via Firebase
  /// Sends Firebase ID token to backend
  Future<Map<String, dynamic>> googleSignIn({
    required String firebaseToken,
    required String role,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/google', // ✅ backend endpoint
        body: {
          'firebase_token': firebaseToken,
          'role': role,
        },
      );

      final token = response['token'] as String?;
      final userData = response['user'] as Map<String, dynamic>?;

      final userId = userData?['user_id'] as int?;
      final userName = userData?['user_name'] as String?;
      final userEmail = userData?['email'] as String?;

      final apiResponse = ApiResponse<UserModel>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: userData != null ? UserModel.fromJson(userData) : null,
      );

      return {
        'response': apiResponse,
        'token': token,
        'user_id': userId,
        'user_name': userName,
        'email': userEmail,
      };
    } on ApiException catch (e) {
      return {
        'response': ApiResponse<UserModel>(
          status: false,
          message: e.message,
          error: e.errors,
        ),
        'token': null,
        'user_id': null,
        'user_name': null,
        'email': null,
      };
    }
  }

  /// Upload profile image
  Future<ApiResponse<String>> uploadProfileImage({
    required String token,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/user/profile_upload');

      debugPrint('🌐 Uploading profile image to: $url');
      debugPrint('📁 Image path: ${imageFile.path}');
      debugPrint('📁 Image size: ${await imageFile.length()} bytes');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // Default
      if (fileName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }

      // Add token as field
      request.fields['token'] = token;

      // Create multipart file
      final multipartFile = http.MultipartFile(
        'profile_image', // Field name as required by API
        http.ByteStream.fromBytes(imageBytes),
        imageBytes.length,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      // Set headers
      request.headers['Accept'] = 'application/json';

      debugPrint('📤 Sending request with token and profile_image file');
      debugPrint('📤 File field name: profile_image');
      debugPrint('📤 File name: $fileName');
      debugPrint('📤 Content-Type: $contentType');
      debugPrint('📤 File size: ${imageBytes.length} bytes');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      // Parse response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          final profileImageUrl = responseData['profile_image'] as String?;

          return ApiResponse<String>(
            status: responseData['status'] ?? true,
            message:
                responseData['message'] ??
                'Profile image uploaded successfully',
            data: profileImageUrl,
          );
        } catch (e) {
          debugPrint('❌ JSON Decode Error: $e');
          throw ApiException(
            message: 'Invalid response format from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        // Handle error response
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          throw ApiException(
            message: errorBody['message'] ?? 'Failed to upload profile image',
            statusCode: response.statusCode,
            errors: errorBody['errors'],
          );
        } catch (e) {
          if (e is ApiException) {
            rethrow;
          }
          throw ApiException(
            message: 'Failed to upload profile image',
            statusCode: response.statusCode,
          );
        }
      }
    } on ApiException catch (e) {
      debugPrint('❌ UploadProfileImage API Error: ${e.message}');
      return ApiResponse<String>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ UploadProfileImage Unknown Error: $e');
      return ApiResponse<String>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }
}
