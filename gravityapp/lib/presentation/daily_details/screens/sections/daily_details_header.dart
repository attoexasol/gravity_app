import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/daily_details_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class DailyDetailsHeader extends StatelessWidget {
  final DailyDetailsController controller;

  const DailyDetailsHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 48.h,
        bottom: 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigation buttons and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                GestureDetector(
                  onTap: controller.canGoPrevious ? controller.goToPreviousDay : null,
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: controller.canGoPrevious
                          ? const Color(0xFF0A2342)
                          : const Color(0xFF0A2342).withOpacity(0.3),
                      size: 20.sp,
                    ),
                  ),
                ),
                // Date (current date when viewing today, else selected day)
                Expanded(
                  child: Text(
                    controller.headerDateText.value,
                    style: ResponsiveTextStyles.h2.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // Next button
                GestureDetector(
                  onTap: controller.canGoNext ? controller.goToNextDay : null,
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: controller.canGoNext
                          ? const Color(0xFF0A2342)
                          : const Color(0xFF0A2342).withOpacity(0.3),
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // "Day Details" subtitle
            Text(
              'Day Details',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }
}

