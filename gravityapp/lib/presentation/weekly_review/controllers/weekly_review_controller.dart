import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../../data/model/weekly_review.dart';
import '../../../data/model/day_wise_goal_completion.dart';
import '../../../data/repositories/user_gravity_repository.dart';
import '../../../core/services/token_manager.dart';
import '../../../app/routes/app_routes.dart';

/// Weekly Review Controller using GetX with API integration
class WeeklyReviewController extends GetxController {
  // Repository
  final UserGravityRepository _repository = UserGravityRepository();
  final TokenManager _tokenManager = TokenManager();

  // Selected week index
  final selectedWeekIndex = 0.obs;

  // Show week picker modal
  final showWeekPicker = false.obs;

  // Week options
  final weekOptions = <WeekOption>[].obs;

  // Weekly review data
  final weeklyReview = Rx<WeeklyReview?>(null);

  // Loading state
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _generateWeekOptions();
    // Load data for current week (index 0)
    _fetchWeeklyData();
  }

  /// Generate week options (last 8 weeks)
  void _generateWeekOptions() {
    final weeks = <WeekOption>[];
    final today = DateTime.now();

    for (int i = 0; i < 8; i++) {
      final weekStart = DateTime(
        today.year,
        today.month,
        today.day - (today.weekday == 7 ? 6 : today.weekday - 1) - (i * 7),
      );

      final weekEnd = weekStart.add(const Duration(days: 6));

      String formatDate(DateTime date) {
        return DateFormat('MMM d').format(date);
      }

      String label;
      if (i == 0) {
        label = 'This Week';
      } else if (i == 1) {
        label = 'Last Week';
      } else {
        label = '$i weeks ago';
      }

      weeks.add(WeekOption(
        id: i,
        label: label,
        dateRange: '${formatDate(weekStart)} – ${formatDate(weekEnd)}',
        startDate: weekStart,
        endDate: weekEnd,
      ));
    }

    weekOptions.value = weeks;
  }

  /// Fetch weekly goal completion data from API
  Future<void> _fetchWeeklyData() async {
    if (weekOptions.isEmpty) {
      debugPrint('⚠️ Week options not generated yet');
      return;
    }

    final selectedWeek = weekOptions[selectedWeekIndex.value];
    final startDate = selectedWeek.startDate;
    final endDate = selectedWeek.endDate;

    // Format dates as YYYY-MM-DD
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // Get API token
    final apiToken = _tokenManager.getAccessToken();
    if (apiToken == null || apiToken.isEmpty) {
      debugPrint('⚠️ No API token available, using mock data');
      _loadMockData();
      return;
    }

    isLoading.value = true;

    try {
      debugPrint('🔄 Fetching weekly goal completion for: $startDateStr to $endDateStr');

      final response = await _repository.fetchWeeklyGoalCompletion(
        apiToken: apiToken,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        debugPrint('✅ Successfully fetched ${response.data!.length} days of data');
        _mapApiDataToWeeklyReview(response.data!, startDate);
      } else {
        debugPrint('⚠️ API returned no data or failed, using mock data');
        debugPrint('   Status: ${response.status}, Message: ${response.message}');
        _loadMockData();
      }
    } catch (e) {
      debugPrint('❌ Error fetching weekly data: $e');
      // Keep previous data visible on error (don't clear)
      if (weeklyReview.value == null) {
        _loadMockData();
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Map API response to WeeklyReview model
  void _mapApiDataToWeeklyReview(
    List<DayWiseGoalCompletion> apiData,
    DateTime weekStart,
  ) {
    // Initialize arrays for each goal (7 days: Mon-Sun)
    final nutrition = List<PillarStatus>.filled(7, PillarStatus.missed);
    final hydration = List<PillarStatus>.filled(7, PillarStatus.missed);
    final sleep = List<PillarStatus>.filled(7, PillarStatus.missed);
    final steps = List<PillarStatus>.filled(7, PillarStatus.missed);
    final fasting = List<PillarStatus>.filled(7, PillarStatus.missed);
    final weighin = List<PillarStatus>.filled(7, PillarStatus.missed);

    // Helper function to convert API status string to PillarStatus enum
    PillarStatus mapStatus(String status) {
      switch (status.toLowerCase()) {
        case 'completed':
          return PillarStatus.complete;
        case 'partial':
          return PillarStatus.partial;
        case 'missed':
        default:
          return PillarStatus.missed;
      }
    }

    // Helper function to get weekday index (0=Monday, 6=Sunday)
    int getWeekdayIndex(DateTime date) {
      // DateTime.weekday: 1=Monday, 7=Sunday
      // We want: 0=Monday, 6=Sunday
      return date.weekday - 1;
    }

    // Map each day's data to the correct weekday position
    for (final dayData in apiData) {
      try {
        // Parse date string - try multiple formats
        DateTime? date;
        try {
          date = DateFormat('yyyy-MM-dd').parse(dayData.date);
        } catch (e) {
          // Try alternative formats if needed
          try {
            date = DateTime.parse(dayData.date);
          } catch (e2) {
            debugPrint('⚠️ Could not parse date: ${dayData.date}');
            continue; // Skip this day if date parsing fails
          }
        }

        final weekdayIndex = getWeekdayIndex(date);

        // Ensure index is within bounds (0-6)
        if (weekdayIndex >= 0 && weekdayIndex < 7) {
          // Map each goal status to the correct weekday position
          nutrition[weekdayIndex] = mapStatus(dayData.nutration.status);
          hydration[weekdayIndex] = mapStatus(dayData.hydration.status);
          sleep[weekdayIndex] = mapStatus(dayData.sleep.status);
          steps[weekdayIndex] = mapStatus(dayData.steps.status);
          weighin[weekdayIndex] = mapStatus(dayData.weight.status);
          // Note: Fasting is not in API response, keep as missed
        } else {
          debugPrint('⚠️ Invalid weekday index: $weekdayIndex for date: ${dayData.date}');
        }
      } catch (e) {
        debugPrint('⚠️ Error processing day data for ${dayData.date}: $e');
      }
    }

    // Create consistency data
    final consistency = WeekConsistencyData(
      nutrition: nutrition,
      hydration: hydration,
      sleep: sleep,
      steps: steps,
      fasting: fasting, // Not in API, keep as missed
      weighin: weighin,
    );

    // Keep existing patterns and status insights (not from API)
    final patterns = weeklyReview.value?.patterns ?? [
      WeekPattern(
        category: 'Nutrition',
        insight: 'Dinners were least consistent mid-week',
      ),
      WeekPattern(
        category: 'Steps',
        insight: 'Steps were consistent on logged days',
      ),
    ];

    final statusInsights = weeklyReview.value?.statusInsights ?? WeekStatusInsights(
      weightTrend: 'Trending Down',
      consistency: 'Moderate',
      momentum: 'Building',
    );

    // Count days with at least one completed goal
    final daysLogged = apiData.length;

    // Update weekly review
    weeklyReview.value = WeeklyReview(
      phase: weeklyReview.value?.phase ?? 'Weight Loss',
      daysLogged: daysLogged,
      summary: weeklyReview.value?.summary ?? 'This week shows steady effort with a few gaps',
      consistency: consistency,
      patterns: patterns,
      statusInsights: statusInsights,
    );

    debugPrint('✅ Mapped API data to WeeklyReview model');
  }

  /// Load mock data for UI demonstration (fallback)
  void _loadMockData() {
    // Mock consistency data
    final consistency = WeekConsistencyData(
      nutrition: [
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.missed,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
      ],
      hydration: [
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.missed,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
      ],
      sleep: [
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.partial,
        PillarStatus.complete,
        PillarStatus.complete,
      ],
      steps: [
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.missed,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
      ],
      fasting: [
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
        PillarStatus.complete,
      ],
      weighin: [
        PillarStatus.complete,
        PillarStatus.missed,
        PillarStatus.missed,
        PillarStatus.missed,
        PillarStatus.complete,
        PillarStatus.missed,
        PillarStatus.complete,
      ],
    );

    // Mock patterns
    final patterns = [
      WeekPattern(
        category: 'Nutrition',
        insight: 'Dinners were least consistent mid-week',
      ),
      WeekPattern(
        category: 'Steps',
        insight: 'Steps were consistent on logged days',
      ),
    ];

    // Mock status insights
    final statusInsights = WeekStatusInsights(
      weightTrend: 'Trending Down',
      consistency: 'Moderate',
      momentum: 'Building',
    );

    weeklyReview.value = WeeklyReview(
      phase: 'Weight Loss',
      daysLogged: 7,
      summary: 'This week shows steady effort with a few gaps',
      consistency: consistency,
      patterns: patterns,
      statusInsights: statusInsights,
    );
  }

  /// Get status color
  Color getStatusColor(PillarStatus status) {
    switch (status) {
      case PillarStatus.complete:
        return const Color(0xFF00B8A9);
      case PillarStatus.partial:
        return const Color(0xFFF5E6D3);
      case PillarStatus.missed:
        return const Color(0xFFE5E7EB);
    }
  }

  /// Get status label
  String getStatusLabel(PillarStatus status) {
    switch (status) {
      case PillarStatus.complete:
        return 'Complete';
      case PillarStatus.partial:
        return 'Partial';
      case PillarStatus.missed:
        return 'Missed';
    }
  }

  /// Navigate back
  void onBack() {
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
    }
  }

  /// Toggle week picker
  void toggleWeekPicker() {
    showWeekPicker.value = !showWeekPicker.value;
  }

  /// Select week
  void selectWeek(int index) {
    selectedWeekIndex.value = index;
    showWeekPicker.value = false;
    // Fetch data for selected week from API
    _fetchWeeklyData();
  }

  /// Navigate to older week
  void navigateToOlderWeek() {
    if (selectedWeekIndex.value < weekOptions.length - 1) {
      selectedWeekIndex.value = selectedWeekIndex.value + 1;
      _fetchWeeklyData();
    }
  }

  /// Navigate to newer week
  void navigateToNewerWeek() {
    if (selectedWeekIndex.value > 0) {
      selectedWeekIndex.value = selectedWeekIndex.value - 1;
      _fetchWeeklyData();
    }
  }

  /// Navigate to daily details
  void navigateToDailyDetails() {
    Get.toNamed('/daily-details?from=weekly-review');
  }
}

