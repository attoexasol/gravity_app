import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import '../../messages/controllers/messages_controllers.dart';

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
  final mealsEaten = 0.obs; // Number of meals eaten today (0-2)

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
  final fastingInput = ''.obs;

  // Scroll controller for dashboard view
  final ScrollController dashboardScrollController = ScrollController();

  // Time ticker for forcing relative time updates
  final timeTicker = 0.obs;
  Timer? _timeTickerTimer;
  Timer? _healthSyncTimer;
  
  // App lifecycle observer for syncing when app resumes
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void onInit() {
    super.onInit();
    _loadGoals(); // Load goals first to initialize weight
    
    // Listen for goal changes in storage (when updated from settings)
    _setupGoalsListener();
    
    // Load today's entry from DB
    loadTodayFromDb();
    
    // Subscribe to health service updates BEFORE initializing
    _healthService.subscribe((metrics) {
      // Always update healthMetrics to trigger UI rebuild
      healthMetrics.value = metrics;
      isSyncing.value = metrics.syncStatus == SyncStatus.syncing;
      
      // Debug: Log when metrics update
      debugPrint('🔄 Health metrics updated: Steps=${metrics.steps}, Sleep=${metrics.sleepHours}, Water=${metrics.waterIntake}, Status=${metrics.syncStatus}');
      
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
      
      // Update water intake from HealthKit/Google Fit if available
      // Always update when sync is successful, even if value is 0 (means no water logged today)
      if (metrics.syncStatus == SyncStatus.success && metrics.platform != HealthPlatform.none) {
        // If sync was successful, always use the synced value (even if 0 or null)
        // null means error fetching, 0.0 means no data found
        waterIntake.value = metrics.waterIntake ?? 0.0;
        debugPrint('💧 Updated water intake from health sync: ${waterIntake.value} L (sync status: ${metrics.syncStatus}, platform: ${metrics.platform})');
      } else if (metrics.waterIntake != null) {
        // Update if we have any value (including 0) even if sync wasn't fully successful
        waterIntake.value = metrics.waterIntake!;
        debugPrint('💧 Updated water intake from metrics: ${waterIntake.value} L');
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

    // Force rebuild every 30 seconds for relative sync time
    _timeTickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      timeTicker.value++;
    });
    
    // Periodic health data sync every 2 minutes to refresh data after walking
    _healthSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      final currentMetrics = _healthService.getMetrics();
      // Only sync if not already syncing and health service is initialized
      if (currentMetrics.syncStatus != SyncStatus.syncing && 
          (currentMetrics.platform == HealthPlatform.apple || 
           currentMetrics.platform == HealthPlatform.google)) {
        debugPrint('🔄 Periodic health sync triggered');
        _healthService.syncHealthData();
      }
    });
    
    // Setup lifecycle observer to sync when app resumes
    _setupLifecycleObserver();
  }
  
  /// Setup app lifecycle observer to sync health data when app resumes
  void _setupLifecycleObserver() {
    _lifecycleObserver = AppLifecycleObserver(
      onPaused: () {
        debugPrint('📱 Dashboard: App paused');
      },
      onResumed: () {
        debugPrint('📱 Dashboard: App resumed - syncing health data and reloading goals');
        // Reload goals when app resumes (in case they were updated in settings)
        _loadGoals();
        
        final currentMetrics = _healthService.getMetrics();
        // Sync if health service is initialized and not already syncing
        if (currentMetrics.syncStatus != SyncStatus.syncing && 
            (currentMetrics.platform == HealthPlatform.apple || 
             currentMetrics.platform == HealthPlatform.google)) {
          _healthService.syncHealthData();
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }
  
  @override
  void onClose() {
    _timeTickerTimer?.cancel();
    _healthSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    dashboardScrollController.dispose();
    super.onClose();
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

          // Populate UI values from DB entry with priority logic
          // Priority: Health Sync (if successful) > Manual DB Entry > Default
          final oldMetrics = healthMetrics.value;
          final isHealthSyncSuccessful = oldMetrics.syncStatus == SyncStatus.success;
          final isDbEntryManual = todayEntryFound.dataSource == 'manual';
          final hasHealthSyncPlatform = oldMetrics.platform == HealthPlatform.apple || 
                                         oldMetrics.platform == HealthPlatform.google;
          
          // Determine final values with priority
          // Priority: If health sync was successful, always use health sync data (even if 0)
          // This ensures we show the most up-to-date data from Google Fit/Apple Health
          final finalSteps = (isHealthSyncSuccessful && hasHealthSyncPlatform)
              ? oldMetrics.steps  // Health sync wins (most recent, even if 0)
              : (todayEntryFound.steps ?? oldMetrics.steps);  // Use DB or fallback
          
          final finalSleep = (isHealthSyncSuccessful && hasHealthSyncPlatform)
              ? oldMetrics.sleepHours  // Health sync wins (most recent, even if 0)
              : (todayEntryFound.sleepHours ?? oldMetrics.sleepHours);  // Use DB or fallback
          
          final finalWater = (isHealthSyncSuccessful && hasHealthSyncPlatform)
              ? (oldMetrics.waterIntake ?? 0.0)  // Health sync wins (most recent, even if 0 or null)
              : (todayEntryFound.hydrationLiters ?? oldMetrics.waterIntake ?? 0.0);  // Use DB or fallback
          
          healthMetrics.value = HealthMetrics(
            steps: finalSteps,
            sleepHours: finalSleep,
            syncStatus: oldMetrics.syncStatus, // Preserve sync status
            lastSyncTime: oldMetrics.lastSyncTime, // Preserve last sync time
            platform: oldMetrics.platform, // Preserve platform
            weight: todayEntryFound.weight ?? oldMetrics.weight,
            waterIntake: finalWater,
          );
          
          debugPrint('📊 Merged data - Steps: $finalSteps (DB: ${todayEntryFound.steps}, Health: ${oldMetrics.steps}), Health sync active: $isHealthSyncSuccessful');
          
          // Update weight separately if available
          if (todayEntryFound.weight != null && todayEntryFound.weight! > 0) {
            weight.value = todayEntryFound.weight!;
          }
          
          // Update water intake separately if available
          // Only update from DB if health sync wasn't successful (to avoid overwriting fresh sync data)
          if (!isHealthSyncSuccessful && todayEntryFound.hydrationLiters != null) {
            waterIntake.value = todayEntryFound.hydrationLiters!;
          } else if (isHealthSyncSuccessful && hasHealthSyncPlatform) {
            // Use health sync value (even if 0)
            waterIntake.value = finalWater ?? 0.0;
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
      Get.printInfo(info: '📤 Preparing to ${todayEntryId.value != null ? "update" : "create"} gravity entry:');
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
  
  /// Setup listener for goal changes
  /// Real-time updates are handled via direct method calls from SettingsController
  /// This method is kept for app resume scenarios
  void _setupGoalsListener() {
    // No periodic checking needed - real-time updates via notifyGoalsChanged()
  }
  
  /// Public method to be called when goals are updated in settings
  /// This provides real-time goal updates without polling
  void notifyGoalsChanged() {
    debugPrint('🔄 Goals changed notification received - reloading immediately...');
    _loadGoals();
  }

  /// Load goals from storage
  /// This method is called on init and when goals are updated in settings
  void _loadGoals() {
    try {
      final savedGoals = PreferencesService.getStorage().read('userGoals');
      if (savedGoals != null) {
        final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
        
        // Load target weight (use targetWeight from goals)
        final targetWeightStr = goalsMap['targetWeight']?.toString() ?? '70';
        weightGoal.value = double.tryParse(targetWeightStr) ?? 70.0;
        
        // Load step goal (match settings default of 12000)
        final stepGoalStr = goalsMap['stepGoal']?.toString() ?? '12000';
        stepGoal.value = int.tryParse(stepGoalStr) ?? 12000;
        
        // Load water intake goal (remove 'L' suffix if present, match settings default of 3)
        final waterStr = goalsMap['waterIntake']?.toString() ?? '3';
        final waterValue = waterStr.replaceAll('L', '').replaceAll('l', '').trim();
        waterGoal.value = double.tryParse(waterValue) ?? 3.0;
        
        // Load sleep goal (handle ranges like "7-8" by taking average)
        final sleepStr = goalsMap['sleepHours']?.toString() ?? '7-8';
        if (sleepStr.contains('-')) {
          final parts = sleepStr.split('-');
          final start = double.tryParse(parts[0].trim()) ?? 7.0;
          final end = parts.length > 1 ? (double.tryParse(parts[1].trim()) ?? 8.0) : start;
          sleepGoal.value = (start + end) / 2;
        } else {
          sleepGoal.value = double.tryParse(sleepStr) ?? 7.5;
        }
        
        // Initialize weight and previousWeight from currentWeight if available
        // This ensures weight is displayed even if HealthKit doesn't have data
        final currentWeightStr = goalsMap['currentWeight']?.toString();
        if (currentWeightStr != null) {
          final currentWeight = double.tryParse(currentWeightStr);
          if (currentWeight != null && currentWeight > 0) {
            // Only update if weight is still 0 (not set from HealthKit)
            if (weight.value == 0) {
              weight.value = currentWeight;
              previousWeight.value = currentWeight;
              debugPrint('📊 Weight initialized from goals: $currentWeight kg');
            }
          }
        }
        
        debugPrint('✅ Goals loaded: Steps=$stepGoal, Water=$waterGoal, Sleep=$sleepGoal, TargetWeight=$weightGoal');
      } else {
        // Use consistent defaults if no goals are saved
        weightGoal.value = 70.0;
        stepGoal.value = 12000;
        waterGoal.value = 3.0;
        sleepGoal.value = 7.5;
        debugPrint('⚠️ No goals found in storage, using defaults');
      }
    } catch (e) {
      Get.printError(info: 'Error loading goals: $e');
      // Use safe defaults on error
      weightGoal.value = 70.0;
      stepGoal.value = 12000;
      waterGoal.value = 3.0;
      sleepGoal.value = 7.5;
    }
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

  Future<void> handleFastingSubmit() async {
    final value = int.tryParse(fastingInput.value);
    if (value != null && value >= 0 && value <= 2) {
      // Update local state immediately (optimistic update)
      mealsEaten.value = value;
      fastingInput.value = '';
      
      // Save to DB using manual entry API
      await _saveManualEntry(type: 'meals_eaten', value: value.toString());
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

  /// Calculate overall progress percentage
  /// Steps, Sleep, Water: (current / goal) * 100, capped at 100%
  /// Weight: Progress toward target weight (0% if above target, 100% if at/below target)
  double get overallProgress {
    // Steps progress: percentage of goal achieved, capped at 100%
    final stepsProgress = stepGoal.value > 0 
        ? ((healthMetrics.value.steps / stepGoal.value) * 100).clamp(0.0, 100.0)
        : 0;
    
    // Sleep progress: percentage of goal achieved, capped at 100%
    final sleepProgress = sleepGoal.value > 0 
        ? ((healthMetrics.value.sleepHours / sleepGoal.value) * 100).clamp(0.0, 100.0)
        : 0;
    
    // Water progress: percentage of goal achieved, capped at 100%
    final waterProgress = waterGoal.value > 0 
        ? ((waterIntake.value / waterGoal.value) * 100).clamp(0.0, 100.0)
        : 0;
    
    // Weight progress: Calculate based on current weight vs target weight
    // If we have both current and target weight, calculate progress
    // Progress = 100% if at or below target, decreasing as weight increases above target
    double weightProgress = 0;
    if (weight.value > 0 && weightGoal.value > 0) {
      // Get current weight from goals for comparison
      final savedGoals = PreferencesService.getStorage().read('userGoals');
      double? startingWeight;
      if (savedGoals != null) {
        try {
          final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
          final currentWeightStr = goalsMap['currentWeight']?.toString();
          if (currentWeightStr != null) {
            startingWeight = double.tryParse(currentWeightStr);
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
      
      // If we have starting weight, calculate progress toward target
      if (startingWeight != null && startingWeight > 0) {
        final totalWeightToLose = startingWeight - weightGoal.value;
        final weightLost = startingWeight - weight.value;
        
        if (totalWeightToLose > 0) {
          // Weight loss goal: progress = (weight lost / total to lose) * 100
          weightProgress = ((weightLost / totalWeightToLose) * 100).clamp(0.0, 100.0);
        } else if (totalWeightToLose < 0) {
          // Weight gain goal: progress = (weight gained / total to gain) * 100
          final totalWeightToGain = weightGoal.value - startingWeight;
          final weightGained = weight.value - startingWeight;
          weightProgress = ((weightGained / totalWeightToGain) * 100).clamp(0.0, 100.0);
        } else {
          // Already at target
          weightProgress = 100.0;
        }
      } else {
        // Fallback: simple comparison to target
        // If weight is at or below target, 100% progress
        // Otherwise, calculate based on how far above target
        if (weight.value <= weightGoal.value) {
          weightProgress = 100.0;
        } else {
          // Penalize being above target (but don't go negative)
          final excessWeight = weight.value - weightGoal.value;
          final maxExcess = weightGoal.value * 0.5; // Consider 50% above target as 0% progress
          weightProgress = ((1 - (excessWeight / maxExcess)) * 100).clamp(0.0, 100.0);
        }
      }
    }
    
    // Average of all four metrics
    final average = (stepsProgress + sleepProgress + waterProgress + weightProgress) / 4;
    return average.clamp(0.0, 100.0);
  }

  // String get formatLastSync {
  //   if (healthMetrics.value.lastSyncTime == null) return 'Never';
  //   final now = DateTime.now();
  //   final diff = now.difference(healthMetrics.value.lastSyncTime!);
  //   if (diff.inMinutes < 1) return 'Just now';
  //   if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  //   return '${diff.inHours}h ago';
  // }

  String get formatLastSync {
    final lastSync = healthMetrics.value.lastSyncTime;
    if (lastSync == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }


  /// Scroll to the top of the dashboard view
  void scrollToTop() {
    if (dashboardScrollController.hasClients) {
      dashboardScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
}