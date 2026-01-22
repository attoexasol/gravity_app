import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Text editing controller
  late final TextEditingController emailController;

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Observable for error message
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    
    // Clear error when user starts typing
    emailController.addListener(() {
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });
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

  /// Handle forgot password request - Send OTP
  Future<void> handleForgotPassword() async {
    if (isClosed) return;

    final email = emailController.text.trim();

    // Clear previous error
    errorMessage.value = '';

    // Validate email
    if (validateEmail(email) != null) {
      errorMessage.value = 'Please enter a valid email address';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = ''; // Clear error when starting new request

      // Call API to send OTP
      final response = await _authRepository.sendOtp(email: email);

      if (isClosed) return;

      if (response.isSuccess) {
        // Clear any error message
        errorMessage.value = '';
        
        _safeSnackbar(
          title: 'Success',
          message: response.message,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Navigate to OTP verification screen after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (!isClosed) {
          Get.toNamed(
            AppRoutes.otpVerification,
            parameters: {'email': email},
          );
        }
      } else {
        // Display error message in UI
        errorMessage.value = _getUserFriendlyErrorMessage(response.message);
      }
    } catch (e) {
      if (!isClosed) {
        errorMessage.value = 'An unexpected error occurred. Please try again.';
      }
      debugPrint('❌ Forgot Password Error: $e');
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Get user-friendly error message for email-related errors
  String _getUserFriendlyErrorMessage(String? originalMessage) {
    if (originalMessage == null || originalMessage.isEmpty) {
      return 'The email address you entered is invalid or not associated with any account. Please check your email and try again.';
    }

    final message = originalMessage.toLowerCase();

    // Check for common error patterns indicating invalid/unregistered email
    if (message.contains('email') && 
        (message.contains('not found') || 
         message.contains('not exist') || 
         message.contains('not registered') ||
         message.contains('not associated') ||
         message.contains('invalid') ||
         message.contains('does not exist'))) {
      return 'The email address you entered is not registered with any account. Please check your email address and try again, or sign up if you don\'t have an account.';
    }

    if (message.contains('user not found') || 
        message.contains('account not found') ||
        message.contains('no account found')) {
      return 'No account found with this email address. Please verify your email address or sign up to create a new account.';
    }

    if (message.contains('validation') && message.contains('email')) {
      return 'The email address format is invalid. Please enter a valid email address and try again.';
    }

    // For other errors, return the original message or a generic helpful message
    return originalMessage;
  }

  /// Navigate back to login
  void navigateToLogin() {
    Get.back();
  }
}

