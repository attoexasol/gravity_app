import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/today_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class WeightJourneySection extends StatelessWidget {
  final TodayController controller;

  const WeightJourneySection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight Journey',
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342),
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: controller.openGoalsModal,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    color: const Color(0xFF00B8A9),
                    size: 16.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Obx(() {
            final startingWeight = controller.startingWeight.value;
            final currentWeight = controller.currentWeight.value;
            final totalLossGoal = startingWeight - controller.goalWeight.value;
            final currentLoss = startingWeight - currentWeight;
            final progressPercentage = (currentLoss / totalLossGoal) * 100;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Starting: $startingWeight kg',
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'Goal: $totalLossGoal kg loss',
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progressPercentage),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return FractionallySizedBox(
                                widthFactor: value / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$currentLoss kg lost',
                      style: ResponsiveTextStyles.textLg.copyWith(
                        color: const Color(0xFF00B8A9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Current: $currentWeight kg',
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weight moves slowly. Consistency moves it.",
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Status: Holding steady",
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF00B8A9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Based on weekly averages",
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.5),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Updated on your last weigh-in",
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: controller.openWeighInModal,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'Log weigh-in',
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: controller.onNavigateToHistory,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'View history',
                    style: ResponsiveTextStyles.textBase.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

