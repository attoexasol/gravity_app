import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/daily_details_controller.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/routes/app_routes.dart';

class DailyReflectionSection extends StatelessWidget {
  final DailyDetailsController controller;

  const DailyReflectionSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reflection = controller.dailyReflection.value;
      final hasReflection = reflection != null && reflection.trim().isNotEmpty;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: const Color(0xFF0A2342).withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Reflection',
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              if (hasReflection)
                Text(
                  reflection!.trim(),
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.8),
                  ),
                )
              else
                Text(
                  'No reflection added for this day',
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.5),
                  ),
                ),
              if (!hasReflection) ...[
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () => Get.toNamed(
                    AppRoutes.dailySummary,
                    arguments: {'scrollToReflection': true},
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+',
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF00B8A9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Add reflection',
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF00B8A9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

