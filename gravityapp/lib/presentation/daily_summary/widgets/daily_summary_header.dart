import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';
import '../controllers/daily_summary_controller.dart';
import '../../../app/theme/app_text_styles.dart';

class DailySummaryHeader extends StatelessWidget {
  final DailySummaryController controller;

  const DailySummaryHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 56.h,
        bottom: 24.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title row
          Row(
            children: [
              GestureDetector(
                onTap: () => controller.onBack(),
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                'Daily Summary',
                style: ResponsiveTextStyles.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Date
          Obx(() {
            final date = controller.selectedDate.value;
            return Text(
              DateFormat('EEEE, MMMM d, yyyy').format(date),
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFFD4AF37),
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ],
      ),
    );
  }
}

