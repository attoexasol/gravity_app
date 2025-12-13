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
  Size get preferredSize => Size.fromHeight(180.h); // Reduced from 180.h

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
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 12.h,
            bottom: 16.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize:
                MainAxisSize.min, // Important: Use minimum space needed
            children: [
              // Top row with menu and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu button
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: 24.sp),
                    onPressed: onMenuTap,
                    tooltip: 'Menu',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 40.w,
                      minHeight: 40.h,
                    ),
                  ),

                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification button
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                            onPressed: onNotificationTap,
                            tooltip: 'Notifications',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 40.w,
                              minHeight: 40.h,
                            ),
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              right: 4.w,
                              top: 4.h,
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
                      // Settings button
                      if (onSettingsTap != null) ...[
                        SizedBox(width: 8.w),
                        IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                          onPressed: onSettingsTap,
                          tooltip: 'Settings',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 40.w,
                            minHeight: 40.h,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              SizedBox(height: 8.h),

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
