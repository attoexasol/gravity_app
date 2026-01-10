import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/today_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class TomorrowsFocusSection extends StatelessWidget {
  final TodayController controller;

  const TomorrowsFocusSection({
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
            "TOMORROW'S FOCUS",
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          Obx(() {
            if (controller.isEditingFocus.value) {
              return Column(
                children: [
                  TextField(
                    controller: controller.tomorrowFocusController,
                    maxLines: 3,
                    decoration: InputDecoration(
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
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: controller.saveTomorrowFocus,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B8A9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              'Save',
                              style: ResponsiveTextStyles.textSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: controller.cancelEditingFocus,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'Cancel',
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Text(
                    controller.tomorrowFocus.value,
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: controller.handleDone,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B8A9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              'Accept',
                              style: ResponsiveTextStyles.textSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: controller.toggleEditingFocus,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'Edit',
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          }),
        ],
      ),
    );
  }
}

