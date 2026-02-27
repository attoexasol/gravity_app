import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/notifications_controller.dart';
import 'sections/notification_card.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final list = controller.notifications;
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return NotificationCard(
                      item: item,
                      onTap: () => controller.markAsRead(item.id),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Header uses same gradient as MainAppBar and extends under the status bar.
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(40.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: controller.onBack,
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Notifications',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Obx(() => Text(
                          '${controller.unreadCount.value} unread',
                          style: AppTextStyles.textSm.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: controller.markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: AppTextStyles.textSm.copyWith(
                    color: AppColors.chart5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
