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
          _buildHeader(context),
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
                        onDelete: () => controller.deleteNotification(item),
                      );
                    },
                    ),
                  ),
                );
              }),
            ),
          ),
          _buildClearBar(context),
        ],
      ),
    );
  }

  /// Header uses same gradient as MainAppBar and extends under the status bar.
  Widget _buildHeader(BuildContext context) {
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
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
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Obx(() => Text(
                          '${controller.unreadCount.value} unread',
                          style: AppTextStyles.textSm.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        )),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
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

  /// Bottom bar with "Clear all" – similar to smartphone notification panel.
  /// Only visible when there are notifications; tap shows confirmation then clears.
  Widget _buildClearBar(BuildContext context) {
    return Obx(() {
      if (controller.notifications.isEmpty) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: TextButton(
            onPressed: () => _showClearConfirmation(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.chart5,
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: Text(
              'Clear all',
              style: AppTextStyles.textSm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showClearConfirmation(BuildContext context) {
    if (controller.notifications.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear notifications?'),
        content: const Text(
          'All notifications will be removed from this list. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.onClearAll();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
