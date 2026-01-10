import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/weekly_review_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class ViewDailyDetailsButton extends StatelessWidget {
  final WeeklyReviewController controller;

  const ViewDailyDetailsButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.navigateToDailyDetails(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View Daily Details',
              style: ResponsiveTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '→',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

