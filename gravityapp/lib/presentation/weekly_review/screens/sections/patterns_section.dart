import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/weekly_review_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Icons matching WeeklyConsistencyGrid per pillar.
const Map<String, IconData> _pillarIcons = {
  'Nutrition': Icons.restaurant,
  'Hydration': Icons.water_drop,
  'Sleep': Icons.bedtime,
  'Steps': Icons.directions_walk,
  'Fasting': Icons.access_time,
  'Weigh-in': Icons.monitor_weight,
};

class PatternsSection extends StatelessWidget {
  final WeeklyReviewController controller;

  const PatternsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final review = controller.weeklyReview.value;
      if (review == null || review.patterns.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patterns This Week',
            style: ResponsiveTextStyles.textLg.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          // Exactly 2 cards: index 0 = highest (green), index 1 = lowest (yellow)
          ...review.patterns.asMap().entries.map((entry) {
            final index = entry.key;
            final pattern = entry.value;
            final isHighest = index == 0;
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildPatternCard(
                icon: _pillarIcons[pattern.category] ?? Icons.circle,
                isHighest: isHighest,
                category: pattern.category,
                insight: pattern.insight,
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildPatternCard({
    required IconData icon,
    required bool isHighest,
    required String category,
    required String insight,
  }) {
    // Green style (Complete tone) for highest; yellow style (Partial tone) for lowest
    const greenColor = Color(0xFF00B8A9);
    const yellowColor = Color(0xFFD4AF37);
    final iconColor = isHighest ? greenColor : yellowColor;
    final borderColor = isHighest
        ? greenColor.withOpacity(0.3)
        : yellowColor.withOpacity(0.3);
    final gradientColors = isHighest
        ? const [Color(0xFFE6F9F6), Colors.white]
        : const [Color(0xFFFFF9E6), Colors.white];

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  insight,
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

