import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/model/today_screen.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../data/repositories/ai_coach_repository.dart';
import '../../../../data/repositories/user_gravity_repository.dart';
import '../../../../data/repositories/goals_repository.dart';
import '../../../../data/model/user_gravity_entry.dart';
import '../../../../data/model/date_wise_gravity_response.dart';
import '../../../../data/model/api_response.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/app_lifecycle_service.dart';

class TodayController extends GetxController {
  // Weight data
  final RxDouble startingWeight = 85.0.obs; // Loaded from storage (Settings > Current Weight)
  final RxDouble currentWeight = 79.0.obs;
  final RxDouble goalWeight = 71.5.obs;

  // Reflection
  final RxString reflection = ''.obs;
  final RxBool isSubmittingReflection = false.obs;

  // Text controllers
  late final TextEditingController reflectionController;
  late final TextEditingController weightController;
  
  // Weight-in modal data
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Modals
  final RxBool showWeighInModal = false.obs;
  final RxBool showGoalsModal = false.obs;

  // Date-wise gravity data (from new API)
  final Rx<DateWiseGravityResponse?> dateWiseData = Rx<DateWiseGravityResponse?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;
  
  // Nutrition data
  final RxInt totalNutrition = 0.obs; // Total daily calories
  final RxBool isLoadingNutrition = false.obs;
  final RxString nutritionError = ''.obs;

  // Pillar data (Hydration, Sleep, Steps) - fallback values (primary source is dateWiseData from fetchDateWiseGravity)
  final RxDouble hydrationLiters = 0.0.obs; // Hydration in liters
  final RxDouble sleepHours = 0.0.obs; // Sleep hours
  final RxInt steps = 0.obs; // Steps count

  // Repositories
  final AiCoachRepository _aiCoachRepository = AiCoachRepository();
  final UserGravityRepository _gravityRepository = UserGravityRepository();
  final GoalsRepository _goalsRepository = GoalsRepository();

  // Navigation guard to prevent multiple rapid calls
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
    reflectionController = TextEditingController();
    weightController = TextEditingController(); // Start blank - no Google Fit prefill
    
    // Listen to reflection changes
    reflectionController.addListener(() {
      reflection.value = reflectionController.text;
    });

    // Load starting weight and goal weight from storage (set from Settings)
    _loadStartingWeight();
    _loadGoalWeight();

    // Fetch goal weight from API to ensure we have the latest data
    // This is critical after logout/login when local storage might be cleared
    _fetchGoalWeightFromAPI();

    // Fetch date-wise gravity data on screen load
    // This single API call provides all data for Pillar Status (Nutrition, Hydration, Sleep, Steps, Fasting, Weight-in)
    fetchDateWiseGravity();
    
    // Fetch nutrition data on screen load (keep for backward compatibility)
    fetchNutritionData();
  }

  @override
  void onClose() {
    reflectionController.dispose();
    weightController.dispose();
    super.onClose();
  }

  /// Debug helper method for weight journey logs (debug-only)
  void _debugWeightJourneyLog({
    required double starting,
    required double target,
    required double current,
    required double goalLoss,
    required double clampedGoalLoss,
    required double lost,
    required double clampedLost,
    required double remaining,
    required double clampedRemaining,
  }) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📊 WEIGHT JOURNEY VERIFICATION');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('INPUTS:');
      debugPrint('  Starting Weight: ${starting.toStringAsFixed(1)} kg');
      debugPrint('  Target Weight: ${target.toStringAsFixed(1)} kg');
      debugPrint('  Current Weight: ${current.toStringAsFixed(1)} kg');
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('CALCULATIONS:');
      debugPrint('  goalLoss = startingWeight - targetWeight');
      debugPrint('  goalLoss = ${starting.toStringAsFixed(1)} - ${target.toStringAsFixed(1)} = ${goalLoss.toStringAsFixed(1)} kg (clamped: ${clampedGoalLoss.toStringAsFixed(1)} kg)');
      debugPrint('  lost = startingWeight - currentWeight');
      debugPrint('  lost = ${starting.toStringAsFixed(1)} - ${current.toStringAsFixed(1)} = ${lost.toStringAsFixed(1)} kg (clamped: ${clampedLost.toStringAsFixed(1)} kg)');
      debugPrint('  remaining = currentWeight - targetWeight');
      debugPrint('  remaining = ${current.toStringAsFixed(1)} - ${target.toStringAsFixed(1)} = ${remaining.toStringAsFixed(1)} kg (clamped: ${clampedRemaining.toStringAsFixed(1)} kg)');
      debugPrint('═══════════════════════════════════════════════════════');
    }
  }

  // Calculated values
  double get totalLossGoal {
    final starting = startingWeightFromApi;
    final target = goalWeight.value;
    
    // goalLoss = startingWeight - targetWeight
    double goalLoss;
    if (dateWiseData.value?.goalWeightLoss != null) {
      goalLoss = dateWiseData.value!.goalWeightLoss!;
    } else {
      goalLoss = starting - target;
    }
    
    // Clamp: goalLoss cannot go below 0
    final clampedGoalLoss = goalLoss.clamp(0.0, double.infinity);
    
    return clampedGoalLoss;
  }
  
  double get currentLoss {
    final starting = startingWeightFromApi;
    final current = currentWeightFromApi;
    
    // lost = startingWeight - currentWeight
    // Safe null-handling for API data
    final s = dateWiseData.value?.startingWeight;
    final w = dateWiseData.value?.weight;
    final apiLost = (s != null && w != null) ? (s - w) : null;
    final lost = apiLost ?? (starting - current);
    
    // Clamp: lost cannot go below 0
    final clampedLost = lost.clamp(0.0, double.infinity);
    
    return clampedLost;
  }
  
  /// Get remaining weight to lose
  double get remainingWeight {
    final current = currentWeightFromApi;
    final target = goalWeight.value;
    
    // remaining = currentWeight - targetWeight
    final remaining = current - target;
    
    // Clamp: remaining cannot go below 0
    // If currentWeight < targetWeight, set remaining = 0
    final clampedRemaining = remaining.clamp(0.0, double.infinity);
    
    return clampedRemaining;
  }
  
  double get progressPercentage {
    final goalLoss = totalLossGoal;
    final lost = currentLoss;
    final current = currentWeightFromApi;
    final target = goalWeight.value;
    
    // If currentWeight < targetWeight, progress must be 1.0 (100%)
    if (current < target) {
      return 100.0;
    }
    
    // Calculate progress: lost / goalLoss
    if (goalLoss > 0) {
      final percentage = (lost / goalLoss * 100).clamp(0.0, 100.0);
      return percentage;
    }
    
    return 0.0;
  }
  
  /// Debug method to log weight journey values (called from UI on render)
  void logWeightJourneyValues() {
    if (kDebugMode) {
      final starting = startingWeightFromApi;
      final target = goalWeight.value;
      final current = currentWeightFromApi;
      final goalLoss = totalLossGoal;
      final lost = currentLoss;
      final remaining = remainingWeight;
      
      _debugWeightJourneyLog(
        starting: starting,
        target: target,
        current: current,
        goalLoss: starting - target, // Unclamped for log
        clampedGoalLoss: goalLoss,
        lost: starting - current, // Unclamped for log
        clampedLost: lost,
        remaining: current - target, // Unclamped for log
        clampedRemaining: remaining,
      );
    }
  }
  
  // Get current weight from API or fallback
  double get currentWeightFromApi {
    return dateWiseData.value?.weight ?? currentWeight.value;
  }
  
  // Get starting weight from API or storage or fallback
  double get startingWeightFromApi {
    // Priority: API data > Storage (Settings) > Fallback
    if (dateWiseData.value?.startingWeight != null) {
      return dateWiseData.value!.startingWeight!;
    }
    // Use storage value (from Settings > Current Weight)
    if (startingWeight.value > 0) {
      return startingWeight.value;
    }
    // Fallback
    return 85.0;
  }
  
  /// Load starting weight from storage (set from Settings > Current Weight)
  void _loadStartingWeight() {
    final savedStartingWeight = PreferencesService.getStartingWeight();
    if (savedStartingWeight != null && savedStartingWeight > 0) {
      startingWeight.value = savedStartingWeight;
      debugPrint('📊 Today: Starting weight loaded from storage: $savedStartingWeight kg');
    } else {
      // Fallback: try to get from goals
      final savedGoals = PreferencesService.getStorage().read('userGoals');
      if (savedGoals != null) {
        try {
          final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
          final currentWeightStr = goalsMap['currentWeight']?.toString();
          if (currentWeightStr != null) {
            final currentWeight = double.tryParse(currentWeightStr);
            if (currentWeight != null && currentWeight > 0) {
              startingWeight.value = currentWeight;
              debugPrint('📊 Today: Starting weight fallback to current weight from goals: $currentWeight kg');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error loading starting weight from goals: $e');
        }
      }
    }
  }
  
  /// Load goal weight (target weight) from storage (set from Settings > Target Weight)
  void _loadGoalWeight() {
    final savedGoals = PreferencesService.getStorage().read('userGoals');
    if (savedGoals != null) {
      try {
        final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
        final targetWeightStr = goalsMap['targetWeight']?.toString();
        if (targetWeightStr != null) {
          final targetWeight = double.tryParse(targetWeightStr);
          if (targetWeight != null && targetWeight > 0) {
            goalWeight.value = targetWeight;
            debugPrint('📊 Today: Goal weight (target) loaded from storage: $targetWeight kg');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error loading goal weight from goals: $e');
      }
    }
  }
  
  /// Fetch goal weight (target weight) from API
  /// This ensures we have the latest goal weight from backend, especially after logout/login
  /// when local storage might be cleared
  Future<void> _fetchGoalWeightFromAPI() async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ Token not found, skipping goal weight API fetch');
        return;
      }

      debugPrint('🔍 Fetching goal weight from API...');
      final response = await _goalsRepository.getSingleGoal(token: apiToken);

      if (response.isSuccess && response.data != null) {
        final goalData = response.data!;
        final targetWeightStr = goalData['target_weight']?.toString();
        
        if (targetWeightStr != null && targetWeightStr.isNotEmpty) {
          final targetWeight = double.tryParse(targetWeightStr);
          if (targetWeight != null && targetWeight > 0) {
            goalWeight.value = targetWeight;
            debugPrint('✅ Goal weight (target) loaded from API: $targetWeight kg');
            
            // Also update local storage for faster future loads
            final savedGoals = PreferencesService.getStorage().read('userGoals');
            if (savedGoals != null) {
              try {
                final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
                goalsMap['targetWeight'] = targetWeightStr;
                PreferencesService.getStorage().write('userGoals', jsonEncode(goalsMap));
                debugPrint('💾 Goal weight saved to local storage for faster future loads');
              } catch (e) {
                debugPrint('⚠️ Error updating goal weight in storage: $e');
              }
            }
          } else {
            debugPrint('⚠️ Invalid target weight from API: $targetWeightStr');
          }
        } else {
          debugPrint('⚠️ Target weight not found in API response');
        }
      } else {
        debugPrint('⚠️ Goals API returned no data or failed: ${response.message}');
        // Keep existing value from storage if API fails
      }
    } catch (e) {
      debugPrint('❌ Error fetching goal weight from API: $e');
      // Keep existing value from storage on error
    }
  }
  
  /// Public method to be called when goals are updated in settings
  /// This provides real-time updates for starting weight and goal weight
  void notifyGoalsChanged() {
    debugPrint('🔄 Today: Goals changed notification received - reloading weights...');
    _loadStartingWeight();
    _loadGoalWeight();
    // Also fetch from API to ensure we have the latest data
    _fetchGoalWeightFromAPI();
    update(); // Trigger UI rebuild to show updated values
  }

  // Format date for API (YY-MM-dd format, e.g., "26-01-19" for January 19, 2026)
  String _formatDateForApi(DateTime date) {
    final year = date.year.toString().substring(2); // Last 2 digits of year
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // Format date for User Gravity API (yyyy-MM-dd format)
  String _formatDateForGravityApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Fetch date-wise gravity data from new API endpoint
  Future<void> fetchDateWiseGravity({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        isLoading.value = true;
      }
      hasError.value = false;
      errorMessage.value = '';

      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'No authentication token';
        isLoading.value = false;
        return;
      }

      // Use current date (today) in YYYY-MM-DD format
      final today = DateTime.now();
      final dateString = _formatDateForGravityApi(today);

      debugPrint('📤 Fetching date-wise gravity for: $dateString');

      final response = await _gravityRepository.getDateWiseGravity(
        apiToken: apiToken,
        date: dateString,
      );

      if (response.isSuccess && response.data != null) {
        // Parse the response data
        final data = DateWiseGravityResponse.fromJson(response.data!);
        dateWiseData.value = data;
        
        // Update reactive variables from API data
        if (data.weight != null) {
          currentWeight.value = data.weight!;
        }
        if (data.startingWeight != null) {
          startingWeight.value = data.startingWeight!;
        }
        if (data.hydrationLiters != null) {
          hydrationLiters.value = data.hydrationLiters!;
        }
        if (data.sleepHours != null) {
          sleepHours.value = data.sleepHours!;
        }
        if (data.steps != null) {
          steps.value = data.steps!;
        }
        if (data.nutritionCalories != null) {
          totalNutrition.value = data.nutritionCalories!;
        }
        
        // If goalWeightLoss is available from API and goalWeight is still at default/0,
        // calculate target weight from goalWeightLoss: targetWeight = startingWeight - goalWeightLoss
        if (data.goalWeightLoss != null && data.startingWeight != null) {
          final calculatedTarget = data.startingWeight! - data.goalWeightLoss!;
          // Only update if goalWeight is still at default (71.5) or invalid (0 or equals starting)
          if (goalWeight.value <= 0 || goalWeight.value == 71.5 || goalWeight.value >= data.startingWeight!) {
            if (calculatedTarget > 0 && calculatedTarget < data.startingWeight!) {
              goalWeight.value = calculatedTarget;
              debugPrint('📊 Goal weight calculated from API goalWeightLoss: $calculatedTarget kg (from ${data.startingWeight} - ${data.goalWeightLoss})');
            }
          }
        }
        
        hasError.value = false;
        errorMessage.value = '';
        debugPrint('✅ Date-wise gravity data loaded successfully');
        
        // Log weight journey values after API data is loaded
        logWeightJourneyValues();
      } else {
        // No data exists for this date - this is NORMAL for new users or days without entries
        // Don't treat this as an error - just show UI with default/empty values
        dateWiseData.value = null;
        hasError.value = false; // Not an error - just no data yet
        errorMessage.value = ''; // Clear any previous error messages
        
        // Reset to default values when no data exists (so UI shows empty/default state)
        // Keep currentWeight and startingWeight from storage/previous values
        // Reset only the daily tracking values
        hydrationLiters.value = 0.0;
        sleepHours.value = 0.0;
        steps.value = 0;
        totalNutrition.value = 0;
        
        debugPrint('ℹ️ No data found for date: $dateString - showing UI with default values');
      }
    } catch (e) {
      // Only set error for actual exceptions (network failures, parsing errors, etc.)
      // Not for "no data" responses (which are handled above)
      hasError.value = true;
      errorMessage.value = 'Failed to load data. Please try again.';
      dateWiseData.value = null;
      
      // Reset to default values on error too (so UI still shows)
      hydrationLiters.value = 0.0;
      sleepHours.value = 0.0;
      steps.value = 0;
      totalNutrition.value = 0;
      
      debugPrint('❌ Error fetching date-wise gravity: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Pull to refresh handler
  Future<void> onRefresh() async {
    await fetchDateWiseGravity(isRefresh: true);
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



  // Get hydration status (with new color logic: Green/Yellow/Red)
  PillarStatus get hydrationStatus {
    if (isLoading.value) {
      return PillarStatus.borderline;
    }
    final value = dateWiseData.value?.hydrationLiters ?? hydrationLiters.value;
    if (value == 0) {
      return PillarStatus.missed; // Red - missing or zero
    }
    // You can add logic here for partial (yellow) vs meets target (green)
    // For now, if > 0, consider it meets target (green)
    return PillarStatus.onTrack; // Green - meets target
  }

  // Get sleep status (with new color logic: Green/Yellow/Red)
  PillarStatus get sleepStatus {
    if (isLoading.value) {
      return PillarStatus.borderline;
    }
    final value = dateWiseData.value?.sleepHours ?? sleepHours.value;
    if (value == 0) {
      return PillarStatus.missed; // Red - missing or zero
    }
    // You can add logic here for partial (yellow) vs meets target (green)
    return PillarStatus.onTrack; // Green - meets target
  }

  // Get steps status (with new color logic: Green/Yellow/Red)
  PillarStatus get stepsStatus {
    if (isLoading.value) {
      return PillarStatus.borderline;
    }
    final value = dateWiseData.value?.steps ?? steps.value;
    if (value == 0) {
      return PillarStatus.missed; // Red - missing or zero
    }
    // You can add logic here for partial (yellow) vs meets target (green)
    return PillarStatus.onTrack; // Green - meets target
  }
  
  // Get nutrition status (with new color logic: Green/Yellow/Red)
  PillarStatus get nutritionStatus {
    if (isLoading.value || isLoadingNutrition.value) {
      return PillarStatus.borderline;
    }
    final value = dateWiseData.value?.nutritionCalories ?? totalNutrition.value;
    if (value == 0) {
      return PillarStatus.missed; // Red - missing or zero
    }
    // You can add logic here for partial (yellow) vs meets target (green)
    // For now, if > 0, consider it partial (yellow) - can be customized
    return PillarStatus.borderline; // Yellow - partial
  }
  
  // Get fasting status
  PillarStatus get fastingStatus {
    if (isLoading.value) {
      return PillarStatus.borderline;
    }
    final completed = dateWiseData.value?.fastingCompleted ?? false;
    if (completed) {
      return PillarStatus.onTrack; // Green - stayed within
    }
    return PillarStatus.missed; // Red - didn't stay within
  }
  
  // Get weight-in status
  PillarStatus get weighInStatus {
    if (isLoading.value) {
      return PillarStatus.borderline;
    }
    final hasWeight = dateWiseData.value?.weight != null && dateWiseData.value!.weight! > 0;
    if (hasWeight) {
      return PillarStatus.onTrack; // Green - has weight
    }
    return PillarStatus.notScheduled; // Gray - not scheduled
  }

  // Get nutrition display text from API
  String get nutritionDisplayTextFromApi {
    if (isLoading.value) {
      return 'Loading...';
    }
    final value = dateWiseData.value?.nutritionCalories ?? totalNutrition.value;
    if (value == 0) {
      return '0 cal';
    }
    return '$value cal';
  }
  
  // Get hydration display text from API
  String get hydrationDisplayTextFromApi {
    if (isLoading.value) {
      return 'Loading...';
    }
    final value = dateWiseData.value?.hydrationLiters ?? hydrationLiters.value;
    if (value == 0) {
      return '0L';
    }
    if (value % 1 == 0) {
      return '${value.toInt()}L';
    } else {
      return '${value.toStringAsFixed(1)}L';
    }
  }
  
  // Get sleep display text from API
  String get sleepDisplayTextFromApi {
    if (isLoading.value) {
      return 'Loading...';
    }
    final value = dateWiseData.value?.sleepHours ?? sleepHours.value;
    if (value == 0) {
      return '0h';
    }
    final hours = value.toInt();
    final minutes = ((value - hours) * 60).toInt();
    if (minutes > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${hours}h';
    }
  }
  
  // Get steps display text from API
  String get stepsDisplayTextFromApi {
    if (isLoading.value) {
      return 'Loading...';
    }
    final value = dateWiseData.value?.steps ?? steps.value;
    if (value == 0) {
      return '0 steps';
    }
    return '$value steps';
  }
  
  // Get fasting display text
  String get fastingDisplayText {
    if (isLoading.value) {
      return 'Loading...';
    }
    final completed = dateWiseData.value?.fastingCompleted ?? false;
    if (completed) {
      return 'Stayed within';
    }
    return 'Not within';
  }
  
  // Get weight-in display text
  String get weighInDisplayText {
    if (isLoading.value) {
      return 'Loading...';
    }
    final hasWeight = dateWiseData.value?.weight != null && dateWiseData.value!.weight! > 0;
    if (hasWeight) {
      return '${dateWiseData.value!.weight!.toStringAsFixed(1)} kg';
    }
    return 'Not scheduled';
  }

  // Pillars data - dynamically updated from API
  List<Pillar> get pillars => [
    Pillar(
      name: 'Nutrition',
      status: nutritionStatus,
      detail: nutritionDisplayTextFromApi,
      icon: Icons.restaurant,
    ),
    Pillar(
      name: 'Hydration',
      status: hydrationStatus,
      detail: hydrationDisplayTextFromApi,
      icon: Icons.water_drop,
    ),
    Pillar(
      name: 'Sleep',
      status: sleepStatus,
      detail: sleepDisplayTextFromApi,
      icon: Icons.nightlight_round,
    ),
    Pillar(
      name: 'Steps',
      status: stepsStatus,
      detail: stepsDisplayTextFromApi,
      icon: Icons.directions_walk,
    ),
    Pillar(
      name: 'Fasting window',
      status: fastingStatus,
      detail: fastingDisplayText,
      icon: Icons.favorite,
    ),
    Pillar(
      name: 'Weight-in',
      status: weighInStatus,
      detail: weighInDisplayText,
      icon: Icons.monitor_weight,
    ),
  ];

  // Get current date string
  String get currentDateString {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE · MMM d', 'en_US');
    return formatter.format(now);
  }

  // Get pillar color (Green/Yellow/Red logic)
  Color getPillarColor(PillarStatus status) {
    switch (status) {
      case PillarStatus.onTrack:
      case PillarStatus.logged:
        return const Color(0xFF00B8A9); // Green - meets target
      case PillarStatus.borderline:
        return const Color(0xFFD4AF37); // Yellow - partial
      case PillarStatus.missed:
        return const Color(0xFFE57373); // Red - missing or zero
      case PillarStatus.notScheduled:
        return const Color(0xFF9CA3AF); // Gray - not scheduled
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

  /// Submit daily reflection to API. Disables submit button while in progress.
  /// Does nothing if input is empty. Shows success snackbar on status=true; handles errors silently.
  Future<void> submitReflection() async {
    if (!AppLifecycleService().isAppInForeground) return;
    final text = reflectionController.text.trim();
    if (text.isEmpty) return;

    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) return;

    isSubmittingReflection.value = true;
    try {
      final response = await _gravityRepository.storeDailyReflection(
        apiToken: apiToken,
        dailyReflection: text,
      );
      if (response.isSuccess) {
        reflectionController.clear();
        reflection.value = '';
        Get.snackbar(
          'Success',
          response.message.isNotEmpty ? response.message : 'Daily Reflection updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Submit reflection error: $e');
    } finally {
      isSubmittingReflection.value = false;
    }
  }

  void openWeighInModal() {
    // Reset weight field to blank - user must enter manually
    weightController.clear();
    selectedDate.value = DateTime.now();
    showWeighInModal.value = true;
  }

  void closeWeighInModal() {
    showWeighInModal.value = false;
  }

  /// Save weight-in entry using the create_manual_user_gravity API
  /// Same API as used in Dashboard Quick Actions
  Future<void> saveWeighIn() async {
    if (!AppLifecycleService().isAppInForeground) return;
    final weightValue = double.tryParse(weightController.text);
    
    // Validate weight input
    if (weightValue == null || weightValue <= 0 || weightValue >= 300) {
      Get.snackbar(
        'Invalid Weight',
        'Please enter a valid weight between 0 and 300 kg',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        Get.snackbar(
          'Error',
          'Session expired. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Format date as YYYY-MM-DD
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      
      debugPrint('💾 Saving weight-in:');
      debugPrint('   - Weight: $weightValue kg');
      debugPrint('   - Date: $dateStr');

      // Call the same API as Dashboard Quick Actions
      final response = await _gravityRepository.createManualUserGravity(
        apiToken: apiToken,
        date: dateStr,
        type: 'weight',
        value: weightValue.toString(),
      );

      if (response.isSuccess) {
        debugPrint('✅ Weight-in saved successfully: ${response.message}');
        
        // Update local state immediately (optimistic update)
        currentWeight.value = weightValue;
        
        // Close modal
        closeWeighInModal();
        
        // Show success message
        Get.snackbar(
          'Success',
          response.message.isNotEmpty 
              ? response.message 
              : 'Weight saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Reload date-wise gravity data to get updated weight
        await fetchDateWiseGravity();
      } else {
        if (response.message != kNetworkUnavailableMessage) {
          debugPrint('❌ Failed to save weight-in: ${response.message}');
          Get.snackbar(
            'Error',
            response.message.isNotEmpty
                ? response.message
                : 'Failed to save weight',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE53935),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving weight-in: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void openGoalsModal() {
    showGoalsModal.value = true;
  }

  void closeGoalsModal() {
    showGoalsModal.value = false;
  }

  /// Save weight goals from the Weight Goals modal.
  /// Validates (target < starting, both > 0), persists to PreferencesService and userGoals,
  /// updates reactive state so Weight Journey progress bar and text recalculate, then closes modal.
  Future<void> saveWeightGoals({required double startingKg, required double targetKg}) async {
    // Re-validate server-side (modal already validated)
    if (startingKg <= 0 || targetKg <= 0 || targetKg >= startingKg) {
      Get.snackbar(
        'Invalid goals',
        'Target weight must be less than starting weight; both must be greater than 0.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      // Persist starting weight
      await PreferencesService.saveStartingWeight(startingKg);

      // Update userGoals map with target weight (keep other goals from storage)
      final savedGoals = PreferencesService.getStorage().read('userGoals');
      Map<String, dynamic> goalsMap = {};
      if (savedGoals != null) {
        try {
          goalsMap = Map<String, dynamic>.from(jsonDecode(savedGoals) as Map);
        } catch (_) {}
      }
      goalsMap['targetWeight'] = targetKg.toString();
      goalsMap['currentWeight'] = currentWeight.value.toString();
      PreferencesService.getStorage().write('userGoals', jsonEncode(goalsMap));

      // Update reactive state so Weight Journey UI recalculates progress bar & text
      startingWeight.value = startingKg;
      goalWeight.value = targetKg;

      closeGoalsModal();

      // Optionally sync to backend (same pattern as Settings > Goals)
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken != null && apiToken.isNotEmpty) {
        final waterIntake = goalsMap['waterIntake']?.toString() ?? '3';
        final waterIntakeWithUnit =
            waterIntake.endsWith('L') || waterIntake.endsWith('l')
                ? waterIntake
                : '$waterIntake L';
        final response = await _goalsRepository.createGoals(
          token: apiToken,
          currentWeight: goalsMap['currentWeight']?.toString() ?? currentWeight.value.toString(),
          targetWeight: targetKg.toString(),
          stepGoal: goalsMap['stepGoal']?.toString() ?? '12000',
          dailyWaterIntake: waterIntakeWithUnit,
          sleepHours: goalsMap['sleepHours']?.toString() ?? '7-8',
          aiTone: goalsMap['aiTone']?.toString() ?? 'encouraging',
        );
        if (!response.isSuccess && kDebugMode) {
          debugPrint('⚠️ Weight goals saved locally but API sync failed: ${response.message}');
        }
      }

      Get.snackbar(
        'Success',
        'Weight goals saved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00B8A9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving weight goals: $e');
      Get.snackbar(
        'Error',
        'Failed to save goals. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Called when user taps Done. Saves reflection if there is text, then navigates back.
  Future<void> handleDone() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final hasReflection = reflectionController.text.trim().isNotEmpty;
    if (hasReflection) {
      await submitReflection();
    }

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

