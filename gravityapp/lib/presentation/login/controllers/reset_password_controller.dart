import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';

class ResetPasswordController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Text editing controllers
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Observable for password visibility
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  // Observable for error message
  final RxString errorMessage = ''.obs;

  // Email from route parameters (after OTP verification)
  String? email;

  @override
  void onInit() {
    super.onInit();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    
    // Get email from route parameters
    email = Get.parameters['email'];
    debugPrint('📧 Reset password for email: ${email ?? "Not provided"}');
    
    // Clear error when user starts typing in password fields
    passwordController.addListener(() {
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });
    
    confirmPasswordController.addListener(() {
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
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
      }
    } catch (e) {
      debugPrint('⚠️ Error showing snackbar: $e');
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
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

  /// Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Handle password reset
  Future<void> handleResetPassword() async {
    if (isClosed) return;

    // Validate email
    if (email == null || email!.isEmpty) {
      _safeSnackbar(
        title: 'Error',
        message: 'Email not found. Please start over.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Clear previous error
    errorMessage.value = '';

    // Validate inputs
    final passwordError = validatePassword(password);
    final confirmPasswordError = validateConfirmPassword(confirmPassword);

    if (passwordError != null || confirmPasswordError != null) {
      // Display error message in UI - prioritize password mismatch
      if (confirmPasswordError != null && confirmPasswordError.contains('match')) {
        errorMessage.value = 'The passwords do not match. Please re-enter them correctly.';
      } else {
        errorMessage.value = passwordError ?? confirmPasswordError ?? 'Please check your inputs';
      }
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = ''; // Clear error when starting new request

      // Call API to reset password
      final response = await _authRepository.resetPassword(
        email: email!,
        password: password,
        passwordConfirmation: confirmPassword,
      );

      if (isClosed) return;

      if (response.isSuccess) {
        // Clear any error message
        errorMessage.value = '';
        
        _safeSnackbar(
          title: 'Success',
          message: response.message,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Navigate to login after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (!isClosed) {
          Get.offAllNamed(AppRoutes.login);
        }
      } else {
        // Display error message in UI
        final message = response.message.toLowerCase();
        if (message.contains('password') && message.contains('match')) {
          errorMessage.value = 'The passwords do not match. Please re-enter them correctly.';
        } else {
          errorMessage.value = response.message;
        }
      }
    } catch (e) {
      if (!isClosed) {
        errorMessage.value = 'An unexpected error occurred. Please try again.';
      }
      debugPrint('❌ Reset Password Error: $e');
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Navigate back
  void navigateBack() {
    Get.back();
  }
}

