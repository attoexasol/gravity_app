import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/model/today_screen.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../data/repositories/ai_coach_repository.dart';
import '../../../../data/repositories/user_gravity_repository.dart';
import '../../../../data/model/user_gravity_entry.dart';
import '../../../../data/model/date_wise_gravity_response.dart';
import '../../../../data/model/api_response.dart';
import '../../../../core/services/preferences_service.dart';

class TodayController extends GetxController {
  // Weight data
  final RxDouble startingWeight = 85.0.obs; // Loaded from storage (Settings > Current Weight)
  final RxDouble currentWeight = 79.0.obs;
  final RxDouble goalWeight = 71.5.obs;

  // Reflection
  final RxString reflection = ''.obs;
  
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

  // Pillar data (Hydration, Sleep, Steps)
  final RxDouble hydrationLiters = 0.0.obs; // Hydration in liters
  final RxDouble sleepHours = 0.0.obs; // Sleep hours
  final RxInt steps = 0.obs; // Steps count
  final RxBool isLoadingPillars = false.obs;
  final RxString pillarsError = ''.obs;
  final Rx<int?> todayGravityEntryId = Rx<int?>(null); // Today's entry ID

  // Repositories
  final AiCoachRepository _aiCoachRepository = AiCoachRepository();
  final UserGravityRepository _gravityRepository = UserGravityRepository();

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

    // Load starting weight from storage (set from Settings > Current Weight)
    _loadStartingWeight();

    // Fetch date-wise gravity data on screen load
    fetchDateWiseGravity();
    
    // Fetch nutrition data on screen load (keep for backward compatibility)
    fetchNutritionData();
    
    // Fetch pillar data (Hydration, Sleep, Steps) on screen load (keep for backward compatibility)
    fetchPillarData();
  }

  @override
  void onClose() {
    reflectionController.dispose();
    weightController.dispose();
    super.onClose();
  }

  // Calculated values
  double get totalLossGoal {
    if (dateWiseData.value?.goalWeightLoss != null) {
      return dateWiseData.value!.goalWeightLoss!;
    }
    return startingWeight.value - goalWeight.value; // 13.5 kg fallback
  }
  
  double get currentLoss {
    if (dateWiseData.value?.startingWeight != null && dateWiseData.value?.weight != null) {
      return dateWiseData.value!.startingWeight! - dateWiseData.value!.weight!;
    }
    return startingWeight.value - currentWeight.value; // 6 kg fallback
  }
  
  double get progressPercentage {
    if (totalLossGoal > 0) {
      return (currentLoss / totalLossGoal * 100).clamp(0.0, 100.0);
    }
    return 0.0;
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
  
  /// Public method to be called when goals are updated in settings
  /// This provides real-time updates for starting weight
  void notifyGoalsChanged() {
    debugPrint('🔄 Today: Goals changed notification received - reloading starting weight...');
    _loadStartingWeight();
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
        
        hasError.value = false;
        errorMessage.value = '';
        debugPrint('✅ Date-wise gravity data loaded successfully');
      } else {
        // No data exists for this date
        hasError.value = true;
        errorMessage.value = response.message.isNotEmpty 
            ? response.message 
            : 'No data available for this date';
        dateWiseData.value = null;
        debugPrint('⚠️ No data found for date: $dateString');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load data. Please try again.';
      dateWiseData.value = null;
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

  /// Fetch today's gravity entry using single_user_gravity API
  /// First gets all entries to find today's ID, then calls single_user_gravity
  Future<void> fetchPillarData() async {
    try {
      isLoadingPillars.value = true;
      pillarsError.value = '';

      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        pillarsError.value = 'No authentication token';
        isLoadingPillars.value = false;
        return;
      }

      // First, get all entries to find today's entry ID
      final todayStr = _formatDateForGravityApi(DateTime.now());
      debugPrint('🔍 Fetching pillar data for date: $todayStr');

      final allEntriesResponse = await _gravityRepository.getAllUserGravity(
        apiToken: apiToken,
      );

      if (!allEntriesResponse.isSuccess || allEntriesResponse.data == null) {
        pillarsError.value = allEntriesResponse.message.isNotEmpty 
            ? allEntriesResponse.message 
            : 'Failed to load pillar data';
        debugPrint('⚠️ Failed to get all entries: ${allEntriesResponse.message}');
        isLoadingPillars.value = false;
        return;
      }

      // Find today's entry
      final todayEntry = allEntriesResponse.data!.firstWhere(
        (entry) => entry.date == todayStr,
        orElse: () => UserGravityEntry(date: ''),
      );

      if (todayEntry.date.isEmpty || todayEntry.id == null) {
        debugPrint('ℹ️ No entry found for today');
        // Reset to default values
        hydrationLiters.value = 0.0;
        sleepHours.value = 0.0;
        steps.value = 0;
        isLoadingPillars.value = false;
        return;
      }

      // Now call single_user_gravity API with today's entry ID
      final entryId = todayEntry.id;
      todayGravityEntryId.value = entryId;
      debugPrint('📞 Calling single_user_gravity API with ID: $entryId');

      final singleEntryResponse = await _gravityRepository.getSingleUserGravity(
        id: entryId!,
      );

      if (singleEntryResponse.isSuccess && singleEntryResponse.data != null) {
        final entry = singleEntryResponse.data!;
        
        // Update pillar data from API response
        hydrationLiters.value = entry.hydrationLiters ?? 0.0;
        sleepHours.value = entry.sleepHours ?? 0.0;
        steps.value = entry.steps ?? 0;
        
        pillarsError.value = ''; // Clear any previous errors
        debugPrint('✅ Pillar data loaded from single_user_gravity:');
        debugPrint('   - Hydration: ${hydrationLiters.value}L');
        debugPrint('   - Sleep: ${sleepHours.value}h');
        debugPrint('   - Steps: ${steps.value}');
      } else {
        pillarsError.value = singleEntryResponse.message.isNotEmpty 
            ? singleEntryResponse.message 
            : 'Failed to load pillar data';
        debugPrint('⚠️ Failed to get single entry: ${singleEntryResponse.message}');
        // Use data from allEntriesResponse as fallback
        hydrationLiters.value = todayEntry.hydrationLiters ?? 0.0;
        sleepHours.value = todayEntry.sleepHours ?? 0.0;
        steps.value = todayEntry.steps ?? 0;
      }
    } catch (e) {
      pillarsError.value = 'Failed to load pillar data';
      debugPrint('❌ Error fetching pillar data: $e');
      // Reset to default values on error
      hydrationLiters.value = 0.0;
      sleepHours.value = 0.0;
      steps.value = 0;
    } finally {
      isLoadingPillars.value = false;
    }
  }

  // Get hydration display text
  String get hydrationDisplayText {
    if (isLoadingPillars.value) {
      return 'Loading...';
    }
    if (pillarsError.value.isNotEmpty) {
      return 'Borderline';
    }
    // Format hydration: show as "X.X L" or "X L" (including 0L)
    if (hydrationLiters.value % 1 == 0) {
      return '${hydrationLiters.value.toInt()}L';
    } else {
      return '${hydrationLiters.value.toStringAsFixed(1)}L';
    }
  }

  // Get sleep display text
  String get sleepDisplayText {
    if (isLoadingPillars.value) {
      return 'Loading...';
    }
    if (pillarsError.value.isNotEmpty) {
      return 'Borderline';
    }
    // Format sleep: show as "Xh Ym" (e.g., "6h 45m") or "0h" if 0
    final hours = sleepHours.value.toInt();
    final minutes = ((sleepHours.value - hours) * 60).toInt();
    if (sleepHours.value == 0.0) {
      return '0h';
    } else if (minutes > 0) {
      return 'Logged (${hours}h ${minutes}m)';
    } else {
      return 'Logged (${hours}h)';
    }
  }

  // Get steps display text
  String get stepsDisplayText {
    if (isLoadingPillars.value) {
      return 'Loading...';
    }
    if (pillarsError.value.isNotEmpty) {
      return 'Missed';
    }
    // Format steps: show with comma separator (e.g., "10,500 steps") or "0 steps" if 0
    if (steps.value == 0) {
      return '0 steps';
    }
    final formattedSteps = steps.value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formattedSteps steps';
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

  void openWeighInModal() {
    weightController.text = currentWeight.value.toString();
    selectedDate.value = DateTime.now();
    showWeighInModal.value = true;
  }

  void closeWeighInModal() {
    showWeighInModal.value = false;
  }

  /// Save weight-in entry using the create_manual_user_gravity API
  /// Same API as used in Dashboard Quick Actions
  Future<void> saveWeighIn() async {
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

