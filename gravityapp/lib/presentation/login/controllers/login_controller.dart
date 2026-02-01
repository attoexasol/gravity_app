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
import '../../../core/services/token_manager.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/services/device_manager.dart';

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

  // Observable for error messages - separate for email and password
  final RxString emailErrorMessage = ''.obs;
  final RxString passwordErrorMessage = ''.obs;

  // Observable for password visibility
  final RxBool isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController(text: "rajibduet02@gmail.com");
    passwordController = TextEditingController(text: "Gravity@024017");
    // Initialize controllers in onInit to ensure they're created when controller is initialized
    // emailController = TextEditingController(text: "");
    // passwordController = TextEditingController(text: "");
    
    // Clear error when user starts typing
    emailController.addListener(() {
      if (emailErrorMessage.value.isNotEmpty) {
        emailErrorMessage.value = '';
      }
    });
    
    passwordController.addListener(() {
      if (passwordErrorMessage.value.isNotEmpty) {
        passwordErrorMessage.value = '';
      }
    });
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

    // Clear previous errors
    emailErrorMessage.value = '';
    passwordErrorMessage.value = '';

    // Validate inputs
    final email = emailController.text.trim();
    final password = passwordController.text;

    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);

    if (emailError != null || passwordError != null) {
      if (emailError != null) {
        emailErrorMessage.value = emailError;
      }
      if (passwordError != null) {
        passwordErrorMessage.value = passwordError;
      }
      return;
    }

    try {
      isLoading.value = true;
      // Clear errors when starting new request
      emailErrorMessage.value = '';
      passwordErrorMessage.value = '';

      // Call login API
      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      final response = result['response'] as ApiResponse<UserModel>;
      final accessToken = result['access_token'] as String? ?? result['token'] as String?;
      final refreshToken = result['refresh_token'] as String?;
      final userId = result['user_id'] as int?;
      final userName = result['user_name'] as String?;
      final userEmail = result['email'] as String?;

      // Check if controller is still mounted before proceeding
      if (isClosed) return;

      if (response.isSuccess && accessToken != null) {
        // Mark onboarding as completed when user successfully logs in
        // This ensures onboarding is only shown once, on first launch
        await PreferencesService.setOnboardingCompleted(true);
        
        // IMPORTANT: Do NOT mark first-time setup as completed here
        // First-time setup should only be marked when goals are saved in goal_settings_controller
        // This ensures: Sign up → Login → Goal Settings (first time) → Dashboard (subsequent)
        
        // Save tokens using TokenManager
        final tokenManager = TokenManager();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await tokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        } else {
          // If no refresh token provided, save only access token
          // This handles backward compatibility with APIs that only return access token
          await tokenManager.updateAccessToken(accessToken);
          debugPrint('⚠️ No refresh token received from API - only access token saved');
        }
        
        // Also save to PreferencesService for backward compatibility
        await PreferencesService.saveAuthToken(accessToken);

        // Initialize session for single-device authentication
        final deviceManager = DeviceManager();
        final sessionManager = SessionManager();
        final deviceId = await deviceManager.getDeviceId();
        final userIdString = userId?.toString() ?? 
                           (response.data?.id.toString() ?? '');
        
        if (userIdString.isNotEmpty) {
          await sessionManager.initializeSession(
            userId: userIdString,
            deviceId: deviceId,
          );
          debugPrint('✅ Session initialized for device: $deviceId');
        }

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

        // Clear any previous user's profile image first to prevent image leakage
        await PreferencesService.clearProfileImage();
        
        // Save profile image from API response if available
        if (response.data != null &&
            response.data!.profileImage != null &&
            response.data!.profileImage!.isNotEmpty) {
          final profileImageUrl = response.data!.profileImage!;
          await PreferencesService.saveProfileImageUrl(profileImageUrl);
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
              await PreferencesService.saveProfileImageUrl(profileImageUrl);
              debugPrint(
                '✅ Profile image saved from profile API: $profileImageUrl',
              );
            } else {
              // User has no profile image - ensure it's cleared
              debugPrint('✅ No profile image found for user - cleared previous image');
            }
          } catch (e) {
            debugPrint('⚠️ Could not fetch profile image: $e');
            // Continue with login even if profile fetch fails
            // Profile image is already cleared above, so new user won't see old image
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

        // Clear any error messages
        emailErrorMessage.value = '';
        passwordErrorMessage.value = '';
        
        // Check consent and goals data availability
        await _checkUserDataAndNavigate(accessToken);
      } else {
        // Determine which field has the error and display appropriate message
        _setFieldSpecificError(response.message);
      }
    } catch (e) {
      if (!isClosed) {
        // For unexpected errors, show on password field as default
        passwordErrorMessage.value = 'An unexpected error occurred. Please check your connection and try again.';
      }
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

  /// Check user goals from backend and navigate accordingly
  /// Implements conditional navigation based on SERVER data (not local storage):
  /// - User has goals in backend → Dashboard directly
  /// - User missing goals in backend → Goal Settings screen
  /// This works even after reinstall since it checks backend, not local flags
  Future<void> _checkUserDataAndNavigate(String token) async {
    try {
      // Check if controller is still mounted
      if (isClosed) return;

      debugPrint('🔍 Checking user goals from backend...');

      // Check backend for user goals (server-side check, not local storage)
      final goalsResponse = await _goalsRepository.getSingleGoal(token: token);

      // Determine if user has completed goals based on backend response
      bool hasGoalsCompleted = false;

      if (goalsResponse.isSuccess && goalsResponse.data != null) {
        final goalData = goalsResponse.data!;
        
        // Check if essential goals are set: currentWeight and targetWeight
        final currentWeight = goalData['current_weight']?.toString();
        final targetWeight = goalData['target_weight']?.toString();
        
        // User has goals if both currentWeight and targetWeight are present and non-empty
        hasGoalsCompleted = (currentWeight != null && 
                           currentWeight.isNotEmpty && 
                           targetWeight != null && 
                           targetWeight.isNotEmpty);
        
        debugPrint('📊 Backend goals check:');
        debugPrint('   - currentWeight: ${currentWeight ?? "null"}');
        debugPrint('   - targetWeight: ${targetWeight ?? "null"}');
        debugPrint('   - hasGoalsCompleted: $hasGoalsCompleted');
      } else {
        // API call failed or returned no data - assume goals not set
        debugPrint('⚠️ Goals API returned no data or failed: ${goalsResponse.message}');
        hasGoalsCompleted = false;
      }

      // Navigate based on backend response
      if (!hasGoalsCompleted) {
        // User doesn't have goals → show Goal Settings screen
        debugPrint('✅ User missing goals → Navigating to Goal Settings');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!isClosed) {
          Get.offAllNamed(AppRoutes.goalSettings);
        }
      } else {
        // User has goals → go directly to Dashboard
        debugPrint('✅ User has goals → Navigating directly to Dashboard');
        
        // Update local cache flag for faster future checks (optional optimization)
        await PreferencesService.setFirstTimeSetupCompleted(true);
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (!isClosed) {
          Get.offAllNamed(AppRoutes.home);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking user goals from backend: $e');
      
      // On error, fallback to local storage check (for backward compatibility)
      // But prefer showing Goal Settings if uncertain (safer for new users)
      if (!isClosed) {
        final isFirstTimeSetupCompleted = PreferencesService.isFirstTimeSetupCompleted();
        if (!isFirstTimeSetupCompleted) {
          // Default to goal settings if local flag says first-time
          debugPrint('⚠️ Error occurred, defaulting to Goal Settings (local flag indicates first-time)');
          Get.offAllNamed(AppRoutes.goalSettings);
        } else {
          // If local flag says completed, go to dashboard
          // But this should rarely happen since we check backend first
          debugPrint('⚠️ Error occurred, defaulting to Dashboard (local flag indicates completed)');
          Get.offAllNamed(AppRoutes.home);
        }
      }
    }
  }

  /// Set field-specific error messages based on the API response
  /// Maps email-related errors to emailErrorMessage
  /// Maps password-related errors to passwordErrorMessage
  void _setFieldSpecificError(String? originalMessage) {
    // Clear both errors first
    emailErrorMessage.value = '';
    passwordErrorMessage.value = '';

    if (originalMessage == null || originalMessage.isEmpty) {
      // Default to password error if message is empty
      passwordErrorMessage.value = 'Wrong password';
      return;
    }

    final message = originalMessage.toLowerCase();

    // PRIORITY 1: Check for messages that mention BOTH email AND password
    // These are ambiguous - default to password error since email format is validated client-side
    if (message.contains('email') && message.contains('password')) {
      // Generic "Invalid email or password" type messages
      // Since email format is validated client-side, assume password is wrong
      passwordErrorMessage.value = 'Wrong password';
      return;
    }

    // PRIORITY 2: Check for explicit password-only errors (password mentioned but NOT email)
    // These are clear password errors
    if (message.contains('password') && !message.contains('email')) {
      if (message.contains('incorrect') || 
          message.contains('wrong') ||
          message.contains('invalid') ||
          message.contains('not match') ||
          message.contains('does not match') ||
          message.contains('mismatch')) {
        passwordErrorMessage.value = 'Wrong password';
        return;
      }
      if (message.contains('required') || message.contains('missing')) {
        passwordErrorMessage.value = 'Password is required. Please enter your password.';
        return;
      }
      // Generic password error
      passwordErrorMessage.value = 'Password incorrect';
      return;
    }

    // PRIORITY 3: Check for explicit email-only errors (email mentioned but NOT password)
    // Only trigger if password is NOT mentioned in the message
    if (message.contains('email') && !message.contains('password')) {
      if (message.contains('not found') || 
          message.contains('does not exist') ||
          message.contains('not registered')) {
        emailErrorMessage.value = 'Email not found';
        return;
      }
      if (message.contains('invalid') || message.contains('incorrect')) {
        emailErrorMessage.value = 'Invalid email address';
        return;
      }
      // Generic email error
      emailErrorMessage.value = 'Invalid email address';
      return;
    }

    // PRIORITY 4: Check for user/account not found - this is an email error
    // Only if password is NOT mentioned in the message
    if (!message.contains('password') &&
        (message.contains('user not found') || 
         message.contains('account not found') ||
         message.contains('no account found') ||
         message.contains('user does not exist'))) {
      emailErrorMessage.value = 'Email not found';
      return;
    }

    // PRIORITY 5: Check for generic authentication/credential errors
    // These are ambiguous, but since email format is validated client-side,
    // we'll default to password error for these
    if (message.contains('credentials') || 
        message.contains('authentication failed') ||
        message.contains('unauthorized') ||
        message.contains('login failed') ||
        message.contains('invalid credentials')) {
      // Default to password error since email validation happens client-side
      passwordErrorMessage.value = 'Wrong password';
      return;
    }

    // PRIORITY 6: Check for "incorrect" without email/username context - assume password
    if (message.contains('incorrect') && 
        !message.contains('email') && 
        !message.contains('username') &&
        !message.contains('user')) {
      passwordErrorMessage.value = 'Wrong password';
      return;
    }

    // PRIORITY 7: For any other errors, default to password error
    // (since email format is validated client-side, most API errors are password-related)
    passwordErrorMessage.value = 'Wrong password';
  }
}
