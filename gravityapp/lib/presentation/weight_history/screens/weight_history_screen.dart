import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/weight_history_controller.dart';
import 'sections/weight_history_header.dart';
import 'sections/progress_chart_section.dart';
import 'sections/estimated_target_date_section.dart';
import 'sections/recent_entries_section.dart';
import 'sections/journey_stats_section.dart';
import '../../../../app/theme/app_text_styles.dart';

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
                    SizedBox(height: 16.h),
                    // Disclaimer Banner
                    _buildDisclaimerBanner(),
                    SizedBox(height: 16.h),
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

  Widget _buildDisclaimerBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Light yellow background
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20.sp,
            color: const Color(0xFFD4AF37),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'This is an estimate — progress isn\'t always linear',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

