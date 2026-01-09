import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// API Service - Handles all HTTP requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Base URL for the API
  static const String baseUrl = 'https://gravity.attoexasolutions.com/api';

  /// HTTP Client
  final http.Client _client = http.Client();

  /// Default headers
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'GravityApp/1.0 (Flutter)',
  };

  /// POST request
  Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        Duration? timeout,
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');

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
        headers: {..._defaultHeaders, ...?headers},
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

  /// GET request
  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');

      debugPrint('🌐 GET Request: $url');

      final response = await _client.get(
        url,
        headers: {..._defaultHeaders, ...?headers},
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