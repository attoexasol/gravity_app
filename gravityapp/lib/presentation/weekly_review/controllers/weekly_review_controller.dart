import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/model/weekly_review.dart';
import '../../../app/routes/app_routes.dart';

/// Weekly Review Controller using GetX - UI Only (No API)
class WeeklyReviewController extends GetxController {
  // Selected week index
  final selectedWeekIndex = 0.obs;

  // Show week picker modal
  final showWeekPicker = false.obs;

  // Week options
  final weekOptions = <WeekOption>[].obs;

  // Weekly review data
  final weeklyReview = Rx<WeeklyReview?>(null);

  @override
  void onInit() {
    super.onInit();
    _generateWeekOptions();
    _loadMockData();
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

      final formatDate = (DateTime date) {
        return DateFormat('MMM d').format(date);
      };

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

  /// Load mock data for UI demonstration
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
    // Reload data for selected week (in real app, this would fetch from API)
    _loadMockData();
  }

  /// Navigate to older week
  void navigateToOlderWeek() {
    if (selectedWeekIndex.value < weekOptions.length - 1) {
      selectedWeekIndex.value = selectedWeekIndex.value + 1;
      _loadMockData();
    }
  }

  /// Navigate to newer week
  void navigateToNewerWeek() {
    if (selectedWeekIndex.value > 0) {
      selectedWeekIndex.value = selectedWeekIndex.value - 1;
      _loadMockData();
    }
  }

  /// Navigate to daily details
  void navigateToDailyDetails() {
    Get.toNamed('/daily-details?from=weekly-review');
  }
}

