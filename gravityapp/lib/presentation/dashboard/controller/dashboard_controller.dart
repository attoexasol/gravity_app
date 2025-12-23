import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:get/get.dart';

import '../../../core/services/health_sync_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/repositories/user_gravity_repository.dart';
import '../../../data/model/user_gravity_entry.dart';
import '../../../data/model/api_response.dart';

class DashboardController extends GetxController {
  final HealthSyncService _healthService = HealthSyncService();
  final UserGravityRepository _gravityRepository = UserGravityRepository();
  
  // Expose healthService for sync_status_section
  HealthSyncService get healthService => _healthService;

  // Reactive state variables
  final healthMetrics = Rx<HealthMetrics>(HealthSyncService().getMetrics());
  final isSyncing = false.obs;
  final waterIntake = 0.0.obs; // in Liters - will be updated from HealthKit
  final weight = 0.0.obs; // in kg - will be updated from HealthKit
  final previousWeight = 0.0.obs; // in kg

  // Today's entry from DB
  final todayEntry = Rx<UserGravityEntry?>(null);
  final todayEntryId = Rx<int?>(null);
  final isDbLoaded = false.obs; // Track if DB load was attempted

  // Throttle for saving to prevent multiple rapid API calls
  DateTime? _lastSaveTime;
  bool _isSavingGravity = false;
  
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
    
    // Load today's entry from DB
    loadTodayFromDb();
    
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

      // When sync finishes successfully, save to DB
      if (metrics.syncStatus == SyncStatus.success) {
        // Determine data source based on platform
        final dataSource = _getDataSourceFromPlatform(metrics.platform);
        if (dataSource != null) {
          // Debounce: only save if last save was more than 3 seconds ago
          final now = DateTime.now();
          if (_lastSaveTime == null || 
              now.difference(_lastSaveTime!).inSeconds >= 3) {
            upsertTodayGravity(dataSource: dataSource);
          }
        }
      }
    });
    
    // Initialize HealthKit and subscribe to updates
    _healthService.initialize().then((success) {
      if (success) {
        _healthService.syncHealthData();
      }
    });
  }

  /// Get today's date string in yyyy-MM-dd format
  String get _todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get data source string from platform
  String? _getDataSourceFromPlatform(HealthPlatform platform) {
    if (kIsWeb) return null;
    if (Platform.isIOS) return 'health_connect';
    if (Platform.isAndroid) return 'google_fit';
    return null;
  }

  /// Load today's entry from database
  Future<void> loadTodayFromDb() async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        Get.printError(info: 'API token not found, cannot load today\'s entry');
        isDbLoaded.value = true; // Mark as attempted
        return;
      }

      final response = await _gravityRepository.getAllUserGravity(apiToken: apiToken);
      isDbLoaded.value = true;

      if (response.isSuccess && response.data != null) {
        final todayStr = _todayString;
        final todayEntryFound = response.data!.firstWhere(
          (entry) => entry.date == todayStr,
          orElse: () => UserGravityEntry(date: ''),
        );

        if (todayEntryFound.date.isNotEmpty) {
          todayEntry.value = todayEntryFound;
          todayEntryId.value = todayEntryFound.id;

          // Populate UI values from DB entry (DB is source of truth when available)
          final oldMetrics = healthMetrics.value;
          healthMetrics.value = HealthMetrics(
            steps: todayEntryFound.steps ?? oldMetrics.steps,
            sleepHours: todayEntryFound.sleepHours ?? oldMetrics.sleepHours,
            syncStatus: oldMetrics.syncStatus, // Preserve sync status
            lastSyncTime: oldMetrics.lastSyncTime, // Preserve last sync time
            platform: oldMetrics.platform, // Preserve platform
            weight: todayEntryFound.weight ?? oldMetrics.weight,
            waterIntake: todayEntryFound.hydrationLiters ?? oldMetrics.waterIntake,
          );
          
          // Update weight separately if available
          if (todayEntryFound.weight != null && todayEntryFound.weight! > 0) {
            weight.value = todayEntryFound.weight!;
          }
          
          // Update water intake separately if available
          if (todayEntryFound.hydrationLiters != null) {
            waterIntake.value = todayEntryFound.hydrationLiters!;
          }

          Get.printInfo(info: '✅ Loaded today\'s entry from DB: ${todayEntryFound.id}');
        } else {
          Get.printInfo(info: 'ℹ️ No entry found for today in DB');
        }
      } else {
        Get.printError(info: 'Failed to load entries: ${response.message}');
      }
    } catch (e) {
      Get.printError(info: 'Error loading today\'s entry: $e');
      isDbLoaded.value = true; // Mark as attempted even on error
    }
  }

  /// Upsert (create or update) today's gravity entry
  Future<void> upsertTodayGravity({required String dataSource}) async {
    // Prevent multiple simultaneous saves
    if (_isSavingGravity) {
      Get.printInfo(info: '⏳ Save already in progress, skipping...');
      return;
    }

    try {
      _isSavingGravity = true;
      _lastSaveTime = DateTime.now();

      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        Get.snackbar(
          'Session Expired',
          'Please login again',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final todayStr = _todayString;
      final currentWeight = weight.value > 0 ? weight.value : null;
      final currentSteps = healthMetrics.value.steps;
      final currentSleepHours = healthMetrics.value.sleepHours;
      final currentHydration = waterIntake.value > 0 ? waterIntake.value : null;

      // Log the data being sent to API
      Get.printInfo(info: '📤 Preparing to call /create_user_gravity API:');
      Get.printInfo(info: '   Data Source: $dataSource');
      Get.printInfo(info: '   Weight: $currentWeight kg');
      Get.printInfo(info: '   Steps: $currentSteps');
      Get.printInfo(info: '   Sleep Hours: $currentSleepHours');
      Get.printInfo(info: '   Hydration: $currentHydration L');
      Get.printInfo(info: '   Date: $todayStr');

      ApiResponse<UserGravityEntry> response;

      if (todayEntryId.value != null) {
        // Update existing entry
        Get.printInfo(info: '🔄 Updating existing entry (ID: ${todayEntryId.value})');
        response = await _gravityRepository.updateUserGravity(
          id: todayEntryId.value!,
          apiToken: apiToken,
          weight: currentWeight,
          steps: currentSteps > 0 ? currentSteps : null,
          sleepHours: currentSleepHours > 0 ? currentSleepHours : null,
          hydrationLiters: currentHydration,
          nutration: 'good',
          dataSource: dataSource,
          date: todayStr,
        );
      } else {
        // Create new entry
        Get.printInfo(info: '➕ Creating new entry');
        response = await _gravityRepository.createUserGravity(
          apiToken: apiToken,
          weight: currentWeight,
          steps: currentSteps > 0 ? currentSteps : null,
          sleepHours: currentSleepHours > 0 ? currentSleepHours : null,
          hydrationLiters: currentHydration,
          nutration: 'good',
          dataSource: dataSource,
          date: todayStr,
        );
      }

      if (response.isSuccess && response.data != null) {
        todayEntry.value = response.data;
        todayEntryId.value = response.data!.id;
        Get.printInfo(info: '✅ Saved today\'s gravity entry to DB (ID: ${response.data!.id})');
      } else {
        Get.snackbar(
          'Save Failed',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.printError(info: 'Failed to save: ${response.message}');
      }
    } catch (e) {
      Get.snackbar(
        'Save Failed',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.printError(info: 'Error saving gravity entry: $e');
    } finally {
      _isSavingGravity = false;
    }
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
    // Don't dispose the health service since it's a singleton
    // and may be used by other controllers
    super.onClose();
  }

  // Manual sync handler
  Future<void> handleManualSync() async {
    isSyncing.value = true;
    await _healthService.syncHealthData();
    // Note: upsertTodayGravity will be called automatically when syncStatus becomes success
    // via the subscription in onInit
  }

  // --- Manual Entry Handlers (CORRECTED AGAIN) ---

  Future<void> handleWeightSubmit() async {
    final value = double.tryParse(weightInput.value);
    if (value != null && value > 0 && value < 300) {
      // Update local state immediately (optimistic update)
      weight.value = value;
      weightInput.value = '';
      showWeightModal.value = false;
      
      // Save to DB using manual entry API
      await _saveManualEntry(type: 'weight', value: value.toString());
    }
  }

  Future<void> handleStepsSubmit() async {
    final value = int.tryParse(stepsInput.value);
    if (value != null && value >= 0) {
      // Update local state immediately (optimistic update)
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
      
      // Save to DB using manual entry API
      await _saveManualEntry(type: 'steps', value: value.toString());
    }
  }

  Future<void> handleSleepSubmit() async {
    final value = double.tryParse(sleepInput.value);
    if (value != null && value >= 0 && value <= 24) {
      // Update local state immediately (optimistic update)
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
      
      // Save to DB using manual entry API
      await _saveManualEntry(type: 'sleep_hours', value: value.toString());
    }
  }

  Future<void> handleHydrationSubmit() async {
    final value = double.tryParse(hydrationInput.value);
    if (value != null && value >= 0) {
      // Update local state immediately (optimistic update)
      waterIntake.value = value;
      hydrationInput.value = '';
      showHydrationModal.value = false;
      
      // Save to DB using manual entry API
      await _saveManualEntry(type: 'hydration', value: value.toString());
    }
  }

  /// Save manual entry using the create_manual_user_gravity API
  Future<void> _saveManualEntry({required String type, required String value}) async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        Get.snackbar(
          'Error',
          'Session expired. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFE53935),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final todayStr = _todayString;
      
      debugPrint('💾 Saving manual entry:');
      debugPrint('   - Type: $type');
      debugPrint('   - Value: $value');
      debugPrint('   - Date: $todayStr');

      final response = await _gravityRepository.createManualUserGravity(
        apiToken: apiToken,
        date: todayStr,
        type: type,
        value: value,
      );

      if (response.isSuccess) {
        debugPrint('✅ Manual entry saved successfully: ${response.message}');
        
        // Show success message
        Get.snackbar(
          'Success',
          response.message.isNotEmpty ? response.message : 'Data saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Reload today's entry from DB to get updated data
        await loadTodayFromDb();
      } else {
        debugPrint('❌ Failed to save manual entry: ${response.message}');
        Get.snackbar(
          'Error',
          response.message.isNotEmpty ? response.message : 'Failed to save data',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFE53935),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving manual entry: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
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