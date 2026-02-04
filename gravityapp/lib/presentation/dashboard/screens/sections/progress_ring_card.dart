import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_text_styles.dart';

import '../../../widgets/progress_ring.dart';

class ProgressRingsSection extends StatelessWidget {
  final dynamic controller; // Your GetX controller

  const ProgressRingsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,  
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10.r),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Progress",
              style: ResponsiveTextStyles.textLg.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A2342),
              ),
            ),
            SizedBox(height: 10.h),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 4.w,
              childAspectRatio: 0.75,
              children: [
                // Steps
                ProgressRing(
                  value: controller.healthMetrics.value.steps.toDouble(),
                  max: controller.stepGoal.value.toDouble(),
                  label: "Steps",
                  icon: Icons.directions_walk_outlined,
                  color: const Color(0xFF00B8A9),
                  customValue: controller.healthMetrics.value.steps.toString(),
                ),
                // Sleep: from health sync (single session, duration = endTime - startTime)
                ProgressRing(
                  value: controller.healthMetrics.value.sleepHours,
                  max: controller.sleepGoal.value,
                  label: "Sleep",
                  icon: Icons.bedtime_outlined,
                  color: const Color(0xFF0A2342),
                  suffix: "hrs",
                ),
                // Hydration: Use localWaterToday as source of truth (accumulates user entries)
                ProgressRing(
                  value: controller.localWaterToday.value,
                  max: controller.waterGoal.value,
                  label: "Hydration",
                  icon: Icons.water_drop_outlined,
                  color: const Color(0xFF00B8A9),
                  suffix: "L",
                ),
                // Fasting
                ProgressRing(
                  value: controller.mealsEaten.value.toDouble(),
                  max: 2.0,
                  label: "Fasting",
                  icon: Icons.restaurant_outlined,
                  color: const Color(0xFFD4AF37),
                  customValue: "${controller.mealsEaten.value}/2",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
