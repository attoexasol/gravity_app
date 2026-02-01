import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'token_manager.dart';
import 'auth_error_handler.dart';
import 'session_manager.dart';
import '../../app/routes/app_routes.dart';
import 'preferences_service.dart';

/// API Service - Handles all HTTP requests with automatic token management
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Base URL for the API
  static const String baseUrl = 'https://gravity.attoexasolutions.com/api';

  /// HTTP Client
  final http.Client _client = http.Client();

  /// Token Manager instance
  final TokenManager _tokenManager = TokenManager();

  /// Auth Error Handler instance
  final AuthErrorHandler _authErrorHandler = AuthErrorHandler();

  /// Flag to prevent multiple simultaneous refresh attempts
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;
  
  /// Flag to prevent multiple simultaneous retry attempts
  int _retryCount = 0;
  static const int _maxRetries = 1; // Only retry once after refresh

  /// Default headers
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'GravityApp/1.0 (Flutter)',
  };

  /// Get headers with authentication token
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{..._defaultHeaders};
    
    if (includeAuth) {
      final accessToken = _tokenManager.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  /// POST request with automatic token management
  Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        Duration? timeout,
        bool requireAuth = true,
      }) async {
    return _executeWithRetry(
      () => _postInternal(
        endpoint: endpoint,
        body: body,
        headers: headers,
        timeout: timeout,
        requireAuth: requireAuth,
      ),
    );
  }

  /// Internal POST request implementation
  Future<Map<String, dynamic>> _postInternal({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _getHeaders(
        additionalHeaders: headers,
        includeAuth: requireAuth,
      );

      debugPrint('🌐 POST Request: $url');
      // Don't print full body if it contains large data (like base64 images)
      if (body != null) {
        final bodyKeys = body.keys.toList();
        final hasLargeData = body.values.any((v) => v is String && v.length > 1000);
        if (hasLargeData) {
          debugPrint('📦 Body keys: $bodyKeys (contains large data, not printing full body)');
        } else {
          debugPrint('📦 Body: ${jsonEncode(body)}');
        }
      }

      final jsonBody = jsonEncode(body);
      debugPrint('📦 Body size: ${jsonBody.length} chars');

      // Use longer timeout for requests with large data
      final requestTimeout = timeout ?? const Duration(seconds: 60);
      
      final response = await _client.post(
        url,
        headers: requestHeaders,
        body: jsonBody,
      ).timeout(requestTimeout);

      debugPrint('📡 Response Status: ${response.statusCode}');
      // Don't print very long response bodies
      if (response.body.length > 2000) {
        debugPrint('📄 Response Body: ${response.body.substring(0, 500)}... (truncated)');
      } else {
        debugPrint('📄 Response Body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  /// POST request without authentication (for login, signup, refresh token, etc.)
  Future<Map<String, dynamic>> postWithoutAuth(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        Duration? timeout,
      }) async {
    return _postInternal(
      endpoint: endpoint,
      body: body,
      headers: headers,
      timeout: timeout,
      requireAuth: false,
    );
  }

  /// GET request with automatic token management
  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, String>? headers,
        bool requireAuth = true,
      }) async {
    return _executeWithRetry(
      () => _getInternal(
        endpoint: endpoint,
        headers: headers,
        requireAuth: requireAuth,
      ),
    );
  }

  /// Internal GET request implementation
  Future<Map<String, dynamic>> _getInternal({
    required String endpoint,
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _getHeaders(
        additionalHeaders: headers,
        includeAuth: requireAuth,
      );

      debugPrint('🌐 GET Request: $url');

      final response = await _client.get(
        url,
        headers: requestHeaders,
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  /// Check if response body is JSON
  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('application/json')) {
      return true;
    }
    // Also check if body looks like JSON
    final trimmedBody = response.body.trim();
    return trimmedBody.startsWith('{') || trimmedBody.startsWith('[');
  }

  /// Extract error message from HTML response (for 403, 404, etc.)
  String _extractErrorMessageFromHtml(String htmlBody, int statusCode) {
    // Try to extract title or h2 text from HTML
    final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false).firstMatch(htmlBody);
    if (titleMatch != null) {
      final title = titleMatch.group(1)?.trim();
      if (title != null && title.isNotEmpty) {
        return title;
      }
    }
    
    // Try to extract h2 text
    final h2Match = RegExp(r'<h2[^>]*>([^<]+)</h2>', caseSensitive: false).firstMatch(htmlBody);
    if (h2Match != null) {
      final h2Text = h2Match.group(1)?.trim();
      if (h2Text != null && h2Text.isNotEmpty) {
        return h2Text;
      }
    }

    // Fallback to status code specific messages
    switch (statusCode) {
      case 403:
        return 'Access forbidden. Please check your credentials or contact support.';
      case 404:
        return 'The requested resource was not found.';
      case 401:
        return 'Authentication failed. Please check your credentials.';
      default:
        return 'Request failed with status $statusCode';
    }
  }

  /// Execute request with automatic retry on 401
  Future<Map<String, dynamic>> _executeWithRetry(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    // Reset retry count for new request
    _retryCount = 0;
    return await _executeWithRetryInternal(request);
  }

  /// Internal retry logic with retry count tracking
  Future<Map<String, dynamic>> _executeWithRetryInternal(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on ApiException catch (e) {
      // Handle 401 Unauthorized
      if (e.statusCode == 401) {
        // Parse error body to determine error type
        Map<String, dynamic>? errorBody;
        try {
          if (e.errors is Map) {
            errorBody = e.errors as Map<String, dynamic>?;
          }
        } catch (_) {
          // Ignore parsing errors
        }

        // Use AuthErrorHandler to determine if we should refresh or logout
        final handled = await _authErrorHandler.handle401Error(
          errorMessage: e.message,
          statusCode: e.statusCode,
          errorBody: errorBody,
        );

        if (handled) {
          // Error was handled (forced logout) - don't retry
          rethrow;
        }

        // Not handled by error handler - try to refresh token
        if (_retryCount < _maxRetries) {
          debugPrint('🔐 Received 401 Unauthorized - Attempting token refresh...');
          _retryCount++;
          
          final refreshed = await _refreshTokenIfNeeded();
          if (refreshed) {
            // Retry the original request after successful refresh
            debugPrint('✅ Token refreshed - Retrying original request (attempt $_retryCount)...');
            return await _executeWithRetryInternal(request);
          } else {
            // Refresh failed - force logout
            debugPrint('❌ Token refresh failed - Forcing logout...');
            await _forceLogout();
            rethrow;
          }
        } else {
          // Max retries reached - force logout
          debugPrint('❌ Max retries reached - Forcing logout...');
          await _forceLogout();
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Refresh access token if needed
  Future<bool> _refreshTokenIfNeeded() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      debugPrint('⏳ Token refresh already in progress - waiting...');
      // Wait for ongoing refresh to complete
      if (_refreshCompleter != null) {
        await _refreshCompleter!.future;
      }
      // Check if we now have a valid token
      return _tokenManager.getAccessToken() != null;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = _tokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ No refresh token available');
        _isRefreshing = false;
        _refreshCompleter!.complete();
        _refreshCompleter = null;
        return false;
      }

      debugPrint('🔄 Refreshing access token...');
      
      // Call refresh endpoint directly (without auth to avoid circular dependency)
      final url = Uri.parse('$baseUrl/auth/refresh');
      final response = await _client.post(
        url,
        headers: _defaultHeaders,
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final newAccessToken = responseData['access_token'] as String?;
          final newRefreshToken = responseData['refresh_token'] as String?;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            // Update tokens
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await _tokenManager.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );
            } else {
              // Only access token was refreshed
              await _tokenManager.updateAccessToken(newAccessToken);
            }
            
            debugPrint('✅ Token refreshed successfully');
            _isRefreshing = false;
            _refreshCompleter!.complete();
            _refreshCompleter = null;
            return true;
          }
        } catch (e) {
          debugPrint('❌ Error parsing refresh response: $e');
        }
      }

      debugPrint('❌ Token refresh failed: Status ${response.statusCode}');
      _isRefreshing = false;
      _refreshCompleter!.complete();
      _refreshCompleter = null;
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      _isRefreshing = false;
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete();
      }
      _refreshCompleter = null;
      return false;
    }
  }

  /// Force logout by clearing tokens and navigating to login
  /// Note: This is a fallback - AuthErrorHandler should handle most cases
  Future<void> _forceLogout() async {
    try {
      // Clear tokens
      await _tokenManager.clearTokens();
      
      // Clear session
      final sessionManager = SessionManager();
      await sessionManager.clearSession();
      
      // Clear user data and legacy auth token (so isAuthenticated() is false)
      await PreferencesService.clearUserData();
      await PreferencesService.clearAuthToken();
      
      // Navigate to login screen
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
      
      debugPrint('✅ Forced logout completed');
    } catch (e) {
      debugPrint('❌ Error during forced logout: $e');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      try {
        if (response.body.isEmpty) {
          return <String, dynamic>{};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('❌ JSON Decode Error: $e');
        throw ApiException(
          message: 'Invalid response format from server',
          statusCode: response.statusCode,
        );
      }
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      // Client error
      try {
        // Check if response is JSON
        if (_isJsonResponse(response)) {
          Map<String, dynamic> errorBody = <String, dynamic>{};
          if (response.body.isNotEmpty) {
            errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          }
          throw ApiException(
            message: errorBody['message'] ?? _getDefaultErrorMessage(response.statusCode),
            statusCode: response.statusCode,
            errors: errorBody['errors'],
          );
        } else {
          // Response is HTML or other non-JSON format
          final errorMessage = _extractErrorMessageFromHtml(response.body, response.statusCode);
          debugPrint('⚠️ Server returned HTML error page (Status: ${response.statusCode})');
          throw ApiException(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) {
          rethrow;
        }
        debugPrint('❌ Error processing response: $e');
        throw ApiException(
          message: _getDefaultErrorMessage(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } else if (response.statusCode >= 500) {
      // Server error
      throw ApiException(
        message: 'Server error occurred. Please try again later.',
        statusCode: response.statusCode,
      );
    } else {
      throw ApiException(
        message: 'Unknown error occurred',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get default error message for status code
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Authentication failed. Please check your credentials.';
      case 403:
        return 'Access forbidden. You do not have permission to access this resource.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Validation error. Please check your input.';
      default:
        return 'Request failed. Please try again.';
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}