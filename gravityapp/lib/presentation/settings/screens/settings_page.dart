import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/settings_controller.dart';
import 'sections/account_section.dart';
import 'sections/section_title_widget.dart';
import 'sections/wellness_goals_section.dart';
import 'sections/health_integration.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F6FA), Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Section
                    Obx(() => AccountSection(
                      name: controller.user.value.name,
                      email: controller.user.value.email,
                      initials: controller.user.value.initials,
                      profileImagePath: controller.user.value.profileImagePath,
                    )),
                    SizedBox(height: 24.h),

                    // Wellness Goals Section
                    WellnessGoalsSection(controller: controller),
                    SizedBox(height: 24.h),

                    // Health Integration Section
                    HealthIntegrationSection(controller: controller),
                    SizedBox(height: 24.h),

                    // Notifications Section
                    _buildNotificationsSection(),
                    SizedBox(height: 24.h),

                    // Privacy & Data Control
                    _buildPrivacySection(),
                    SizedBox(height: 24.h),

                    // Support Section
                    _buildSupportSection(),
                    SizedBox(height: 24.h),

                    // Logout Section
                    _buildLogoutSection(),
                    SizedBox(height: 24.h),

                    // Danger Zone
                    _buildDangerZone(),
                    SizedBox(height: 24.h),

                    // App Version
                    _buildAppVersion(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: MediaQuery.of(context).padding.top + 12.h,
        bottom: 32.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.navigateBack,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'Settings',
            style: ResponsiveTextStyles.textXl.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitleWidget(title: 'Notifications', isDanger: false),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: !controller.notificationPrefs.value.enabled
                ? Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48.w,
                              height: 48.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFBBF24),
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Icon(
                                Icons.notifications_off,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enable Notifications',
                                    style: ResponsiveTextStyles.textBase
                                        .copyWith(
                                          color: const Color(0xFF0A2342),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Get wellness reminders & summaries',
                                    style: ResponsiveTextStyles.textSm.copyWith(
                                      color: const Color(
                                        0xFF0A2342,
                                      ).withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _EnableNotificationsButton(
                          onPressed: controller.enableNotifications,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildSettingsToggle(
                        icon: Icons.notifications,
                        title: 'All Notifications',
                        subtitle: 'Enabled',
                        iconColors: [
                          const Color(0xFFFBBF24),
                          const Color(0xFFF59E0B),
                        ],
                        checked: controller.notificationPrefs.value.enabled,
                        onChanged: (value) => controller
                            .toggleNotificationPreference('enabled', value),
                        showBorder: true,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        color: const Color(0xFFF5F6FA),
                        child: Row(
                          children: [
                            Text(
                              'Reminder Types',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSettingsToggle(
                        icon: Icons.water_drop,
                        title: 'Hydration Reminders',
                        subtitle: 'Every 2 hours (9 AM - 9 PM)',
                        iconColors: [
                          const Color(0xFF60A5FA),
                          const Color(0xFF3B82F6),
                        ],
                        checked: controller.notificationPrefs.value.hydration,
                        onChanged: (value) => controller
                            .toggleNotificationPreference('hydration', value),
                        showBorder: true,
                      ),
                      _buildSettingsToggle(
                        icon: Icons.restaurant,
                        title: 'Meal Reminders',
                        subtitle: 'Breakfast, lunch & dinner times',
                        iconColors: [
                          const Color(0xFFFB923C),
                          const Color(0xFFF97316),
                        ],
                        checked: controller.notificationPrefs.value.meals,
                        onChanged: (value) => controller
                            .toggleNotificationPreference('meals', value),
                        showBorder: true,
                      ),
                      _buildSettingsToggle(
                        icon: Icons.bedtime,
                        title: 'Sleep Reminder',
                        subtitle: 'Wind down at 10 PM',
                        iconColors: [
                          const Color(0xFF818CF8),
                          const Color(0xFF6366F1),
                        ],
                        checked: controller.notificationPrefs.value.sleep,
                        onChanged: (value) => controller
                            .toggleNotificationPreference('sleep', value),
                        showBorder: true,
                      ),
                      _buildSettingsToggle(
                        icon: Icons.fitness_center,
                        title: 'Exercise Reminder',
                        subtitle: 'Stay active at 5 PM',
                        iconColors: [
                          const Color(0xFF34D399),
                          const Color(0xFF10B981),
                        ],
                        checked: controller.notificationPrefs.value.exercise,
                        onChanged: (value) => controller
                            .toggleNotificationPreference('exercise', value),
                        showBorder: true,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        color: const Color(0xFFF5F6FA),
                        child: Row(
                          children: [
                            Text(
                              'AI Summaries',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSettingsToggle(
                        icon: Icons.auto_awesome,
                        title: 'Daily Summary',
                        subtitle: 'Receive at 8 PM daily',
                        iconColors: [
                          const Color(0xFFA78BFA),
                          const Color(0xFF8B5CF6),
                        ],
                        checked:
                            controller.notificationPrefs.value.dailySummary,
                        onChanged: (value) =>
                            controller.toggleNotificationPreference(
                              'dailySummary',
                              value,
                            ),
                        showBorder: true,
                      ),
                      _buildSettingsToggle(
                        icon: Icons.bar_chart,
                        title: 'Weekly Summary',
                        subtitle: 'Every Sunday at 9 AM',
                        iconColors: [
                          const Color(0xFFF472B6),
                          const Color(0xFFEC4899),
                        ],
                        checked:
                            controller.notificationPrefs.value.weeklySummary,
                        onChanged: (value) =>
                            controller.toggleNotificationPreference(
                              'weeklySummary',
                              value,
                            ),
                        showBorder: true,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        color: const Color(0xFFF5F6FA),
                        child: Row(
                          children: [
                            Text(
                              'Settings',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSettingsToggle(
                        icon: Icons.notifications_off,
                        title: 'Quiet Hours',
                        subtitle:
                            '${controller.notificationPrefs.value.quietHoursStart} - ${controller.notificationPrefs.value.quietHoursEnd}',
                        iconColors: [
                          const Color(0xFF94A3B8),
                          const Color(0xFF64748B),
                        ],
                        checked: controller
                            .notificationPrefs
                            .value
                            .quietHoursEnabled,
                        onChanged: (value) =>
                            controller.toggleNotificationPreference(
                              'quietHoursEnabled',
                              value,
                            ),
                        showBorder: true,
                      ),
                      _buildSettingsButton(
                        icon: Icons.shield,
                        title: 'View Notification Logs',
                        subtitle: 'Check delivery status & errors',
                        iconColors: [
                          const Color(0xFF14B8A6),
                          const Color(0xFF0D9488),
                        ],
                        onTap: () => controller.showNotificationLogs.value =
                            !controller.showNotificationLogs.value,
                      ),
                    ],
                  ),
          ),
          // Notification Logs Expanded
          if (controller.showNotificationLogs.value) _buildNotificationLogs(),
        ],
      ),
    );
  }

  Widget _buildNotificationLogs() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Notification Activity',
            style: ResponsiveTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 240.h,
            child: Obx(() {
              final logs = controller.getNotificationLogs();
              if (logs.isEmpty) {
                return Center(
                  child: Text(
                    'No notifications yet',
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.4),
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: logs.length > 10 ? 10 : logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              log.status == 'success'
                                  ? Icons.check_circle
                                  : log.status == 'permission_denied'
                                  ? Icons.notifications_off
                                  : Icons.error,
                              size: 16.sp,
                              color: log.status == 'success'
                                  ? const Color(0xFF00B8A9)
                                  : log.status == 'permission_denied'
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                log.title,
                                style: ResponsiveTextStyles.textSm.copyWith(
                                  color: const Color(0xFF0A2342),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          log.body,
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          DateFormat('MMM d, y h:mm a').format(log.timestamp),
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.4),
                          ),
                        ),
                        if (log.error != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            log.error!,
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //_buildSectionTitle(''),
          SectionTitleWidget(title: 'Privacy & Data Control', isDanger: false),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSettingsToggle(
              icon: Icons.auto_awesome,
              title: 'AI Features',
              subtitle: 'Enable AI meal analysis & health recommendations',
              iconColors: [const Color(0xFFA78BFA), const Color(0xFF8B5CF6)],
              checked: controller.aiFeatures.value,
              onChanged: controller.toggleAiFeatures,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitleWidget(title: 'Support', isDanger: false),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildSettingsButton(
            icon: Icons.mail,
            title: 'Contact Support',
            subtitle: 'Get help from our team',
            iconColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitleWidget(title: 'Session', isDanger: false),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildSettingsButton(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out and clear all local data',
            iconColors: [const Color(0xFF0A2342), const Color(0xFF00B8A9)],
            onTap: controller.handleLogout,
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitleWidget(title: 'Danger Zone', isDanger: true),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildSettingsButton(
            icon: Icons.delete,
            title: 'Delete Account',
            subtitle: 'Permanently delete your data',
            iconColors: [Colors.red, Colors.red.shade700],
            onTap: controller.handleDeleteAccount,
            danger: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAppVersion() {
    return Center(
      child: Column(
        children: [
          Text(
            'Gravity v2.0.1',
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.4),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Built with ❤️ for wellness',
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> iconColors,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconColors),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: danger ? Colors.red : const Color(0xFF0A2342),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: danger
                    ? Colors.red.withOpacity(0.5)
                    : const Color(0xFF0A2342).withOpacity(0.3),
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> iconColors,
    required bool checked,
    required Function(bool) onChanged,
    bool showBorder = false,
  }) {
    return Container(
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF0A2342).withOpacity(0.1),
                  width: 1,
                ),
              ),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: iconColors),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ResponsiveTextStyles.textBase.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: checked,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF00B8A9),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit Goals Button with gradient and tap animation (matching React design)
class _EditGoalsButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _EditGoalsButton({required this.onPressed});

  @override
  State<_EditGoalsButton> createState() => _EditGoalsButtonState();
}

class _EditGoalsButtonState extends State<_EditGoalsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.track_changes, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Edit Goals',
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enable Notifications Button with gradient and tap animation (matching React design)
class _EnableNotificationsButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _EnableNotificationsButton({required this.onPressed});

  @override
  State<_EnableNotificationsButton> createState() =>
      _EnableNotificationsButtonState();
}

class _EnableNotificationsButtonState extends State<_EnableNotificationsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Enable Notifications',
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
