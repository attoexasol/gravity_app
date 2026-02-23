// lib/presentation/messages/screens/chat_screen.dart
// WhatsApp-style UI. ListView.builder reverse; send button visible; no extra scroll wrappers.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../data/model/message.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  static const Color _teal = Color(0xFF00B8A9);
  static const Color _darkBlue = Color(0xFF0A2342);
  static const Color _bgGrey = Color(0xFFF4F6F8);
  static const Color _emptyGrey = Color(0xFF9CA3AF);
  static const Color _bubbleOtherBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(context)),
          SafeArea(
            top: false,
            child: _buildInputBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return Obx(() {
      final list = controller.allMessages;
      final cid = controller.conversationId.value;
      if (cid == null && list.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (list.isEmpty) {
        return _buildEmptyState(context);
      }
      final items = _buildMessageItems(controller, list);
      final reversedItems = items.reversed.toList();
      final loading = controller.isLoadingOlder.value;
      return NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification &&
              controller.scrollController.hasClients &&
              controller.scrollController.position.pixels >=
                  controller.scrollController.position.maxScrollExtent - 80) {
            controller.loadOlder();
          }
          return false;
        },
        child: ListView.builder(
          controller: controller.scrollController,
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          physics: const BouncingScrollPhysics(),
          itemCount: (loading ? 1 : 0) + reversedItems.length,
          itemBuilder: (context, index) {
            if (loading && index == 0) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
                  ),
                ),
              );
            }
            final itemIndex = loading ? index - 1 : index;
            final item = reversedItems[itemIndex];
            if (item is _DaySeparator) {
              return _DaySeparatorWidget(label: item.label);
            }
            final messageItem = item as _MessageItem;
            return GestureDetector(
              onLongPress: () => _showMessageActions(context, messageItem.message),
              child: _MessageBubble(
                key: ValueKey(messageItem.message.id),
                message: messageItem.message,
                isMe: messageItem.isMe,
                isRead: messageItem.message.isRead,
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80.sp, color: _emptyGrey.withOpacity(0.7)),
          SizedBox(height: 16.h),
          Text(
            'No messages yet',
            style: ResponsiveTextStyles.textLg.copyWith(
              color: _emptyGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Send a message to start conversation',
            style: ResponsiveTextStyles.textSm.copyWith(color: _emptyGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static List<Object> _buildMessageItems(ChatController controller, List<Message> list) {
    final items = <Object>[];
    DateTime? lastDate;
    for (final msg in list) {
      final dt = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      if (lastDate != dt) {
        lastDate = dt;
        items.add(_DaySeparator(label: _dayLabel(msg.timestamp)));
      }
      items.add(_MessageItem(message: msg, isMe: controller.currentUid == msg.senderId));
    }
    return items;
  }

  static String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat.yMMMd().format(t);
  }

  void _showMessageActions(BuildContext context, Message message) {
    final isMyMessage = controller.currentUid == message.senderId;
    final canEditDelete = isMyMessage && message.type == 'text';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: AppShadows.shadowXl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (canEditDelete) ...[
                _MessageActionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  iconColor: AppColors.primary,
                  textColor: AppColors.foreground,
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.startEdit(message);
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.accent,
                ),
                _MessageActionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  iconColor: AppColors.destructive,
                  textColor: AppColors.destructive,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteMessage(context, message);
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.accent,
                ),
              ],
              _MessageActionTile(
                icon: Icons.copy,
                label: 'Copy',
                iconColor: AppColors.foreground,
                textColor: AppColors.foreground,
                onTap: () {
                  Navigator.pop(ctx);
                  if (message.type != 'deleted' && message.text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Get.snackbar('', 'Copied to clipboard', snackPosition: SnackPosition.BOTTOM);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMessage(BuildContext context, Message message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.deleteMessageSoft(messageId: message.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);
    if (d == today) return 'Last seen ${DateFormat.jm().format(lastSeen)}';
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Last seen yesterday ${DateFormat.jm().format(lastSeen)}';
    }
    return 'Last seen ${DateFormat.MMMd().format(lastSeen)}';
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Get.back();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (Get.isRegistered<ChatController>()) {
              Get.delete<ChatController>();
            }
          });
        },
      ),
      title: Row(
        children: [
          Hero(
            tag: 'chat_avatar_${controller.otherFirebaseUid}',
            child: CircleAvatar(
              radius: 22.r,
              backgroundColor: AppColors.muted,
              backgroundImage: controller.otherUserAvatar != null &&
                      controller.otherUserAvatar!.isNotEmpty
                  ? CachedNetworkImageProvider(controller.otherUserAvatar!)
                  : null,
              child: controller.otherUserAvatar == null ||
                      controller.otherUserAvatar!.isEmpty
                  ? Text(
                      controller.otherUserName.isNotEmpty
                          ? controller.otherUserName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.otherUserName,
                  style: ResponsiveTextStyles.textBase.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Obx(() {
                  if (controller.isOtherTyping.value) {
                    return Text(
                      'Typing...',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  final isOnline = controller.isOtherOnline.value;
                  final lastSeen = controller.otherLastSeen.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF4ADE80) : Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          isOnline
                              ? 'Online'
                              : _formatLastSeen(lastSeen),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_teal, _darkBlue],
          ),
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          if (!controller.isEditing.value) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            color: AppColors.muted.withOpacity(0.5),
            child: Row(
              children: [
                Text(
                  'Editing message',
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.cancelEdit,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }),
        Container(
          margin: EdgeInsets.all(12.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: _bubbleOtherBg,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller.textController,
                  onChanged: controller.onTextChanged,
                  onSubmitted: (_) => controller.submit(),
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 15.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    filled: false,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Obx(() {
                final canSend = controller.messageInput.value.trim().isNotEmpty;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canSend ? () => controller.submit() : null,
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: canSend ? _teal : AppColors.muted,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.send_rounded,
                        color: canSend ? Colors.white : AppColors.mutedForeground,
                        size: 24.sp,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 16),
              Text(
                label,
                style: AppTextStyles.textSm.copyWith(
                  color: textColor,
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

class _DaySeparator {
  final String label;
  _DaySeparator({required this.label});
}

class _MessageItem {
  final Message message;
  final bool isMe;
  _MessageItem({required this.message, required this.isMe});
}

class _DaySeparatorWidget extends StatelessWidget {
  final String label;

  const _DaySeparatorWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.muted.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            style: ResponsiveTextStyles.textXs.copyWith(
              color: AppColors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isRead;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.type == 'deleted';
    final showEdited = message.editedAt != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 8.h),
          constraints: BoxConstraints(maxWidth: 0.75 * MediaQuery.of(context).size.width),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isDeleted
                      ? AppColors.muted.withOpacity(0.6)
                      : (isMe ? ChatScreen._teal : ChatScreen._bubbleOtherBg),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: isMe && !isDeleted
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  isDeleted ? 'This message was deleted' : message.text,
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: isDeleted
                        ? AppColors.mutedForeground
                        : (isMe ? Colors.white : const Color(0xFF1F2937)),
                    height: 1.35,
                    fontStyle: isDeleted ? FontStyle.italic : null,
                  ),
                  softWrap: true,
                ),
              ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.only(left: 4.w, right: 4.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.jm().format(message.timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    if (showEdited) ...[
                      SizedBox(width: 4.w),
                      Text(
                        'Edited',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.mutedForeground,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (isMe && !isDeleted) ...[
                      SizedBox(width: 4.w),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14.sp,
                        color: isRead ? Colors.blueAccent : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
