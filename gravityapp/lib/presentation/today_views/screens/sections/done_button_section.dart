import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/today_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class DoneButtonSection extends StatelessWidget {
  final TodayController controller;

  const DoneButtonSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Obx(() {
        final isSubmitting = controller.isSubmittingReflection.value;
        return GestureDetector(
          onTap: isSubmitting ? null : controller.handleDone,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              gradient: isSubmitting
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
                    ),
              color: isSubmitting ? const Color(0xFFF5F6FA) : null,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10.r,
                ),
              ],
            ),
            child: Text(
              isSubmitting ? 'Saving...' : 'Done',
              style: ResponsiveTextStyles.textBase.copyWith(
                color: isSubmitting
                    ? const Color(0xFF0A2342).withOpacity(0.5)
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }),
    );
  }
}

