import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/weekly_review_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class StatusInsightCards extends StatelessWidget {
  final WeeklyReviewController controller;

  const StatusInsightCards({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final review = controller.weeklyReview.value;
      if (review == null) return const SizedBox.shrink();

      return SizedBox(
        height: 110.h, // Increased height to prevent overflow
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          children: [
            // Weight Card
            _buildCard(
              icon: Icons.trending_down,
              iconColor: const Color(0xFF00B8A9),
              title: 'Weight',
              value: review.statusInsights.weightTrend,
              gradientColors: [
                const Color(0xFFE6F7F5),
                Colors.white,
              ],
              borderColor: const Color(0xFF00B8A9).withOpacity(0.2),
            ),
            SizedBox(width: 12.w),
            
            // Consistency Card
            _buildCard(
              icon: Icons.show_chart,
              iconColor: const Color(0xFFD4AF37),
              title: 'Consistency',
              value: review.statusInsights.consistency,
              gradientColors: [
                const Color(0xFFFFF9E6),
                Colors.white,
              ],
              borderColor: const Color(0xFFD4AF37).withOpacity(0.2),
            ),
            SizedBox(width: 12.w),
            
            // Momentum Card
            _buildCard(
              icon: Icons.bolt,
              iconColor: const Color(0xFF00B8A9),
              title: 'Momentum',
              value: review.statusInsights.momentum,
              gradientColors: [
                const Color(0xFFE6F7F5),
                Colors.white,
              ],
              borderColor: const Color(0xFF00B8A9).withOpacity(0.2),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    return Container(
      width: 140.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            title,
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: ResponsiveTextStyles.textXs.copyWith(
              color: iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

