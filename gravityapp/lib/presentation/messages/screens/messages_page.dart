// Messages tab: inbox (users from API + Firestore conversation preview).
// Badge driven by hasUnread from realtime conversation stream. Tap user -> ChatScreen.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../widgets/notification_icon_button.dart';
import '../controllers/messages_controller.dart';
import '../../../data/model/message_user_model.dart';

/// Messages tab: professional inbox with search, infinite scroll, real-time preview per row.
/// Unread badge shown only when hasUnread == true (from stream).
class MessagesPage extends GetView<InboxController> {
  const MessagesPage({super.key});

  static const _headerGradient = [Color(0xFF00B8A9), Color(0xFF0A2342)];
  static const _pad = 16.0;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<InboxController>()) {
      Get.put(InboxController());
    }
    return Column(
      children: [
        _buildHeader(context),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _pad.w, vertical: 8.h),
          child: _buildSearchField(context),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.users.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = controller.sortedUsersList;
            if (list.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildUserList(context, list);
          }),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _headerGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: _pad.w,
            right: _pad.w,
            top: 12.h,
            bottom: 18.h,
          ),
          child: Row(
            children: [
              Text(
                'Messages',
                style: ResponsiveTextStyles.textLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final count = Get.isRegistered<NotificationsController>()
                        ? Get.find<NotificationsController>().unreadCount.value
                        : 0;
                    return NotificationIconButton(
                      unreadCount: count,
                      onTap: () => Get.toNamed('/notifications'),
                      size: 44,
                      iconSize: 22,
                      icon: Icons.notifications_outlined,
                    );
                  }),
                  SizedBox(width: 12.w),
                  _buildHeaderIcon(
                    icon: Icons.settings_outlined,
                    onTap: () => Get.toNamed('/settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Same icon container style as dashboard header: rounded, light background, shadow.
  Widget _buildHeaderIcon({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 44.w,
          height: 44.h,
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
          child: Icon(icon, color: Colors.white, size: 22.sp),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.search,
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, size: 22.sp, color: AppColors.mutedForeground),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64.sp, color: AppColors.mutedForeground),
            SizedBox(height: 16.h),
            Text(
              'No users found',
              style: ResponsiveTextStyles.textBase.copyWith(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.searchQuery.value.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Try a different search',
                style: ResponsiveTextStyles.textSm.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<MessageUserModel> list) {
    return ListView.builder(
      controller: controller.scrollController,
      padding: EdgeInsets.symmetric(horizontal: _pad.w, vertical: 8.h),
      itemCount: list.length + (controller.isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= list.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final user = list[index];
        return _UserRow(
          key: ValueKey(user.id),
          user: user,
          controller: controller,
        );
      },
    );
  }
}

/// Single user row. Badge visibility driven only by hasUnread from stream.
class _UserRow extends StatelessWidget {
  final MessageUserModel user;
  final InboxController controller;

  const _UserRow({super.key, required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    final otherUid = (user.firebaseUid != null && user.firebaseUid!.isNotEmpty)
        ? user.firebaseUid!
        : user.id.toString();
    final displayMessage = user.lastMessage;
    final displayTime = user.lastMessageTime;
    return Obx(() {
      final hasUnread = controller.hasUnreadByUser[user.id] ?? false;
      final isOtherTyping = controller.typingByUser[user.id] ?? false;
      final unreadCount = hasUnread ? (controller.unreadCountByUser[user.id] ?? 1) : 0;
      return StreamBuilder<bool>(
        stream: controller.userPresenceStream(otherUid),
        initialData: false,
        builder: (context, presenceSnapshot) {
          final isOnline = presenceSnapshot.data ?? false;
          return _buildTile(
            context,
            displayMessage,
            displayTime,
            hasUnread: hasUnread,
            unreadCount: unreadCount,
            isOtherTyping: isOtherTyping,
            isOnline: isOnline,
          );
        },
      );
    });
  }

  Widget _buildTile(
    BuildContext context,
    String? subtitle,
    DateTime? time, {
    required bool hasUnread,
    int unreadCount = 0,
    bool isOtherTyping = false,
    bool isOnline = false,
  }) {
    final displaySubtitle = isOtherTyping ? 'Typing...' : (subtitle != null && subtitle.isNotEmpty ? subtitle : 'Start conversation');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openChat(user),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: AppColors.muted,
                    backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                        ? CachedNetworkImageProvider(user.profileImage!)
                        : null,
                    child: user.profileImage == null || user.profileImage!.isEmpty
                        ? Text(
                            (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                            style: TextStyle(
                              fontSize: 20.sp,
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF4ADE80) : AppColors.muted,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.w),
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: -4.w,
                      top: -4.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00B8A9),
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.h),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: ResponsiveTextStyles.textBase.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      displaySubtitle,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: isOtherTyping
                            ? AppColors.primary
                            : (subtitle != null && subtitle.isNotEmpty ? AppColors.mutedForeground : AppColors.primary),
                        fontStyle: isOtherTyping ? FontStyle.italic : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (time != null) ...[
                SizedBox(width: 8.w),
                Text(
                  _formatTime(time),
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dt = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (dt == today) {
      return DateFormat.jm().format(dateTime);
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (dt == yesterday) {
      return 'Yesterday';
    }
    if (now.difference(dateTime).inDays < 7) {
      return DateFormat.E().format(dateTime);
    }
    return DateFormat.yMd().format(dateTime);
  }
}
