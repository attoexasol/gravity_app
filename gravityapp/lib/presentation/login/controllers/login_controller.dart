import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:gravityapp/data/model/api_response.dart';
import 'package:gravityapp/data/model/user_model.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consent_repository.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/token_manager.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/services/device_manager.dart';
import '../../../core/utils/app_snackbar.dart';

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
  /// [scaffoldContext] optional context from LoginScreen for showing snackbar on the correct Scaffold.
  Future<void> handleLogin([BuildContext? scaffoldContext]) async {
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

        // Save user type: prefer Laravel response.user.role, fallback to selected role
        final apiRole = response.data?.role?.toString().trim().toLowerCase();
        final fallbackRole = selectedRole.value == UserType.coach ? 'coach' : 'customer';
        final roleToSave = (apiRole != null && apiRole.isNotEmpty && (apiRole == 'coach' || apiRole == 'customer'))
            ? apiRole
            : fallbackRole;
        await PreferencesService.saveUserType(roleToSave);
        debugPrint('✅ User type saved from ${apiRole != null ? 'API' : 'selected role'}: $roleToSave');

        // Firebase: sign in with custom token and sync user to Firestore (for real-time chat)
        final firebaseCustomToken = result['firebase_custom_token'] as String?;
        if (firebaseCustomToken != null && firebaseCustomToken.isNotEmpty) {
          try {
            final authService = AuthService();
            final name = response.data?.name ?? userName ?? '';
            final role = response.data?.role ?? roleToSave;
            final profileImageUrl = response.data?.profileImage;
            await authService.signInWithCustomTokenAndSyncUser(
              firebaseCustomToken: firebaseCustomToken,
              name: name,
              role: role,
              profileImageUrl: profileImageUrl,
            );
            debugPrint('✅ Firebase sign-in and Firestore user sync completed');
          } catch (e) {
            debugPrint('⚠️ Firebase custom token sign-in failed (chat may not work): $e');
            // Don't block login; user is still logged in via Laravel
          }
        } else {
          debugPrint('⚠️ No firebase_custom_token in login response (real-time chat disabled)');
        }

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

        // Clear any error messages
        emailErrorMessage.value = '';
        passwordErrorMessage.value = '';

        // Show success SnackBar (matches Sign-Up page style)
        AppSnackbar.show(
          title: 'Login Successful',
          message: 'Welcome back!',
          isSuccess: true,
        );

        // Check consent and goals data availability
        await _checkUserDataAndNavigate(accessToken);
      } else {
        // Server-side login failure: show only SnackBar (no field-level errors)
        AppSnackbar.show(
          title: 'Login Failed',
          message: response.message.isNotEmpty
              ? response.message
              : 'Invalid email or password',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!isClosed) {
        AppSnackbar.show(
          title: 'Login Failed',
          message: 'An unexpected error occurred. Please check your connection and try again.',
          isSuccess: false,
        );
      }
      debugPrint('❌ Login Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle Google login: requires role (Coach/Customer). Calls Laravel /api/auth/google, saves api_token + user, then Firebase custom token so UID = Laravel user_id.
  Future<void> handleGoogleLogin() async {
    if (isClosed) return;

    final roleString = selectedRole.value == UserType.coach ? 'Coach' : 'Customer';
    if (roleString.isEmpty) {
      AppSnackbar.show(
        title: 'Select role',
        message: 'Please select Customer or Coach before signing in.',
        isSuccess: false,
      );
      return;
    }

    try {
      isLoading.value = true;

      final result = await _googleAuthService.signInWithGoogle(role: roleString);

      if (isClosed) return;

      if (result['success'] == true) {
        await PreferencesService.setOnboardingCompleted(true);

        AppSnackbar.show(
          title: 'Login Successful',
          message: 'Welcome back!',
          isSuccess: true,
        );

        final token = result['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _checkUserDataAndNavigate(token);
        } else {
          if (!isClosed) {
            Get.offAllNamed(AppRoutes.home);
          }
        }
      } else {
        final error = result['error'] as String? ?? 'Google login failed';
        if (!isClosed) {
          Get.snackbar(
            'Google Login Failed',
            error,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Google Login Error: $e');
      if (!isClosed) {
        final msg = e.toString().contains('Server error')
            ? 'Server error. Please try again later.'
            : e.toString().toLowerCase().contains('cancelled')
                ? 'Sign-in was cancelled'
                : 'Please try again';
        Get.snackbar(
          'Google Login Failed',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
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
        AppSnackbar.show(
          title: 'Login Successful',
          message: 'Welcome back!',
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Apple Login Error: $e');
      if (!isClosed) {
        AppSnackbar.show(
          title: 'Apple Login Failed',
          message: e.toString(),
          isSuccess: false,
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
        // User has goals → write to local storage so dashboard shows Starting weight from Current Weight
        final goalData = goalsResponse.data!;
        final waterIntake = goalData['daily_water_intake']?.toString() ?? '3';
        final goalsMap = <String, String>{
          'currentWeight': goalData['current_weight']?.toString() ?? '',
          'targetWeight': goalData['target_weight']?.toString() ?? '70',
          'stepGoal': goalData['step_goal']?.toString() ?? '12000',
          'waterIntake': waterIntake.replaceAll('L', '').replaceAll('l', '').trim(),
          'sleepHours': goalData['sleep_hours']?.toString() ?? '7-8',
          'aiTone': goalData['ai_tone']?.toString() ?? 'encouraging',
        };
        PreferencesService.getStorage().write('userGoals', jsonEncode(goalsMap));
        final cw = double.tryParse(goalsMap['currentWeight'] ?? '');
        if (cw != null && cw > 0) {
          await PreferencesService.saveStartingWeight(cw);
        }
        debugPrint('✅ User has goals → Navigating directly to Dashboard');
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
}
