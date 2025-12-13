import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';

class MainDrawer extends StatelessWidget {
  final String userName;
  final String userType;
  final VoidCallback onLogout;

  const MainDrawer({
    super.key,
    required this.userName,
    required this.userType,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280.w, // Responsive drawer width
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A2342),
              Color(0xFF00B8A9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              SizedBox(height: 24.h),

              // Menu Items
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 24.h,
                    ),
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'My Profile',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/profile');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.track_changes,
                        title: 'My Goals',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/goal-settings');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.show_chart,
                        title: 'Progress Reports',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/reports');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Activity History',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/history');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/settings');
                        },
                      ),

                      SizedBox(height: 16.h),
                      Divider(height: 1.h),
                      SizedBox(height: 16.h),

                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/help');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'About Gravity',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/about');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.policy_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/privacy');
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Logout button
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build drawer header
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white,
                width: 3.w,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 40.sp,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // User name
          Text(
            userName,
            style: AppTextStyles.textXl.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),

          // User type badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              userType == 'coach' ? 'Coach' : 'Customer',
              style: AppTextStyles.textXs.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 14.h,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF0A2342).withOpacity(0.7),
                size: 22.sp,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w500,
                    fontSize: 15.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF0A2342).withOpacity(0.3),
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build logout button
  Widget _buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: ElevatedButton(
        onPressed: onLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFFD4183D),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(
              color: const Color(0xFFD4183D),
              width: 2.w,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Logout',
              style: ResponsiveTextStyles.textBase.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}