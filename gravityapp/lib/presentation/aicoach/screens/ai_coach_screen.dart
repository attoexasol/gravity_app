import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gravityapp/data/model/ai_coach.dart';
import 'package:gravityapp/presentation/aicoach/screens/sections/quick_actions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/ai_coach_controller.dart';
import '../../main_layout/controllers/main_layout_controller.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Initialize controller
  late final AiCoachController controller;
  
  // Animation controllers for typing indicator dots
  late final AnimationController _dot1Controller;
  late final AnimationController _dot2Controller;
  late final AnimationController _dot3Controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    controller = Get.put(AiCoachController());

    // Initialize animation controllers for typing dots
    _dot1Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dot2Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dot3Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Listen to typing state changes to control animations
    ever(controller.isTyping, (isTyping) {
      if (isTyping) {
        // Start animations with staggered delays
        Future.delayed(const Duration(milliseconds: 0), () {
          if (mounted && controller.isTyping.value) {
            _dot1Controller.repeat(reverse: true);
          }
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && controller.isTyping.value) {
            _dot2Controller.repeat(reverse: true);
          }
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && controller.isTyping.value) {
            _dot3Controller.repeat(reverse: true);
          }
        });
      } else {
        // Stop all animations when typing stops
        _dot1Controller.stop();
        _dot1Controller.reset();
        _dot2Controller.stop();
        _dot2Controller.reset();
        _dot3Controller.stop();
        _dot3Controller.reset();
      }
    });

    // Listen to keyboard visibility changes to scroll to bottom when keyboard opens
    ever(controller.isKeyboardVisible, (isKeyboardVisible) {
      if (isKeyboardVisible && controller.messageFocusNode.hasFocus) {
        // Scroll to bottom when keyboard opens and text field is focused
        // Delay to allow keyboard animation to complete
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    });

    // Listen to text field focus changes to scroll when user taps on input
    controller.messageFocusNode.addListener(() {
      if (controller.messageFocusNode.hasFocus) {
        // Scroll to bottom when text field gets focus
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    });

    // Observe keyboard visibility changes
    WidgetsBinding.instance.addObserver(this);

    // Initial keyboard state check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardVisibility();
      // Jump to bottom immediately when screen first opens (no animation)
      _jumpToBottomOnInit();
    });
  }

  /// Jump to bottom immediately when screen first opens (no animation)
  void _jumpToBottomOnInit() {
    if (!controller.messagesScrollController.hasClients) {
      // Wait for ListView to be built
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && controller.messagesScrollController.hasClients) {
          final position = controller.messagesScrollController.position;
          controller.messagesScrollController.jumpTo(position.maxScrollExtent);
        }
      });
      return;
    }
    
    final position = controller.messagesScrollController.position;
    controller.messagesScrollController.jumpTo(position.maxScrollExtent);
  }

  @override
  void dispose() {
    // Dispose animation controllers
    _dot1Controller.dispose();
    _dot2Controller.dispose();
    _dot3Controller.dispose();
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when keyboard visibility changes (via WidgetsBindingObserver)
  /// Also handles screen rotation and other layout changes
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Update keyboard visibility when metrics change (keyboard open/close, rotation, etc.)
    _updateKeyboardVisibility();
  }

  /// ============================================
  /// KEYBOARD VISIBILITY DETECTION
  /// ============================================
  /// Detects keyboard visibility using MediaQuery.viewInsets.bottom
  /// - viewInsets.bottom > 0 means keyboard is visible
  /// - Updates controller state to trigger animations
  /// - Threshold of 50 pixels to avoid false positives from small insets
  void _updateKeyboardVisibility() {
    if (!mounted) return;

    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardHeight = viewInsets.bottom;

    // Keyboard is considered visible if bottom inset is significant (> 50 pixels)
    // This threshold prevents false positives from small safe area insets
    final isKeyboardVisible = keyboardHeight > 50;

    // Update controller state (triggers reactive updates)
    controller.isKeyboardVisible.value = isKeyboardVisible;
  }

  /// Scroll to bottom of messages list
  void _scrollToBottom() {
    if (!controller.messagesScrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.messagesScrollController.hasClients) return;
      
      final position = controller.messagesScrollController.position;
      final maxScroll = position.maxScrollExtent;
      
      // Scroll to bottom to show most recent messages
      controller.messagesScrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Navigate back to Home/Dashboard
  /// Resets the navigation index to 0 (Home) and navigates to the home route
  void _safeBack() {
    try {
      // Reset the main layout controller's current index to 0 (Home/Dashboard)
      if (Get.isRegistered<MainLayoutController>()) {
        final mainLayoutController = Get.find<MainLayoutController>();
        mainLayoutController.currentIndex.value = 0;
      }

      // Navigate to home route, replacing the current route
      Get.offNamed('/home');
      debugPrint('✅ Navigated back to Home/Dashboard');
    } catch (e) {
      debugPrint('⚠️ Navigation to Home failed: $e');
      // Fallback: try regular pop if navigation fails
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (popError) {
        debugPrint('⚠️ Navigator.pop() also failed: $popError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update keyboard visibility on every build (handles MediaQuery changes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardVisibility();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      // Use resizeToAvoidBottomInset to handle keyboard properly
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button
            _buildHeader(),

            // Quick Actions (with keyboard-aware animation)
            _buildAnimatedQuickActions(),

            // Messages List
            Expanded(child: _buildMessagesList()),

            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _safeBack(),
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
                child: Icon(Icons.psychology, color: Colors.white, size: 24.sp),
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

  /// ============================================
  /// ANIMATED QUICK ACTIONS SECTION
  /// ============================================
  /// Animates Quick Actions based on keyboard visibility and TextField focus:
  /// - When keyboard opens AND TextField is focused → slide up and fade
  /// - When keyboard closes OR TextField loses focus → slide down and restore
  ///
  /// Animation Strategy:
  /// 1. ClipRect: Prevents overflow during animation
  /// 2. AnimatedSize: Smoothly animates height changes (no layout jump)
  ///    - Always renders QuickActionsSection to allow proper measurement
  ///    - Uses SizedBox with height 0 when hidden to collapse smoothly
  /// 3. AnimatedOpacity: Fades in/out for smooth visual transition
  /// 4. AnimatedSlide: Slides up/down on Y-axis for natural movement
  ///
  /// Edge Cases Handled:
  /// - Fast keyboard open/close: Animation completes smoothly without lag
  /// - Screen rotation: Maintains correct state via didChangeMetrics
  /// - Multiple focus changes: No flickering or layout jumps
  /// - Keyboard dismissal via back button: Properly detects via viewInsets
  /// - Layout stability: AnimatedSize prevents jumping during transitions
  Widget _buildAnimatedQuickActions() {
    return Obx(() {
      // Single source of truth: Hide when keyboard is visible AND TextField is focused
      final shouldHide = controller.shouldHideQuickActions;

      return ClipRect(
        // Clip overflow to prevent content from showing during animation
        child: AnimatedSize(
          duration: const Duration(
            milliseconds: 300,
          ), // Smooth height animation
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter, // Align from top for upward slide
          // AnimatedSize requires the child to be present in both states for proper measurement
          // We always render QuickActionsSection but constrain its height when hidden
          child: shouldHide
              ? SizedBox(
                  // When hidden: zero height collapses the widget smoothly
                  height: 0,
                  child: _buildQuickActionsWithAnimation(
                    opacity: 0.0,
                    slideOffset: const Offset(
                      0,
                      -1,
                    ), // Slide upward (off-screen)
                  ),
                )
              : _buildQuickActionsWithAnimation(
                  opacity: 1.0,
                  slideOffset: Offset.zero, // Normal position (no offset)
                ),
        ),
      );
    });
  }

  /// Helper method to build Quick Actions with consistent animation widgets
  /// This ensures the same animation structure is used in both visible and hidden states
  Widget _buildQuickActionsWithAnimation({
    required double opacity,
    required Offset slideOffset,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250), // Slightly faster fade
      opacity: opacity,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        offset: slideOffset,
        child: QuickActionsSection(controller: controller),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Obx(() {
      // Set initial scroll position to bottom immediately (no animation)
      // This ensures the latest message is visible when screen opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.messages.isNotEmpty && 
            controller.messagesScrollController.hasClients) {
          final position = controller.messagesScrollController.position;
          if (position.pixels != position.maxScrollExtent) {
            // Only jump if not already at bottom (to avoid unnecessary jumps)
            controller.messagesScrollController.jumpTo(position.maxScrollExtent);
          }
        }
      });

      return ListView.builder(
        controller:
            controller.messagesScrollController, // Add scroll controller
        reverse: false, // Normal order: oldest at top, newest at bottom
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: 20.h,
        ),
        itemCount:
            controller.messages.length + (controller.isTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Typing indicator
          if (index == controller.messages.length &&
              controller.isTyping.value) {
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
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
              child: Icon(Icons.psychology, color: Colors.white, size: 18.sp),
            ),
            SizedBox(width: 8.w),
          ],

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
            child: Icon(Icons.psychology, color: Colors.white, size: 18.sp),
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
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
                child: _buildTypingDots(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build typing indicator dots with continuous looping animation
  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedDot(_dot1Controller),
        SizedBox(width: 4.w),
        _buildAnimatedDot(_dot2Controller),
        SizedBox(width: 4.w),
        _buildAnimatedDot(_dot3Controller),
      ],
    );
  }

  /// Build a single animated dot with bouncing animation
  Widget _buildAnimatedDot(AnimationController dotController) {
    return AnimatedBuilder(
      animation: dotController,
      builder: (context, child) {
        // Create a bouncing effect: goes from 0 to 1 and back
        final value = dotController.value;
        final offset = -5 * (value < 0.5 ? value * 2 : (1 - value) * 2);
        
        return Transform.translate(
          offset: Offset(0, offset),
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
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
            child: Obx(
              () => TextField(
                controller: controller.messageController,
                focusNode: controller
                    .messageFocusNode, // Connect FocusNode for focus detection
                onChanged: (value) => controller.inputMessage.value = value,
                onSubmitted: (_) {
                  if (controller.inputMessage.value.trim().isNotEmpty &&
                      !controller.isSending.value) {
                    controller.sendMessage();
                  }
                },
                enabled: !controller.isSending.value,
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
          ),
          SizedBox(width: 8.w),

          // Send button
          Obx(() {
            final canSend =
                controller.inputMessage.value.trim().isNotEmpty &&
                !controller.isSending.value;
            final isSending = controller.isSending.value;
            return InkWell(
              onTap: canSend ? controller.sendMessage : null,
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: (canSend || isSending)
                      ? const LinearGradient(
                          colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                        )
                      : null,
                  color: (canSend || isSending)
                      ? null
                      : const Color(0xFF0A2342).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
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
}
