import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Token Manager - Handles secure storage and management of access and refresh tokens
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  static final _storage = GetStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(_accessTokenKey, accessToken);
    await _storage.write(_refreshTokenKey, refreshToken);
    
    if (kDebugMode) {
      debugPrint('✅ Tokens saved successfully');
    }
  }

  /// Get access token
  String? getAccessToken() {
    return _storage.read(_accessTokenKey);
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _storage.read(_refreshTokenKey);
  }

  /// Check if user has valid tokens
  bool hasTokens() {
    final accessToken = getAccessToken();
    final refreshToken = getRefreshToken();
    return accessToken != null && 
           accessToken.isNotEmpty && 
           refreshToken != null && 
           refreshToken.isNotEmpty;
  }

  /// Update access token (used after refresh)
  Future<void> updateAccessToken(String accessToken) async {
    await _storage.write(_accessTokenKey, accessToken);
    
    if (kDebugMode) {
      debugPrint('✅ Access token updated');
    }
  }

  /// Clear both tokens
  Future<void> clearTokens() async {
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
    
    if (kDebugMode) {
      debugPrint('✅ Tokens cleared');
    }
  }

  /// Clear only access token (keep refresh token for retry)
  Future<void> clearAccessToken() async {
    await _storage.remove(_accessTokenKey);
    
    if (kDebugMode) {
      debugPrint('✅ Access token cleared');
    }
  }
}