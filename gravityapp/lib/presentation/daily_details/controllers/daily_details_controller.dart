import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/model/daily_details.dart';
import '../../../../app/routes/app_routes.dart';

class DailyDetailsController extends GetxController {
  // Source screen: 'dashboard' or 'weekly-review'
  final String fromScreen;
  
  // Current day index
  final RxInt currentDayIndex = 0.obs;

  // Animation direction for slide transitions
  final RxInt direction = 0.obs;

  // All days data
  final List<DayData> allDaysData = [];

  /// Header date string (day name + date). Uses real current date when viewing today (index 0).
  final RxString headerDateText = ''.obs;

  DailyDetailsController({this.fromScreen = 'dashboard'}) {
    _initializeData();
    _setInitialDayIndex();
  }

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
    // Dashboard → Show today (index 0), Weekly Review → Show Tuesday of that week (index 2)
    if (fromScreen == 'dashboard') {
      currentDayIndex.value = 0;
    } else {
      currentDayIndex.value = 2; // Tuesday (May 7)
    }
    _updateHeaderDateText();
  }

  DayData get currentDay => allDaysData[currentDayIndex.value];

  void _updateHeaderDateText() {
    if (currentDayIndex.value == 0) {
      headerDateText.value = DateFormat('EEEE, MMMM d').format(DateTime.now());
    } else {
      headerDateText.value = currentDay.fullDate;
    }
  }

  bool get canGoPrevious => currentDayIndex.value > 0;
  bool get canGoNext => currentDayIndex.value < allDaysData.length - 1;

  void goToPreviousDay() {
    if (canGoPrevious) {
      direction.value = -1;
      currentDayIndex.value--;
      _updateHeaderDateText();
    }
  }

  void goToNextDay() {
    if (canGoNext) {
      direction.value = 1;
      currentDayIndex.value++;
      _updateHeaderDateText();
    }
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
        return const Color(0xFFE5E7EB);
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

