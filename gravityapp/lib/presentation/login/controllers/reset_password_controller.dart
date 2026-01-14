import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/model/api_response.dart';

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

  // Token from route parameters
  String? resetToken;

  @override
  void onInit() {
    super.onInit();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    // Get token from route parameters
    resetToken = Get.parameters['token'];
    debugPrint('🔑 Reset token: ${resetToken ?? "Not provided"}');
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

    // Validate token
    if (resetToken == null || resetToken!.isEmpty) {
      _safeSnackbar(
        title: 'Error',
        message: 'Invalid reset token. Please request a new password reset link.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validate inputs
    final passwordError = validatePassword(password);
    final confirmPasswordError = validateConfirmPassword(confirmPassword);

    if (passwordError != null || confirmPasswordError != null) {
      _safeSnackbar(
        title: 'Validation Error',
        message: passwordError ?? confirmPasswordError ?? 'Please check your inputs',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Call API to reset password
      final response = await _authRepository.resetPassword(
        token: resetToken!,
        password: password,
        passwordConfirmation: confirmPassword,
      );

      if (isClosed) return;

      if (response.isSuccess) {
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
        _safeSnackbar(
          title: 'Error',
          message: response.message,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (!isClosed) {
        _safeSnackbar(
          title: 'Error',
          message: 'An unexpected error occurred. Please try again.',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
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

