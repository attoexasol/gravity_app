import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../core/services/preferences_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class GoalSettingsController extends GetxController {
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
  final GoalsRepository _goalsRepository = GoalsRepository();

  // Loading state
  final RxBool isLoading = false.obs;

  // Text editing controllers for weight goals
  final currentWeightController = TextEditingController();
  final targetWeightController = TextEditingController();

  // Text editing controllers for activity and wellness
  final stepGoalController = TextEditingController(text: '12000');
  final waterIntakeController = TextEditingController(text: '3');
  final sleepHoursController = TextEditingController(text: '7-8');

  // Reactive variables
  final RxBool isFormValid = false.obs;
  final RxString weightDiff = ''.obs; // NEW FIX
  
  // AI Interaction Tone
  final RxString selectedAiTone = ''.obs;
  final RxString selectedExample = ''.obs;
  
  // Available AI tones
  static const List<String> aiTones = [
    'Encouraging',
    'Faith centered',
    'Tough love',
    'Balanced tone',
  ];
  
  // Example conversations for each tone
  static const Map<String, List<String>> toneExamples = {
    'Encouraging': [
      "You're growing. Keep going.",
      "Every small choice today matters.",
      "You showed discipline — well done.",
    ],
    'Faith centered': [
      "Grace covers your journey — take your next step with peace.",
      "Center your day. Breathe. You're not walking alone.",
      "Your body and your spirit deserve this moment of alignment.",
    ],
    'Tough love': [
      "You know what you want — let's act like it today.",
      "You're capable of more discipline than you showed yesterday.",
      "This setback isn't the end. Stand up, reset, and continue.",
    ],
    'Balanced tone': [
      "Let's aim for a 14-hour fast tonight.",
      "Drink one more glass of water before bed.",
      "Walk for five minutes to reset your energy.",
    ],
  };
  
  /// Get a random example for a tone
  String _getRandomExampleForTone(String tone) {
    final examples = toneExamples[tone];
    if (examples == null || examples.isEmpty) return '';
    // Use Random to select a random example
    final random = Random();
    final index = random.nextInt(examples.length);
    return examples[index];
  }
  
  void selectAiTone(String tone) {
    selectedAiTone.value = tone;
    // Select a random example when tone is selected
    selectedExample.value = _getRandomExampleForTone(tone);
  }

  /// Get the currently selected example
  String getExampleForTone() {
    return selectedExample.value;
  }

  /// Map UI tone values to API-expected format
  /// Converts UI display names to API format (lowercase with underscores)
  String _mapToneToApiFormat(String uiTone) {
    // Map UI values to API format
    // UI: "Encouraging" -> API: "encouraging" or "motivational" (adjust based on backend)
    // UI: "Faith centered" -> API: "faith_centered"
    // UI: "Tough love" -> API: "tough_love"
    // UI: "Balanced tone" -> API: "balanced_tone"
    
    // Convert to lowercase and replace spaces with underscores
    return uiTone.toLowerCase().replaceAll(' ', '_');
  }

  @override
  void onInit() {
    super.onInit();

    // Add listeners to validate form & update weight difference
    currentWeightController.addListener(_validateForm);
    targetWeightController.addListener(_validateForm);

    stepGoalController.addListener(_validateForm);
    waterIntakeController.addListener(_validateForm);
    sleepHoursController.addListener(_validateForm);
  }

  @override
  void onClose() {
    // Remove listeners before disposing to prevent accessing disposed controllers
    currentWeightController.removeListener(_validateForm);
    targetWeightController.removeListener(_validateForm);
    stepGoalController.removeListener(_validateForm);
    waterIntakeController.removeListener(_validateForm);
    sleepHoursController.removeListener(_validateForm);
    
    currentWeightController.dispose();
    targetWeightController.dispose();
    stepGoalController.dispose();
    waterIntakeController.dispose();
    sleepHoursController.dispose();
    super.onClose();
  }

  /// Validate form and update reactive variables
  void _validateForm() {
    // Check if controller is still mounted before accessing controllers
    if (!isClosed) {
      isFormValid.value =
          currentWeightController.text.isNotEmpty &&
              targetWeightController.text.isNotEmpty &&
              stepGoalController.text.isNotEmpty &&
              waterIntakeController.text.isNotEmpty &&
              sleepHoursController.text.isNotEmpty;

      // Update weight difference reactively
      weightDiff.value = getWeightDifference();
    }
  }

  /// Weight Difference Logic
  String getWeightDifference() {
    // Check if controller is still mounted before accessing controllers
    if (isClosed) return '';
    
    final current = double.tryParse(currentWeightController.text);
    final target = double.tryParse(targetWeightController.text);

    if (current == null || target == null) return '';

    final difference = (target - current).abs();
    final direction = target < current ? 'lose' : 'gain';

    return 'Goal: $direction ${difference.toStringAsFixed(1)} kg';
  }

  /// Save goals and continue
  Future<void> saveGoalsAndContinue() async {
    if (!isFormValid.value) {
      _safeSnackbar(
        title: 'Incomplete Form',
        message: 'Please fill in all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

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
      return;
    }

    try {
      isLoading.value = true;

      // Prepare water intake with "L" suffix
      final waterIntake = waterIntakeController.text.trim();
      final waterIntakeWithUnit = waterIntake.endsWith('L') || waterIntake.endsWith('l')
          ? waterIntake
          : '$waterIntake L';

      // Prepare AI tone - map UI value to API format
      // UI options: "Encouraging", "Faith centered", "Tough love", "Balanced tone"
      // Maps to API format: "encouraging", "faith_centered", "tough_love", "balanced_tone"
      final aiTone = _mapToneToApiFormat(selectedAiTone.value);

      // Call API to create goals
      final response = await _goalsRepository.createGoals(
        token: token,
        currentWeight: currentWeightController.text.trim(),
        targetWeight: targetWeightController.text.trim(),
        stepGoal: stepGoalController.text.trim(),
        dailyWaterIntake: waterIntakeWithUnit,
        sleepHours: sleepHoursController.text.trim(),
        aiTone: aiTone,
      );

      if (response.isSuccess) {
        // Mark first-time setup as completed when goals are successfully saved
        // This is the ONLY place where first-time setup should be marked as completed
        // Flow: Sign up → Login → Goal Settings (first time, this method) → Dashboard (subsequent)
        await PreferencesService.setFirstTimeSetupCompleted(true);
        debugPrint('✅ First-time setup marked as completed');

        // Write goals to local storage so dashboard Weight Journey shows starting weight immediately
        // (Dashboard reads userGoals and starting_weight on load; without this, it only appears after re-login.)
        final waterValue = waterIntake.endsWith('L') || waterIntake.endsWith('l')
            ? waterIntake.replaceAll('L', '').replaceAll('l', '').trim()
            : waterIntake.trim();
        final goalsMap = <String, String>{
          'currentWeight': currentWeightController.text.trim(),
          'targetWeight': targetWeightController.text.trim(),
          'stepGoal': stepGoalController.text.trim(),
          'waterIntake': waterValue,
          'sleepHours': sleepHoursController.text.trim(),
          'aiTone': aiTone,
        };
        PreferencesService.getStorage().write('userGoals', jsonEncode(goalsMap));
        final currentWeightKg = double.tryParse(currentWeightController.text.trim());
        if (currentWeightKg != null && currentWeightKg > 0) {
          await PreferencesService.saveStartingWeight(currentWeightKg);
        }
        debugPrint('✅ Goals written to local storage for immediate dashboard display');
        // If dashboard is already in memory, refresh so Weight Journey shows starting weight immediately
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().notifyGoalsChanged();
        }

        // Navigate to dashboard after successful API call (skip snackbar since we're navigating)
        await Future.delayed(const Duration(milliseconds: 300));
        Get.offAllNamed(AppRoutes.home);
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
      debugPrint('❌ Save Goals Error: $e');
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
}
