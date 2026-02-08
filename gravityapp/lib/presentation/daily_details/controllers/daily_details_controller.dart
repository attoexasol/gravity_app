import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/model/daily_details.dart';
import '../../../../data/model/day_activity.dart';
import '../../../../data/repositories/user_gravity_repository.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../app/routes/app_routes.dart';

class DailyDetailsController extends GetxController {
  // Source screen: 'dashboard' or 'weekly-review'
  final String fromScreen;
  
  // Current day index (used for mock pillar data; derived from selectedDate)
  final RxInt currentDayIndex = 0.obs;

  // Animation direction for slide transitions
  final RxInt direction = 0.obs;

  // All days data
  final List<DayData> allDaysData = [];

  /// Selected calendar date (day-by-day navigation). Previous = yesterday, Next = tomorrow.
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());

  /// Header date string (day name + date). Driven by selectedDate.
  final RxString headerDateText = ''.obs;

  /// Day-wise daily reflection from API; when non-empty, "+ Add reflection" is hidden.
  final Rx<String?> dailyReflection = Rx<String?>(null);

  /// Day-wise activity from API (weight, steps, sleep, hydration, nutration). When non-null, Pillar Breakdown and Day Summary use this.
  final Rx<DayActivityData?> dayActivityData = Rx<DayActivityData?>(null);

  final UserGravityRepository _gravityRepository = UserGravityRepository();

  DailyDetailsController({this.fromScreen = 'dashboard'}) {
    _initializeData();
    _setInitialDayIndex();
  }

  /// Selected date in YYYY-MM-DD for API calls
  String get selectedDateYyyyMmDd => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    _fetchDayActivityForSelectedDate();
    _fetchDailyReflectionForSelectedDate();
  }

  Future<void> _fetchDayActivityForSelectedDate() async {
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      dayActivityData.value = null;
      return;
    }
    final response = await _gravityRepository.getDayActivity(
      apiToken: apiToken,
      date: selectedDateYyyyMmDd,
    );
    dayActivityData.value = response.isSuccess ? response.data : null;
  }

  Future<void> _fetchDailyReflectionForSelectedDate() async {
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      dailyReflection.value = null;
      return;
    }
    final reflection = await _gravityRepository.getDailyReflectionByDate(
      apiToken: apiToken,
      date: selectedDateYyyyMmDd,
    );
    dailyReflection.value = reflection;
  }

  /// Refetch daily reflection for the current selected date (e.g. after returning from Today where user added one).
  Future<void> refetchDailyReflection() async {
    await _fetchDailyReflectionForSelectedDate();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _initializeData() {
    // Mock data - Add today's data (Jan 5, 2026) and the week (May 6-12)
    allDaysData.addAll([
      // Today's data (Jan 5, 2026) - shown when coming from Dashboard
      DayData(
        date: 'Jan 5',
        dayName: 'Monday',
        fullDate: 'Monday, January 5',
        mood: DayMood.great,
        moodEmoji: '🤩',
        moodLabel: 'Great day',
        pillarsCompleted: 4,
        totalPillars: 4,
        morningTag: 'Energized',
        eveningTag: 'Focused',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.complete, detail: '2 meals logged - OMAD'),
          hydration: Pillar(status: PillarStatus.complete, detail: '8 glasses so far'),
          sleep: Pillar(status: PillarStatus.complete, detail: '7.5 hours - Quality rest'),
          step: Pillar(status: PillarStatus.complete, detail: '10,500 steps today'),
          fasting: Pillar(status: PillarStatus.complete, detail: '18:6 window maintained'),
          weighin: Pillar(status: PillarStatus.none, detail: 'Not scheduled'),
        ),
        reflection: 'Feeling strong today! Stuck to my fasting window and made healthy meal choices. Energy levels are great.',
      ),
      // Historical week data (May 6-12)
      DayData(
        date: 'May 6',
        dayName: 'Monday',
        fullDate: 'Monday, May 6',
        mood: DayMood.good,
        moodEmoji: '😊',
        moodLabel: 'Good day',
        pillarsCompleted: 5,
        totalPillars: 5,
        morningTag: 'Strong',
        eveningTag: 'Balanced',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.complete, detail: '3 balanced meals'),
          hydration: Pillar(status: PillarStatus.complete, detail: '10 glasses'),
          sleep: Pillar(status: PillarStatus.complete, detail: '8 hours'),
          step: Pillar(status: PillarStatus.complete, detail: '12,000 steps'),
          fasting: Pillar(status: PillarStatus.complete, detail: '16:8 maintained'),
          weighin: Pillar(status: PillarStatus.complete, detail: '82.8 kg'),
        ),
      ),
      DayData(
        date: 'May 7',
        dayName: 'Tuesday',
        fullDate: 'Tuesday, May 7',
        mood: DayMood.good,
        moodEmoji: '😊',
        moodLabel: 'Good day',
        pillarsCompleted: 4,
        totalPillars: 5,
        morningTag: 'Strong',
        eveningTag: 'Mixed',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.complete, detail: '3 balanced meals'),
          hydration: Pillar(status: PillarStatus.complete, detail: '9 glasses'),
          sleep: Pillar(status: PillarStatus.partial, detail: '6 hours - Stayed up late reading'),
          step: Pillar(status: PillarStatus.complete, detail: '10,200 steps'),
          fasting: Pillar(status: PillarStatus.complete, detail: '16:8 maintained'),
          weighin: Pillar(status: PillarStatus.none, detail: 'Not scheduled'),
        ),
      ),
      DayData(
        date: 'May 8',
        dayName: 'Wednesday',
        fullDate: 'Wednesday, May 8',
        mood: DayMood.okay,
        moodEmoji: '😐',
        moodLabel: 'Okay day',
        pillarsCompleted: 3,
        totalPillars: 5,
        morningTag: 'Slow',
        eveningTag: 'Better',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.missed, detail: 'Skipped lunch, late dinner'),
          hydration: Pillar(status: PillarStatus.complete, detail: '8 glasses'),
          sleep: Pillar(status: PillarStatus.complete, detail: '7.5 hours'),
          step: Pillar(status: PillarStatus.missed, detail: 'Only 4,200 steps'),
          fasting: Pillar(status: PillarStatus.complete, detail: '18:6 extended'),
          weighin: Pillar(status: PillarStatus.none, detail: 'Not scheduled'),
        ),
      ),
      DayData(
        date: 'May 9',
        dayName: 'Thursday',
        fullDate: 'Thursday, May 9',
        mood: DayMood.good,
        moodEmoji: '😊',
        moodLabel: 'Good day',
        pillarsCompleted: 4,
        totalPillars: 5,
        morningTag: 'Energized',
        eveningTag: 'Productive',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.complete, detail: '2 meals (OMAD)'),
          hydration: Pillar(status: PillarStatus.missed, detail: 'Only 5 glasses'),
          sleep: Pillar(status: PillarStatus.complete, detail: '8 hours'),
          step: Pillar(status: PillarStatus.complete, detail: '11,500 steps'),
          fasting: Pillar(status: PillarStatus.complete, detail: '20:4 OMAD'),
          weighin: Pillar(status: PillarStatus.none, detail: 'Not scheduled'),
        ),
      ),
      DayData(
        date: 'May 10',
        dayName: 'Friday',
        fullDate: 'Friday, May 10',
        mood: DayMood.good,
        moodEmoji: '😊',
        moodLabel: 'Good day',
        pillarsCompleted: 4,
        totalPillars: 5,
        morningTag: 'Great',
        eveningTag: 'Relaxed',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.complete, detail: '3 balanced meals'),
          hydration: Pillar(status: PillarStatus.complete, detail: '10 glasses'),
          sleep: Pillar(status: PillarStatus.partial, detail: '5.5 hours - Late night out'),
          step: Pillar(status: PillarStatus.complete, detail: '9,800 steps'),
          fasting: Pillar(status: PillarStatus.complete, detail: '16:8 maintained'),
          weighin: Pillar(status: PillarStatus.none, detail: 'Not scheduled'),
        ),
      ),
      DayData(
        date: 'May 11',
        dayName: 'Saturday',
        fullDate: 'Saturday, May 11',
        mood: DayMood.great,
        moodEmoji: '🤩',
        moodLabel: 'Great day',
        pillarsCompleted: 5,
        totalPillars: 5,
        morningTag: 'Refreshed',
        eveningTag: 'Accomplished',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.complete, detail: '3 balanced meals'),
          hydration: Pillar(status: PillarStatus.complete, detail: '12 glasses'),
          sleep: Pillar(status: PillarStatus.complete, detail: '9 hours'),
          step: Pillar(status: PillarStatus.complete, detail: '15,000 steps - Long walk'),
          fasting: Pillar(status: PillarStatus.complete, detail: '16:8 maintained'),
          weighin: Pillar(status: PillarStatus.none, detail: 'Not scheduled'),
        ),
      ),
      DayData(
        date: 'May 12',
        dayName: 'Sunday',
        fullDate: 'Sunday, May 12',
        mood: DayMood.okay,
        moodEmoji: '😐',
        moodLabel: 'Okay day',
        pillarsCompleted: 4,
        totalPillars: 6,
        morningTag: 'Lazy',
        eveningTag: 'Calm',
        pillars: DayPillars(
          nutrition: Pillar(status: PillarStatus.partial, detail: '2 meals - OMAD attempt'),
          hydration: Pillar(status: PillarStatus.complete, detail: '7 glasses'),
          sleep: Pillar(status: PillarStatus.complete, detail: '8 hours'),
          step: Pillar(status: PillarStatus.partial, detail: '6,200 steps - Rest day'),
          fasting: Pillar(status: PillarStatus.complete, detail: '20:4 extended'),
          weighin: Pillar(status: PillarStatus.complete, detail: '82.1 kg'),
        ),
      ),
    ]);
  }

  void _setInitialDayIndex() {
    selectedDate.value = _dateOnly(DateTime.now());
    _syncCurrentDayIndexFromSelectedDate();
    _updateHeaderDateText();
  }

  DayData get currentDay => allDaysData[currentDayIndex.value];

  /// Day to show: from day-activity API when available, else mock currentDay.
  DayData get displayDay {
    final api = dayActivityData.value;
    if (api != null) return _dayDataFromApi(api);
    return currentDay;
  }

  static PillarStatus _apiStatusToPillarStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'complete':
        return PillarStatus.complete;
      case 'partial':
        return PillarStatus.partial;
      case 'missed':
      case 'missing':
        return PillarStatus.missed;
      default:
        return PillarStatus.none;
    }
  }

  DayData _dayDataFromApi(DayActivityData api) {
    final d = selectedDate.value;
    final dateStr = DateFormat('MMM d').format(d);
    final dayName = DateFormat('EEEE').format(d);
    final fullDateStr = DateFormat('EEEE, MMMM d').format(d);

    final nutrition = api.nutration != null
        ? Pillar(
            status: _apiStatusToPillarStatus(api.nutration!.status),
            detail: api.nutration!.actualString.isNotEmpty
                ? '${api.nutration!.actualString} cal'
                : 'Logged',
          )
        : Pillar(status: PillarStatus.none, detail: 'Not logged');
    final hydration = api.hydration != null
        ? Pillar(
            status: _apiStatusToPillarStatus(api.hydration!.status),
            detail: api.hydration!.actualString.isNotEmpty
                ? api.hydration!.actualString
                : (api.hydration!.goal ?? '—'),
          )
        : Pillar(status: PillarStatus.none, detail: '—');
    final sleep = api.sleep != null
        ? Pillar(
            status: _apiStatusToPillarStatus(api.sleep!.status),
            detail: api.sleep!.actualString.isNotEmpty
                ? '${api.sleep!.actualString} hours'
                : (api.sleep!.goal != null ? '${api.sleep!.goal} hours' : '—'),
          )
        : Pillar(status: PillarStatus.none, detail: '—');
    final step = api.steps != null
        ? Pillar(
            status: _apiStatusToPillarStatus(api.steps!.status),
            detail: api.steps!.actualString.isNotEmpty
                ? '${api.steps!.actualString} steps today'
                : (api.steps!.goal ?? '—'),
          )
        : Pillar(status: PillarStatus.none, detail: '—');
    final fasting = api.fasting != null
        ? Pillar(
            status: _apiStatusToPillarStatus(api.fasting!.status),
            detail: api.fasting!.detailString,
          )
        : Pillar(status: PillarStatus.none, detail: 'Not scheduled');
    final weighin = api.weight != null
        ? Pillar(
            status: _apiStatusToPillarStatus(api.weight!.status),
            detail: api.weight!.actualString.isNotEmpty
                ? '${api.weight!.actualString} kg'
                : (api.weight!.goal != null ? '${api.weight!.goal} kg' : 'Not scheduled'),
          )
        : Pillar(status: PillarStatus.none, detail: 'Not scheduled');

    final pillars = DayPillars(
      nutrition: nutrition,
      hydration: hydration,
      sleep: sleep,
      step: step,
      fasting: fasting,
      weighin: weighin,
    );

    // Count only fully Complete pillars (not Partial) so Summary matches Pillar Breakdown
    int completed = 0;
    for (final p in [nutrition, hydration, sleep, step, fasting, weighin]) {
      if (p.status == PillarStatus.complete) completed++;
    }
    const totalPillars = 6;

    // Derive morning/evening tags from pillar data (API does not provide them)
    final morningTag = _deriveMorningTag(sleep, nutrition, hydration);
    final eveningTag = _deriveEveningTag(step, completed, totalPillars);

    DayMood mood;
    String moodLabel;
    String moodEmoji;
    if (completed == totalPillars) {
      mood = DayMood.great;
      moodLabel = 'Great day';
      moodEmoji = '🤩';
    } else if (completed >= totalPillars - 1) {
      mood = DayMood.good;
      moodLabel = 'Good day';
      moodEmoji = '😊';
    } else if (completed >= totalPillars - 2) {
      mood = DayMood.okay;
      moodLabel = 'Okay day';
      moodEmoji = '😐';
    } else {
      mood = DayMood.tough;
      moodLabel = 'Tough day';
      moodEmoji = '😓';
    }

    return DayData(
      date: dateStr,
      dayName: dayName,
      fullDate: fullDateStr,
      mood: mood,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      pillarsCompleted: completed,
      totalPillars: totalPillars,
      morningTag: morningTag,
      eveningTag: eveningTag,
      pillars: pillars,
      reflection: null,
    );
  }

  /// Derives morning tag from sleep + nutrition + hydration (start-of-day pillars).
  static String _deriveMorningTag(Pillar sleep, Pillar nutrition, Pillar hydration) {
    int n = 0;
    if (sleep.status == PillarStatus.complete) n++;
    if (nutrition.status == PillarStatus.complete) n++;
    if (hydration.status == PillarStatus.complete) n++;
    if (n >= 3) return 'Energized';
    if (n == 2) return 'Strong';
    if (n == 1) return 'Mixed';
    return 'Slow';
  }

  /// Derives evening tag from steps and overall completion (end-of-day / activity).
  static String _deriveEveningTag(Pillar step, int completed, int totalPillars) {
    final stepsComplete = step.status == PillarStatus.complete;
    if (stepsComplete && completed >= totalPillars - 1) return 'Focused';
    if (stepsComplete && completed >= 2) return 'Balanced';
    if (step.status == PillarStatus.partial || completed == 1) return 'Mixed';
    return 'Calm';
  }

  void _syncCurrentDayIndexFromSelectedDate() {
    final today = _dateOnly(DateTime.now());
    final daysDiff = today.difference(selectedDate.value).inDays;
    currentDayIndex.value = daysDiff.clamp(0, allDaysData.length - 1);
  }

  void _updateHeaderDateText() {
    headerDateText.value = DateFormat('EEEE, MMMM d').format(selectedDate.value);
  }

  /// Left arrow: always allow navigating to previous dates.
  bool get canGoPrevious => true;

  /// Right arrow: enabled only when selectedDate is before today (date-only comparison).
  /// Disabled when selectedDate is today to prevent navigation to future dates.
  bool get canGoNext =>
      _dateOnly(selectedDate.value).isBefore(_dateOnly(DateTime.now()));

  /// True when the displayed day is today (used to show "+ Add reflection" only for present day).
  bool get isSelectedDateToday =>
      _dateOnly(selectedDate.value) == _dateOnly(DateTime.now());

  void goToPreviousDay() {
    direction.value = -1;
    selectedDate.value = _dateOnly(selectedDate.value.subtract(const Duration(days: 1)));
    _syncCurrentDayIndexFromSelectedDate();
    _updateHeaderDateText();
    _fetchDayActivityForSelectedDate();
    _fetchDailyReflectionForSelectedDate();
  }

  void goToNextDay() {
    direction.value = 1;
    selectedDate.value = _dateOnly(selectedDate.value.add(const Duration(days: 1)));
    _syncCurrentDayIndexFromSelectedDate();
    _updateHeaderDateText();
    _fetchDayActivityForSelectedDate();
    _fetchDailyReflectionForSelectedDate();
  }

  void onBack() {
    // Always navigate to dashboard
    Get.offNamed(AppRoutes.home);
  }

  // Helper methods for status
  String getStatusLabel(PillarStatus status) {
    switch (status) {
      case PillarStatus.complete:
        return 'Complete';
      case PillarStatus.partial:
        return 'Partial';
      case PillarStatus.missed:
        return 'Missed';
      case PillarStatus.none:
        return 'Not scheduled';
    }
  }

  String getStatusIcon(PillarStatus status) {
    switch (status) {
      case PillarStatus.complete:
        return '✓';
      case PillarStatus.partial:
        return '⚠️';
      case PillarStatus.missed:
        return '✕';
      case PillarStatus.none:
        return '-';
    }
  }

  Color getStatusIconColor(PillarStatus status) {
    switch (status) {
      case PillarStatus.complete:
        return const Color(0xFF00B8A9);
      case PillarStatus.partial:
        return const Color(0xFFF5E6D3);
      case PillarStatus.missed:
        return const Color(0xFFE53935); // Red when data is missing
      case PillarStatus.none:
        return const Color(0xFF0A2342).withOpacity(0.3);
    }
  }

  Color getStatusBorderColor(PillarStatus status) {
    switch (status) {
      case PillarStatus.complete:
        return const Color(0xFF00B8A9).withOpacity(0.3);
      case PillarStatus.partial:
        return const Color(0xFFD4AF37).withOpacity(0.3);
      case PillarStatus.missed:
        return const Color(0xFFE5E7EB);
      case PillarStatus.none:
        return const Color(0xFFE5E7EB);
    }
  }

  Color getStatusBackgroundColor(PillarStatus status) {
    switch (status) {
      case PillarStatus.complete:
        return const Color(0xFFE6F7F5);
      case PillarStatus.partial:
        return const Color(0xFFFFF9E6);
      case PillarStatus.missed:
        return const Color(0xFFF5F6FA);
      case PillarStatus.none:
        return Colors.white;
    }
  }
}

