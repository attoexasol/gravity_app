import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/weekly_review_controller.dart';
import 'sections/weekly_review_header.dart';
import 'sections/weekly_summary_card.dart';
import 'sections/status_insight_cards.dart';
import 'sections/weekly_consistency_grid.dart';
import 'sections/patterns_section.dart';
import 'sections/view_daily_details_button.dart';
import 'sections/week_picker_modal.dart';

class WeeklyReviewScreen extends GetView<WeeklyReviewController> {
  const WeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Obx(() {
              if (controller.weeklyReview.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header
                    WeeklyReviewHeader(controller: controller),
                    
                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                      child: Column(
                        children: [
                          // Weekly Summary Card
                          WeeklySummaryCard(controller: controller),
                          SizedBox(height: 16.h),
                          
                          // Status Insight Cards
                          StatusInsightCards(controller: controller),
                          SizedBox(height: 24.h),
                          
                          // Weekly Consistency Grid
                          WeeklyConsistencyGrid(controller: controller),
                          SizedBox(height: 24.h),
                          
                          // Patterns Section
                          PatternsSection(controller: controller),
                          SizedBox(height: 24.h),
                          
                          // View Daily Details Button
                          ViewDailyDetailsButton(controller: controller),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            // Week Picker Modal (overlay)
            WeekPickerModal(controller: controller),
          ],
        ),
      ),
    );
  }
}

