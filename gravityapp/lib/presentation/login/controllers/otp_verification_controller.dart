import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';

class OtpVerificationController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Text editing controller
  late final TextEditingController otpController;

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Observable for error message
  final RxString errorMessage = ''.obs;

  // Email from previous screen
  final RxString email = ''.obs;

  // Resend OTP countdown
  final RxInt resendCountdown = 60.obs;
  final RxBool canResend = false.obs;
  Timer? _resendTimer;

  @override
  void onInit() {
    super.onInit();
    otpController = TextEditingController();
    
    // Get email from route parameters
    email.value = Get.parameters['email'] ?? '';
    
    // Clear error when user starts typing
    otpController.addListener(() {
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });
    
    // Start resend countdown
    _startResendCountdown();
  }

  @override
  void onClose() {
    otpController.dispose();
    _resendTimer?.cancel();
    super.onClose();
  }

  /// Start countdown timer for resend OTP
  void _startResendCountdown() {
    canResend.value = false;
    resendCountdown.value = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown.value > 0) {
        resendCountdown.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
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

  /// Validate OTP
  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  /// Handle OTP verification
  Future<void> handleVerifyOtp() async {
    if (isClosed) return;

    final otp = otpController.text.trim();

    // Clear previous error
    errorMessage.value = '';

    // Validate OTP
    final validationError = validateOtp(otp);
    if (validationError != null) {
      errorMessage.value = validationError;
      return;
    }

    if (email.value.isEmpty) {
      errorMessage.value = 'Email not found. Please start over.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = ''; // Clear error when starting new request

      // Call API to verify OTP
      final response = await _authRepository.verifyOtp(
        email: email.value,
        otp: otp,
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
          duration: const Duration(seconds: 2),
        );

        // Navigate to reset password screen after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (!isClosed) {
          Get.toNamed(
            AppRoutes.resetPassword,
            parameters: {'email': email.value},
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
      debugPrint('❌ Verify OTP Error: $e');
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Get user-friendly error message for OTP-related errors
  String _getUserFriendlyErrorMessage(String? originalMessage) {
    if (originalMessage == null || originalMessage.isEmpty) {
      return 'The OTP you entered is incorrect. Please check and try again.';
    }

    final message = originalMessage.toLowerCase();

    // Check for common error patterns indicating invalid/incorrect OTP
    if (message.contains('otp') && 
        (message.contains('invalid') || 
         message.contains('incorrect') || 
         message.contains('wrong') ||
         message.contains('expired') ||
         message.contains('not match'))) {
      return 'The OTP you entered is incorrect or has expired. Please check your email and enter the correct OTP, or request a new one.';
    }

    if (message.contains('expired')) {
      return 'The OTP has expired. Please request a new OTP and try again.';
    }

    if (message.contains('invalid') || message.contains('incorrect')) {
      return 'The OTP you entered is incorrect. Please check your email and try again.';
    }

    // For other errors, return the original message or a generic helpful message
    return originalMessage;
  }

  /// Resend OTP
  Future<void> resendOtp() async {
    if (isClosed || email.value.isEmpty) return;

    try {
      isLoading.value = true;

      // Call API to resend OTP
      final response = await _authRepository.sendOtp(email: email.value);

      if (isClosed) return;

      if (response.isSuccess) {
        _safeSnackbar(
          title: 'Success',
          message: 'OTP has been resent to your email',
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Clear OTP field
        otpController.clear();

        // Restart countdown
        _startResendCountdown();
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
      debugPrint('❌ Resend OTP Error: $e');
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
