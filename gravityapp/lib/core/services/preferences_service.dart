import 'package:get_storage/get_storage.dart';

class PreferencesService {
  static final _storage = GetStorage();
  static const String _onboardingKey = 'onboarding_completed';
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
  static Future<void> clearAll() async {
    await _storage.erase(); // This clears all data from storage
  }

  // Get storage instance for direct access
  static GetStorage getStorage() {
    return _storage;
  }
}
