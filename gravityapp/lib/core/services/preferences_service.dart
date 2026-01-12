import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class PreferencesService {
  static final _storage = GetStorage();
  static const String _onboardingKey = 'onboarding_completed';
  static const String _firstTimeSetupKey = 'first_time_setup_completed';
  static const String _authTokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';

  static Future<void> init() async {
    await GetStorage.init();
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    await _storage.write(_onboardingKey, completed);
  }

  static bool isOnboardingCompleted() {
    return _storage.read(_onboardingKey) ?? false;
  }

  // First-time setup completion methods
  static Future<void> setFirstTimeSetupCompleted(bool completed) async {
    await _storage.write(_firstTimeSetupKey, completed);
  }

  static bool isFirstTimeSetupCompleted() {
    return _storage.read(_firstTimeSetupKey) ?? false;
  }

  // Auth token methods
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(_authTokenKey, token);
  }

  static String? getAuthToken() {
    return _storage.read(_authTokenKey);
  }

  static Future<void> clearAuthToken() async {
    await _storage.remove(_authTokenKey);
  }

  // User email methods
  static Future<void> saveUserEmail(String email) async {
    await _storage.write(_userEmailKey, email);
  }

  static String? getUserEmail() {
    return _storage.read(_userEmailKey);
  }

  // User name methods
  static Future<void> saveUserName(String name) async {
    await _storage.write(_userNameKey, name);
  }

  static String? getUserName() {
    return _storage.read(_userNameKey);
  }

  // User ID methods
  static Future<void> saveUserId(int userId) async {
    await _storage.write(_userIdKey, userId);
  }

  static int? getUserId() {
    return _storage.read(_userIdKey);
  }

  // User type methods
  static Future<void> saveUserType(String userType) async {
    await _storage.write(_userTypeKey, userType);
  }

  static String? getUserType() {
    return _storage.read(_userTypeKey);
  }

  // Clear user data (for logout)
  static Future<void> clearUserData() async {
    await _storage.remove(_userEmailKey);
    await _storage.remove(_userNameKey);
    await _storage.remove(_userIdKey);
    await _storage.remove(_userTypeKey);
  }

  // Clear all storage data (for complete logout)
  // Note: This preserves onboarding and first-time setup status as they should persist across logouts
  static Future<void> clearAll() async {
    // Save onboarding and first-time setup status before clearing
    final onboardingCompleted = isOnboardingCompleted();
    final firstTimeSetupCompleted = isFirstTimeSetupCompleted();
    
    // Clear all storage data
    await _storage.erase();
    
    // Restore onboarding and first-time setup status after clearing
    if (onboardingCompleted) {
      await setOnboardingCompleted(true);
    }
    if (firstTimeSetupCompleted) {
      await setFirstTimeSetupCompleted(true);
    }
  }

  // Clear all storage data for account deletion
  // Note: This completely resets everything including onboarding and first-time setup status
  // This ensures that after account deletion, a new sign-up will be treated as first-time
  static Future<void> clearAllForAccountDeletion() async {
    // Clear all storage data without preserving any status
    await _storage.erase();
    debugPrint('✅ All storage cleared for account deletion (including first-time setup status)');
  }

  // Get storage instance for direct access
  static GetStorage getStorage() {
    return _storage;
  }
}
