import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/model/today_screen.dart';
import '../../../../app/routes/app_routes.dart';

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

  // Pillars data
  List<Pillar> get pillars => [
    Pillar(
      name: 'Nutrition',
      status: PillarStatus.borderline,
      detail: 'Borderline',
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

