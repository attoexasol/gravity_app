import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_text_styles.dart';

class QuickActionsSection extends StatelessWidget {
  final dynamic controller; // GetX controller

  const QuickActionsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Quick Actions',
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.6),
            ),
          ),

          SizedBox(height: 12.h),

          // Quick Action Buttons Row
          Row(
            children: controller.quickActions.map<Widget>((action) {
              bool isLast = action == controller.quickActions.last;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8.w),
                  child: InkWell(
                    onTap: () => controller.handleQuickAction(action.label),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      height: 90.h, // FIXED HEIGHT → Perfect symmetry
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical:
                            8.h, // Reduced vertical padding to prevent overflow
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: action.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: action.gradient[0].withOpacity(0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize:
                            MainAxisSize.min, // Use min to prevent overflow
                        children: [
                          Flexible(
                            child: Icon(
                              action.icon,
                              color: Colors.white,
                              size: 20.sp, // Slightly reduced icon size
                            ),
                          ),

                          SizedBox(height: 6.h), // Reduced spacing

                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                action.label,
                                style: ResponsiveTextStyles.textXs.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
