import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/messages_controller.dart';
import '../../../../data/model/message_user_model.dart';

/// Inbox: user list with search, infinite scroll, real-time conversation preview per row.
class MessagesView extends GetView<InboxController> {
  const MessagesView({super.key});

  static const _headerGradient = [Color(0xFF00B8A9), Color(0xFF0A2342)];
  static const _pad = 16.0;

  @override
  Widget build(BuildContext context) {
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
    final topPadding = MediaQuery.of(context).padding.top;
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
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Get.toNamed('/settings'),
              ),
            ],
          ),
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

/// Single user row. READ-ONLY: no controller state updates, no sort/scroll from here.
/// Preview from controller (sortedUsersList + unreadCountByUser, typingByUser); presence from stream only for UI.
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
      final unreadCount = controller.unreadCountByUser[user.id] ?? 0;
      final isOtherTyping = controller.typingByUser[user.id] ?? false;
      return StreamBuilder<bool>(
        stream: controller.userPresenceStream(otherUid),
        initialData: false,
        builder: (context, presenceSnapshot) {
          final isOnline = presenceSnapshot.data ?? false;
          return _buildTile(
            context,
            displayMessage,
            displayTime,
            unreadCount: unreadCount,
            isOtherTyping: isOtherTyping,
            isOnline: isOnline,
          );
        },
      );
    });
  }

  Widget _buildTile(BuildContext context, String? subtitle, DateTime? time, {int unreadCount = 0, bool isOtherTyping = false, bool isOnline = false}) {
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
                  if (unreadCount > 0)
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
