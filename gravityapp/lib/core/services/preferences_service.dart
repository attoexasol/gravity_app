import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'token_manager.dart';

class PreferencesService {
  static final _storage = GetStorage();
  static const String _onboardingKey = 'onboarding_completed';
  static const String _firstTimeSetupKey = 'first_time_setup_completed';
  static const String _authTokenKey = 'auth_token'; // Deprecated: Use TokenManager instead
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

  /// Check if user is authenticated (has a valid token)
  /// Returns true if token exists and is not empty
  /// Checks both TokenManager (preferred) and legacy auth_token for backward compatibility
  static bool isAuthenticated() {
    // First check TokenManager (new system)
    final tokenManager = TokenManager();
    if (tokenManager.hasTokens()) {
      return true;
    }
    
    // Fallback to legacy token check for backward compatibility
    final token = getAuthToken();
    return token != null && token.isNotEmpty;
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

  // Profile image storage keys
  static const String _userProfileImageUrlKey = 'user_profile_image_url';
  static const String _userProfileImageKey = 'user_profile_image';

  // Profile image methods
  static Future<void> saveProfileImageUrl(String url) async {
    await _storage.write(_userProfileImageUrlKey, url);
  }

  static String? getProfileImageUrl() {
    return _storage.read(_userProfileImageUrlKey) as String?;
  }

  static Future<void> saveProfileImagePath(String path) async {
    await _storage.write(_userProfileImageKey, path);
  }

  static String? getProfileImagePath() {
    return _storage.read(_userProfileImageKey) as String?;
  }

  /// Clear profile image data (URL and local path)
  static Future<void> clearProfileImage() async {
    await _storage.remove(_userProfileImageUrlKey);
    await _storage.remove(_userProfileImageKey);
    if (kDebugMode) {
      debugPrint('✅ Profile image data cleared');
    }
  }

  // Clear user data (for logout)
  static Future<void> clearUserData() async {
    await _storage.remove(_userEmailKey);
    await _storage.remove(_userNameKey);
    await _storage.remove(_userIdKey);
    await _storage.remove(_userTypeKey);
    // Also clear profile image data to prevent old user's image showing for new user
    await clearProfileImage();
  }

  /// Clear authentication data (token and user data) while preserving onboarding status
  /// This is the recommended method for logout as it safely preserves onboarding
  /// and first-time setup status without using erase() which can be fragile
  static Future<void> clearAuthData() async {
    // Clear auth token
    await clearAuthToken();
    
    // Clear user data
    await clearUserData();
    
    if (kDebugMode) {
      debugPrint('✅ Auth data cleared (onboarding preserved)');
    }
  }

  // Clear all storage data (for complete logout)
  // Note: This preserves onboarding and first-time setup status as they should persist across logouts
  // WARNING: This method uses erase() which clears everything. Use clearAuthData() for safer logout.
  static Future<void> clearAll() async {
    try {
      // Save onboarding and first-time setup status before clearing
      final onboardingCompleted = isOnboardingCompleted();
      final firstTimeSetupCompleted = isFirstTimeSetupCompleted();
      
      if (kDebugMode) {
        debugPrint('🔍 Saving onboarding status before clear: $onboardingCompleted');
        debugPrint('🔍 Saving first-time setup status before clear: $firstTimeSetupCompleted');
      }
      
      // Clear all storage data
      await _storage.erase();
      
      // Restore onboarding and first-time setup status after clearing
      if (onboardingCompleted) {
        await setOnboardingCompleted(true);
        if (kDebugMode) {
          debugPrint('✅ Onboarding status restored after clear');
        }
      }
      if (firstTimeSetupCompleted) {
        await setFirstTimeSetupCompleted(true);
        if (kDebugMode) {
          debugPrint('✅ First-time setup status restored after clear');
        }
      }
      
      // Verify restoration was successful
      if (kDebugMode) {
        final verifyOnboarding = isOnboardingCompleted();
        final verifySetup = isFirstTimeSetupCompleted();
        if (onboardingCompleted != verifyOnboarding) {
          debugPrint('⚠️ WARNING: Onboarding status restoration may have failed!');
          debugPrint('   Expected: $onboardingCompleted, Got: $verifyOnboarding');
        }
        if (firstTimeSetupCompleted != verifySetup) {
          debugPrint('⚠️ WARNING: First-time setup status restoration may have failed!');
          debugPrint('   Expected: $firstTimeSetupCompleted, Got: $verifySetup');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in clearAll(): $e');
      // If erase() fails, fall back to selective clearing
      await clearAuthData();
      rethrow;
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

  // Weight storage methods
  static const String _startingWeightKey = 'starting_weight';

  /// Save starting weight (from Settings > Wellness Goals > Current Weight)
  static Future<void> saveStartingWeight(double weight) async {
    await _storage.write(_startingWeightKey, weight);
    if (kDebugMode) {
      debugPrint('✅ Starting weight saved: $weight kg');
    }
  }

  /// Get starting weight
  static double? getStartingWeight() {
    final weight = _storage.read(_startingWeightKey);
    if (weight is num) {
      return weight.toDouble();
    }
    return null;
  }

  // Get storage instance for direct access
  static GetStorage getStorage() {
    return _storage;
  }
}
