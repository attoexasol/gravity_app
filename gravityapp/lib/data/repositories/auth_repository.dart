import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/services/api_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/token_manager.dart';
import '../../core/services/device_manager.dart';
import '../../core/services/session_manager.dart';
import '../model/api_response.dart';
import '../model/user_model.dart';

/// Auth Repository - Handles authentication API calls
class AuthRepository {
  final ApiService _apiService = ApiService();
  final DeviceManager _deviceManager = DeviceManager();

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
        error: response['errors'],
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
  /// Returns a map with 'response' (ApiResponse), 'access_token' (String?), 'refresh_token' (String?), 
  /// 'token' (String? - for backward compatibility), 'user_id' (int?), 'user_name' (String?), and 'email' (String?)
  /// Includes device information for single-device authentication
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Get device information
      final deviceInfo = await _deviceManager.getDeviceInfo();
      
      final response = await _apiService.postWithoutAuth(
        '/user/login',
        body: {
          'email': email,
          'password': password,
          ...deviceInfo, // Include device_id, platform, app_version
        },
      );

      // Extract tokens - support both new format (access_token/refresh_token) and legacy (token)
      final accessToken = response['access_token'] as String? ?? response['token'] as String?;
      final refreshToken = response['refresh_token'] as String?;

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
      debugPrint('  - Access Token: ${accessToken != null ? "Present" : "Missing"}');
      debugPrint('  - Refresh Token: ${refreshToken != null ? "Present" : "Missing"}');
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
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token': accessToken, // For backward compatibility
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
        'access_token': null,
        'refresh_token': null,
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
        'access_token': null,
        'refresh_token': null,
        'token': null,
        'user_id': null,
        'user_name': null,
        'email': null,
      };
    }
  }

  /// Get user profile
  /// This method can be called after login to get full user information including user_id
  /// Note: Authorization header is automatically added by ApiService
  Future<ApiResponse<UserModel>> getUserProfile() async {
    try {
      final tokenManager = TokenManager();
      if (!tokenManager.hasTokens()) {
        throw ApiException(
          message: 'Authentication token not found',
          statusCode: 401,
        );
      }

      final response = await _apiService.get(
        '/user/profile',
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
  /// Notifies backend and clears tokens
  /// Note: Using POST with body since GET requests don't support request bodies in standard HTTP
  /// If the API specifically requires GET, the token would need to be passed as a query parameter
  Future<ApiResponse<void>> logout() async {
    try {
      final tokenManager = TokenManager();
      final accessToken = tokenManager.getAccessToken();
      final refreshToken = tokenManager.getRefreshToken();

      // Notify backend about logout (send refresh token if available, otherwise access token)
      final tokenToSend = refreshToken ?? accessToken;
      
      if (tokenToSend != null && tokenToSend.isNotEmpty) {
        try {
          // Using POST with token in body as specified in the request format
          // If API requires GET, we would use: '/user/logout?token=$token'
          final response = await _apiService.post(
            '/user/logout',
            body: {'refresh_token': refreshToken ?? accessToken},
          );

          debugPrint('✅ Logout API call successful');
        } on ApiException catch (e) {
          debugPrint('⚠️ Logout API Error: ${e.message}');
          // Continue with local logout even if API call fails
        } catch (e) {
          debugPrint('⚠️ Logout API Unknown Error: $e');
          // Continue with local logout even if API call fails
        }
      }

      // Clear tokens locally (TokenManager + legacy auth_token)
      await tokenManager.clearTokens();
      await PreferencesService.clearAuthToken();

      // Clear session
      final sessionManager = SessionManager();
      await sessionManager.clearSession();

      return ApiResponse<void>(
        status: true,
        message: 'Logged out successfully',
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Logout Error: $e');
      // Even if logout fails, clear tokens locally
      try {
        await TokenManager().clearTokens();
        await PreferencesService.clearAuthToken();
      } catch (clearError) {
        debugPrint('❌ Error clearing tokens: $clearError');
      }
      
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred during logout.',
        error: e.toString(),
      );
    }
  }

  /// Google Sign-In
  /// Sends Google ID token to backend for authentication
  /// Google Sign-In via Firebase
  /// Sends Firebase ID token to backend
  /// Includes device information for single-device authentication
  Future<Map<String, dynamic>> googleSignIn({
    required String firebaseToken,
    required String role,
  }) async {
    try {
      // Get device information
      final deviceInfo = await _deviceManager.getDeviceInfo();
      
      final response = await _apiService.postWithoutAuth(
        '/auth/google', // ✅ backend endpoint
        body: {
          'firebase_token': firebaseToken,
          'role': role,
          ...deviceInfo, // Include device_id, platform, app_version
        },
      );

      // Extract tokens - support both new format (access_token/refresh_token) and legacy (token)
      final accessToken = response['access_token'] as String? ?? response['token'] as String?;
      final refreshToken = response['refresh_token'] as String?;
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
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token': accessToken, // For backward compatibility
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
        'access_token': null,
        'refresh_token': null,
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

  /// Send OTP - Send one-time password to email
  /// API: POST /send-email-otp
  /// Body: { "email": "user@example.com" }
  /// Response: { "status": true, "message": "OTP sent to your email" }
  Future<ApiResponse<void>> sendOtp({required String email}) async {
    try {
      final response = await _apiService.post(
        '/send-email-otp',
        body: {'email': email},
      );

      return ApiResponse<void>(
        status: response['status'] ?? false,
        message: response['message'] ?? 'OTP sent to your email',
        data: null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ SendOTP API Error: ${e.message} (Status: ${e.statusCode})');
      
      // Provide user-friendly message for email not found scenarios
      String errorMessage = e.message;
      if (e.statusCode == 404) {
        errorMessage = 'The email address you entered is not registered with any account. Please check your email address and try again.';
      } else if (e.statusCode == 422) {
        // Validation error - check if it's email-related
        final messageLower = e.message.toLowerCase();
        if (messageLower.contains('email')) {
          errorMessage = 'The email address you entered is invalid or not associated with any account. Please check your email and try again.';
        }
      }
      
      return ApiResponse<void>(
        status: false,
        message: errorMessage,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ SendOTP Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Verify OTP - Verify one-time password
  /// API: POST /verify-email-otp
  /// Body: { "email": "user@example.com", "otp": "123456" }
  /// Response: { "status": true, "message": "Email OTP verified successfully" }
  Future<ApiResponse<void>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        '/verify-email-otp',
        body: {
          'email': email,
          'otp': otp,
        },
      );

      return ApiResponse<void>(
        status: response['status'] ?? false,
        message: response['message'] ?? 'Email OTP verified successfully',
        data: null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ VerifyOTP API Error: ${e.message}');
      return ApiResponse<void>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ VerifyOTP Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Forgot Password - Request password reset link (DEPRECATED - Use sendOtp instead)
  /// TODO: Replace with real API call when backend is ready
  /// Expected API: POST /user/forgot-password
  /// Body: { "email": "user@example.com" }
  /// Response: { "status": true, "message": "Password reset link sent to your email" }
  @Deprecated('Use sendOtp instead')
  Future<ApiResponse<void>> forgotPassword({required String email}) async {
    try {
      // TODO: Replace this mock implementation with real API call
      // Uncomment the code below and remove the mock implementation
      
      /*
      final response = await _apiService.post(
        '/user/forgot-password',
        body: {'email': email},
      );

      return ApiResponse<void>(
        status: response['status'] ?? false,
        message: response['message'] ?? '',
        data: null,
      );
      */

      // MOCK IMPLEMENTATION - Simulates API call with delay
      debugPrint('🔵 [MOCK] Forgot Password Request for: $email');
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      // Simulate success response
      return ApiResponse<void>(
        status: true,
        message: 'Password reset link has been sent to your email address. Please check your inbox.',
        data: null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ ForgotPassword API Error: ${e.message}');
      return ApiResponse<void>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ ForgotPassword Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Reset Password - Reset password with email (after OTP verification)
  /// API: POST /forget-password
  /// Body: { 
  ///   "email": "user@example.com",
  ///   "password": "new_password",
  ///   "password_confirmation": "new_password"
  /// }
  /// Response: { "status": true, "message": "Password has been reset successfully." }
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        '/forget-password',
        body: {
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      return ApiResponse<void>(
        status: response['status'] ?? false,
        message: response['message'] ?? 'Password has been reset successfully.',
        data: null,
      );
    } on ApiException catch (e) {
      debugPrint('❌ ResetPassword API Error: ${e.message}');
      return ApiResponse<void>(
        status: false,
        message: e.message,
        error: e.errors,
      );
    } catch (e) {
      debugPrint('❌ ResetPassword Unknown Error: $e');
      return ApiResponse<void>(
        status: false,
        message: 'An unexpected error occurred. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Refresh access token using refresh token
  /// Note: This method is kept for backward compatibility but token refresh
  /// is now handled automatically by ApiService
  /// API: POST /auth/refresh
  /// Body: { "refresh_token": "..." }
  /// Response: { "status": true, "access_token": "...", "refresh_token": "..." }
  @Deprecated('Token refresh is now handled automatically by ApiService')
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      // Use postWithoutAuth to avoid infinite loop (refresh endpoint shouldn't require auth)
      final response = await _apiService.postWithoutAuth(
        '/auth/refresh',
        body: {'refresh_token': refreshToken},
      );

      final newAccessToken = response['access_token'] as String?;
      final newRefreshToken = response['refresh_token'] as String?;

      return {
        'success': true,
        'access_token': newAccessToken,
        'refresh_token': newRefreshToken,
      };
    } on ApiException catch (e) {
      debugPrint('❌ RefreshToken API Error: ${e.message}');
      return {
        'success': false,
        'access_token': null,
        'refresh_token': null,
        'error': e.message,
        'statusCode': e.statusCode,
      };
    } catch (e) {
      debugPrint('❌ RefreshToken Unknown Error: $e');
      return {
        'success': false,
        'access_token': null,
        'refresh_token': null,
        'error': e.toString(),
      };
    }
  }
}
