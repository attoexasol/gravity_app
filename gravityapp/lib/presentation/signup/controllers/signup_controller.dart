import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consent_repository.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/preferences_service.dart';

enum UserType { customer, coach }

class SignupController extends GetxController {
  // Repository
  final AuthRepository _authRepository = AuthRepository();
  final ConsentRepository _consentRepository = ConsentRepository();
  final GoalsRepository _goalsRepository = GoalsRepository();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  // Observable for selected user role
  final Rx<UserType> selectedRole = UserType.customer.obs;

  // Text editing controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Reactive copy of confirm password text (for Obx + validation UI)
  final RxString confirmPasswordText = ''.obs;

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Observable for password visibility
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  // Observable for form validation
  final RxBool isFormValid = false.obs;

  // Observable for signup success state
  final RxBool isSignupSuccess = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Add listeners to validate form
    fullNameController.addListener(_validateForm);
    emailController.addListener(_validateForm);
    phoneController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
    confirmPasswordController.addListener(_validateForm);
  }

  @override
  void onClose() {
    // Remove listeners before disposing to prevent accessing disposed controllers
    fullNameController.removeListener(_validateForm);
    emailController.removeListener(_validateForm);
    phoneController.removeListener(_validateForm);
    passwordController.removeListener(_validateForm);
    confirmPasswordController.removeListener(_validateForm);

    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Validate form
  void _validateForm() {
    // Check if controller is still mounted before accessing controllers
    if (!isClosed) {
      // keep reactive text in sync for confirm-password field UI
      confirmPasswordText.value = confirmPasswordController.text;

      isFormValid.value =
          fullNameController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          passwordController.text == confirmPasswordController.text &&
          validateEmail(emailController.text) == null &&
          validatePassword(passwordController.text) == null;
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

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
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
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Validate full name
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Please enter a valid name';
    }
    return null;
  }

  /// Check if passwords match
  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  /// Handle signup - UPDATED WITH REAL API CALL
  Future<void> handleSignup() async {
    // Check if controller is still mounted before accessing controllers
    if (isClosed) return;

    // Validate inputs
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (validateFullName(fullName) != null ||
        validateEmail(email) != null ||
        validatePassword(password) != null ||
        password != confirmPassword) {
      Get.snackbar(
        'Validation Error',
        'Please check your inputs',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Convert UserType enum to API role string
      final role = selectedRole.value == UserType.customer
          ? 'Customer'
          : 'Coach';

      // Call API to create user
      final response = await _authRepository.createUser(
        name: fullName,
        email: email,
        phone: phone.isEmpty ? '' : phone, // Phone is optional
        password: password,
        passwordConfirmation: confirmPassword,
        role: role,
      );

      // Check if controller is still mounted before proceeding
      if (isClosed) return;

      // Handle response
      if (response.isSuccess && response.data != null) {
        // Mark onboarding as completed when user successfully registers
        // This ensures onboarding is only shown once, on first launch
        await PreferencesService.setOnboardingCompleted(true);
        
        // IMPORTANT: Do NOT mark first-time setup as completed here
        // First-time setup should only be marked when goals are saved
        // This ensures: Sign up → Login → Goal Settings (first time) → Dashboard (subsequent)
        
        // Success - Set success state and show message
        FocusManager.instance.primaryFocus?.unfocus();
        isSignupSuccess.value = true;

        Get.snackbar(
          'Success',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        // Error from API
        Get.snackbar(
          'Signup Failed',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      // Network or unexpected error
      Get.snackbar(
        'Signup Failed',
        'An unexpected error occurred. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
      debugPrint('❌ Signup Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle Google signup
  Future<void> handleGoogleSignup() async {
    if (isClosed) return;

    try {
      isLoading.value = true;

      final roleString = selectedRole.value == UserType.coach ? 'Coach' : 'Customer';

      final result = await _googleAuthService.signInWithGoogle(role: roleString);

      if (isClosed) return;

      if (result['success'] == true) {
        // Mark onboarding as completed when user successfully signs up with Google
        await PreferencesService.setOnboardingCompleted(true);
        
        final token = result['token'] as String;
        await _checkUserDataAndNavigate(token);
      } else {
        final error = result['error'] as String;
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('❌ Google Signup Error: $e');
      if (!isClosed) {
        Get.snackbar(
          'Google Signup Failed',
          e.toString().contains('Server error')
              ? 'Server error. Please try again later.'
              : e.toString().contains('cancelled')
                  ? 'Sign-up was cancelled'
                  : 'Please try again',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Check consent and goals data availability and navigate accordingly
  /// For signup (Google signup that logs in directly), use first-time setup logic
  /// First-time users → Goal Settings (skip consent), Subsequent → Dashboard directly
  Future<void> _checkUserDataAndNavigate(String token) async {
    try {
      if (isClosed) return;

      // Check if first-time setup has been completed
      final isFirstTimeSetupCompleted = PreferencesService.isFirstTimeSetupCompleted();
      
      debugPrint('📊 First-time setup completed: $isFirstTimeSetupCompleted');

      // If first-time setup is not completed, navigate to Goal Settings (skip consent)
      if (!isFirstTimeSetupCompleted) {
        debugPrint('✅ First-time signup → Navigating to Goal Settings (skipping consent)');
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

  /// Handle Apple signup
  Future<void> handleAppleSignup() async {
    try {
      isLoading.value = true;

      // TODO: Implement Apple Sign-Up when available
      await Future.delayed(const Duration(seconds: 1));

      Get.snackbar(
        'Coming Soon',
        'Apple Sign-Up will be available soon',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00B8A9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Apple Signup Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate back to login
  void navigateToLogin() {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.back();
  }

  /// Navigate to login screen after successful signup
  void navigateToLoginAfterSignup() {
    FocusManager.instance.primaryFocus?.unfocus();
    isSignupSuccess.value = false; // Reset success state
    Get.offNamed(AppRoutes.login);
  }
}
