import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/model/api_response.dart';
import '../../data/model/user_model.dart';
import 'preferences_service.dart';

class GoogleAuthService {
  final AuthRepository _authRepository = AuthRepository();

  Future<Map<String, dynamic>> signInWithGoogle({
    required String role,
  }) async {
    try {
      debugPrint('🔄 Starting Google Sign-In via Firebase...');

      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut();
        debugPrint('✅ Signed out from Google Sign-In to show account picker');
      } catch (e) {
        debugPrint(
          '⚠️ Error signing out from Google Sign-In (may not be signed in): $e',
        );
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-In cancelled');
        throw Exception('Google Sign-In cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential firebaseUser = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final user = firebaseUser.user;
      if (user == null) {
        throw Exception('Firebase user is null');
      }

      final firebaseIdToken = await user.getIdToken();

      debugPrint('✅ Firebase sign-in successful');
      debugPrint('   UID: ${user.uid}');
      debugPrint('   Email: ${user.email}');

      final result = await _authRepository.googleSignIn(
        firebaseToken: firebaseIdToken ?? '',
        role: role,
      );

      final response = result['response'] as ApiResponse<UserModel>;
      final token = result['token'] as String?;

      if (response.isSuccess && token != null) {
        await PreferencesService.saveAuthToken(token);
        await PreferencesService.saveUserEmail(user.email ?? '');
        await PreferencesService.saveUserName(user.displayName ?? '');
        await PreferencesService.saveUserType(role);

        if (user.photoURL != null) {
          PreferencesService.getStorage().write(
            'user_profile_image_url',
            user.photoURL,
          );
        }

        return {
          'success': true,
          'token': token,
          'user': user,
          'response': response,
        };
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      debugPrint('❌ Google Auth Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

