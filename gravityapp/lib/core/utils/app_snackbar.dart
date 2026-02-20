import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reusable styled SnackBar matching Sign-Up / Login design.
/// Use for consistent auth feedback across email, Google, and Apple flows.
class AppSnackbar {
  static void show({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: isSuccess
          ? const Color(0xFF00B8A9)
          : const Color(0xFFD32F2F),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
