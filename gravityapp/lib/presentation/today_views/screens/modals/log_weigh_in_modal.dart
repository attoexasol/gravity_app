import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/today_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

class LogWeighInModal extends StatelessWidget {
  final TodayController controller;

  const LogWeighInModal({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showWeighInModal.value) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () => controller.closeWeighInModal(),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside modal
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(maxWidth: 400.w),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                padding: EdgeInsets.all(20.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Log Weight-In',
                            style: ResponsiveTextStyles.h3.copyWith(
                              color: const Color(0xFF0A2342),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.closeWeighInModal,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            child: Icon(
                              Icons.close,
                              color: const Color(0xFF0A2342),
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Description
                    Text(
                      'Record your weight. No pressure — just information.',
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Weight Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight (kg)',
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Stack(
                          children: [
                            TextField(
                              controller: controller.weightController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              style: ResponsiveTextStyles.textLg.copyWith(
                                color: const Color(0xFF0A2342),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: '79.0',
                                hintStyle: ResponsiveTextStyles.textLg.copyWith(
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16.w,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Icon(
                                  Icons.monitor_weight,
                                  color: const Color(0xFF0A2342).withOpacity(0.4),
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Date Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: controller.selectedDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF00B8A9),
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Color(0xFF0A2342),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              controller.selectedDate.value = picked;
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MM/dd/yyyy').format(controller.selectedDate.value),
                                  style: ResponsiveTextStyles.textBase.copyWith(
                                    color: const Color(0xFF0A2342),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: const Color(0xFF0A2342).withOpacity(0.4),
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: controller.closeWeighInModal,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'Cancel',
                                style: ResponsiveTextStyles.textBase.copyWith(
                                  color: const Color(0xFF0A2342),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: controller.saveWeighIn,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10.r,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Save',
                                style: ResponsiveTextStyles.textBase.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
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

