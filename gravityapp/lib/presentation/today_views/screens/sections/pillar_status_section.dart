import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/today_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class PillarStatusSection extends StatelessWidget {
  final TodayController controller;

  const PillarStatusSection({
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
            "PILLAR STATUS",
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16.h),
          Obx(() => Column(
                children: controller.pillars.map((pillar) {
                  final statusColor = controller.getPillarColor(pillar.status);
                  final statusIcon = controller.getPillarStatusIcon(pillar.status);
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 16.sp,
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          pillar.icon,
                          color: statusColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            pillar.name,
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342),
                            ),
                          ),
                        ),
                        // Show loading indicator for Nutrition or other pillars (Hydration, Sleep, Steps) if loading
                        if ((pillar.name == 'Nutrition' && controller.isLoadingNutrition.value) ||
                            ((pillar.name == 'Hydration' || pillar.name == 'Sleep' || pillar.name == 'Steps') && 
                             controller.isLoadingPillars.value))
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          )
                        else
                          Text(
                            pillar.detail,
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
          )),
        ],
      ),
    );
  }
}

