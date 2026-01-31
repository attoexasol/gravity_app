import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'progress_chart_section.dart';

/// Example usage of ProgressChartSection with mock weekly data
/// 
/// This demonstrates how the chart works with weekly weight entries
/// matching the reference design behavior.
class ProgressChartExample extends StatelessWidget {
  const ProgressChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock weekly weight data
    // Example: Apr 16, Apr 23, Apr 30, May 7, May 14
    final mockEntries = [
      ChartWeightEntry(
        date: DateTime(2024, 4, 16),
        weight: 84.5,
      ),
      ChartWeightEntry(
        date: DateTime(2024, 4, 23),
        weight: 82.0,
      ),
      ChartWeightEntry(
        date: DateTime(2024, 4, 30),
        weight: 80.5,
      ),
      ChartWeightEntry(
        date: DateTime(2024, 5, 7),
        weight: 80.0,
      ),
      ChartWeightEntry(
        date: DateTime(2024, 5, 14),
        weight: 79.0,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Progress Chart Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Example chart with mock data
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildExampleChart(mockEntries),
            ),
          ],
        ),
      ),
    );
  }

  /// Build example chart (simplified version for demonstration)
  Widget _buildExampleChart(List<ChartWeightEntry> entries) {
    // Calculate Y-axis bounds
    final weights = entries.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    // Y-axis bounds (minY, maxY) and FlSpot list - use with real chart in ProgressChartSection
    final minY = (minWeight - 2).roundToDouble();
    final maxY = (maxWeight + 2).roundToDouble();
    final chartSpots = entries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    // This is a simplified example - in production, use ProgressChartSection widget
    return const SizedBox(
      height: 240,
      child: Center(
        child: Text(
          'Use ProgressChartSection widget with WeightHistoryController',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Integration guide:
/// 
/// To use ProgressChartSection in your app:
/// 
/// 1. Ensure you have WeightHistoryController set up:
/// ```dart
/// final controller = Get.put(WeightHistoryController());
/// await controller.fetchWeightHistory();
/// ```
/// 
/// 2. Use the widget in your screen:
/// ```dart
/// ProgressChartSection(
///   controller: controller,
/// )
/// ```
/// 
/// 3. The widget automatically:
/// - Sorts entries by date (oldest to newest)
/// - Calculates Y-axis bounds (min = lowest - 2, max = highest + 2)
/// - Uses 5-unit intervals for Y-axis (70, 75, 80, 85)
/// - Formats dates as "Apr 16", "Apr 23", etc.
/// - Shows target line with label
/// - Handles empty states
