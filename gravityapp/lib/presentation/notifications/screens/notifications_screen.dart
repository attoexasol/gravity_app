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
                if (controller.loading.value && controller.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.value != null && controller.notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.error.value ?? 'Something went wrong',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.textSm,
                          ),
                          SizedBox(height: 16.h),
                          TextButton(
                            onPressed: () => controller.refreshList(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final list = controller.notifications;
                return RefreshIndicator(
                  onRefresh: () => controller.refreshList(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification) {
                        final m = notification.metrics;
                        if (m.pixels >= m.maxScrollExtent - 200) controller.loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: list.length + (controller.loadingMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                      if (index >= list.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = list[index];
                      return NotificationCard(
                        item: item,
                        onTap: () => controller.onOpenNotification(item),
                      );
                    },
                    ),
                  ),
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
                onTap: () => controller.onMarkAllRead(),
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
