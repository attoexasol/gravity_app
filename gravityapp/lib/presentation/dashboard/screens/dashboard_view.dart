import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gravityapp/presentation/dashboard/screens/sections/progress_ring_card.dart';
import 'package:gravityapp/presentation/dashboard/screens/sections/weight_journey_section.dart';
import 'package:gravityapp/presentation/dashboard/screens/sections/summary_reports_nav_section.dart';
import 'package:gravityapp/presentation/dashboard/screens/sections/quick_actions_section.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';

import '../controllers/dashboard_controller.dart';
import '../../main_layout/controllers/main_layout_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate the controller if it hasn't been already (avoid multiple instances)
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController(), permanent: true);
    }

    return SingleChildScrollView(
      controller: controller.dashboardScrollController,
      padding: EdgeInsets.only(
        bottom: 20.h,
        top: 70.h, // Space for sticky sync section
      ),
      child: Column(
        children: [
          ProgressRingsSection(controller: controller),
          WeightLossJourneySection(controller: controller),
          SummaryReportsNavSection(
            onTodayTap: () => Get.toNamed(AppRoutes.dailySummary),
            onWeeklyReviewTap: () => Get.toNamed(AppRoutes.weeklyReview),
            onDailyDetailsTap: () => Get.toNamed('${AppRoutes.dailyDetails}?from=dashboard'),
          ),
          QuickActionsSection(controller: controller),
          _buildCommunityPreview(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(
      () => Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        "Today's Summary",
                        style: ResponsiveTextStyles.textBase.copyWith(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A2342),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Flexible(
                        child: Text(
                          "You're at ${controller.overallProgress.toStringAsFixed(0)}% of your daily goal. ${controller.overallProgress >= 75 ? 'Great progress! 🎉' : 'Keep going! 💪'}",
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: () => print('Navigate to daily-summary'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_upward,
                              color: const Color(0xFF0A2342),
                              size: 14.sp,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFF00B8A9).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        "Weekly Stats",
                        style: ResponsiveTextStyles.textBase.copyWith(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A2342),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Flexible(
                        child: Text(
                          "Check your 7-day trends and insights to track your progress.",
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: () => print('Navigate to weekly-summary'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_upward,
                              color: const Color(0xFF0A2342),
                              size: 14.sp,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCommunityPreview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: InkWell(
        onTap: () {
          // Navigate to Community tab (index 1) using MainLayoutController
          final mainLayoutController = Get.find<MainLayoutController>();
          mainLayoutController.navigateToTab(1);
        },
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent, Colors.pinkAccent],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outlined,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Community Feed",
                      style: ResponsiveTextStyles.textBase.copyWith(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A2342),
                      ),
                    ),
                    Text(
                      "Share your journey",
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF00B8A9),
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


