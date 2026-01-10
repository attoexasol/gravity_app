import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/model/weight_history.dart';
import '../../../../app/routes/app_routes.dart';

class WeightHistoryController extends GetxController {
  // Weight data
  final double goalWeight = 71.5;
  final double currentWeight = 79.0;
  final double startingWeight = 85.0;
  final double weeklyAverage = 1.6; // kg per week

  // Weight history entries
  List<WeightEntry> get weightHistory => [
    WeightEntry(
      date: '2025-04-16',
      weight: 85.0,
      displayDate: 'Apr 16',
    ),
    WeightEntry(
      date: '2025-04-23',
      weight: 83.5,
      displayDate: 'Apr 23',
    ),
    WeightEntry(
      date: '2025-04-30',
      weight: 82.2,
      displayDate: 'Apr 30',
    ),
    WeightEntry(
      date: '2025-05-07',
      weight: 80.8,
      displayDate: 'May 7',
    ),
    WeightEntry(
      date: '2025-05-14',
      weight: 79.0,
      displayDate: 'May 14',
    ),
  ];

  // Get reversed entries (latest first)
  List<WeightEntry> get recentEntries => weightHistory.reversed.toList();

  // Calculated values
  double get totalLoss => startingWeight - currentWeight;
  double get remaining => currentWeight - goalWeight;
  int get weeksTracking => weightHistory.length - 1;

  // Calculate estimated target date
  String get estimatedTargetDate {
    final weeksRemaining = (remaining / weeklyAverage).ceil();
    final estimatedDate = DateTime.now().add(Duration(days: weeksRemaining * 7));
    return DateFormat('MMMM yyyy', 'en_US').format(estimatedDate);
  }

  // Chart data points
  List<FlSpot> get chartSpots {
    return weightHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  // Chart Y-axis domain
  double get minY => goalWeight - 2;
  double get maxY => startingWeight + 2;

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

  void onEditEntry(WeightEntry entry) {
    // TODO: Implement edit entry functionality
    print('Edit entry: ${entry.weight} kg on ${entry.date}');
  }
}

