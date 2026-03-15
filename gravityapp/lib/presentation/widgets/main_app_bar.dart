import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_text_styles.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final VoidCallback onNotificationTap;
  final VoidCallback onMenuTap;
  final VoidCallback? onSettingsTap;
  final int notificationCount;

  const MainAppBar({
    super.key,
    required this.userName,
    required this.onNotificationTap,
    required this.onMenuTap,
    this.onSettingsTap,
    this.notificationCount = 3,
  });

  @override
  // Size get preferredSize => Size.fromHeight(180.h);
  Size get preferredSize => Size.fromHeight(120.h); // Reduced from 180.h

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
      ),
      child: SafeArea(
        bottom: false, // Don't apply bottom safe area padding
        child: Padding(
          // padding: EdgeInsets.only(
          //   left: 20.w,
          //   right: 20.w,
          //   top: 12.h,
          //   bottom: 16.h,
          // ),
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 4.h,
            bottom: 10.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize:
                MainAxisSize.min, // Important: Use minimum space needed
            children: [
              // Top row with actions (notification + settings in rounded containers)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification button in rounded container
                      Tooltip(
                        message: 'Notifications',
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onNotificationTap,
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  width: 44.w,
                                  height: 44.h,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                ),
                              ),
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: 2.w,
                                top: 2.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16.w,
                                    minHeight: 16.h,
                                  ),
                                  child: Center(
                                    child: Text(
                                      notificationCount > 9
                                          ? '9+'
                                          : notificationCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onSettingsTap != null) ...[
                        SizedBox(width: 12.w),
                        Tooltip(
                          message: 'Settings',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onSettingsTap,
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                width: 44.w,
                                height: 44.h,                               
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // SizedBox(height: 8.h),
              // Welcome message
              Text(
                'Welcome back,',
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),

              // User name - with overflow protection
              Text(
                userName,
                style: ResponsiveTextStyles.textXl.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),

              // Date - with overflow protection
              Text(
                _getFormattedDate(),
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: const Color(0xFFD4AF37),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get formatted date
  String _getFormattedDate() {
    final now = DateTime.now();
    final weekday = _getWeekday(now.weekday);
    final month = _getMonth(now.month);
    return '$weekday, $month ${now.day}, ${now.year}';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
