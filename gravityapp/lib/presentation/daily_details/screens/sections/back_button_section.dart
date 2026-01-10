import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/daily_details_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class BackButtonSection extends StatelessWidget {
  final DailyDetailsController controller;

  const BackButtonSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final backText = controller.fromScreen == 'dashboard'
        ? 'Back to Dashboard'
        : 'Back to Weekly Review';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: GestureDetector(
        onTap: controller.onBack,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: const Color(0xFF0A2342).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chevron_left,
                color: const Color(0xFF0A2342),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                backText,
                style: ResponsiveTextStyles.button.copyWith(
                  color: const Color(0xFF0A2342),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

