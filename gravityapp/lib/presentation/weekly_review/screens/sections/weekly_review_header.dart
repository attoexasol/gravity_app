import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/weekly_review_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class WeeklyReviewHeader extends StatelessWidget {
  final WeeklyReviewController controller;

  const WeeklyReviewHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 48.h),
      child: Column(
        children: [
          // Top row with buttons and title
          Stack(
            alignment: Alignment.center,
            children: [
              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => controller.onBack(),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: const Color(0xFF0A2342),
                        size: 20.sp,
                      ),
                    ),
                  ),
                  
                  // Spacer for centering
                  SizedBox(width: 40.w),
                  
                  // Calendar button
                  GestureDetector(
                    onTap: () => controller.toggleWeekPicker(),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF0A2342),
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Title (centered absolutely)
              Text(
                'Weekly Review',
                style: ResponsiveTextStyles.h2.copyWith(
                  color: const Color(0xFF0A2342),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Date range
          Obx(() {
            final selectedWeek = controller.weekOptions.isNotEmpty
                ? controller.weekOptions[controller.selectedWeekIndex.value]
                : null;
            
            if (selectedWeek == null) return const SizedBox.shrink();
            
            return Text(
              selectedWeek.dateRange,
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.6),
              ),
            );
          }),
        ],
      ),
    );
  }
}

