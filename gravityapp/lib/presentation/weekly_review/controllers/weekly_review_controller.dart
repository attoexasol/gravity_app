import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../../data/model/weekly_review.dart';
import '../../../data/model/day_wise_goal_completion.dart';
import '../../../data/repositories/user_gravity_repository.dart';
import '../../../core/services/token_manager.dart';
import '../../../app/routes/app_routes.dart';

/// Helper to score a pillar from weekly consistency (score = complete×2 + partial×1, max 14).
class _PillarScore {
  final String name;
  final int score;
  final int complete;
  final int partial;
  final int missed;

  _PillarScore({
    required this.name,
    required this.score,
    required this.complete,
    required this.partial,
    required this.missed,
  });
}

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
        case 'complete':
          return PillarStatus.complete;
        case 'partial':
          return PillarStatus.partial;
        case 'missed':
        case 'missing':
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
          fasting[weekdayIndex] = mapStatus(dayData.fasting.status);
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
      fasting: fasting,
      weighin: weighin,
    );

    // Weight trend: first vs last day of week (when API provides weight value)
    double? weightStart;
    double? weightEnd;
    if (apiData.isNotEmpty) {
      final sorted = List<DayWiseGoalCompletion>.from(apiData)
        ..sort((a, b) => (a.date).compareTo(b.date));
      weightStart = sorted.first.weight.value;
      weightEnd = sorted.last.weight.value;
    }

    // Derive from consistency grid (no mock/static strings)
    final daysLogged = _computeDaysLogged(consistency);
    final summary = _computeSummary(consistency, daysLogged);
    final statusInsights = _computeStatusInsights(
      consistency,
      weightStart: weightStart,
      weightEnd: weightEnd,
    );
    final patterns = generateTopAndBottomPatterns(consistency);

    // Update weekly review
    weeklyReview.value = WeeklyReview(
      phase: weeklyReview.value?.phase ?? 'Weight Loss',
      daysLogged: daysLogged,
      summary: summary,
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

    // Derive from consistency grid (same as API path)
    final daysLogged = _computeDaysLogged(consistency);
    final summary = _computeSummary(consistency, daysLogged);
    final statusInsights = _computeStatusInsights(consistency);
    final patterns = generateTopAndBottomPatterns(consistency);

    weeklyReview.value = WeeklyReview(
      phase: 'Weight Loss',
      daysLogged: daysLogged,
      summary: summary,
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

  // --- Computed from WeekConsistencyData (no UI changes) ---

  static const int _daysInWeek = 7;
  static const int _pillarsCount = 6;

  /// Count days where at least one pillar is complete or partial.
  int _computeDaysLogged(WeekConsistencyData c) {
    int count = 0;
    for (int day = 0; day < _daysInWeek; day++) {
      final hasLogged = c.nutrition[day] != PillarStatus.missed ||
          c.hydration[day] != PillarStatus.missed ||
          c.sleep[day] != PillarStatus.missed ||
          c.steps[day] != PillarStatus.missed ||
          c.fasting[day] != PillarStatus.missed ||
          c.weighin[day] != PillarStatus.missed;
      if (hasLogged) count++;
    }
    return count;
  }

  /// Consistency percentage: (complete + 0.5 * partial) / totalPossible * 100.
  double _computeConsistencyPercentage(WeekConsistencyData c) {
    int complete = 0, partial = 0;
    for (final list in [c.nutrition, c.hydration, c.sleep, c.steps, c.fasting, c.weighin]) {
      for (final s in list) {
        if (s == PillarStatus.complete) complete++;
        else if (s == PillarStatus.partial) partial++;
      }
    }
    const totalPossible = _daysInWeek * _pillarsCount;
    if (totalPossible == 0) return 0;
    return ((complete + 0.5 * partial) / totalPossible) * 100;
  }

  /// Label from percentage: >=80 Strong, 60-79 Moderate, 40-59 Building, <40 Needs Focus.
  String _consistencyLabelFromPercentage(double pct) {
    if (pct >= 80) return 'Strong';
    if (pct >= 60) return 'Moderate';
    if (pct >= 40) return 'Building';
    return 'Needs Focus';
  }

  /// Momentum: compare first 3 vs last 3 days (completes). Building / Steady / Slowing.
  String _computeMomentum(WeekConsistencyData c) {
    int completeFirst3 = 0, completeLast3 = 0;
    for (final list in [c.nutrition, c.hydration, c.sleep, c.steps, c.fasting, c.weighin]) {
      for (int i = 0; i < 3; i++) {
        if (list[i] == PillarStatus.complete) completeFirst3++;
        if (list[4 + i] == PillarStatus.complete) completeLast3++;
      }
    }
    if (completeLast3 > completeFirst3) return 'Building';
    if (completeLast3 < completeFirst3) return 'Slowing';
    return 'Steady';
  }

  /// Weight trend from start vs end week weight: Trending Down / Up / Stable.
  /// When either weight is null, returns "Stable".
  String _computeWeightTrendFromValues(double? weightStart, double? weightEnd) {
    if (weightStart == null || weightEnd == null) return 'Stable';
    if (weightEnd < weightStart) return 'Trending Down';
    if (weightEnd > weightStart) return 'Trending Up';
    return 'Stable';
  }

  /// Status insights derived from consistency data.
  /// Optional [weightStart] and [weightEnd] (first/last day of week) for Weight Trend card.
  WeekStatusInsights _computeStatusInsights(
    WeekConsistencyData c, {
    double? weightStart,
    double? weightEnd,
  }) {
    final pct = _computeConsistencyPercentage(c);
    return WeekStatusInsights(
      weightTrend: _computeWeightTrendFromValues(weightStart, weightEnd),
      consistency: _consistencyLabelFromPercentage(pct),
      momentum: _computeMomentum(c),
    );
  }

  /// Smart summary text from days logged and consistency.
  String _computeSummary(WeekConsistencyData c, int daysLogged) {
    final pct = _computeConsistencyPercentage(c);
    final label = _consistencyLabelFromPercentage(pct);
    if (daysLogged == 0) {
      return 'No days logged this week. Log your first day to see insights.';
    }
    if (daysLogged == 7 && pct >= 80) {
      return 'Full week logged with strong consistency. Great momentum.';
    }
    if (daysLogged == 7) {
      return 'You logged all 7 days. Consistency is $label.';
    }
    return 'You logged $daysLogged of 7 days. Consistency is $label.';
  }

  /// Build pillar scores from consistency data. Score = (complete×2) + (partial×1), max 14.
  List<_PillarScore> _buildPillarScores(WeekConsistencyData data) {
    final List<_PillarScore> scores = [];
    final pillarData = [
      ('Nutrition', data.nutrition),
      ('Hydration', data.hydration),
      ('Sleep', data.sleep),
      ('Steps', data.steps),
      ('Fasting', data.fasting),
      ('Weigh-in', data.weighin),
    ];
    for (final e in pillarData) {
      int complete = 0, partial = 0, missed = 0;
      for (final s in e.$2) {
        switch (s) {
          case PillarStatus.complete: complete++; break;
          case PillarStatus.partial: partial++; break;
          case PillarStatus.missed: missed++; break;
        }
      }
      final score = (complete * 2) + (partial * 1);
      scores.add(_PillarScore(
        name: e.$1,
        score: score,
        complete: complete,
        partial: partial,
        missed: missed,
      ));
    }
    return scores;
  }

  /// Generate exactly 2 patterns: highest scoring pillar (green) + lowest scoring pillar (yellow).
  /// Both derived from WeekConsistencyData. Score = (complete×2) + (partial×1).
  List<WeekPattern> generateTopAndBottomPatterns(WeekConsistencyData data) {
    final scores = _buildPillarScores(data);
    if (scores.isEmpty) return [];
    if (scores.length == 1) {
      return [
        WeekPattern(
          category: scores.first.name,
          insight: '${scores.first.name} was your strongest area this week.',
        ),
        WeekPattern(
          category: scores.first.name,
          insight: '${scores.first.name} needs more consistency next week.',
        ),
      ];
    }

    // Highest score → green (first card)
    final byScoreDesc = List<_PillarScore>.from(scores)
      ..sort((a, b) => b.score.compareTo(a.score));
    final best = byScoreDesc.first;
    final worst = byScoreDesc.last;

    return [
      WeekPattern(
        category: best.name,
        insight: '${best.name} was your strongest area this week.',
      ),
      WeekPattern(
        category: worst.name,
        insight: '${worst.name} needs more consistency next week.',
      ),
    ];
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

