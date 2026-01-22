import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/today_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class ReflectionSection extends StatelessWidget {
  final TodayController controller;

  const ReflectionSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What made it hard to fit in movement today?",
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
                controller: controller.reflectionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Type your thoughts here...",
                  hintStyle: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: const Color(0xFF00B8A9).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(16.r),
                ),
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: const Color(0xFF0A2342),
                ),
              ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: controller.clearReflection,
            child: Text(
              'Skip',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

