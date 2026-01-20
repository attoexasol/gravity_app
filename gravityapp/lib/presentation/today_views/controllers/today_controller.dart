import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/model/today_screen.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../data/repositories/ai_coach_repository.dart';
import '../../../../core/services/preferences_service.dart';

class TodayController extends GetxController {
  // Weight data
  final RxDouble startingWeight = 85.0.obs;
  final RxDouble currentWeight = 79.0.obs;
  final RxDouble goalWeight = 71.5.obs;

  // Reflection
  final RxString reflection = ''.obs;
  
  // Text controllers
  late final TextEditingController reflectionController;
  late final TextEditingController weightController;
  
  // Weigh-in modal data
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Modals
  final RxBool showWeighInModal = false.obs;
  final RxBool showGoalsModal = false.obs;

  // Nutrition data
  final RxInt totalNutrition = 0.obs; // Total daily calories
  final RxBool isLoadingNutrition = false.obs;
  final RxString nutritionError = ''.obs;

  // Repository
  final AiCoachRepository _aiCoachRepository = AiCoachRepository();

  // Navigation guard to prevent multiple rapid calls
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
    reflectionController = TextEditingController();
    weightController = TextEditingController(text: currentWeight.value.toString());
    
    // Listen to reflection changes
    reflectionController.addListener(() {
      reflection.value = reflectionController.text;
    });

    // Fetch nutrition data on screen load
    fetchNutritionData();
  }

  @override
  void onClose() {
    reflectionController.dispose();
    weightController.dispose();
    super.onClose();
  }

  // Calculated values
  double get totalLossGoal => startingWeight.value - goalWeight.value; // 13.5 kg
  double get currentLoss => startingWeight.value - currentWeight.value; // 6 kg
  double get progressPercentage => (currentLoss / totalLossGoal) * 100;

  // Format date for API (YY-MM-dd format, e.g., "26-01-19" for January 19, 2026)
  String _formatDateForApi(DateTime date) {
    final year = date.year.toString().substring(2); // Last 2 digits of year
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // Fetch nutrition data from API
  Future<void> fetchNutritionData() async {
    try {
      isLoadingNutrition.value = true;
      nutritionError.value = '';

      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        nutritionError.value = 'No authentication token';
        isLoadingNutrition.value = false;
        return;
      }

      // Use current date (today)
      final today = DateTime.now();
      final dayString = _formatDateForApi(today);

      final response = await _aiCoachRepository.getDayWiseNutrition(
        apiToken: apiToken,
        day: dayString,
      );

      if (response.isSuccess && response.data != null) {
        // API successfully returned data
        // The repository defaults total_nutration to 0 if null, so we always get a number
        final totalNutritionValue = response.data!['total_nutration'] as int? ?? 0;
        
        // If API succeeds, we have valid data (even if it's 0 calories)
        // Clear error FIRST to ensure UI updates correctly
        nutritionError.value = '';
        // Then set the value
        totalNutrition.value = totalNutritionValue;
        debugPrint('✅ Nutrition data loaded: $totalNutritionValue calories (error cleared)');
      } else {
        // API failed or returned error - no data available
        totalNutrition.value = 0;
        nutritionError.value = response.message.isNotEmpty ? response.message : 'Failed to load nutrition data';
        debugPrint('⚠️ Failed to load nutrition data: ${response.message}');
      }
    } catch (e) {
      nutritionError.value = 'Failed to load nutrition data';
      totalNutrition.value = 0;
      debugPrint('❌ Error fetching nutrition data: $e');
    } finally {
      isLoadingNutrition.value = false;
    }
  }

  // Get nutrition display text
  String get nutritionDisplayText {
    if (isLoadingNutrition.value) {
      return 'Loading...';
    }
    // If there's an error (no data, failed to load, etc.), show "Borderline"
    if (nutritionError.value.isNotEmpty) {
      return 'Borderline';
    }
    // If we have valid data (including 0 calories), show the calories
    // Note: If totalNutrition is 0 and there's no error, it means the API
    // successfully returned 0 calories (user logged 0 calories)
    // If there's an error, we already returned "Borderline" above
    return '${totalNutrition.value} cal';
  }

  // Pillars data
  List<Pillar> get pillars => [
    Pillar(
      name: 'Nutrition',
      status: PillarStatus.borderline,
      detail: nutritionDisplayText, // Dynamic detail with calorie count
      icon: Icons.restaurant,
    ),
    Pillar(
      name: 'Hydration',
      status: PillarStatus.onTrack,
      detail: 'On track',
      icon: Icons.water_drop,
    ),
    Pillar(
      name: 'Sleep',
      status: PillarStatus.logged,
      detail: 'Logged (6h 45m)',
      icon: Icons.nightlight_round,
    ),
    Pillar(
      name: 'Steps',
      status: PillarStatus.missed,
      detail: 'Missed',
      icon: Icons.directions_walk,
    ),
    Pillar(
      name: 'Fasting window',
      status: PillarStatus.onTrack,
      detail: 'Stayed within',
      icon: Icons.favorite,
    ),
    Pillar(
      name: 'Weigh-in',
      status: PillarStatus.notScheduled,
      detail: 'Not scheduled',
      icon: Icons.monitor_weight,
    ),
  ];

  // Get current date string
  String get currentDateString {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE · MMM d', 'en_US');
    return formatter.format(now);
  }

  // Get pillar color
  Color getPillarColor(PillarStatus status) {
    switch (status) {
      case PillarStatus.onTrack:
      case PillarStatus.logged:
        return const Color(0xFF00B8A9);
      case PillarStatus.borderline:
        return const Color(0xFFD4AF37);
      case PillarStatus.missed:
        return const Color(0xFFE57373);
      case PillarStatus.notScheduled:
        return const Color(0xFF9CA3AF);
    }
  }

  // Get pillar status icon
  IconData getPillarStatusIcon(PillarStatus status) {
    switch (status) {
      case PillarStatus.onTrack:
      case PillarStatus.logged:
        return Icons.check_circle;
      case PillarStatus.borderline:
        return Icons.warning;
      case PillarStatus.missed:
        return Icons.cancel;
      case PillarStatus.notScheduled:
        return Icons.radio_button_unchecked;
    }
  }

  void updateReflection(String value) {
    reflection.value = value;
  }

  void clearReflection() {
    reflectionController.clear();
    reflection.value = '';
  }

  void openWeighInModal() {
    weightController.text = currentWeight.value.toString();
    selectedDate.value = DateTime.now();
    showWeighInModal.value = true;
  }

  void closeWeighInModal() {
    showWeighInModal.value = false;
  }

  void saveWeighIn() {
    final weightValue = double.tryParse(weightController.text);
    if (weightValue != null && weightValue > 0 && weightValue < 300) {
      currentWeight.value = weightValue;
      print('Saving weight: $weightValue, Date: ${selectedDate.value}');
      // Here you would save to your data store
      closeWeighInModal();
    } else {
      // Show error message
      Get.snackbar(
        'Invalid Weight',
        'Please enter a valid weight between 0 and 300 kg',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void openGoalsModal() {
    showGoalsModal.value = true;
  }

  void closeGoalsModal() {
    showGoalsModal.value = false;
  }

  void handleDone() {
    // Prevent multiple rapid calls
    if (_isNavigating) {
      return;
    }
    
    _isNavigating = true;
    
    // Save reflection
    print('Saving reflection: ${reflection.value}');
    
    // Use a small delay to ensure state is saved, then navigate
    Future.delayed(const Duration(milliseconds: 100), () {
      _navigateBack();
    });
  }

  void onBack() {
    // Prevent multiple rapid calls
    if (_isNavigating) {
      return;
    }
    
    _isNavigating = true;
    _navigateBack();
  }

  void _navigateBack() {
    try {
      // Use Navigator directly to avoid GetX snackbar controller issues
      final context = Get.context;
      if (context != null) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          // Use Navigator.pop() instead of Get.back() to avoid snackbar issues
          navigator.pop();
        } else {
          // If no route to go back to, navigate to home
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        // If no context, navigate to home as fallback
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      // If navigation fails, navigate to home as fallback
      print('Navigation error: $e');
      try {
        Get.offAllNamed(AppRoutes.home);
      } catch (e2) {
        print('Fallback navigation also failed: $e2');
      }
    } finally {
      // Reset navigation flag after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigating = false;
      });
    }
  }

  void onNavigateToHistory() {
    Get.toNamed(AppRoutes.weightHistory);
  }
}

