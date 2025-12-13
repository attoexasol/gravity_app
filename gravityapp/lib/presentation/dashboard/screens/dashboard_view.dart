import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gravityapp/presentation/dashboard/screens/sections/progress_ring_card.dart';
import '../../../app/theme/app_text_styles.dart';

import '../controller/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate the controller if it hasn't been already
    Get.put(DashboardController());

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 20.h,
        top: 70.h, // Space for sticky sync section
      ),
      child: Column(
        children: [
          ProgressRingsSection(controller: controller),
          _buildSummaryCards(),
          _buildQuickActions(),
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
                      Expanded(
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
                      Expanded(
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

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.camera_alt_outlined,
        'title': 'Upload Meal',
        'gradient': const [Color(0xFFF9A71F), Color(0xFFF57C00)],
      },
      {
        'icon': Icons.monitor_weight_outlined,
        'title': 'Add Weight',
        'gradient': const [Color(0xFF00B8A9), Color(0xFF0A2342)],
      },
      {
        'icon': Icons.bedtime_outlined,
        'title': 'Log Sleep',
        'gradient': const [Color(0xFF6C63FF), Color(0xFF7F82FF)],
      },
      {
        'icon': Icons.water_drop_outlined,
        'title': 'Log Hydration',
        'gradient': const [Color(0xFF00B8A9), Color(0xFF00E5D3)],
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: ResponsiveTextStyles.textLg.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A2342),
            ),
          ),
          SizedBox(height: 15.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 2.5,
            children: actions.map((action) {
              return _QuickActionCard(
                icon: action['icon'] as IconData,
                title: action['title'] as String,
                gradient: action['gradient'] as List<Color>,
                onTap: () {
                  if (action['title'] == 'Upload Meal') {
                    Get.toNamed('/meal-upload');
                  }
                  // Handle other quick actions
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPreview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: InkWell(
        onTap: () => print('Navigate to community'),
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

// Helper widget for Quick Actions
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                title,
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
