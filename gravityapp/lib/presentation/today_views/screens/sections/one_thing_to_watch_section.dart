import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/app_text_styles.dart';

class OneThingToWatchSection extends StatelessWidget {
  const OneThingToWatchSection({super.key});

  @override
  Widget build(BuildContext context) {
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
            "ONE THING TO WATCH",
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFFD4AF37).withOpacity(0.7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Movement dropped off completely today, which may affect energy and appetite.",
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

