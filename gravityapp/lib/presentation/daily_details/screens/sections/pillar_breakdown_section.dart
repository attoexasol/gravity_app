import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/daily_details_controller.dart';
import '../../../../data/model/daily_details.dart';
import '../../../../app/theme/app_text_styles.dart';

class PillarBreakdownSection extends StatelessWidget {
  final DailyDetailsController controller;

  const PillarBreakdownSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = controller.currentDay;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Pillar Breakdown',
              style: ResponsiveTextStyles.textLg.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12.h),
            // Nutrition
            _buildPillarCard(
              controller: controller,
              icon: Icons.restaurant,
              iconColor: const Color(0xFFD4AF37),
              title: 'Nutrition',
              pillar: day.pillars.nutrition,
            ),
            SizedBox(height: 12.h),
            // Hydration
            _buildPillarCard(
              controller: controller,
              icon: Icons.water_drop,
              iconColor: const Color(0xFF00B8A9),
              title: 'Hydration',
              pillar: day.pillars.hydration,
            ),
            SizedBox(height: 12.h),
            // Sleep
            _buildPillarCard(
              controller: controller,
              icon: Icons.nightlight_round,
              iconColor: const Color(0xFF6C63FF),
              title: 'Sleep',
              pillar: day.pillars.sleep,
            ),
            SizedBox(height: 12.h),
            // Movement
            _buildPillarCard(
              controller: controller,
              icon: Icons.directions_walk,
              iconColor: const Color(0xFF00B8A9),
              title: 'Steps',
              pillar: day.pillars.step,
            ),
            SizedBox(height: 12.h),
            // Fasting
            _buildPillarCard(
              controller: controller,
              icon: Icons.access_time,
              iconColor: const Color(0xFFD4AF37),
              title: 'Fasting',
              pillar: day.pillars.fasting,
            ),
            SizedBox(height: 12.h),
            // Weigh-in
            _buildPillarCard(
              controller: controller,
              icon: Icons.monitor_weight,
              iconColor: const Color(0xFF00B8A9),
              title: 'Weigh-in',
              pillar: day.pillars.weighin,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPillarCard({
    required DailyDetailsController controller,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Pillar pillar,
  }) {
    final status = pillar.status;
    final borderColor = controller.getStatusBorderColor(status);
    final backgroundColor = controller.getStatusBackgroundColor(status);
    final statusIcon = controller.getStatusIcon(status);
    final statusIconColor = controller.getStatusIconColor(status);
    final statusLabel = controller.getStatusLabel(status);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5.r,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: const Color(0xFF0A2342),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      statusIcon,
                      style: TextStyle(
                        color: statusIconColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                // Status label
                Text(
                  statusLabel,
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4.h),
                // Detail
                Text(
                  pillar.detail,
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

