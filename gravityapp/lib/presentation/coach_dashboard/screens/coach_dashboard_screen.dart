import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/coach_dashboard_controller.dart';

class CoachDashboardScreen extends GetView<CoachDashboardController> {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate the controller if it hasn't been already
    Get.put(CoachDashboardController());

    return SafeArea(
      child: Container(
        color: const Color(0xFFF5F6FA),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(),
                    SizedBox(height: 24.h),
                    // Client Overview Title
                    Text(
                      'Client Overview',
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: const Color(0xFF0A2342),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // User List
                    _buildUserList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
      ),
      padding: EdgeInsets.only(
        top: 56.h,
        bottom: 24.h,
        left: 24.w,
        right: 24.w,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coach Dashboard',
                style: ResponsiveTextStyles.textXl.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Notifications Button
                  GestureDetector(
                    onTap: controller.navigateToNotifications,
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                          // Notification Badge
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: Container(
                              width: 20.w,
                              height: 20.h,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '2',
                                  style: ResponsiveTextStyles.textXs.copyWith(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Settings Button
                  GestureDetector(
                    onTap: controller.navigateToSettings,
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'User Compliance Overview',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFFD4AF37),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: 'High',
              count: controller.highComplianceCount,
              gradient: const [Color(0xFF4ADE80), Color(0xFF22C55E)],
              delay: 0,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              label: 'Medium',
              count: controller.mediumComplianceCount,
              gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              delay: 0.1,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              label: 'Low',
              count: controller.lowComplianceCount,
              gradient: const [Color(0xFFF87171), Color(0xFFEF4444)],
              delay: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required List<Color> gradient,
    required double delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (delay * 1000).toInt()),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.r,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$count',
                    style: ResponsiveTextStyles.textXl.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'users',
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    return Obx(
      () => Column(
        children: controller.users.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-20 * (1 - value), 0),
                  child: _buildUserCard(user),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserCard(ClientUser user) {
    final statusColor = user.status == 'high'
        ? const Color(0xFF22C55E)
        : user.status == 'medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 28.sp,
                        color: Colors.grey[400],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: const Color(0xFF0A2342),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: user.compliance / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        SizedBox(
                          width: 40.w,
                          child: Text(
                            '${user.compliance}%',
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.6),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              SizedBox(width: 8.w),
              user.alerts.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${user.alerts.length}',
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20.sp,
                    ),
            ],
          ),
          // Alerts Section
          if (user.alerts.isNotEmpty) ...[
            Divider(
              height: 24.h,
              thickness: 1,
              color: const Color(0xFF0A2342).withOpacity(0.1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: user.alerts.map((alert) {
                      return Text(
                        '• $alert',
                        style: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.7),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
          // Today's Score
          Divider(
            height: 24.h,
            thickness: 1,
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Score",
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.6),
                ),
              ),
              Text(
                '${user.todayScore}%',
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: user.todayScore >= 80
                      ? const Color(0xFF22C55E)
                      : user.todayScore >= 60
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

