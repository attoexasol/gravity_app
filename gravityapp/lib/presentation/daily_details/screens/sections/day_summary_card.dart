import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/daily_details_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class DaySummaryCard extends StatelessWidget {
  final DailyDetailsController controller;

  const DaySummaryCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = controller.displayDay;
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji and title row
            Row(
              children: [
                Text(
                  day.moodEmoji,
                  style: TextStyle(fontSize: 30.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.moodLabel,
                        style: ResponsiveTextStyles.h3.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${day.pillarsCompleted} of ${day.totalPillars} pillars completed',
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Morning and Evening tags
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Morning tag
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F5),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFF00B8A9).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '🌅',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Morning: ${day.morningTag}',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Evening tag
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '🌙',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Evening: ${day.eveningTag}',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

