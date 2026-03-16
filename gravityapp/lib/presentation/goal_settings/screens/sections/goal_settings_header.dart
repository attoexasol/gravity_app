import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_text_styles.dart';

/// Premium onboarding/goals header: gradient background, rounded bottom corners,
/// centered glass icon, title, subtitle, and subtle motion.
/// Reusable for goal settings, onboarding, and similar setup screens.
class OnboardingGradientHeader extends StatelessWidget {
  const OnboardingGradientHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  static const Color _gradientStart = Color(0xFF0A2342);
  static const Color _gradientEnd = Color(0xFF00B8A9);
  static const Color _subtitleColor = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_gradientStart, _gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40.r),
              bottomRight: Radius.circular(40.r),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                // top: 12.h,
                top: 4.h,
                bottom: 24.h,
              ),
              child: Animate(
                effects: [
                  FadeEffect(duration: 380.ms),
                  MoveEffect(
                    begin: const Offset(0, -20),
                    end: Offset.zero,
                    duration: 380.ms,
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconContainer(),
                    SizedBox(height: 16.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: ResponsiveTextStyles.textXl.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: _subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconContainer() {
    const double iconContainerSize = 72;
    const double iconSize = 36;
    const double glassOpacity = 0.20;

    return ClipRRect(
      borderRadius: BorderRadius.circular(36.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: iconContainerSize.w,
          height: iconContainerSize.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(glassOpacity),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize.sp,
              color: _subtitleColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Builds the goal settings header with default icon, title, and subtitle.
/// For custom content, use [OnboardingGradientHeader] directly.
Widget buildHeader(
  BuildContext context, {
  IconData icon = Icons.track_changes,
  String title = "Set Your Goals",
  String subtitle = "Let's personalize your wellness journey",
}) {
  return OnboardingGradientHeader(
    icon: icon,
    title: title,
    subtitle: subtitle,
  );
}
