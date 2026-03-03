import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Notification bell icon with unread count badge (red circle at top-right).
/// Use on Home, Community, AI Coach, and Messages headers for consistent badge UI.
class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({
    super.key,
    required this.onTap,
    required this.unreadCount,
    this.size = 44,
    this.iconSize = 22,
    this.icon = Icons.notifications_outlined,
  });

  final VoidCallback onTap;
  final int unreadCount;
  final double size;
  final double iconSize;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final w = size.w;
    final h = size.h;
    return Tooltip(
      message: 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: w,
                height: h,
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
                  icon,
                  color: Colors.white,
                  size: iconSize.sp,
                ),
              ),
            ),
          ),
          if (unreadCount > 0)
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
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
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
    );
  }
}
