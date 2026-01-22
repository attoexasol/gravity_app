import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'token_manager.dart';
import 'device_manager.dart';

/// Session Manager - Handles single-device session management
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static final _storage = GetStorage();
  static const String _sessionDeviceIdKey = 'session_device_id';
  static const String _sessionUserIdKey = 'session_user_id';
  static const String _sessionActiveKey = 'session_active';

  final TokenManager _tokenManager = TokenManager();
  final DeviceManager _deviceManager = DeviceManager();

  /// Initialize session after successful login
  /// This marks the current device as the active session
  Future<void> initializeSession({
    required String userId,
    required String deviceId,
  }) async {
    await _storage.write(_sessionDeviceIdKey, deviceId);
    await _storage.write(_sessionUserIdKey, userId);
    await _storage.write(_sessionActiveKey, true);
    
    if (kDebugMode) {
      debugPrint('✅ Session initialized for user: $userId, device: $deviceId');
    }
  }

  /// Check if current device is the active session
  Future<bool> isActiveSession() async {
    final currentDeviceId = await _deviceManager.getDeviceId();
    final sessionDeviceId = _storage.read(_sessionDeviceIdKey) as String?;
    final isActive = _storage.read(_sessionActiveKey) as bool? ?? false;
    
    // Session is active if:
    // 1. We have tokens
    // 2. Session is marked as active
    // 3. Current device matches the session device
    if (!_tokenManager.hasTokens()) {
      return false;
    }
    
    if (!isActive) {
      return false;
    }
    
    if (sessionDeviceId == null || sessionDeviceId != currentDeviceId) {
      if (kDebugMode) {
        debugPrint('⚠️ Device mismatch: Current=$currentDeviceId, Session=$sessionDeviceId');
      }
      return false;
    }
    
    return true;
  }

  /// Get the device ID associated with the current session
  String? getSessionDeviceId() {
    return _storage.read(_sessionDeviceIdKey) as String?;
  }

  /// Get the user ID associated with the current session
  String? getSessionUserId() {
    return _storage.read(_sessionUserIdKey) as String?;
  }

  /// Clear session (on logout or session invalidation)
  Future<void> clearSession() async {
    await _storage.remove(_sessionDeviceIdKey);
    await _storage.remove(_sessionUserIdKey);
    await _storage.remove(_sessionActiveKey);
    
    if (kDebugMode) {
      debugPrint('✅ Session cleared');
    }
  }

  /// Invalidate session (when another device logs in)
  Future<void> invalidateSession() async {
    await _storage.write(_sessionActiveKey, false);
    
    if (kDebugMode) {
      debugPrint('⚠️ Session invalidated (another device logged in)');
    }
  }

  /// Check if session was invalidated by another device
  bool isSessionInvalidated() {
    final isActive = _storage.read(_sessionActiveKey) as bool? ?? false;
    return !isActive;
  }
}