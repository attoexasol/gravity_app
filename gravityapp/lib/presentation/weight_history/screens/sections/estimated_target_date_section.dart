import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/weight_history_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class EstimatedTargetDateSection extends StatelessWidget {
  final WeightHistoryController controller;

  const EstimatedTargetDateSection({
    super.key,
    required this.controller,
  });

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
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: const Color(0xFFD4AF37),
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'ESTIMATED TARGET DATE',
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            controller.estimatedTargetDate,
            style: ResponsiveTextStyles.h2.copyWith(
              color: const Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Based on ${controller.weeklyAverage} kg/week average',
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.6),
              height: 1.6,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This is an estimate — progress isn\'t always linear',
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

