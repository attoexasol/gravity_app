import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gravityapp/presentation/onboarding/screens/sections/onboarding_slides.dart';
import '../../../app/theme/app_text_styles.dart';


import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 900;
    final isLargeScreen = size.width >= 900;
    final screenHeight = size.height;
    final isShortScreen = screenHeight < 700; // Detect short screens

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A2342), // Deep blue
              Color(0xFF00B8A9), // Teal
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Main Content - Slides (flexible)
                  Flexible(
                    flex: isShortScreen ? 2 : 3,
                    child: PageView.builder(
                      controller: controller.pageController,
                      onPageChanged: controller.onPageChanged,
                      itemCount: controller.slides.length,
                      itemBuilder: (context, index) {
                        return OnboardingSlide(
                          slide: controller.slides[index],
                          index: index,
                          isSmallScreen: isSmallScreen,
                          isMediumScreen: isMediumScreen,
                          isLargeScreen: isLargeScreen,
                          isShortScreen: isShortScreen,
                        );
                      },
                    ),
                  ),

                  // Bottom Section (scrollable to prevent overflow)
                  Flexible(
                    flex: isShortScreen ? 1 : 2,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight * 0.3,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 64 : (isMediumScreen ? 48 : 24),
                            vertical: isShortScreen 
                                ? (isSmallScreen ? 16 : 20)
                                : (isLargeScreen ? 48 : (isMediumScreen ? 40 : 32)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress Dots
                              Obx(() => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  controller.slides.length,
                                      (index) => _buildProgressDot(index),
                                ),
                              )),
                              SizedBox(height: isShortScreen 
                                  ? (isSmallScreen ? 12 : 16)
                                  : (isSmallScreen ? 24 : 32)),

                              // Get Started Button
                              Obx(() => _buildButton(isSmallScreen, isShortScreen)),

                              SizedBox(height: isShortScreen ? 12 : 16),

                              // Privacy Notice
                              Text(
                                'No data shared without your consent.',
                                textAlign: TextAlign.center,
                                style: ResponsiveTextStyles.textSm.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: isShortScreen ? 12 : null,
                                ),
                              ),

                              // Privacy & Data Control Section (only on last slide)
                              Obx(() => controller.isLastSlide 
                                  ? _buildPrivacySection(isSmallScreen, isShortScreen) 
                                  : const SizedBox.shrink()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    final isActive = index == controller.currentSlide.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isActive ? 32 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildButton(bool isSmallScreen, bool isShortScreen) {
    final buttonPadding = isShortScreen 
        ? (isSmallScreen ? 12.0 : 14.0)
        : 16.0;
    final fontSize = isShortScreen && isSmallScreen ? 14.0 : null;
    
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 448), // max-w-md
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: const Color(0xFFD4AF37), // Gold color
          borderRadius: BorderRadius.circular(24),
          elevation: 4,
          child: InkWell(
            onTap: controller.handleNext,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: buttonPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.buttonText,
                    style: ResponsiveTextStyles.textBase.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A2342),
                      fontSize: fontSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFF0A2342),
                    size: fontSize != null ? 18 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(bool isSmallScreen, bool isShortScreen) {
    final topPadding = isShortScreen ? 16.0 : 24.0;
    final spacing = isShortScreen ? 8.0 : 12.0;
    final fontSize = isShortScreen && isSmallScreen ? 12.0 : null;
    
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Title
          Text(
            'Privacy & Data Control',
            textAlign: TextAlign.center,
            style: ResponsiveTextStyles.textBase.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize != null ? fontSize + 2 : null,
            ),
          ),
          SizedBox(height: spacing),
          
          // Description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
            child: Text(
              'Your privacy matters. We ensure your data is encrypted, stored securely, and you have full control over your personal wellness information.',
              textAlign: TextAlign.center,
              style: ResponsiveTextStyles.textSm.copyWith(
                color: Colors.white.withOpacity(0.8),
                height: isShortScreen ? 1.3 : 1.4,
                fontSize: fontSize,
              ),
            ),
          ),
          SizedBox(height: spacing),
          
          // Learn More Link
          GestureDetector(
            onTap: () => controller.navigateToPrivacyDetails(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Learn more',
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFFD4AF37),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    fontSize: fontSize,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  color: const Color(0xFFD4AF37),
                  size: fontSize != null ? 14 : 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

