import 'dart:convert';
import 'package:get/get.dart';

import '../../../core/services/health_sync_service.dart';
import '../../../core/services/preferences_service.dart';




class DashboardController extends GetxController {
  final HealthSyncService _healthService = HealthSyncService();
  
  // Expose healthService for sync_status_section
  HealthSyncService get healthService => _healthService;

  // Reactive state variables
  final healthMetrics = Rx<HealthMetrics>(HealthSyncService().getMetrics());
  final isSyncing = false.obs;
  final waterIntake = 0.0.obs; // in Liters - will be updated from HealthKit
  final weight = 0.0.obs; // in kg - will be updated from HealthKit
  final previousWeight = 0.0.obs; // in kg
  
  // Goals loaded from storage/API
  final weightGoal = 75.0.obs; // in kg
  final stepGoal = 10000.obs; // steps per day
  final waterGoal = 2.5.obs; // in Liters
  final sleepGoal = 8.0.obs; // in hours

  // Modal visibility states
  final showWeightModal = false.obs;
  final showStepsModal = false.obs;
  final showSleepModal = false.obs;
  final showHydrationModal = false.obs;

  // Input field states
  final weightInput = ''.obs;
  final stepsInput = ''.obs;
  final sleepInput = ''.obs;
  final hydrationInput = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadGoals(); // Load goals first to initialize weight
    
    // Subscribe to health service updates BEFORE initializing
    _healthService.subscribe((metrics) {
      healthMetrics.value = metrics;
      isSyncing.value = metrics.syncStatus == SyncStatus.syncing;
      
      // Update weight from HealthKit if available
      if (metrics.weight != null && metrics.weight! > 0) {
        // Only update previousWeight if current weight is different
        if (weight.value > 0 && (weight.value - metrics.weight!).abs() > 0.1) {
          previousWeight.value = weight.value;
        }
        weight.value = metrics.weight!;
      }
      // If weight is still 0 after HealthKit sync, use currentWeight from goals as fallback
      if (weight.value == 0 && metrics.syncStatus == SyncStatus.success) {
        final savedGoals = PreferencesService.getStorage().read('userGoals');
        if (savedGoals != null) {
          try {
            final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
            final currentWeightStr = goalsMap['currentWeight']?.toString();
            if (currentWeightStr != null) {
              final currentWeight = double.tryParse(currentWeightStr);
              if (currentWeight != null && currentWeight > 0) {
                weight.value = currentWeight;
                previousWeight.value = currentWeight;
              }
            }
          } catch (e) {
            // Ignore errors
          }
        }
      }
      
      // Update water intake from HealthKit if available
      // Note: If waterIntake is 0 or null, that's correct - it means no water logged today in HealthKit
      if (metrics.waterIntake != null) {
        waterIntake.value = metrics.waterIntake!;
      }
    });
    
    // Initialize HealthKit and subscribe to updates
    _healthService.initialize().then((success) {
      if (success) {
        _healthService.syncHealthData();
      }
    });
  }
  
  /// Load goals from storage
  void _loadGoals() {
    try {
      final savedGoals = PreferencesService.getStorage().read('userGoals');
      if (savedGoals != null) {
        final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
        
        // Load target weight
        final targetWeightStr = goalsMap['targetWeight']?.toString() ?? '75';
        weightGoal.value = double.tryParse(targetWeightStr) ?? 75.0;
        
        // Load step goal
        final stepGoalStr = goalsMap['stepGoal']?.toString() ?? '10000';
        stepGoal.value = int.tryParse(stepGoalStr) ?? 10000;
        
        // Load water intake goal (remove 'L' suffix if present)
        final waterStr = goalsMap['waterIntake']?.toString() ?? '2.5';
        final waterValue = waterStr.replaceAll('L', '').replaceAll('l', '').trim();
        waterGoal.value = double.tryParse(waterValue) ?? 2.5;
        
        // Load sleep goal (handle ranges like "7-8" by taking average)
        final sleepStr = goalsMap['sleepHours']?.toString() ?? '8';
        if (sleepStr.contains('-')) {
          final parts = sleepStr.split('-');
          final start = double.tryParse(parts[0].trim()) ?? 8.0;
          final end = parts.length > 1 ? (double.tryParse(parts[1].trim()) ?? 8.0) : start;
          sleepGoal.value = (start + end) / 2;
        } else {
          sleepGoal.value = double.tryParse(sleepStr) ?? 8.0;
        }
        
        // Initialize weight and previousWeight from currentWeight if available
        // This ensures weight is displayed even if HealthKit doesn't have data
        final currentWeightStr = goalsMap['currentWeight']?.toString();
        if (currentWeightStr != null) {
          final currentWeight = double.tryParse(currentWeightStr);
          if (currentWeight != null && currentWeight > 0) {
            weight.value = currentWeight;
            previousWeight.value = currentWeight;
            print('📊 Weight initialized from goals: $currentWeight kg');
          }
        }
      }
    } catch (e) {
      Get.printError(info: 'Error loading goals: $e');
    }
  }

  @override
  void onClose() {
    _healthService.dispose();
    super.onClose();
  }

  // Manual sync handler
  Future<void> handleManualSync() async {
    isSyncing.value = true;
    await _healthService.syncHealthData();
  }

  // --- Manual Entry Handlers (CORRECTED AGAIN) ---

  void handleWeightSubmit() {
    final value = double.tryParse(weightInput.value);
    if (value != null && value > 0 && value < 300) {
      weight.value = value;
      weightInput.value = '';
      showWeightModal.value = false;
    }
  }

  void handleStepsSubmit() {
    final value = int.tryParse(stepsInput.value);
    if (value != null && value >= 0) {
      // CORRECT: Assign a new HealthMetrics object directly to .value
      final oldMetrics = healthMetrics.value;
      healthMetrics.value = HealthMetrics(
        steps: value, // New value
        sleepHours: oldMetrics.sleepHours, // Old value
        syncStatus: oldMetrics.syncStatus, // Old value
        lastSyncTime: oldMetrics.lastSyncTime, // Old value
        platform: oldMetrics.platform, // Old value
        weight: oldMetrics.weight, // Old value
        waterIntake: oldMetrics.waterIntake, // Old value
      );
      stepsInput.value = '';
      showStepsModal.value = false;
    }
  }

  void handleSleepSubmit() {
    final value = double.tryParse(sleepInput.value);
    if (value != null && value >= 0 && value <= 24) {
      // CORRECT: Assign a new HealthMetrics object directly to .value
      final oldMetrics = healthMetrics.value;
      healthMetrics.value = HealthMetrics(
        steps: oldMetrics.steps, // Old value
        sleepHours: value, // New value
        syncStatus: oldMetrics.syncStatus, // Old value
        lastSyncTime: oldMetrics.lastSyncTime, // Old value
        platform: oldMetrics.platform, // Old value
        weight: oldMetrics.weight, // Old value
        waterIntake: oldMetrics.waterIntake, // Old value
      );
      sleepInput.value = '';
      showSleepModal.value = false;
    }
  }

  void handleHydrationSubmit() {
    final value = double.tryParse(hydrationInput.value);
    if (value != null && value >= 0) {
      waterIntake.value = value;
      hydrationInput.value = '';
      showHydrationModal.value = false;
    }
  }

  // --- Calculated Getters ---
  String get weightTrend {
    final change = previousWeight.value - weight.value;
    if (change > 0.1) return 'down';
    if (change < -0.1) return 'up';
    return 'flat';
  }

  double get weightChange => previousWeight.value - weight.value;

  double get overallProgress {
    final stepsProgress = stepGoal.value > 0 
        ? (healthMetrics.value.steps / stepGoal.value) * 100 
        : 0;
    final sleepProgress = sleepGoal.value > 0 
        ? (healthMetrics.value.sleepHours / sleepGoal.value) * 100 
        : 0;
    final waterProgress = waterGoal.value > 0 
        ? (waterIntake.value / waterGoal.value) * 100 
        : 0;
    final weightProgress = weightGoal.value > 0 
        ? (1 - (weight.value - weightGoal.value) / weightGoal.value) * 100 
        : 0;
    return (stepsProgress + sleepProgress + waterProgress + weightProgress) / 4;
  }

  String get formatLastSync {
    if (healthMetrics.value.lastSyncTime == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(healthMetrics.value.lastSyncTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}