import 'package:flutter/material.dart';
import 'progress_over_time_chart.dart';

/// Example usage of ProgressOverTimeChart widget
/// 
/// This demonstrates how to use the reusable chart widget with mock data
/// matching the reference design behavior.
class ProgressOverTimeChartExample extends StatelessWidget {
  const ProgressOverTimeChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock weight data matching reference image
    // Dates: Apr 16, Apr 23, Apr 30, May 7, May 14
    // Weights: 84.5, 82.0, 80.5, 80.0, 79.0 (approximate from reference)
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
      backgroundColor: const Color(0xFFF5F6FA), // Light gray background
      appBar: AppBar(
        title: const Text('Progress Chart Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Example 1: Basic usage with subtitle
            ProgressOverTimeChart(
              entries: mockEntries,
              targetWeight: 70.5, // Target/goal weight
              rangeLabel: 'Last 30 Days',
            ),
            
            const SizedBox(height: 24),
            
            // Example 2: Without subtitle
            ProgressOverTimeChart(
              entries: mockEntries,
              targetWeight: 70.5,
            ),
            
            const SizedBox(height: 24),
            
            // Example 3: Custom height
            ProgressOverTimeChart(
              entries: mockEntries,
              targetWeight: 70.5,
              rangeLabel: 'Last 7 Days',
              chartHeight: 260,
            ),
            
            const SizedBox(height: 24),
            
            // Example 4: Empty state
            ProgressOverTimeChart(
              entries: [],
              targetWeight: 70.5,
              rangeLabel: 'No Data',
            ),
          ],
        ),
      ),
    );
  }
}

/// Integration example: How to use with real data from API/Controller
/// 
/// ```dart
/// // In your screen/widget:
/// Obx(() {
///   final weightHistory = controller.weightHistory;
///   
///   // Convert WeightEntry to ChartWeightEntry
///   final chartEntries = weightHistory.map((entry) {
///     return ChartWeightEntry(
///       date: DateTime.parse(entry.date),
///       weight: entry.weight,
///     );
///   }).toList();
///   
///   return ProgressOverTimeChart(
///     entries: chartEntries,
///     targetWeight: controller.goalWeight,
///     rangeLabel: 'Last 30 Days',
///   );
/// });
/// ```
