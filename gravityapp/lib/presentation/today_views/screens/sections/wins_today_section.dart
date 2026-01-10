import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/app_text_styles.dart';

class WinsTodaySection extends StatelessWidget {
  const WinsTodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F7F5), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF00B8A9).withOpacity(0.2),
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
            "WINS TODAY",
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF00B8A9).withOpacity(0.7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          _buildWinItem("Stayed hydrated despite a busy schedule"),
          SizedBox(height: 8.h),
          _buildWinItem("Recovered quickly after a tough afternoon"),
        ],
      ),
    );
  }

  Widget _buildWinItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6.w,
          height: 6.h,
          margin: EdgeInsets.only(top: 6.h, right: 8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF00B8A9),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342),
            ),
          ),
        ),
      ],
    );
  }
}

