import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/weekly_review_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

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
          
          ...review.patterns.map((pattern) {
            final isNutrition = pattern.category == 'Nutrition';
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildPatternCard(
                icon: isNutrition ? Icons.restaurant : Icons.directions_walk,
                iconColor: isNutrition ? const Color(0xFFD4AF37) : const Color(0xFF00B8A9),
                category: pattern.category,
                insight: pattern.insight,
                backgroundColor: isNutrition
                    ? const Color(0xFFFFF9E6)
                    : const Color(0xFFE6F7F5),
                borderColor: isNutrition
                    ? const Color(0xFFD4AF37).withOpacity(0.2)
                    : const Color(0xFF00B8A9).withOpacity(0.2),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildPatternCard({
    required IconData icon,
    required Color iconColor,
    required String category,
    required String insight,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Icon
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
          
          // Text content
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

