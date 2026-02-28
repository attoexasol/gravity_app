import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/daily_details_controller.dart';
import 'sections/daily_details_header.dart';
import 'sections/day_summary_card.dart';
import 'sections/pillar_breakdown_section.dart';
import 'sections/daily_reflection_section.dart';
import 'sections/back_button_section.dart';

class DailyDetailsScreen extends GetView<DailyDetailsController> {
  const DailyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header with navigation
            DailyDetailsHeader(controller: controller),
            // Scrollable content with slide animation
            Expanded(
              child: Obx(() {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final direction = controller.direction.value;
                    final offset = direction > 0 ? 0.3 : -0.3;
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(offset, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Builder(
                    key: ValueKey<int>(controller.currentDayIndex.value),
                    builder: (context) => SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Day Summary Card
                          DaySummaryCard(controller: controller),
                          // Pillar Breakdown
                          PillarBreakdownSection(controller: controller),
                          SizedBox(height: 16.h),
                          // Daily Reflection
                          DailyReflectionSection(controller: controller),
                          SizedBox(height: 16.h),
                          // Back Button
                          BackButtonSection(controller: controller),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

