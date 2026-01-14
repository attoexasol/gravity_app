import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/model/api_response.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Text editing controller
  late final TextEditingController emailController;

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Observable for success state
  final RxBool isSuccess = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
  }

  @override
  void onClose() {
    emailController.dispose();
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

  /// Handle forgot password request
  Future<void> handleForgotPassword() async {
    if (isClosed) return;

    final email = emailController.text.trim();

    // Validate email
    if (validateEmail(email) != null) {
      _safeSnackbar(
        title: 'Validation Error',
        message: 'Please enter a valid email address',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      isLoading.value = true;
      isSuccess.value = false;

      // Call API to request password reset
      final response = await _authRepository.forgotPassword(email: email);

      if (isClosed) return;

      if (response.isSuccess) {
        isSuccess.value = true;
        _safeSnackbar(
          title: 'Success',
          message: response.message,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
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
      debugPrint('❌ Forgot Password Error: $e');
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Navigate back to login
  void navigateToLogin() {
    Get.back();
  }

  /// Navigate to reset password (for demo purposes - in real app, this would be via deep link)
  void navigateToResetPassword({String? token}) {
    // In a real app, the token would come from the email link
    // For demo, we'll use a mock token
    final resetToken = token ?? 'demo_reset_token_${DateTime.now().millisecondsSinceEpoch}';
    Get.toNamed(
      AppRoutes.resetPassword,
      parameters: {'token': resetToken},
    );
  }
}

