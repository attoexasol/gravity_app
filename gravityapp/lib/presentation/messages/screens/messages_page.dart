import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gravityapp/data/model/conversation.dart';
import 'package:gravityapp/data/model/message.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';

import '../controllers/messages_controllers.dart';

/// Message status enum
enum MessageStatus {
  sent,      // Single checkmark, gray
  delivered, // Double checkmark, gray
  read,      // Double checkmark, colored
}

/// Message group information for UI styling
class MessageGroupInfo {
  final bool showAvatar;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isMiddleInGroup;

  MessageGroupInfo({
    required this.showAvatar,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.isMiddleInGroup,
  });
}

/// Item type for ListView (message, date separator, or typing indicator)
class _ListViewItem {
  final Message? message;
  final int? messageIndex;
  final DateTime? date;
  final bool isDateSeparator;
  final bool isTypingIndicator;

  _ListViewItem({
    this.message,
    this.messageIndex,
    this.date,
    this.isDateSeparator = false,
    this.isTypingIndicator = false,
  });

  factory _ListViewItem.message(Message message, int index) {
    return _ListViewItem(
      message: message,
      messageIndex: index,
    );
  }

  factory _ListViewItem.dateSeparator(DateTime date) {
    return _ListViewItem(
      date: date,
      isDateSeparator: true,
    );
  }

  factory _ListViewItem.typingIndicator() {
    return _ListViewItem(
      isTypingIndicator: true,
    );
  }
}

/// UI constants: teal → deep green, stacked below global header
class _MessagesUI {
  static const Color teal = Color(0xFF00B8A9);
  static const Color deepGreen = Color(0xFF0A2342);
  static const List<Color> headerGradient = [teal, deepGreen];
  static const Color bubbleIncoming = Color(0xFFE8E8EC);
  static const double pad = 16.0;
  static const double radiusSearch = 20.0;
  static const double radiusCard = 16.0;
  static const double radiusIncoming = 16.0;
  static const double radiusOutgoing = 20.0;
}

class MessagesPage extends GetView<MessagesController> {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedConversationId.value.isNotEmpty) {
        return _buildChatView(context);
      }
      return _buildConversationsList(context);
    });
  }

  /// Messages header: gradient extends to status bar; content padded below it
  Widget _buildMessagesListHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _MessagesUI.headerGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: _MessagesUI.pad.w,
          right: _MessagesUI.pad.w,
          top: topPadding + 12.h,
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
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '2 new',
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_outlined, color: Colors.white, size: 24.sp),
                  Positioned(
                    top: -2.h,
                    right: -2.w,
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12.w),
              InkWell(
                onTap: () => Get.toNamed('/settings'),
                borderRadius: BorderRadius.circular(24.r),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Icon(Icons.settings_outlined, color: Colors.white, size: 24.sp),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildConversationsList(BuildContext context) {
    return Column(
      children: [
        _buildMessagesListHeader(context),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _MessagesUI.pad.w,
            vertical: _MessagesUI.pad.h,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(_MessagesUI.radiusSearch.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search messages…',
                hintStyle: ResponsiveTextStyles.textSm.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.4),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFF0A2342).withOpacity(0.4),
                  size: 20.sp,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              ),
              style: ResponsiveTextStyles.textSm,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingConversations.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00B8A9)),
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
              controller: controller.conversationsScrollController,
              padding: EdgeInsets.only(
                left: _MessagesUI.pad.w,
                right: _MessagesUI.pad.w,
                bottom: _MessagesUI.pad.h,
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
      padding: EdgeInsets.only(bottom: 14.h),
      child: InkWell(
        onTap: () => controller.selectConversation(conversation.id),
        borderRadius: BorderRadius.circular(_MessagesUI.radiusCard.r),
        child: Container(
          padding: EdgeInsets.all(_MessagesUI.pad.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_MessagesUI.radiusCard.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildUserAvatar(imageUrl: conversation.avatar, size: 48.w),
              SizedBox(width: 12.w),
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
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          controller.formatTime(conversation.timestamp),
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.5),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      conversation.lastMessage,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (conversation.unreadCount > 0) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: const BoxDecoration(
                    color: _MessagesUI.teal,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 22.w, minHeight: 22.w),
                  child: Center(
                    child: Text(
                      conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
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

  Widget _buildChatView(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final conversation = controller.currentConversation;
          final typingUserId = controller.typingUserId.value;
          final currentUserId = controller.currentUserId;
          final isOtherUserTyping = typingUserId != null &&
              typingUserId != currentUserId &&
              conversation != null &&
              controller.selectedConversationId.value.isNotEmpty;
          if (conversation == null) {
            return const SizedBox.shrink();
          }
          return _buildChatHeader(context, conversation, isTyping: isOtherUserTyping);
        }),

        // Messages list - reactive to messages list only
        Expanded(
          child: Stack(
            children: [
              // Messages list - wrapped in Obx to watch messages
              Obx(() {
                final conversation = controller.currentConversation;
                if (conversation == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = conversation.messages;
                
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

                // Get reactive values for this build
                final typingUserId = controller.typingUserId.value;
                final currentUserId = controller.currentUserId;
                final lastReceivedMessageId = controller.lastReceivedMessageId.value;
                final editingMessageId = controller.editingMessageId.value;

                // Show typing indicator only if OTHER user is typing (not current user)
                final isOtherUserTyping = typingUserId != null && 
                    typingUserId != currentUserId &&
                    controller.selectedConversationId.value.isNotEmpty;

                // Calculate total items including date separators and typing indicator
                final totalItems = _calculateTotalItems(messages, includeTypingIndicator: isOtherUserTyping);
                
                // Use a stable key based on conversation ID to preserve scroll position
                return ListView.builder(
                  key: ValueKey('messages_${conversation.id}'),
                  controller: controller.messagesScrollController,
                  padding: EdgeInsets.only(
                    left: _MessagesUI.pad.w,
                    right: _MessagesUI.pad.w,
                    top: _MessagesUI.pad.h,
                    bottom: _MessagesUI.pad.h,
                  ),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    // Get the actual item (message or date separator) at this index
                    final item = _getItemAtIndex(messages, index, includeTypingIndicator: isOtherUserTyping);
                    
                    // Typing indicator (last item)
                    if (item.isTypingIndicator) {
                      // Typing indicator is already reactive via isTyping check above
                      return _buildTypingIndicator();
                    }
                    
                    // Date separator
                    if (item.isDateSeparator) {
                      return _buildDateSeparator(item.date!);
                    }
                    
                    // Message bubble - check if this message should be highlighted
                    final shouldHighlight = !item.message!.isSent && 
                        lastReceivedMessageId == item.message!.id;
                    
                    return _buildMessageBubble(
                      item.message!,
                      conversation,
                      messages,
                      item.messageIndex!,
                      shouldHighlight: shouldHighlight,
                    );
                  },
                );
              }),
              
              // WhatsApp-like "New Messages" button - reactive to hasNewIncomingMessage and isNearBottom
              Obx(() {
                if (controller.hasNewIncomingMessage.value && !controller.isNearBottom.value) {
                  return Positioned(
                    bottom: 100.h,
                    right: _MessagesUI.pad.w,
                    child: _buildNewMessagesButton(),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),

        // Input area - has its own Obx for send button
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context, Conversation conversation, {bool isTyping = false}) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        left: _MessagesUI.pad.w,
        right: _MessagesUI.pad.w,
        top: topPadding + _MessagesUI.pad.h,
        bottom: _MessagesUI.pad.h,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _MessagesUI.headerGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Row(
          children: [
            InkWell(
              onTap: controller.closeConversation,
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, size: 20.sp, color: Colors.white),
              ),
            ),
            SizedBox(width: 12.w),
            _buildUserAvatar(imageUrl: conversation.avatar, size: 40.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: ResponsiveTextStyles.textBase.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isTyping ? 'typing...' : 'Active now',
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.more_vert, size: 20.sp, color: Colors.white),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    Conversation conversation,
    List<Message> allMessages,
    int currentIndex, {
    bool shouldHighlight = false,
  }) {
    // Get editing state directly (not reactive inside itemBuilder)
    final isEditing = controller.editingMessageId.value == message.id;
    final conversationId = conversation.id;

    // Check if this message is part of a group with previous/next messages
    final messageGroupInfo = _getMessageGroupInfo(
      allMessages,
      currentIndex,
      message,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: messageGroupInfo.isLastInGroup ? 16.h : 4.h,
      ),
      child: Row(
        mainAxisAlignment:
        message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Other person's avatar (left side) - only show if first in group or not grouped
          if (!message.isSent && messageGroupInfo.showAvatar) ...[
            _buildUserAvatar(
              imageUrl: conversation.avatar,
              size: 32.w,
            ),
            SizedBox(width: 8.w),
          ] else if (!message.isSent && !messageGroupInfo.showAvatar) ...[
            // Spacer to align messages when avatar is hidden
            SizedBox(width: 40.w), // 32.w avatar + 8.w spacing
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
                    child: AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: message.isSent
                                ? const LinearGradient(
                                    colors: _MessagesUI.headerGradient,
                                  )
                                : null,
                            color: message.isSent
                                ? null
                                : (shouldHighlight
                                    ? _MessagesUI.teal.withOpacity(0.15)
                                    : _MessagesUI.bubbleIncoming),
                            borderRadius: _getMessageBorderRadius(
                              message.isSent,
                              messageGroupInfo,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8.r,
                                offset: Offset(0, 1.h),
                              ),
                            ],
                          ),
                          child: Text(
                            message.text,
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: message.isSent
                                  ? Colors.white
                                  : const Color(0xFF0A2342).withOpacity(0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                    ),

                  if (!isEditing && messageGroupInfo.isLastInGroup)
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
                              color: const Color(0xFF0A2342).withOpacity(0.45),
                            ),
                          ),
                          if (message.isSent) ...[
                            SizedBox(width: 4.w),
                            _buildMessageStatusIndicator(message),
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
  }

  /// Determine if message is part of a group and get grouping info
  MessageGroupInfo _getMessageGroupInfo(
    List<Message> allMessages,
    int currentIndex,
    Message currentMessage,
  ) {
    const groupTimeThreshold = Duration(minutes: 3);
    
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < allMessages.length - 1;
    
    Message? previousMessage;
    Message? nextMessage;
    
    if (hasPrevious) {
      previousMessage = allMessages[currentIndex - 1];
    }
    if (hasNext) {
      nextMessage = allMessages[currentIndex + 1];
    }

    // Check if grouped with previous message
    final isGroupedWithPrevious = hasPrevious &&
        previousMessage != null &&
        previousMessage.senderId == currentMessage.senderId &&
        (currentMessage.timestamp.difference(previousMessage.timestamp).abs() < groupTimeThreshold);

    // Check if grouped with next message
    final isGroupedWithNext = hasNext &&
        nextMessage != null &&
        nextMessage.senderId == currentMessage.senderId &&
        (nextMessage.timestamp.difference(currentMessage.timestamp).abs() < groupTimeThreshold);

    final isFirstInGroup = !isGroupedWithPrevious;
    final isLastInGroup = !isGroupedWithNext;
    final isMiddleInGroup = isGroupedWithPrevious && isGroupedWithNext;

    // Show avatar only if first in group (or not grouped at all)
    final showAvatar = isFirstInGroup && !currentMessage.isSent;

    return MessageGroupInfo(
      showAvatar: showAvatar,
      isFirstInGroup: isFirstInGroup,
      isLastInGroup: isLastInGroup,
      isMiddleInGroup: isMiddleInGroup,
    );
  }

  BorderRadius _getMessageBorderRadius(
    bool isSent,
    MessageGroupInfo groupInfo,
  ) {
    final rFirst = isSent ? _MessagesUI.radiusOutgoing : _MessagesUI.radiusIncoming;
    const rTail = 4.0;
    if (groupInfo.isLastInGroup) {
      return BorderRadius.only(
        topLeft: Radius.circular(rFirst.r),
        topRight: Radius.circular(rFirst.r),
        bottomLeft: Radius.circular(isSent ? rFirst.r : rTail.r),
        bottomRight: Radius.circular(isSent ? rTail.r : rFirst.r),
      );
    }
    if (groupInfo.isFirstInGroup) {
      return BorderRadius.only(
        topLeft: Radius.circular(rFirst.r),
        topRight: Radius.circular(rFirst.r),
        bottomLeft: Radius.circular(rTail.r),
        bottomRight: Radius.circular(rTail.r),
      );
    }
    return BorderRadius.all(Radius.circular(rTail.r));
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
              color: const Color(0xFF0A2342), // Dark text color
            ),
            cursorColor: const Color(0xFF0A2342), // Dark cursor
            decoration: InputDecoration(
              hintText: 'Edit message...',
              hintStyle: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
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

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _MessagesUI.bubbleIncoming,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_MessagesUI.radiusIncoming.r),
                topRight: Radius.circular(_MessagesUI.radiusIncoming.r),
                bottomLeft: Radius.circular(4.r),
                bottomRight: Radius.circular(_MessagesUI.radiusIncoming.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8.r,
                  offset: Offset(0, 1.h),
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
    return Builder(
      builder: (context) {
        // Get keyboard height directly from MediaQuery (not reactive)
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: _MessagesUI.pad.w,
            right: _MessagesUI.pad.w,
            top: _MessagesUI.pad.h,
            bottom: _MessagesUI.pad.h + keyboardHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: const Color(0xFF0A2342).withOpacity(0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: Offset(0, -2.h),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  focusNode: controller.messageFocusNode,
                  onChanged: (value) => controller.handleTyping(value),
                  onSubmitted: (_) {
                    if (controller.messageInput.value.trim().isNotEmpty) {
                      controller.sendMessage();
                    }
                  },
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342),
                  ),
                  cursorColor: const Color(0xFF0A2342),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_MessagesUI.radiusSearch.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Obx(() {
                final canSend = controller.messageInput.value.trim().isNotEmpty;
                return AnimatedScale(
                  scale: canSend ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: InkWell(
                    onTap: canSend ? controller.sendMessage : null,
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        gradient: canSend
                            ? const LinearGradient(
                                colors: _MessagesUI.headerGradient,
                              )
                            : null,
                        color: canSend
                            ? null
                            : const Color(0xFF0A2342).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: canSend
                            ? Colors.white
                            : const Color(0xFF0A2342).withOpacity(0.4),
                        size: 22.sp,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Build user avatar widget - displays profile image or default avatar
  Widget _buildUserAvatar({
    required String imageUrl,
    required double size,
  }) {
    Widget avatarWidget;
    
    // Check if imageUrl is a valid URL (starts with http:// or https://)
    final bool isNetworkUrl = imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
    
    // Check if it's a local file path
    final bool isLocalFile = imageUrl.isNotEmpty &&
        (imageUrl.startsWith('/') || imageUrl.contains('\\') || imageUrl.startsWith('file://'));

    if (isNetworkUrl) {
      // Network image
      avatarWidget = ClipOval(
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
          avatarWidget = ClipOval(
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(size: size),
            ),
          );
        } else {
          avatarWidget = _buildDefaultAvatar(size: size, emoji: imageUrl.isNotEmpty ? imageUrl : null);
        }
      } catch (e) {
        // Fall through to default avatar
        avatarWidget = _buildDefaultAvatar(size: size, emoji: imageUrl.isNotEmpty ? imageUrl : null);
      }
    } else {
      // Default avatar (emoji or icon)
      avatarWidget = _buildDefaultAvatar(size: size, emoji: imageUrl.isNotEmpty ? imageUrl : null);
    }
    
    return avatarWidget;
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

  /// Build WhatsApp-like "New Messages" button
  /// Shown when new incoming messages arrive while user is scrolled up
  Widget _buildNewMessagesButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.scrollToBottomManually(),
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 10.h,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'New Messages',
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calculate total items including date separators and typing indicator
  int _calculateTotalItems(List<Message> messages, {bool includeTypingIndicator = true}) {
    if (messages.isEmpty) {
      return includeTypingIndicator ? 1 : 0; // Just typing indicator if included
    }
    
    int count = messages.length; // Messages
    int dateSeparators = 0;
    
    // Count date separators needed
    for (int i = 0; i < messages.length; i++) {
      if (_needsDateSeparator(messages, i)) {
        dateSeparators++;
      }
    }
    
    return count + dateSeparators + (includeTypingIndicator ? 1 : 0); // Messages + separators + typing indicator (if included)
  }

  /// Get item at index (handles mapping between ListView index and actual items)
  _ListViewItem _getItemAtIndex(List<Message> messages, int listViewIndex, {bool includeTypingIndicator = true}) {
    if (messages.isEmpty) {
      if (includeTypingIndicator && listViewIndex == 0) {
        return _ListViewItem.typingIndicator();
      }
      // Should not happen, but return empty item
      return _ListViewItem();
    }
    
    int messageIndex = 0;
    int currentIndex = 0;
    final totalItems = _calculateTotalItems(messages, includeTypingIndicator: includeTypingIndicator);
    
    // Iterate through messages and add date separators as needed
    while (messageIndex < messages.length) {
      // Check if we need a date separator before this message
      if (_needsDateSeparator(messages, messageIndex)) {
        if (currentIndex == listViewIndex) {
          // This is the date separator
          return _ListViewItem.dateSeparator(messages[messageIndex].timestamp);
        }
        currentIndex++;
      }
      
      // Check if this is the message we're looking for
      if (currentIndex == listViewIndex) {
        return _ListViewItem.message(messages[messageIndex], messageIndex);
      }
      
      currentIndex++;
      messageIndex++;
    }
    
    // Must be typing indicator (if included and we've reached the last index)
    if (includeTypingIndicator && listViewIndex == totalItems - 1) {
      return _ListViewItem.typingIndicator();
    }
    
    // Should not happen, but return empty item
    return _ListViewItem();
  }

  /// Check if a date separator is needed before the message at index
  bool _needsDateSeparator(List<Message> messages, int index) {
    if (index == 0) {
      // Always show date separator for first message
      return true;
    }
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    // Check if day changed
    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );
    
    return !currentDate.isAtSameMomentAs(previousDate);
  }

  /// Format date for separator (Today, Yesterday, or formatted date)
  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      // Format as "Month Day, Year" or "Month Day" if same year
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final month = monthNames[date.month - 1];
      final day = date.day;
      
      if (date.year == now.year) {
        return '$month $day';
      } else {
        return '$month $day, ${date.year}';
      }
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: const Color(0xFF0A2342).withOpacity(0.18),
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2342).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                _formatDateSeparator(date),
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: const Color(0xFF0A2342).withOpacity(0.18),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated message status indicator (Sent / Delivered / Read)
  /// Uses existing isRead field to determine state
  Widget _buildMessageStatusIndicator(Message message) {
    // Determine message status based on isRead and timestamp
    // Since we only have isRead, we infer:
    // - Sent: Single checkmark (recent message, not read)
    // - Delivered: Double checkmark gray (older message, not read) 
    // - Read: Double checkmark colored (isRead = true)
    final now = DateTime.now();
    final messageAge = now.difference(message.timestamp);
    final isRecent = messageAge.inMinutes < 2; // Consider "recent" if less than 2 minutes
    
    MessageStatus status;
    if (message.isRead) {
      status = MessageStatus.read;
    } else if (isRecent) {
      status = MessageStatus.sent;
    } else {
      status = MessageStatus.delivered;
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: _buildStatusIcon(status, key: ValueKey(status)),
    );
  }

  Widget _buildStatusIcon(MessageStatus status, {Key? key}) {
    const grey = Color(0xFF0A2342);
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.done_all, key: key, size: 12.sp, color: grey.withOpacity(0.5));
      case MessageStatus.delivered:
        return Icon(Icons.done_all, key: key, size: 12.sp, color: grey.withOpacity(0.5));
      case MessageStatus.read:
        return Icon(Icons.done_all, key: key, size: 12.sp, color: _MessagesUI.teal);
    }
  }
}