import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/weight_history_controller.dart';
import 'sections/weight_history_header.dart';
import 'sections/progress_chart_section.dart';
import 'sections/estimated_target_date_section.dart';
import 'sections/recent_entries_section.dart';
import 'sections/journey_stats_section.dart';

class WeightHistoryScreen extends GetView<WeightHistoryController> {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            WeightHistoryHeader(controller: controller),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24.h),
                    // Progress Chart
                    ProgressChartSection(controller: controller),
                    SizedBox(height: 16.h),
                    // Estimated Target Date
                    EstimatedTargetDateSection(controller: controller),
                    SizedBox(height: 16.h),
                    // Recent Entries
                    RecentEntriesSection(controller: controller),
                    SizedBox(height: 16.h),
                    // Journey Stats
                    JourneyStatsSection(controller: controller),
                    SizedBox(height: 96.h), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

