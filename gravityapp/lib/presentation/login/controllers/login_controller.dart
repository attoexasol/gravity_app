import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:gravityapp/data/model/api_response.dart';
import 'package:gravityapp/data/model/user_model.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consent_repository.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/preferences_service.dart';

enum UserType { customer, coach }

class LoginController extends GetxController {
  // Repository
  final AuthRepository _authRepository = AuthRepository();
  final ConsentRepository _consentRepository = ConsentRepository();
  final GoalsRepository _goalsRepository = GoalsRepository();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  // Google Sign-In instance

  // Observable for selected user role
  final Rx<UserType> selectedRole = UserType.customer.obs;

  // Text editing controllers
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Observable for password visibility
  final RxBool isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize controllers in onInit to ensure they're created when controller is initialized
    emailController = TextEditingController(text: "rajibduet02@gmail.com");
    passwordController = TextEditingController(text: "Gravity@024017");
  }

  @override
  void onClose() {
    // Dispose controllers - dispose() is safe to call even if already disposed
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Safely show snackbar with overlay check
  void _safeSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    if (isClosed) return;

    try {
      final context = Get.context;
      if (context != null) {
        // Check if overlay is available
        try {
          Overlay.of(context);
          Get.snackbar(
            title,
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: backgroundColor ?? Get.theme.colorScheme.error,
            colorText: colorText ?? Get.theme.colorScheme.onError,
            duration: duration ?? const Duration(seconds: 3),
          );
        } catch (overlayError) {
          debugPrint('⚠️ Overlay not available for snackbar: $overlayError');
        }
      } else {
        debugPrint('⚠️ Cannot show snackbar - context unavailable');
      }
    } catch (e) {
      debugPrint('⚠️ Error showing snackbar: $e');
    }
  }

  /// Toggle between customer and coach role
  void selectRole(UserType role) {
    selectedRole.value = role;
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Validate email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Handle login
  Future<void> handleLogin() async {
    // Check if controller is still mounted before accessing controllers
    if (isClosed) return;

    // Validate inputs
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (validateEmail(email) != null || validatePassword(password) != null) {
      _safeSnackbar(
        title: 'Validation Error',
        message: 'Please check your email and password',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Call login API
      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      final response = result['response'] as ApiResponse<UserModel>;
      final token = result['token'] as String?;
      final userId = result['user_id'] as int?;
      final userName = result['user_name'] as String?;
      final userEmail = result['email'] as String?;

      // Check if controller is still mounted before proceeding
      if (isClosed) return;

      if (response.isSuccess && token != null) {
        // Save token from root level
        await PreferencesService.saveAuthToken(token);

        // Save email from user object (or fallback to request email)
        final emailToSave = userEmail ?? email;
        await PreferencesService.saveUserEmail(emailToSave);

        // Save user name from user object
        if (userName != null && userName.isNotEmpty) {
          await PreferencesService.saveUserName(userName);
        } else if (response.data != null && response.data!.name.isNotEmpty) {
          // Fallback to UserModel name if user_name not in result
          await PreferencesService.saveUserName(response.data!.name);
        }

        // Save user ID from user object
        if (userId != null && userId != 0) {
          await PreferencesService.saveUserId(userId);
          debugPrint('✅ User ID saved: $userId');
        } else if (response.data != null && response.data!.id != 0) {
          // Fallback to UserModel id if user_id not in result
          await PreferencesService.saveUserId(response.data!.id);
          debugPrint('✅ User ID saved from UserModel: ${response.data!.id}');
        } else {
          debugPrint('⚠️ Could not determine user ID');
        }

        // Save user type based on selected role
        final userTypeString = selectedRole.value == UserType.coach
            ? 'coach'
            : 'customer';
        await PreferencesService.saveUserType(userTypeString);
        debugPrint('✅ User type saved: $userTypeString');

        // Save profile image from API response if available
        if (response.data != null &&
            response.data!.profileImage != null &&
            response.data!.profileImage!.isNotEmpty) {
          final profileImageUrl = response.data!.profileImage!;
          PreferencesService.getStorage().write(
            'user_profile_image_url',
            profileImageUrl,
          );
          debugPrint('✅ Profile image saved from login: $profileImageUrl');
        } else {
          // Try to fetch user profile to get the latest profile image
          try {
            final profileResponse = await _authRepository.getUserProfile();
            if (profileResponse.isSuccess &&
                profileResponse.data != null &&
                profileResponse.data!.profileImage != null &&
                profileResponse.data!.profileImage!.isNotEmpty) {
              final profileImageUrl = profileResponse.data!.profileImage!;
              PreferencesService.getStorage().write(
                'user_profile_image_url',
                profileImageUrl,
              );
              debugPrint(
                '✅ Profile image saved from profile API: $profileImageUrl',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Could not fetch profile image: $e');
            // Continue with login even if profile fetch fails
          }
        }

        // Show success message
        _safeSnackbar(
          title: 'Success',
          message: response.message,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Check consent and goals data availability
        await _checkUserDataAndNavigate(token);
      } else {
        // Show error message
        _safeSnackbar(
          title: 'Login Failed',
          message: response.message,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      _safeSnackbar(
        title: 'Login Failed',
        message:
            'An unexpected error occurred. Please check your connection and try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      debugPrint('❌ Login Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle Google login
  Future<void> handleGoogleLogin() async {
    if (isClosed) return;

    try {
      isLoading.value = true;

      final roleString = selectedRole.value == UserType.coach ? 'Coach' : 'Customer';

      final result = await _googleAuthService.signInWithGoogle(role: roleString);

      if (isClosed) return;

      if (result['success'] == true) {
        final token = result['token'] as String;
        await _checkUserDataAndNavigate(token);
      } else {
        final error = result['error'] as String;
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('❌ Google Login Error: $e');
      if (!isClosed) {
        _safeSnackbar(
          title: 'Google Login Failed',
          message: e.toString().contains('Server error')
              ? 'Server error. Please try again later.'
              : e.toString().contains('cancelled')
                  ? 'Sign-in was cancelled'
                  : 'Please try again',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Handle Apple login
  Future<void> handleAppleLogin() async {
    if (isClosed) return;

    try {
      isLoading.value = true;

      // TODO: Implement Apple Sign-In
      // Example:
      // await AuthService.signInWithApple();

      await Future.delayed(const Duration(seconds: 1));

      if (!isClosed) {
        _safeSnackbar(
          title: 'Success',
          message: 'Logged in with Apple',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Apple Login Error: $e');
      if (!isClosed) {
        _safeSnackbar(
          title: 'Apple Login Failed',
          message: e.toString(),
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Navigate to sign up
  void navigateToSignUp() {
    Get.toNamed(AppRoutes.signup);
  }

  /// Check consent and goals data availability and navigate accordingly
  Future<void> _checkUserDataAndNavigate(String token) async {
    try {
      // Check if controller is still mounted
      if (isClosed) return;

      // Call both APIs in parallel
      final consentResponse = await _consentRepository.getSingleConsent(
        token: token,
      );
      final goalsResponse = await _goalsRepository.getSingleGoal(token: token);

      // Check if controller is still mounted after async calls
      if (isClosed) return;

      final hasConsent =
          consentResponse.isSuccess && consentResponse.data != null;
      final hasGoals = goalsResponse.isSuccess && goalsResponse.data != null;

      debugPrint('📊 Consent available: $hasConsent');
      debugPrint('📊 Goals available: $hasGoals');

      // Navigate based on data availability
      await Future.delayed(const Duration(milliseconds: 500));

      if (hasConsent && hasGoals) {
        // Both found → Dashboard
        debugPrint('✅ Both consent and goals found → Navigating to Dashboard');
        Get.offAllNamed(AppRoutes.home);
      } else if (hasConsent && !hasGoals) {
        // Only Consent → Goal Settings → Dashboard
        debugPrint('✅ Only consent found → Navigating to Goal Settings');
        Get.offAllNamed(AppRoutes.goalSettings);
      } else if (!hasConsent && hasGoals) {
        // Only Goal Settings → Consent → Dashboard
        debugPrint('✅ Only goals found → Navigating to Consent');
        Get.offAllNamed(AppRoutes.consent);
      } else {
        // Neither → Consent → Goal Settings → Dashboard (current flow)
        debugPrint('✅ Neither found → Navigating to Consent');
        Get.offAllNamed(AppRoutes.consent);
      }
    } catch (e) {
      debugPrint('❌ Error checking user data: $e');
      // On error, default to consent screen
      if (!isClosed) {
        Get.offAllNamed(AppRoutes.consent);
      }
    }
  }
}
