import 'package:flutter/material.dart';

import '../../../../app/theme/app_text_styles.dart';
import '../../controllers/onboarding_controller.dart';

class OnboardingSlide extends StatefulWidget {
  final OnboardingSlideModel slide;
  final int index;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final bool isLargeScreen;

  const OnboardingSlide({super.key, 
    required this.slide,
    required this.index,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.isLargeScreen,
  });

  @override
  State<OnboardingSlide> createState() => OnboardingSlideState();
}

class OnboardingSlideState extends State<OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final illustrationSize = widget.isLargeScreen
        ? 320.0
        : (widget.isMediumScreen ? 256.0 : (widget.isSmallScreen ? 192.0 : 224.0));
    final innerCircleSize = illustrationSize * 0.75;
    final coreCircleSize = illustrationSize * 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isLargeScreen ? 64 : (widget.isMediumScreen ? 48 : 24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Placeholder with Pulse Animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.05);
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: illustrationSize,
              height: illustrationSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.slide.gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.slide.gradientColors[0].withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: innerCircleSize,
                  height: innerCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Container(
                      width: coreCircleSize,
                      height: coreCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: widget.isLargeScreen ? 48 : (widget.isMediumScreen ? 40 : 32)),

          // Title
          Text(
            widget.slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.isLargeScreen
                  ? 48
                  : (widget.isMediumScreen ? 40 : (widget.isSmallScreen ? 30 : 36)),
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          // Tagline - Only on first slide
          if (widget.index == 0 && widget.slide.tagline != null) ...[
            SizedBox(height: widget.isSmallScreen ? 16 : 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.slide.tagline!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: widget.isSmallScreen ? 18 : 20,
                  height: 1.4,
                ),
              ),
            ),
          ],

          SizedBox(height: widget.isSmallScreen ? 16 : 24),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.slide.subtitle,
              textAlign: TextAlign.center,
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFFD4AF37), // Gold color
                fontSize: widget.isSmallScreen ? 16 : 18,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.slide.description,
              textAlign: TextAlign.center,
              style: ResponsiveTextStyles.textBase.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: widget.isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}