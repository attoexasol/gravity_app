import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../controllers/dashboard_controller.dart';

class WeightLossJourneySection extends StatelessWidget {
  final DashboardController controller;

  const WeightLossJourneySection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        // Get starting weight from controller (loaded from storage, set from Settings > Current Weight)
        final double startingWeight = controller.startingWeight.value > 0
            ? controller.startingWeight.value
            : 0.0; // No default; show 0.0 when no data from Current Weight in Wellness Goals
        // Current weight = today's health data only; no fallback. Show 0.0 kg when none.
        final double currentWeight = controller.weight.value > 0
            ? controller.weight.value
            : 0.0;
        final double goalWeight = controller.weightGoal.value;

        // Calculate metrics
        final double totalWeightLoss = startingWeight - goalWeight;
        final double currentWeightLoss = startingWeight - currentWeight;
        final double remainingWeight = currentWeight - goalWeight;
        final double progressPercentage = (totalWeightLoss > 0)
            ? ((currentWeightLoss / totalWeightLoss) * 100).clamp(0.0, 100.0)
            : 0.0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Weight Journey",
                style: ResponsiveTextStyles.textLg.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A2342),
                ),
              ),
              SizedBox(height: 24.h),

              // Starting and Current Weight on Single Line
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Starting weight: ",
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.7),
                      ),
                    ),
                    Text(
                      startingWeight % 1 == 0
                          ? "${startingWeight.toInt()}kg"
                          : "${startingWeight.toStringAsFixed(1)}kg",
                      style: ResponsiveTextStyles.textBase.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A2342),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        "|",
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.3),
                        ),
                      ),
                    ),
                    Text(
                      "Current weight: ",
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.7),
                      ),
                    ),
                    Text(
                      currentWeight % 1 == 0
                          ? "${currentWeight.toInt()}kg"
                          : "${currentWeight.toStringAsFixed(1)}kg",
                      style: ResponsiveTextStyles.textBase.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00B8A9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Visual Separator above Progress Bar
              Container(
                height: 1,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0A2342).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Progress Bar Container
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final markerSize = 24.w; // w-6 h-6 = 24px
                  final markerRadius = markerSize / 2;
                  final barHeight = 8.h; // h-2 = 8px
                  final labelSpacing = 70.w; // Space for "0 kg" and "Goal: X kg" labels
                  final horizontalSpacing = 12.w; // Equal spacing between sections
                  final progressBarWidth = availableWidth - (labelSpacing * 2) - (horizontalSpacing * 2); // Width minus label spaces and spacing
                  final trackHeight = markerSize; // Height for track and thumb
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Bar Row - All three sections on same horizontal line with equal spacing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center align all elements
                        children: [
                          // "0 kg" label - First section (correct, keep as is)
                          SizedBox(
                            width: labelSpacing,
                            height: trackHeight, // Match track height for alignment
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "0 kg",
                                style: ResponsiveTextStyles.textXs.copyWith(
                                  color: const Color(0xFF0A2342).withOpacity(0.4),
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          // Equal spacing
                          SizedBox(width: horizontalSpacing),
                          // Progress Bar Container - Second section (move further left)
                          Expanded(
                            child: Transform.translate(
                              offset: Offset(-12.w, 0), // Move further to the left
                              child: SizedBox(
                                height: trackHeight, // Height for track and thumb
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Progress Bar Track (relative, h-2, bg-[#E5E7EB], rounded-full)
                                    Positioned(
                                      top: markerRadius - (barHeight / 2), // Center track vertically
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(barHeight / 2), // rounded-full
                                        ),
                                      ),
                                    ),
                                    // Active Progress with Gradient (absolute, left-0, top-0, h-full)
                                    Positioned(
                                      top: markerRadius - (barHeight / 2), // Align with track
                                      left: 0,
                                      right: 0,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: progressPercentage),
                                        duration: const Duration(milliseconds: 1000),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Container(
                                            height: barHeight,
                                            clipBehavior: Clip.hardEdge, // overflow-hidden
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(barHeight / 2),
                                            ),
                                            child: FractionallySizedBox(
                                              widthFactor: (value / 100).clamp(0.0, 1.0),
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                height: barHeight,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFF00B8A9), // from-[#00B8A9]
                                                      Color(0xFF0A2342), // to-[#0A2342]
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(barHeight / 2), // rounded-full
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Thumb/Indicator (w-6 h-6, bg-[#D4AF37], rounded-full, shadow-lg, border-4 border-white)
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: progressPercentage),
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeOut,
                                      builder: (context, value, child) {
                                        final clampedValue = (value / 100).clamp(0.0, 1.0);
                                        final progressWidth = progressBarWidth * clampedValue;
                                        // Position thumb center at the end of progress fill
                                        final thumbCenterX = progressWidth > 0
                                            ? progressWidth.clamp(markerRadius, progressBarWidth - markerRadius)
                                            : markerRadius;
                                        
                                        // Positioned must be a direct child of Stack, not wrapped in Transform
                                        // So we apply the animation to the Container inside Positioned
                                        return Positioned(
                                          left: thumbCenterX - markerRadius,
                                          top: 0, // Top of container (thumb extends above/below track)
                                          child: _DelayedScaleAnimation(
                                            delay: const Duration(milliseconds: 500),
                                            child: Container(
                                              width: markerSize, // w-6
                                              height: markerSize, // h-6
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD4AF37), // bg-[#D4AF37]
                                                shape: BoxShape.circle, // rounded-full
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 4.w, // border-4 border-white
                                                ),
                                                boxShadow: [
                                                  // shadow-lg
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 10.r,
                                                    offset: Offset(0, 4.h),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.06),
                                                    blurRadius: 4.r,
                                                    offset: Offset(0, 2.h),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Equal spacing
                          SizedBox(width: horizontalSpacing),
                          // "Goal: X kg" label - Third section (improved readability)
                          SizedBox(
                            width: labelSpacing,
                            height: trackHeight, // Match track height for alignment
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Goal: ${totalWeightLoss.toStringAsFixed(1)} kg",
                                style: ResponsiveTextStyles.textXs.copyWith(
                                  color: const Color(0xFF0A2342).withOpacity(0.6), // Increased opacity for better readability
                                  fontWeight: FontWeight.w500, // Slightly bolder for clarity
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Separate section for "X kg lost" text below the progress bar
                      SizedBox(height: 6.h),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progressPercentage),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          final clampedValue = (value / 100).clamp(0.0, 1.0);
                          final progressWidth = progressBarWidth * clampedValue;
                          final thumbCenterX = progressWidth > 0
                              ? progressWidth.clamp(markerRadius, progressBarWidth - markerRadius)
                              : markerRadius;
                          
                          return Padding(
                            padding: EdgeInsets.only(left: labelSpacing + horizontalSpacing + thumbCenterX - 40.w), // Align with thumb center
                            child: Text(
                              "${currentWeightLoss.toStringAsFixed(1)} kg lost",
                              style: ResponsiveTextStyles.textSm.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD4AF37),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 24.h),

              // Bottom Summary
              Container(
                padding: EdgeInsets.only(top: 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF0A2342).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Weight Lost
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00B8A9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              text: TextSpan(
                                style: ResponsiveTextStyles.textSm.copyWith(
                                  color: const Color(0xFF0A2342).withOpacity(0.7),
                                ),
                                children: [
                                  const TextSpan(text: "Weight Lost: "),
                                  TextSpan(
                                    text: "${currentWeightLoss.toStringAsFixed(1)} kg",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0A2342),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Remaining
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: RichText(
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                text: TextSpan(
                                  style: ResponsiveTextStyles.textSm.copyWith(
                                    color: const Color(0xFF0A2342).withOpacity(0.7),
                                  ),
                                  children: [
                                    const TextSpan(text: "Remaining: "),
                                    TextSpan(
                                      text: "${remainingWeight.toStringAsFixed(1)} kg",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0A2342),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper widget for delayed scale animation
class _DelayedScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _DelayedScaleAnimation({
    required this.child,
    required this.delay,
  });

  @override
  State<_DelayedScaleAnimation> createState() => _DelayedScaleAnimationState();
}

class _DelayedScaleAnimationState extends State<_DelayedScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

