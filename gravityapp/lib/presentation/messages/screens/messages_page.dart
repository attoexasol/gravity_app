import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';

import '../controllers/messages_controllers.dart';

class MessagesPage extends GetView<MessagesController> {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // If conversation selected, show chat view
      if (controller.selectedConversationId.value.isNotEmpty) {
        return _buildChatView();
      }

      // Otherwise show conversations list
      return _buildConversationsList();
    });
  }

  Widget _buildConversationsList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
          child: TextField(
            controller: controller.searchController,
            onChanged: (value) => controller.searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Search messages...',
              hintStyle: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: const Color(0xFF0A2342).withOpacity(0.4),
                size: 20.sp,
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            style: ResponsiveTextStyles.textSm,
          ),
        ),

        // Conversations list
        Expanded(
          child: Obx(() {
            // Show loading indicator
            if (controller.isLoadingConversations.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF00B8A9),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading conversations...',
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            final filteredConvs = controller.filteredConversations;

            if (filteredConvs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                bottom: 20.h,
              ),
              itemCount: filteredConvs.length,
              itemBuilder: (context, index) {
                return _buildConversationCard(filteredConvs[index]);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => controller.selectConversation(conversation.id),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              _buildUserAvatar(
                imageUrl: conversation.avatar,
                size: 48.w,
              ),
              SizedBox(width: 12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            style: ResponsiveTextStyles.textBase.copyWith(
                              color: const Color(0xFF0A2342),
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          controller.formatTime(conversation.timestamp),
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      conversation.lastMessage,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Unread badge
              if (conversation.unreadCount > 0) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B8A9),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: const Color(0xFF00B8A9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                size: 40.sp,
                color: const Color(0xFF00B8A9),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No messages yet',
              style: ResponsiveTextStyles.textLg.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.userType.value == 'customer'
                  ? 'Your coach will send you messages here'
                  : 'Start a conversation with your clients',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return Obx(() {
      // Watch conversations list to trigger rebuild when messages are added
      final conversationsList = controller.conversations;
      final selectedId = controller.selectedConversationId.value;
      
      if (selectedId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      // Find conversation from the reactive list
      Conversation? conversation;
      try {
        conversation = conversationsList.firstWhere((c) => c.id == selectedId);
      } catch (e) {
        conversation = null;
      }
      
      if (conversation == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          // Chat header
          _buildChatHeader(conversation),

          // Messages list
          Expanded(
            child: Obx(() {
              // Watch conversations again to get fresh messages
              final freshConversations = controller.conversations;
              Conversation? freshConv;
              try {
                freshConv = freshConversations.firstWhere((c) => c.id == selectedId);
              } catch (e) {
                freshConv = null;
              }
              
              if (freshConv == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = freshConv.messages;
              final isTyping = controller.isTyping.value;

              debugPrint('📱 Messages: Displaying ${messages.length} messages for conversation ${freshConv.id}');

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.6),
                    ),
                  ),
                );
              }

              // Ensure freshConv is not null before using it
              if (freshConv == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // Use a stable key based on conversation ID to preserve scroll position
              return ListView.builder(
                key: ValueKey('messages_${freshConv.id}'),
                controller: controller.messagesScrollController,
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 20.h,
                  bottom: 20.h,
                ),
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Typing indicator
                  if (index == messages.length && isTyping) {
                    return _buildTypingIndicator();
                  }

                  final message = messages[index];
                  return _buildMessageBubble(message, freshConv!);
                },
              );
            }),
          ),

          // Input area
          _buildInputArea(),
        ],
      );
    });
  }

  Widget _buildChatHeader(Conversation conversation) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: controller.closeConversation,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20.sp,
                color: const Color(0xFF0A2342),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Avatar
          _buildUserAvatar(
            imageUrl: conversation.avatar,
            size: 40.w,
          ),
          SizedBox(width: 12.w),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.name,
                  style: ResponsiveTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  controller.isTyping.value ? 'typing...' : 'Active now',
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // More button
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.more_vert,
                size: 20.sp,
                color: const Color(0xFF0A2342),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, Conversation conversation) {
    return Obx(() {
      final isEditing = controller.editingMessageId.value == message.id;
      final conversationId = conversation.id;

      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Row(
          mainAxisAlignment:
          message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Other person's avatar (left side)
            if (!message.isSent) ...[
              _buildUserAvatar(
                imageUrl: conversation.avatar,
                size: 32.w,
              ),
              SizedBox(width: 8.w),
            ],

            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: message.isSent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Edit mode or message bubble
                  if (isEditing && message.isSent)
                    _buildEditMessageField(conversationId, message)
                  else
                    GestureDetector(
                      onLongPress: message.isSent
                          ? () => controller.showMessageActions(conversationId, message)
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: message.isSent
                              ? const LinearGradient(
                            colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                          )
                              : null,
                          color: message.isSent ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                            bottomLeft: Radius.circular(message.isSent ? 20.r : 4.r),
                            bottomRight: Radius.circular(message.isSent ? 4.r : 20.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: message.isSent
                                ? Colors.white
                                : const Color(0xFF0A2342).withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),

                  // Timestamp & read status (only show when not editing)
                  if (!isEditing)
                    Padding(
                      padding: EdgeInsets.only(
                        left: message.isSent ? 0 : 4.w,
                        right: message.isSent ? 4.w : 0,
                        top: 4.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.formatMessageTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFF0A2342).withOpacity(0.4),
                            ),
                          ),
                          if (message.isSent) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12.sp,
                              color: const Color(0xFF00B8A9),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEditMessageField(String conversationId, Message message) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF00B8A9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller.editMessageController,
            onChanged: (value) => controller.editMessageText.value = value,
            maxLines: null,
            autofocus: true,
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342),
            ),
            decoration: InputDecoration(
              hintText: 'Edit message...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => controller.closeEditMessage(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: const Color(0xFF0A2342).withOpacity(0.6),
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Obx(() {
                final canSave = controller.editMessageText.value.trim().isNotEmpty &&
                    !controller.isUpdatingMessage.value;
                return ElevatedButton(
                  onPressed: canSave
                      ? () => controller.updateMessage(conversationId)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B8A9),
                    disabledBackgroundColor: const Color(0xFF0A2342).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                  child: controller.isUpdatingMessage.value
                      ? SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final conversation = controller.currentConversation;
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _buildUserAvatar(
            imageUrl: conversation?.avatar ?? '',
            size: 32.w,
          ),
          SizedBox(width: 8.w),

          // Typing animation
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(4.r),
                bottomRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4.w),
                _buildDot(1),
                SizedBox(width: 4.w),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, value, child) {
        final offset = value < 0.5 ? value * 2 : (1 - value) * 2;
        return Transform.translate(
          offset: Offset(0, -5 * offset),
          child: Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: Color(0xFF00B8A9),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: const Color(0xFF0A2342).withOpacity(0.5),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Input field
          Expanded(
            child: TextField(
              controller: controller.messageController,
              focusNode: controller.messageFocusNode,
              onChanged: (value) => controller.messageInput.value = value,
              onSubmitted: (_) {
                if (controller.messageInput.value.trim().isNotEmpty) {
                  controller.sendMessage();
                }
              },
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: ResponsiveTextStyles.textSm.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.4),
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              style: ResponsiveTextStyles.textSm,
            ),
          ),
          SizedBox(width: 8.w),

          // Send button
          Obx(() {
            final canSend = controller.messageInput.value.trim().isNotEmpty;
            return InkWell(
              onTap: canSend ? controller.sendMessage : null,
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: canSend
                      ? const LinearGradient(
                    colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                  )
                      : null,
                  color: canSend ? null : const Color(0xFF0A2342).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: canSend
                      ? Colors.white
                      : const Color(0xFF0A2342).withOpacity(0.4),
                  size: 22.sp,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build user avatar widget - displays profile image or default avatar
  Widget _buildUserAvatar({
    required String imageUrl,
    required double size,
  }) {
    // Check if imageUrl is a valid URL (starts with http:// or https://)
    final bool isNetworkUrl = imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
    
    // Check if it's a local file path
    final bool isLocalFile = imageUrl.isNotEmpty &&
        (imageUrl.startsWith('/') || imageUrl.contains('\\') || imageUrl.startsWith('file://'));

    if (isNetworkUrl) {
      // Network image
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildDefaultAvatar(size: size),
        ),
      );
    } else if (isLocalFile) {
      // Local file image
      try {
        final file = File(imageUrl.replaceFirst('file://', ''));
        if (file.existsSync()) {
          return ClipOval(
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(size: size),
            ),
          );
        }
      } catch (e) {
        // Fall through to default avatar
      }
    }

    // Default avatar (emoji or icon)
    return _buildDefaultAvatar(size: size, emoji: imageUrl.isNotEmpty ? imageUrl : null);
  }

  /// Build default avatar widget
  Widget _buildDefaultAvatar({
    required double size,
    String? emoji,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: emoji != null && emoji.length <= 2
            ? Text(
                emoji,
                style: TextStyle(fontSize: size * 0.5),
              )
            : Icon(
                Icons.person,
                size: size * 0.5,
                color: Colors.white,
              ),
      ),
    );
  }
}