import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:get/get.dart';
import '../../messages/controllers/messages_controllers.dart';

import '../../../core/services/health_sync_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/app_lifecycle_service.dart';
import '../../../data/repositories/user_gravity_repository.dart';
import '../../../data/model/user_gravity_entry.dart';
import '../../../data/model/api_response.dart';
import '../../today_views/controllers/today_controller.dart';

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

  // Today's entry ID (set when creating/updating entry, used for upsert logic)
  final todayEntryId = Rx<int?>(null);

  // Throttle for saving to prevent multiple rapid API calls
  DateTime? _lastSaveTime;
  bool _isSavingGravity = false;
  
  // Goals loaded from storage/API
  final weightGoal = 75.0.obs; // in kg
  final stepGoal = 10000.obs; // steps per day
  final waterGoal = 2.5.obs; // in Liters
  final sleepGoal = 8.0.obs; // in hours
  final startingWeight = 0.0.obs; // in kg - loaded from storage (from Settings > Current Weight)

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

  /// Single subscription to health metrics; cancelled in onClose to avoid duplicate listeners.
  StreamSubscription<HealthMetrics>? _healthSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadGoals(); // Load goals first to initialize weight
    
    // Listen for goal changes in storage (when updated from settings)
    _setupGoalsListener();
    
    // Today's Progress & Weight: Health only (no GET /single_user_gravity or /all_user_gravity for display)
    debugPrint('Dashboard: Today\'s Progress & Weight from Health only (no GET /single_user_gravity or /all_user_gravity).');
    
    // Single subscription to health service; cancelled in onClose to prevent duplicate listeners on re-create
    _healthSubscription?.cancel();
    _healthSubscription = _healthService.stream.listen((metrics) {
      // Always update healthMetrics to trigger UI rebuild
      healthMetrics.value = metrics;
      isSyncing.value = metrics.syncStatus == SyncStatus.syncing;
      
      // Debug: Log when metrics update (Today's Progress ring reads healthMetrics.value.sleepHours)
      debugPrint('🔄 Health metrics updated: Steps=${metrics.steps}, Sleep=${metrics.sleepHours}, Water=${metrics.waterIntake}, Status=${metrics.syncStatus}');
      if (metrics.sleepHours > 0) {
        debugPrint('   → Today\'s Progress ring will show sleep: ${metrics.sleepHours.toStringAsFixed(1)} hrs');
      }
      
      // Current weight: ONLY today's value from Health Connect / Google Fit. No fallbacks.
      if (metrics.weight != null && metrics.weight! > 0) {
        if (weight.value > 0 && (weight.value - metrics.weight!).abs() > 0.1) {
          previousWeight.value = weight.value;
        }
        weight.value = metrics.weight!;
      } else {
        weight.value = 0.0;
      }
      
      // Update water intake only when health has data; do not overwrite with null/0 (health-only display)
      if (metrics.waterIntake != null) {
        waterIntake.value = metrics.waterIntake!;
        debugPrint('💧 Updated water intake from health sync: ${waterIntake.value} L (sync status: ${metrics.syncStatus}, platform: ${metrics.platform})');
      }

      // When sync finishes successfully, save to DB
      if (metrics.syncStatus == SyncStatus.success) {
        // Determine data source based on platform
        final dataSource = _getDataSourceFromPlatform(metrics.platform);
        if (dataSource != null) {
          // Debounce: only save if last save was more than 10 seconds ago (reduces duplicate
          // update_user_gravity calls from rapid success emissions e.g. init + first sync)
          final now = DateTime.now();
          if (_lastSaveTime == null ||
              now.difference(_lastSaveTime!).inSeconds >= 10) {
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
        debugPrint('📱 Dashboard: App resumed - will sync health data after delay');
        _loadGoals();
        // Delay before triggering sync to avoid DNS/network instability on resume
        Future.delayed(const Duration(milliseconds: 750), () {
          if (!Get.isRegistered<DashboardController>()) return;
          final currentMetrics = _healthService.getMetrics();
          if (currentMetrics.syncStatus != SyncStatus.syncing &&
              (currentMetrics.platform == HealthPlatform.apple ||
                  currentMetrics.platform == HealthPlatform.google)) {
            _healthService.syncHealthData();
          }
        });
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }
  
  @override
  void onClose() {
    _healthSubscription?.cancel();
    _healthSubscription = null;
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
    if (Platform.isIOS) return 'apple_health';
    if (Platform.isAndroid) return 'health_connect';
    return null;
  }

  /// Upsert (create or update) today's gravity entry. Backend write-only (no GET for display).
  Future<void> upsertTodayGravity({required String dataSource}) async {
    if (!AppLifecycleService().isAppInForeground) return;
    if (_isSavingGravity) return;

    debugPrint('Dashboard: Backend write-only — upsert gravity (create or update); no GET for display.');
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
        // Try to update existing entry first
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

        // If update fails with 404 "Record not found", fallback to CREATE
        // This handles cases where:
        // - Record was deleted from database
        // - ID is stale (from previous day/session)
        // - Date mismatch between app and database
        if (!response.isSuccess && 
            (response.message.toLowerCase().contains('record not found') ||
             response.message.toLowerCase().contains('not found'))) {
          Get.printInfo(info: '⚠️ Update failed with 404, falling back to CREATE (stale ID: ${todayEntryId.value})');
          todayEntryId.value = null; // Clear stale ID
          
          // Retry as CREATE
          Get.printInfo(info: '➕ Creating new entry (fallback from failed update)');
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
        todayEntryId.value = response.data!.id;
        Get.printInfo(info: '✅ Saved today\'s gravity entry to DB (ID: ${response.data!.id})');
      } else {
        if (response.message != kNetworkUnavailableMessage) {
          Get.snackbar(
            'Save Failed',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.printError(info: 'Failed to save: ${response.message}');
        }
      }
    } on SocketException catch (_) {
      debugPrint('Network temporarily unavailable; skipping backend write.');
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
        
        // Do NOT set weight/previousWeight from goals — Current Weight = today's health only (0.0 if none).
        final currentWeightStr = goalsMap['currentWeight']?.toString();
        
        // Starting weight = current user's Current Weight from Wellness Goals (so each user sees their own)
        final currentWeightFromGoals = currentWeightStr != null
            ? double.tryParse(currentWeightStr)
            : null;
        if (currentWeightFromGoals != null && currentWeightFromGoals > 0) {
          startingWeight.value = currentWeightFromGoals;
          PreferencesService.saveStartingWeight(currentWeightFromGoals);
          debugPrint('📊 Starting weight from Current Weight (Wellness Goals): $currentWeightFromGoals kg');
        } else {
          final savedStartingWeight = PreferencesService.getStartingWeight();
          if (savedStartingWeight != null && savedStartingWeight > 0) {
            startingWeight.value = savedStartingWeight;
            debugPrint('📊 Starting weight loaded from storage: $savedStartingWeight kg');
          }
        }
        
        debugPrint('✅ Goals loaded: Steps=$stepGoal, Water=$waterGoal, Sleep=$sleepGoal, TargetWeight=$weightGoal, StartingWeight=${startingWeight.value}');
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
      mealsEaten.value = value;
      fastingInput.value = '';
      await _saveManualEntry(type: 'meals_eaten', value: value.toString());
    }
  }

  /// Mark meal(s) completed from fasting dropdown modal. Persistence/API can be added later.
  void markMealCompleted(int count) {
    mealsEaten.value = count.clamp(0, 2);
    // TODO: persist via API when ready
  }

  /// Write manual entry (weight/hydration/sleep) to device health store.
  /// Never throws; logs errors. DB save is independent.
  Future<void> _writeManualEntryToHealth({required String type, required String value}) async {
    try {
      if (type != 'weight' && type != 'hydration' && type != 'sleep_hours') return;
      final metrics = _healthService.getMetrics();
      final connected = metrics.syncStatus == SyncStatus.success ||
          metrics.platform == HealthPlatform.apple ||
          metrics.platform == HealthPlatform.google;
      if (!connected) {
        final ok = await _healthService.initialize();
        if (!ok) {
          debugPrint('⚠️ Health not connected, skipping write to health store');
          return;
        }
      }
      if (type == 'weight') {
        final kg = double.tryParse(value);
        if (kg != null && kg > 0 && kg < 300) {
          await _healthService.writeWeightKg(kg);
        }
        return;
      }
      if (type == 'hydration') {
        // Best-effort only: Google Fit / Health Connect hydration write is unreliable by platform design.
        // Local data (backend + UI state) is source of truth; failure must NOT affect app or UI.
        final newTotal = double.tryParse(value);
        if (newTotal == null || newTotal < 0) return;
        final currentTotal = (metrics.syncStatus == SyncStatus.success && metrics.waterIntake != null)
            ? metrics.waterIntake!
            : 0.0;
        final delta = newTotal - currentTotal;
        if (delta > 0.01) {
          try {
            await _healthService.writeWaterLiters(delta);
          } catch (_) {
            // Silent failure: hydration write is non-critical; local save already succeeded.
          }
        }
        return;
      }
      if (type == 'sleep_hours') {
        final hours = double.tryParse(value);
        if (hours != null && hours >= 0 && hours <= 24) {
          await _healthService.writeSleepHours(hours);
        }
      }
    } catch (e) {
      debugPrint('⚠️ _writeManualEntryToHealth error: $e');
    }
  }

  /// Save manual entry using the create_manual_user_gravity API
  Future<void> _saveManualEntry({required String type, required String value}) async {
    if (!AppLifecycleService().isAppInForeground) return;
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
        
        // Extract entry ID from response if available (for future single_user_gravity calls)
        if (response.data != null) {
          final entryId = response.data!['id'];
          if (entryId != null) {
            final id = entryId is int ? entryId : int.tryParse(entryId.toString());
            if (id != null) {
              todayEntryId.value = id;
              debugPrint('📝 Updated todayEntryId from manual entry response: $id');
            }
          }
        }
        
        // Write manual entry to device health store (Apple Health / Health Connect), then resync
        await _writeManualEntryToHealth(type: type, value: value);
        await _healthService.syncHealthData();
        debugPrint('Dashboard: Manual entry saved; UI will update from health sync only (no backend GET).');
        
        // Notify TodayController to refetch so Pillar Status reflects updated Hydration/Sleep/Steps/Weight-in
        if (Get.isRegistered<TodayController>()) {
          Get.find<TodayController>().fetchDateWiseGravity(isRefresh: true);
        }
      } else {
        if (response.message != kNetworkUnavailableMessage) {
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