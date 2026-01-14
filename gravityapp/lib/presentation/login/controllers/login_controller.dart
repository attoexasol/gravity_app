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

    // emailController = TextEditingController(text: "");
    // passwordController = TextEditingController(text: "");
  }

  @override
  void onClose() {
    // Dispose controllers after a delay to ensure widget tree has finished updating
    // This prevents "TextEditingController was used after being disposed" errors
    // Use a post-frame callback to ensure disposal happens after all widgets have updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Dispose controllers safely after the frame completes
      // TextEditingController doesn't have a 'disposed' getter, so we use try-catch
      try {
        emailController.dispose();
      } catch (e) {
        // Controller may already be disposed, ignore the error
        debugPrint('⚠️ Error disposing emailController (may already be disposed): $e');
      }
      try {
        passwordController.dispose();
      } catch (e) {
        // Controller may already be disposed, ignore the error
        debugPrint('⚠️ Error disposing passwordController (may already be disposed): $e');
      }
    });
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
        // Mark onboarding as completed when user successfully logs in
        // This ensures onboarding is only shown once, on first launch
        await PreferencesService.setOnboardingCompleted(true);
        
        // IMPORTANT: Do NOT mark first-time setup as completed here
        // First-time setup should only be marked when goals are saved in goal_settings_controller
        // This ensures: Sign up → Login → Goal Settings (first time) → Dashboard (subsequent)
        
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
          // Using getSingleUser() instead of getUserProfile() since /user/profile route doesn't exist
          try {
            final profileResponse = await _authRepository.getSingleUser();
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

        // Skip snackbar before navigation to avoid overlay errors
        // Navigation happens immediately after, which can cause overlay to be unavailable
        // _safeSnackbar(
        //   title: 'Success',
        //   message: response.message,
        //   backgroundColor: const Color(0xFF00B8A9),
        //   colorText: Colors.white,
        //   duration: const Duration(seconds: 2),
        // );

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
        // Mark onboarding as completed when user successfully logs in with Google
        await PreferencesService.setOnboardingCompleted(true);
        
        // IMPORTANT: Do NOT mark first-time setup as completed here
        // First-time setup should only be marked when goals are saved in goal_settings_controller
        // This ensures: Google Sign up → Google Login → Goal Settings (first time) → Dashboard (subsequent)
        
        // Verify role was saved correctly (google_auth_service saves it, but let's ensure it's correct)
        final savedRole = PreferencesService.getUserType();
        debugPrint('🔍 Google Login - Saved role: $savedRole');
        debugPrint('🔍 Google Login - Selected role: ${selectedRole.value}');
        
        // If role wasn't saved or doesn't match, save it again
        if (savedRole == null || savedRole.isEmpty) {
          final roleString = selectedRole.value == UserType.coach ? 'coach' : 'customer';
          await PreferencesService.saveUserType(roleString);
          debugPrint('⚠️ Role was missing, saved selected role: $roleString');
        }
        
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

  /// Navigate to forgot password
  void navigateToForgotPassword() {
    Get.toNamed(AppRoutes.forgotPassword);
  }

  /// Check consent and goals data availability and navigate accordingly
  /// Implements conditional navigation:
  /// - First-time login (first-time setup not completed) → Goal Settings (skip consent)
  /// - Subsequent logins (first-time setup completed) → Dashboard directly (skip consent)
  Future<void> _checkUserDataAndNavigate(String token) async {
    try {
      // Check if controller is still mounted
      if (isClosed) return;

      // Check if first-time setup has been completed
      final isFirstTimeSetupCompleted = PreferencesService.isFirstTimeSetupCompleted();
      
      debugPrint('📊 First-time setup completed: $isFirstTimeSetupCompleted');

      // If first-time setup is not completed, navigate to Goal Settings (skip consent)
      if (!isFirstTimeSetupCompleted) {
        debugPrint('✅ First-time login → Navigating to Goal Settings (skipping consent)');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!isClosed) {
          Get.offAllNamed(AppRoutes.goalSettings);
        }
        return;
      }

      // For subsequent logins, navigate directly to Dashboard (skip consent check)
      debugPrint('✅ Subsequent login → Navigating directly to Dashboard');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!isClosed) {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      debugPrint('❌ Error checking user data: $e');
      // On error, check first-time setup status
      if (!isClosed) {
        final isFirstTimeSetupCompleted = PreferencesService.isFirstTimeSetupCompleted();
        if (!isFirstTimeSetupCompleted) {
          // Default to goal settings for first-time users
          debugPrint('⚠️ Error occurred, defaulting to Goal Settings for first-time user');
          Get.offAllNamed(AppRoutes.goalSettings);
        } else {
          // Default to dashboard for subsequent logins
          debugPrint('⚠️ Error occurred, defaulting to Dashboard for subsequent login');
          Get.offAllNamed(AppRoutes.home);
        }
      }
    }
  }
}
