import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/model/daily_summary.dart';
import '../../../data/model/trend_data.dart';

/// Daily Summary Controller using GetX - UI Only (No API)
class DailySummaryController extends GetxController {
  // Selected date
  final selectedDate = DateTime.now().obs;

  // Loading state
  final isGenerating = false.obs;

  // Error state
  final error = RxString('');

  // Summary data
  final summary = Rx<DailySummary?>(null);

  // 7-day trend data
  final trendData = <TrendData>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load mock data immediately
    _loadMockData();
  }

  /// Load mock data for UI demonstration
  void _loadMockData() {
    // Simulate loading
    isGenerating.value = true;
    
    Future.delayed(const Duration(seconds: 2), () {
      // Generate mock trend data
      _generateTrendData();
      
      // Create mock summary
      summary.value = DailySummary(
        overallScore: 76,
        summary: 'Solid progress today! A few areas to improve, but overall you\'re on track.',
        cached: true,
        trends: DailyTrends(
          steps: 'neutral',
          sleep: 'neutral',
          water: 'down',
        ),
        highlights: [
          'Excellent sleep with 7.2 hours',
        ],
        concerns: [
          'Only 7,543 steps today - below your goal',
          'No meals logged today',
        ],
        recommendations: [
          'Try a 15-minute walk to boost your step count',
          'Log your meals to track nutrition patterns',
        ],
        generatedAt: DateTime.now(),
      );
      
      isGenerating.value = false;
      error.value = '';
    });
  }

  /// Generate summary (mock - for retry button)
  Future<void> generateSummary() async {
    _loadMockData();
  }

  /// Generate 7-day trend data for charts (Mock Data)
  void _generateTrendData() {
    // Get the last 7 days (Sunday to Saturday)
    final now = selectedDate.value;
    final dayOfWeek = now.weekday % 7; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    final startDate = now.subtract(Duration(days: dayOfWeek));

    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final data = <TrendData>[];

    // Mock data matching the reference images
    // Steps: Sunday (high), Monday (high), Tuesday (low), Wednesday (highest), Thursday-Friday (medium-high), Saturday (high)
    final stepsData = [8500, 8200, 5500, 10000, 7500, 7800, 8000];
    
    // Sleep: Sunday (high), Monday (high), Tuesday (medium), Wednesday (highest), Thursday (low), Friday-Saturday (high)
    final sleepData = [7.5, 7.8, 6.8, 8.5, 6.2, 7.6, 7.4];
    
    // Water: Sunday (highest), Monday (high), Tuesday (lowest), Wednesday (medium), Thursday (high), Friday (medium), Saturday (low)
    final waterData = [3.0, 2.5, 1.2, 2.0, 2.8, 2.2, 1.8];

    for (int i = 0; i < 7; i++) {
      data.add(TrendData(
        day: days[i],
        steps: stepsData[i],
        sleep: sleepData[i],
        water: waterData[i],
      ));
    }

    trendData.value = data;
  }

  /// Get score color gradient based on score
  List<Color> getScoreColors(int score) {
    if (score >= 80) {
      return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Yellow to Orange
    } else if (score >= 60) {
      return [const Color(0xFFFFA500), const Color(0xFFFF6347)]; // Orange to Red-Orange
    } else {
      return [const Color(0xFFFF6347), const Color(0xFFDC143C)]; // Red-Orange to Crimson
    }
  }

  /// Get trend icon based on trend direction
  IconData getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'up':
        return Icons.arrow_upward;
      case 'down':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  /// Navigate back
  void onBack() {
    Get.back();
  }

  /// Navigate to home page
  void navigateToHome() {
    Get.offAllNamed('/home');
  }

  /// Update selected date
  void updateSelectedDate(DateTime date) {
    selectedDate.value = date;
    generateSummary();
  }
}

