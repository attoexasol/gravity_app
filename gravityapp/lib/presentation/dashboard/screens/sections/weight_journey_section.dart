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
        // Default starting weight (can be loaded from storage in the future)
        const double startingWeight = 85.0;
        final double currentWeight = controller.weight.value > 0
            ? controller.weight.value
            : startingWeight;
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
                  final markerSize = 24.w;
                  final markerRadius = markerSize / 2;
                  final barHeight = 6.h;
                  final labelHeight = 18.h;
                  final maxContentHeight = markerSize + 32.h;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: maxContentHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 50.w,
                                  child: Text(
                                    "0 kg",
                                    style: ResponsiveTextStyles.textXs.copyWith(
                                      color: const Color(0xFF0A2342).withOpacity(0.4),
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: maxContentHeight,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            height: barHeight,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE5E7EB),
                                              borderRadius: BorderRadius.circular(3.r),
                                            ),
                                            child: Stack(
                                              clipBehavior: Clip.hardEdge,
                                              children: [
                                                TweenAnimationBuilder<double>(
                                                  tween: Tween(begin: 0.0, end: progressPercentage),
                                                  duration: const Duration(milliseconds: 1000),
                                                  curve: Curves.easeOut,
                                                  builder: (context, value, child) {
                                                    return FractionallySizedBox(
                                                      widthFactor: (value / 100).clamp(0.0, 1.0),
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        height: barHeight,
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [
                                                              Color(0xFF00B8A9),
                                                              Color(0xFF0A2342),
                                                            ],
                                                          ),
                                                          borderRadius: BorderRadius.circular(3.r),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: progressPercentage),
                                          duration: const Duration(milliseconds: 1000),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            final clampedValue = (value / 100).clamp(0.0, 1.0);
                                            final progressWidth = (availableWidth - 100.w) * clampedValue;
                                            final markerPosition = progressWidth
                                                .clamp(markerRadius, (availableWidth - 100.w) - markerRadius);
                                            
                                            return _DelayedScaleAnimation(
                                              delay: const Duration(milliseconds: 500),
                                              child: Positioned(
                                                left: markerPosition - markerRadius,
                                                top: (maxContentHeight / 2) - (markerSize / 2),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: markerSize,
                                                      height: markerSize,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFD4AF37),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 4.w,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.15),
                                                            blurRadius: 8.r,
                                                            offset: Offset(0, 2.h),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(height: 6.h),
                                                    ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        maxWidth: ((availableWidth - 100.w) * 0.4).clamp(60.0, 120.0),
                                                      ),
                                                      child: Text(
                                                        "${currentWeightLoss.toStringAsFixed(1)} kg lost",
                                                        style: ResponsiveTextStyles.textSm.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: const Color(0xFFD4AF37),
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 50.w,
                                  child: Text(
                                    "Goal: ${totalWeightLoss.toStringAsFixed(1)} kg",
                                    style: ResponsiveTextStyles.textXs.copyWith(
                                      color: const Color(0xFF0A2342).withOpacity(0.4),
                                    ),
                                    textAlign: TextAlign.right,
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
                    Expanded(
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
                    Expanded(
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

