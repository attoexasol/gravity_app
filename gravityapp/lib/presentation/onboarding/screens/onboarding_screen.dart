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
          child: Column(
            children: [
              // Main Content - Slides
              Expanded(
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
                    );
                  },
                ),
              ),

              // Bottom Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 64 : (isMediumScreen ? 48 : 24),
                  vertical: isLargeScreen ? 48 : (isMediumScreen ? 40 : 32),
                ),
                child: Column(
                  children: [
                    // Progress Dots
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        controller.slides.length,
                            (index) => _buildProgressDot(index),
                      ),
                    )),
                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Get Started Button
                    Obx(() => _buildButton()),

                    const SizedBox(height: 16),

                    // Privacy Notice
                    Text(
                      'No data shared without your consent.',
                      textAlign: TextAlign.center,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),

                    // Privacy & Data Control Section (only on last slide)
                    Obx(() => controller.isLastSlide ? _buildPrivacySection() : const SizedBox.shrink()),
                  ],
                ),
              ),
            ],
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

  Widget _buildButton() {
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.buttonText,
                    style: ResponsiveTextStyles.textBase.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A2342),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF0A2342),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          // Section Title
          Text(
            'Privacy & Data Control',
            textAlign: TextAlign.center,
            style: ResponsiveTextStyles.textBase.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your privacy matters. We ensure your data is encrypted, stored securely, and you have full control over your personal wellness information.',
              textAlign: TextAlign.center,
              style: ResponsiveTextStyles.textSm.copyWith(
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
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
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  color: const Color(0xFFD4AF37),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

