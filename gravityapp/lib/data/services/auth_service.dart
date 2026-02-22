import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_chat_service.dart';

/// Handles Firebase Auth (custom token) and sync of user profile to Firestore.
/// Call after Laravel login returns firebase_custom_token.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreChatService _firestoreChat = FirestoreChatService();

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  /// Sign in to Firebase with custom token from Laravel.
  /// Then create/update users/{uid} in Firestore (name, role, isOnline, lastSeen).
  Future<void> signInWithCustomTokenAndSyncUser({
    required String firebaseCustomToken,
    required String name,
    required String role,
    String? profileImageUrl,
  }) async {
    final credential = await _auth.signInWithCustomToken(firebaseCustomToken);
    final uid = credential.user?.uid;
    if (uid == null) {
      throw StateError('Firebase sign-in succeeded but no user uid');
    }
    await _firestoreChat.updateUserProfile(
      uid: uid,
      name: name,
      role: role,
      profileImageUrl: profileImageUrl,
    );
    if (kDebugMode) {
      debugPrint('✅ Firebase sign-in + Firestore user sync done for $uid');
    }
  }

  /// Sign out from Firebase and set Firestore user offline.
  Future<void> signOutAndSetOffline() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestoreChat.setUserOffline(uid);
    }
    await _auth.signOut();
  }

  /// Update lastSeen in Firestore (e.g. app lifecycle pause).
  Future<void> updateLastSeenIfNeeded() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestoreChat.updateLastSeen(uid);
    }
  }
}
