import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../controllers/today_controller.dart';

class OneThingToWatchSection extends GetView<TodayController> {
  const OneThingToWatchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.oneThingToWatchMessage;

      if (message == null) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9E6), Colors.white],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ONE THING TO WATCH",
              style: ResponsiveTextStyles.textXs.copyWith(
                color: const Color(0xFFD4AF37).withOpacity(0.7),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342),
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    });
  }
}
