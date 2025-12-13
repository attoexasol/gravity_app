import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'section_title_widget.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../../data/model/health_permissions.dart';
import '../../../../../core/services/health_sync_service.dart' show HealthSyncService, HealthPlatform;

class HealthIntegrationSection extends StatelessWidget {
  final dynamic controller;

  const HealthIntegrationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitleWidget(title: 'Health Integration', isDanger: false),
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
            child: Column(
              children: [
                // Platform Status
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF60A5FA),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.getPlatformName(),
                                    style: ResponsiveTextStyles.textBase
                                        .copyWith(
                                          color: const Color(0xFF0A2342),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    _healthService.getMetrics().platform !=
                                            HealthPlatform.none
                                        ? 'Connected'
                                        : 'Not connected',
                                    style: ResponsiveTextStyles.textSm.copyWith(
                                      color: const Color(
                                        0xFF0A2342,
                                      ).withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Obx(
                            () => ElevatedButton(
                              onPressed: controller.isCheckingPermissions.value
                                  ? null
                                  : controller.recheckPermissions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B8A9),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: controller.isCheckingPermissions.value
                                  ? SizedBox(
                                      width: 16.w,
                                      height: 16.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh, size: 16.sp),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Recheck',
                                          style: ResponsiveTextStyles.textSm,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (controller.healthPermissions.value.lastChecked !=
                          null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Last checked: ${DateFormat('MMM d, y h:mm a').format(controller.healthPermissions.value.lastChecked!)}',
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Permissions List
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF0A2342).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPermissionItem(
                        controller: controller,
                        icon: Icons.directions_walk,
                        label: 'Steps',
                        status: controller.healthPermissions.value.steps,
                      ),
                      SizedBox(height: 12.h),
                      _buildPermissionItem(
                        controller: controller,
                        icon: Icons.bedtime,
                        label: 'Sleep',
                        status: controller.healthPermissions.value.sleep,
                      ),
                      SizedBox(height: 12.h),
                      _buildPermissionItem(
                        controller: controller,
                        icon: Icons.favorite,
                        label: 'Heart Rate',
                        status: controller.healthPermissions.value.heartRate,
                      ),
                    ],
                  ),
                ),
                // Sync Logs Button
                _buildSettingsButton(
                  icon: Icons.shield,
                  title: 'View Sync Logs',
                  subtitle: 'Check sync status and diagnostics',
                  iconColors: [
                    const Color(0xFF94A3B8),
                    const Color(0xFF64748B),
                  ],
                  onTap: () => controller.showSyncLogs.value =
                      !controller.showSyncLogs.value,
                ),
              ],
            ),
          ),
          // Sync Logs Expanded
          if (controller.showSyncLogs.value) _buildSyncLogs(controller),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required dynamic controller,
    required IconData icon,
    required String label,
    required PermissionStatus status,
  }) {
    final permissions = controller.healthPermissions.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF0A2342).withOpacity(0.6),
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              _getPermissionIcon(status),
              size: 16.sp,
              color: permissions.getStatusColor(status),
            ),
            SizedBox(width: 4.w),
            Text(
              permissions.getStatusText(status),
              style: ResponsiveTextStyles.textSm.copyWith(
                color: permissions.getStatusColor(status),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getPermissionIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        return Icons.error;
      case PermissionStatus.notDetermined:
        return Icons.access_time;
    }
  }

  Widget _buildSyncLogs(dynamic controller) {
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
            'Recent Sync Activity',
            style: ResponsiveTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 240.h,
            child: Obx(() {
              final logs = controller.getSyncLogs();
              if (logs.isEmpty) {
                return Center(
                  child: Text(
                    'No sync logs yet',
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        log.status == 'syncing'
                            ? SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              )
                            : Icon(
                                log.status == 'success'
                                    ? Icons.check_circle
                                    : Icons.error,
                                size: 16.sp,
                                color: log.status == 'success'
                                    ? const Color(0xFF00B8A9)
                                    : Colors.red,
                              ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.status == 'success'
                                    ? 'Sync Success'
                                    : log.status == 'syncing'
                                        ? 'Syncing...'
                                        : 'Sync Failed',
                                style: ResponsiveTextStyles.textSm.copyWith(
                                  color: const Color(0xFF0A2342),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                DateFormat(
                                  'MMM d, y h:mm a',
                                ).format(log.timestamp),
                                style: ResponsiveTextStyles.textXs.copyWith(
                                  color: const Color(
                                    0xFF0A2342,
                                  ).withOpacity(0.6),
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
                        ),
                        if (log.metrics != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${log.metrics!['steps']} steps',
                                style: ResponsiveTextStyles.textXs.copyWith(
                                  color: const Color(
                                    0xFF0A2342,
                                  ).withOpacity(0.6),
                                ),
                              ),
                              if (log.metrics!['sleepHours'] != null)
                                Text(
                                  '${log.metrics!['sleepHours'].toStringAsFixed(1)} hrs sleep',
                                  style: ResponsiveTextStyles.textXs.copyWith(
                                    color: const Color(
                                      0xFF0A2342,
                                    ).withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
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

  Widget _buildSettingsButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> iconColors,
    required VoidCallback onTap,
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
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF0A2342).withOpacity(0.3),
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Access health service
  HealthSyncService get _healthService => HealthSyncService();
}
