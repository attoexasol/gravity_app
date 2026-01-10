import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/weekly_review_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class WeekPickerModal extends StatelessWidget {
  final WeeklyReviewController controller;

  const WeekPickerModal({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showWeekPicker.value) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () => controller.toggleWeekPicker(),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: 400.w,
                ),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF0A2342).withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Week',
                            style: ResponsiveTextStyles.textLg.copyWith(
                              color: const Color(0xFF0A2342),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.toggleWeekPicker(),
                            child: Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6FA),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: const Color(0xFF0A2342),
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Week List
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.all(16.r),
                        itemCount: controller.weekOptions.length,
                        itemBuilder: (context, index) {
                          final week = controller.weekOptions[index];
                          final isSelected = controller.selectedWeekIndex.value == index;
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: GestureDetector(
                              onTap: () => controller.selectWeek(index),
                              child: Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE6F7F5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00B8A9)
                                        : const Color(0xFF0A2342).withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          week.label,
                                          style: ResponsiveTextStyles.textSm.copyWith(
                                            color: const Color(0xFF0A2342),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          week.dateRange,
                                          style: ResponsiveTextStyles.textXs.copyWith(
                                            color: const Color(0xFF0A2342).withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 24.w,
                                        height: 24.h,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00B8A9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16.sp,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Quick Navigation
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFF0A2342).withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.navigateToOlderWeek(),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: controller.selectedWeekIndex.value <
                                          controller.weekOptions.length - 1
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFF0A2342).withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chevron_left,
                                      color: controller.selectedWeekIndex.value <
                                              controller.weekOptions.length - 1
                                          ? const Color(0xFF0A2342)
                                          : const Color(0xFF0A2342).withOpacity(0.3),
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Older',
                                      style: ResponsiveTextStyles.textSm.copyWith(
                                        color: controller.selectedWeekIndex.value <
                                                controller.weekOptions.length - 1
                                            ? const Color(0xFF0A2342)
                                            : const Color(0xFF0A2342).withOpacity(0.3),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.navigateToNewerWeek(),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: controller.selectedWeekIndex.value > 0
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFF0A2342).withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Newer',
                                      style: ResponsiveTextStyles.textSm.copyWith(
                                        color: controller.selectedWeekIndex.value > 0
                                            ? const Color(0xFF0A2342)
                                            : const Color(0xFF0A2342).withOpacity(0.3),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.chevron_right,
                                      color: controller.selectedWeekIndex.value > 0
                                          ? const Color(0xFF0A2342)
                                          : const Color(0xFF0A2342).withOpacity(0.3),
                                      size: 16.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

