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
  };

  /// POST request
  Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');

      debugPrint('🌐 POST Request: $url');
      debugPrint('📦 Body: ${jsonEncode(body)}');

      final response = await _client.post(
        url,
        headers: {..._defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

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
        Map<String, dynamic> errorBody = <String, dynamic>{};
        if (response.body.isNotEmpty) {
          errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        }
        throw ApiException(
          message: errorBody['message'] ?? 'Client error occurred',
          statusCode: response.statusCode,
          errors: errorBody['errors'],
        );
      } catch (e) {
        if (e is ApiException) {
          rethrow;
        }
        debugPrint('❌ JSON Decode Error: $e');
        throw ApiException(
          message: 'Client error occurred',
          statusCode: response.statusCode,
        );
      }
    } else if (response.statusCode >= 500) {
      // Server error
      throw ApiException(
        message: 'Server error occurred',
        statusCode: response.statusCode,
      );
    } else {
      throw ApiException(
        message: 'Unknown error occurred',
        statusCode: response.statusCode,
      );
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