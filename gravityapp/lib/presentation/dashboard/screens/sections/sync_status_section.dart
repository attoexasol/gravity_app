import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/health_sync_service.dart'
    show SyncStatus, HealthPlatform;

class SyncStatusSection extends StatelessWidget {
  final dynamic controller; // DashboardController

  const SyncStatusSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.timeTicker.value; // force rebuild for relative time updates
      final healthMetrics = controller.healthMetrics.value;
      final isSyncing = controller.isSyncing.value;

      // Always show the section - it will show "Connect" button if never initialized

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(
                0,
                -10 * (1 - opacity), // Animation offset only
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                constraints: BoxConstraints(maxWidth: 1280.w), // max-w-7xl
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      24.r,
                    ), // More rounded for capsule shape
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 20,
                        sigmaY: 20,
                      ), // Enhanced blur for stronger glassmorphism
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w, // Increased horizontal padding
                          vertical: 16
                              .h, // Increased vertical padding for better height
                        ),
                        decoration: BoxDecoration(
                          // Enhanced glassmorphism: gradient background with layered effects
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            24.r,
                          ), // Match clip radius
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5.w,
                          ),
                          boxShadow: [
                            // Outer shadow for depth
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20.r,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                            // Soft inner highlight
                            BoxShadow(
                              color: Colors.white.withOpacity(0.6),
                              blurRadius: 0,
                              offset: const Offset(0, -1),
                              spreadRadius: -1,
                            ),
                            // Additional soft shadow for glass effect
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10.r,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Status Icon
                                if (healthMetrics.syncStatus ==
                                    SyncStatus.syncing)
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.blue,
                                    ),
                                  )
                                else if (healthMetrics.syncStatus ==
                                    SyncStatus.error)
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 16.sp,
                                  )
                                else if (healthMetrics.syncStatus ==
                                    SyncStatus.success)
                                  // Green dot for success
                                  Container(
                                    width: 8.w,
                                    height: 8.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00B8A9),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  // Gray dot for never/not connected
                                  Container(
                                    width: 8.w,
                                    height: 8.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                SizedBox(width: 8.w),
                                // Status Text
                                Text(
                                  healthMetrics.syncStatus == SyncStatus.syncing
                                      ? 'Syncing health data...'
                                      : healthMetrics.syncStatus ==
                                            SyncStatus.success
                                      ? 'Synced ${controller.formatLastSync}'
                                      : healthMetrics.syncStatus ==
                                            SyncStatus.error
                                      ? 'Sync failed'
                                      : 'Not connected',
                                  style: ResponsiveTextStyles.textSm.copyWith(
                                    color:
                                        healthMetrics.syncStatus ==
                                            SyncStatus.success
                                        ? const Color(
                                            0xFF00B8A9,
                                          ) // Teal for success
                                        : healthMetrics.syncStatus ==
                                              SyncStatus.error
                                        ? Colors
                                              .red // Red for error
                                        : healthMetrics.syncStatus ==
                                              SyncStatus.syncing
                                        ? Colors
                                              .blue // Blue for syncing
                                        : const Color(
                                            0xFF0A2342,
                                          ), // Dark for not connected
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Platform Info
                                if (healthMetrics.platform !=
                                    HealthPlatform.none) ...[
                                  SizedBox(width: 8.w),
                                  Text(
                                    ' · ${healthMetrics.platform == HealthPlatform.apple ? 'Apple Health' : 'Google Fit'}',
                                    style: ResponsiveTextStyles.textXs.copyWith(
                                      color: const Color(
                                        0xFF00B8A9,
                                      ).withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Refresh/Connect Button
                            if (!isSyncing)
                              GestureDetector(
                                onTap: () async {
                                  // If never initialized, try to initialize
                                  if (healthMetrics.syncStatus ==
                                      SyncStatus.never) {
                                    final success = await controller.healthService.initialize();
                                    if (success) {
                                      // Initialize() may have already called syncHealthData(),
                                      // but ensure it's called if not
                                      await controller.healthService.syncHealthData();
                                    }
                                  } else {
                                    controller.handleManualSync();
                                  }
                                },
                                child: Text(
                                  healthMetrics.syncStatus == SyncStatus.never
                                      ? 'Connect'
                                      : 'Refresh',
                                  style: ResponsiveTextStyles.textSm.copyWith(
                                    color: const Color(
                                      0xFF00B8A9,
                                    ), // Teal color
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
