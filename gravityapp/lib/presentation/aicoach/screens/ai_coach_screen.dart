import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gravityapp/presentation/aicoach/screens/sections/quick_actions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/ai_coach_controller.dart';

class AiCoachScreen extends GetView<AiCoachController> {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(AiCoachController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button
            _buildHeader(),

            // Quick Actions
            QuickActionsSection(controller: controller),


            // Messages List
            Expanded(
              child: _buildMessagesList(),
            ),

            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 16.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00B8A9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Top row with back button and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
              ),

              // Right actions
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      // Navigate to notifications
                      Get.toNamed('/notifications');
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: () {
                      // Navigate to settings
                      Get.toNamed('/settings');
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // AI Coach Title
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach',
                      style: ResponsiveTextStyles.textLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4AF37),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'Always available',
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildMessagesList() {
    return Obx(() {
      return ListView.builder(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: 20.h,
        ),
        itemCount: controller.messages.length + (controller.isTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Typing indicator
          if (index == controller.messages.length && controller.isTyping.value) {
            return _buildTypingIndicator();
          }

          final message = controller.messages[index];
          return _buildMessageBubble(message);
        },
      );
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00B8A9)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 8.w),
          ],

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name (for AI only)
                if (!isUser)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                    child: Text(
                      'AI Coach',
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                  ),

                // Message bubble
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                      colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                    )
                        : null,
                    color: isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                      bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
                      bottomRight: Radius.circular(isUser ? 4.r : 20.r),
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
                      color: isUser
                          ? Colors.white
                          : const Color(0xFF0A2342).withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ),

                // Timestamp
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 4.w,
                    right: isUser ? 4.w : 0,
                    top: 4.h,
                  ),
                  child: Text(
                    controller.formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF0A2342).withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          Container(
            width: 32.w,
            height: 32.w,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00B8A9)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 8.w),

          // Typing animation
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                child: Text(
                  'AI Coach is typing...',
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.6),
                  ),
                ),
              ),
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
                    _buildDot(200),
                    SizedBox(width: 4.w),
                    _buildDot(400),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * (value < 0.5 ? value * 2 : (1 - value) * 2)),
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
      onEnd: () {
        // Loop animation
      },
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
              onChanged: (value) => controller.inputMessage.value = value,
              onSubmitted: (_) {
                if (controller.inputMessage.value.trim().isNotEmpty) {
                  controller.sendMessage();
                }
              },
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Ask your AI coach',
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
            final canSend = controller.inputMessage.value.trim().isNotEmpty;
            return InkWell(
              onTap: canSend ? controller.sendMessage : null,
              borderRadius: BorderRadius.circular(20.r),
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
                  color: canSend ? Colors.white : const Color(0xFF0A2342).withOpacity(0.4),
                  size: 22.sp,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}