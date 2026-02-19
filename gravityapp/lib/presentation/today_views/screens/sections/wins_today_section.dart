import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../controllers/today_controller.dart';

class WinsTodaySection extends GetView<TodayController> {
  const WinsTodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final wins = controller.winsTodayMessages;

      if (wins.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE6F9F6), Colors.white],
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WINS TODAY",
              style: ResponsiveTextStyles.textXs.copyWith(
                color: const Color(0xFF00B8A9).withOpacity(0.7),
              ),
            ),
            SizedBox(height: 12.h),
            ...wins.map((text) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00B8A9),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          text,
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: const Color(0xFF0A2342),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    });
  }
}
