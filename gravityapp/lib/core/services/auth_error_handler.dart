import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'token_manager.dart';
import 'session_manager.dart';
import 'preferences_service.dart';
import 'image_cache_service.dart';
import '../../app/routes/app_routes.dart';

/// Authentication Error Handler - Handles 401 errors and session management
class AuthErrorHandler {
  static final AuthErrorHandler _instance = AuthErrorHandler._internal();
  factory AuthErrorHandler() => _instance;
  AuthErrorHandler._internal();

  final TokenManager _tokenManager = TokenManager();
  final SessionManager _sessionManager = SessionManager();
  
  bool _isHandlingLogout = false;
  bool _hasShownSessionExpiredDialog = false;

  /// Handle 401 Unauthorized error
  /// Returns true if error was handled, false otherwise
  Future<bool> handle401Error({
    required String? errorMessage,
    required int statusCode,
    Map<String, dynamic>? errorBody,
  }) async {
    // Prevent multiple simultaneous logout attempts
    if (_isHandlingLogout) {
      debugPrint('⏳ Logout already in progress, skipping...');
      return true;
    }

    _isHandlingLogout = true;

    try {
      // Parse error message to determine error type
      final errorType = _parseErrorType(errorMessage, errorBody);
      
      debugPrint('🔐 Handling 401 error - Type: $errorType');

      switch (errorType) {
        case AuthErrorType.tokenExpired:
          // Token expired - try to refresh
          debugPrint('⏰ Token expired - attempting refresh...');
          // This will be handled by ApiService's refresh logic
          _isHandlingLogout = false;
          return false; // Let ApiService handle refresh

        case AuthErrorType.tokenInvalidated:
        case AuthErrorType.sessionExpired:
        case AuthErrorType.deviceMismatch:
          // Session invalidated or device mismatch - force logout
          await _handleForcedLogout(errorType);
          return true;

        case AuthErrorType.unknown:
        default:
          // Unknown 401 - treat as session expired
          await _handleForcedLogout(AuthErrorType.sessionExpired);
          return true;
      }
    } catch (e) {
      debugPrint('❌ Error handling 401: $e');
      // On error, force logout to be safe
      await _handleForcedLogout(AuthErrorType.sessionExpired);
      return true;
    } finally {
      // Reset flag after a delay to allow navigation
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingLogout = false;
        _hasShownSessionExpiredDialog = false;
      });
    }
  }

  /// Parse error type from error message and body
  AuthErrorType _parseErrorType(String? message, Map<String, dynamic>? errorBody) {
    if (message == null) {
      return AuthErrorType.unknown;
    }

    final messageLower = message.toLowerCase();
    
    // Check error body for specific error codes
    if (errorBody != null) {
      final errorCode = errorBody['error_code'] as String?;
      if (errorCode != null) {
        switch (errorCode.toLowerCase()) {
          case 'token_expired':
            return AuthErrorType.tokenExpired;
          case 'token_invalidated':
            return AuthErrorType.tokenInvalidated;
          case 'session_expired':
            return AuthErrorType.sessionExpired;
          case 'device_mismatch':
            return AuthErrorType.deviceMismatch;
          case 'forced_logout':
            return AuthErrorType.tokenInvalidated;
        }
      }
    }

    // Parse from message text
    if (messageLower.contains('expired') || messageLower.contains('expire')) {
      return AuthErrorType.tokenExpired;
    }
    
    if (messageLower.contains('invalidated') || 
        messageLower.contains('invalid') ||
        messageLower.contains('revoked')) {
      return AuthErrorType.tokenInvalidated;
    }
    
    if (messageLower.contains('session') && messageLower.contains('expired')) {
      return AuthErrorType.sessionExpired;
    }
    
    if (messageLower.contains('device') && 
        (messageLower.contains('mismatch') || messageLower.contains('invalid'))) {
      return AuthErrorType.deviceMismatch;
    }
    
    if (messageLower.contains('another device') || 
        messageLower.contains('new device') ||
        messageLower.contains('logged in from')) {
      return AuthErrorType.deviceMismatch;
    }

    return AuthErrorType.unknown;
  }

  /// Handle forced logout (session invalidated, device mismatch, etc.)
  Future<void> _handleForcedLogout(AuthErrorType errorType) async {
    try {
      // Clear tokens
      await _tokenManager.clearTokens();
      
      // Clear session
      await _sessionManager.clearSession();
      
      // Clear user data
      await PreferencesService.clearUserData();
      
      // Clear image cache to prevent old user's profile images from showing
      await ImageCacheService.clearAllImageData();
      
      // Show session expired dialog if not already shown
      if (!_hasShownSessionExpiredDialog) {
        _hasShownSessionExpiredDialog = true;
        await _showSessionExpiredDialog(errorType);
      }
      
      // Navigate to login
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
      
      debugPrint('✅ Forced logout completed - Type: $errorType');
    } catch (e) {
      debugPrint('❌ Error during forced logout: $e');
      // Even if dialog fails, navigate to login
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  /// Show session expired dialog
  Future<void> _showSessionExpiredDialog(AuthErrorType errorType) async {
    try {
      String title = 'Session Expired';
      String message = 'Your session has expired. Please log in again.';
      
      switch (errorType) {
        case AuthErrorType.tokenInvalidated:
        case AuthErrorType.deviceMismatch:
          title = 'Session Invalidated';
          message = 'You have been logged out because you logged in from another device. Please log in again.';
          break;
        case AuthErrorType.sessionExpired:
          title = 'Session Expired';
          message = 'Your session has expired. Please log in again.';
          break;
        default:
          break;
      }

      // Show dialog only if we're not already on login page
      if (Get.currentRoute != AppRoutes.login) {
        await Get.dialog(
          _buildSessionExpiredDialog(title: title, message: message),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error showing session expired dialog: $e');
    }
  }

  /// Build session expired dialog
  Widget _buildSessionExpiredDialog({
    required String title,
    required String message,
  }) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              if (Get.currentRoute != AppRoutes.login) {
                Get.offAllNamed(AppRoutes.login);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Reset handler state (useful for testing)
  void reset() {
    _isHandlingLogout = false;
    _hasShownSessionExpiredDialog = false;
  }
}

/// Authentication error types
enum AuthErrorType {
  tokenExpired,      // Token expired but can be refreshed
  tokenInvalidated,  // Token invalidated (forced logout)
  sessionExpired,    // Session expired
  deviceMismatch,    // Device mismatch (logged in from another device)
  unknown,           // Unknown error
}