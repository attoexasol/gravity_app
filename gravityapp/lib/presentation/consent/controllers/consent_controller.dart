import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/consent_repository.dart';
import '../../../core/services/preferences_service.dart';

class ConsentController extends GetxController {
  /// Safely show snackbar with overlay check
  void _safeSnackbar({
    required String title,
    required String message,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Color? backgroundColor,
    Color? colorText,
    Duration duration = const Duration(seconds: 3),
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
            snackPosition: snackPosition,
            backgroundColor: backgroundColor ?? Get.theme.colorScheme.error,
            colorText: colorText ?? Get.theme.colorScheme.onError,
            duration: duration,
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
  // Repository
  final ConsentRepository _consentRepository = ConsentRepository();

  // Consent toggles
  final RxBool aiFeatures = true.obs;
  final RxBool dataPreferences = true.obs;

  // Delete confirmation modal
  final RxBool showDeleteConfirm = false.obs;

  // Loading state
  final RxBool isLoading = false.obs;

  /// Toggle AI Features consent
  void toggleAiFeatures() {
    aiFeatures.value = !aiFeatures.value;
  }

  /// Toggle Data Preferences consent
  void toggleDataPreferences() {
    dataPreferences.value = !dataPreferences.value;
  }

  /// Show delete confirmation dialog
  void showDeleteConfirmation() {
    showDeleteConfirm.value = true;
  }

  /// Hide delete confirmation dialog
  void hideDeleteConfirmation() {
    showDeleteConfirm.value = false;
  }

  /// Handle data deletion request
  void confirmDataDeletion() {
    // TODO: Implement actual data deletion API call
    // Example: await DataService.deleteUserData();

    _safeSnackbar(
      title: 'Data Deletion Requested',
      message: 'You will receive a confirmation email within 24 hours.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 5),
    );

    hideDeleteConfirmation();

    // TODO: Optionally log user out and navigate to login
    // Get.offAllNamed(AppRoutes.login);
  }

  /// Continue to app
  Future<void> continueToApp() async {
    try {
      isLoading.value = true;

      // Get token from storage
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        _safeSnackbar(
          title: 'Error',
          message: 'Authentication token not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
        isLoading.value = false;
        return;
      }

      // Call consent API
      final response = await _consentRepository.createConsent(
        token: token,
        isAiFeatures: aiFeatures.value ? 1 : 0,
        isDataPreferences: dataPreferences.value ? 1 : 0,
        isDeleteMyData: 0, // Default to 0, deletion is handled separately
      );

      if (response.isSuccess) {
        // Save consent preferences locally
        saveConsents();

        // Navigate to goal settings screen (skip snackbar since we're navigating)
        // The next screen will show success if needed
        await Future.delayed(const Duration(milliseconds: 300));
        Get.offAllNamed('/goal-settings');
      } else {
        // Show error message (we're staying on this screen)
        _safeSnackbar(
          title: 'Error',
          message: response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint('❌ Continue to App Error: $e');
      _safeSnackbar(
        title: 'Error',
        message: 'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Save consent preferences
  void saveConsents() {
    // Save to local storage for quick access
    PreferencesService.getStorage().write('ai_features_consent', aiFeatures.value);
    PreferencesService.getStorage().write('data_preferences_consent', dataPreferences.value);

    debugPrint('✅ Consent saved:');
    debugPrint('  - AI Features: ${aiFeatures.value}');
    debugPrint('  - Data Preferences: ${dataPreferences.value}');
  }

  /// Get consent summary
  String getConsentSummary() {
    int enabledCount = 0;
    if (aiFeatures.value) enabledCount++;
    if (dataPreferences.value) enabledCount++;
    return '$enabledCount of 2 preferences enabled';
  }
}