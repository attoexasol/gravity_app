import 'package:flutter/material.dart';
import 'package:gravityapp/data/model/onboarding_slide_model.dart';

import '../../../../app/theme/app_text_styles.dart';

class OnboardingSlide extends StatefulWidget {
  final OnboardingSlideModel slide;
  final int index;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final bool isLargeScreen;
  final bool isShortScreen;

  const OnboardingSlide({super.key, 
    required this.slide,
    required this.index,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.isLargeScreen,
    this.isShortScreen = false,
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
    // Adjust illustration size based on screen height
    double illustrationSize;
    if (widget.isShortScreen) {
      illustrationSize = widget.isSmallScreen ? 140.0 : (widget.isMediumScreen ? 180.0 : 200.0);
    } else {
      illustrationSize = widget.isLargeScreen
          ? 320.0
          : (widget.isMediumScreen ? 256.0 : (widget.isSmallScreen ? 192.0 : 224.0));
    }
    final innerCircleSize = illustrationSize * 0.75;
    final coreCircleSize = illustrationSize * 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isLargeScreen ? 64 : (widget.isMediumScreen ? 48 : 24),
                vertical: widget.isShortScreen ? 8 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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

                  SizedBox(height: widget.isShortScreen 
                      ? (widget.isSmallScreen ? 16 : 20)
                      : (widget.isLargeScreen ? 48 : (widget.isMediumScreen ? 40 : 32))),

                  // Title
                  Text(
                    widget.slide.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.isShortScreen
                          ? (widget.isSmallScreen ? 24 : 28)
                          : (widget.isLargeScreen
                              ? 48
                              : (widget.isMediumScreen ? 40 : (widget.isSmallScreen ? 30 : 36))),
                      fontWeight: FontWeight.bold,
                      height: widget.isShortScreen ? 1.1 : 1.2,
                    ),
                  ),

                  // Tagline - Only on first slide
                  if (widget.index == 0 && widget.slide.tagline != null) ...[
                    SizedBox(height: widget.isShortScreen 
                        ? (widget.isSmallScreen ? 8 : 12)
                        : (widget.isSmallScreen ? 16 : 24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: widget.isSmallScreen ? 8 : 16),
                      child: Text(
                        widget.slide.tagline!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: widget.isShortScreen 
                              ? (widget.isSmallScreen ? 14 : 16)
                              : (widget.isSmallScreen ? 18 : 20),
                          height: widget.isShortScreen ? 1.2 : 1.4,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: widget.isShortScreen 
                      ? (widget.isSmallScreen ? 8 : 12)
                      : (widget.isSmallScreen ? 16 : 24)),

                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.isSmallScreen ? 8 : 16),
                    child: Text(
                      widget.slide.subtitle,
                      textAlign: TextAlign.center,
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: const Color(0xFFD4AF37), // Gold color
                        fontSize: widget.isShortScreen 
                            ? (widget.isSmallScreen ? 14 : 16)
                            : (widget.isSmallScreen ? 16 : 18),
                      ),
                    ),
                  ),

                  SizedBox(height: widget.isShortScreen ? 12 : 16),

                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.isSmallScreen ? 16 : 24),
                    child: Text(
                      widget.slide.description,
                      textAlign: TextAlign.center,
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: widget.isShortScreen 
                            ? (widget.isSmallScreen ? 12 : 14)
                            : (widget.isSmallScreen ? 14 : 16),
                        height: widget.isShortScreen ? 1.3 : 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}