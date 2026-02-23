// lib/core/services/google_auth_service.dart
// Google sign-in: obtain Firebase ID token → Laravel API → save tokens/user → sign in with custom token so Firebase UID = Laravel user_id.

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/model/api_response.dart';
import '../../data/model/user_model.dart';
import '../../data/services/auth_service.dart';
import 'preferences_service.dart';
import 'token_manager.dart';
import 'session_manager.dart';
import 'device_manager.dart';

class GoogleAuthService {
  final AuthRepository _authRepository = AuthRepository();

  /// Full Google sign-in flow: sign out → Google + Firebase credential → Firebase ID token →
  /// Laravel POST /api/auth/google → save api_token + user → sign in with custom token (Firebase UID = Laravel user_id).
  Future<Map<String, dynamic>> signInWithGoogle({
    required String role,
  }) async {
    try {
      debugPrint('🔄 Starting Google Sign-In...');

      // Avoid stale session: sign out Firebase and Google before starting
      try {
        await FirebaseAuth.instance.signOut();
        debugPrint('✅ Signed out from Firebase');
      } catch (e) {
        debugPrint('⚠️ Firebase signOut: $e');
      }
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut();
        debugPrint('✅ Signed out from Google Sign-In');
      } catch (e) {
        debugPrint('⚠️ Google Sign-In signOut: $e');
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-In cancelled');
        return {'success': false, 'error': 'Sign-in was cancelled'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Firebase user is null after sign-in');
      }

      final firebaseIdToken = await user.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Failed to get Firebase ID token');
      }

      debugPrint('✅ Firebase sign-in successful, calling Laravel API...');

      final result = await _authRepository.googleSignIn(
        firebaseToken: firebaseIdToken,
        role: role,
      );

      final response = result['response'] as ApiResponse<UserModel>;
      final accessToken = result['access_token'] as String? ?? result['token'] as String?;
      final refreshToken = result['refresh_token'] as String?;
      final userId = result['user_id'] as int?;
      final userName = result['user_name'] as String?;
      final userEmail = result['email'] as String?;
      final firebaseCustomToken = result['firebase_custom_token'] as String?;

      if (!response.isSuccess || accessToken == null) {
        final message = response.message.isNotEmpty
            ? response.message
            : 'Google login failed';
        return {'success': false, 'error': message};
      }

      // Save tokens (same as email login)
      final tokenManager = TokenManager();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await tokenManager.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        await tokenManager.updateAccessToken(accessToken);
      }
      await PreferencesService.saveAuthToken(accessToken);

      final deviceManager = DeviceManager();
      final sessionManager = SessionManager();
      final deviceId = await deviceManager.getDeviceId();
      final userIdString = userId?.toString() ?? response.data?.id.toString() ?? '';
      if (userIdString.isNotEmpty) {
        await sessionManager.initializeSession(
          userId: userIdString,
          deviceId: deviceId,
        );
      }

      await PreferencesService.saveUserEmail(userEmail ?? response.data?.email ?? '');
      await PreferencesService.saveUserName(userName ?? response.data?.name ?? '');
      if (userId != null && userId != 0) {
        await PreferencesService.saveUserId(userId);
      } else if (response.data != null && response.data!.id != 0) {
        await PreferencesService.saveUserId(response.data!.id);
      }

      String roleToSave = (response.data?.role ?? role).trim().toLowerCase();
      if (roleToSave != 'coach' && roleToSave != 'customer') {
        roleToSave = role.trim().toLowerCase() == 'coach' ? 'coach' : 'customer';
      }
      await PreferencesService.saveUserType(roleToSave);

      await PreferencesService.clearProfileImage();
      final profileImageUrl = response.data?.profileImage;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        await PreferencesService.saveProfileImageUrl(profileImageUrl);
      }

      // Sign in again with custom token so Firebase UID = Laravel user_id
      if (firebaseCustomToken != null && firebaseCustomToken.isNotEmpty) {
        try {
          await AuthService().signInWithCustomTokenAndSyncUser(
            firebaseCustomToken: firebaseCustomToken,
            name: userName ?? response.data?.name ?? '',
            role: roleToSave,
            profileImageUrl: profileImageUrl,
          );
          debugPrint('✅ Firebase sign-in with custom token completed');
        } catch (e) {
          debugPrint('⚠️ Firebase custom token sign-in failed: $e');
        }
      } else {
        debugPrint('⚠️ No firebase_custom_token in API response');
      }

      return {
        'success': true,
        'token': accessToken,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'response': response,
      };
    } catch (e) {
      debugPrint('❌ Google Auth Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
