import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:gravityapp/data/model/onboarding_slide_model.dart';
import '../../../core/services/preferences_service.dart';

class OnboardingController extends GetxController {
  // Observable for current slide index
  final RxInt currentSlide = 0.obs;

  // Page controller for PageView
  late PageController pageController;

  // Slides data
  final List<OnboardingSlideModel> slides = [
    OnboardingSlideModel(
      title: "Welcome to Gravity",
      subtitle: "Improve your health with smarter insights",
      description: "Track your meals, sleep, and activity with AI-powered analysis",
      tagline: "Designed for real people balancing work, wellness, and life wherever you are.",
      gradientColors: const [Color(0xFF5EEAD4), Color(0xFF14B8A6)],
    ),
    OnboardingSlideModel(
      title: "Smart Meal Analysis",
      subtitle: "Snap a photo, get instant nutrition insights",
      description: "Our AI analyzes your meals and provides personalized recommendations",
      gradientColors: const [Color(0xFFFBBF24), Color(0xFFD97706)],
    ),
    OnboardingSlideModel(
      title: "Complete Wellness Tracking",
      subtitle: "Monitor sleep, hydration, and daily activity",
      description: "Get a complete picture of your health journey",
      gradientColors: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  /// Update current slide index
  void onPageChanged(int index) {
    currentSlide.value = index;
  }

  /// Navigate to next slide or complete onboarding
  Future<void> handleNext() async {
    if (currentSlide.value < slides.length - 1) {
      // Go to next slide
      pageController.animateToPage(
        currentSlide.value + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      await completeOnboarding();
    }
  }

  /// Complete onboarding and navigate to main app
  Future<void> completeOnboarding() async {
    // Save onboarding completion status to local storage
    await PreferencesService.setOnboardingCompleted(true);

    // Navigate to login screen
    Get.offAllNamed('/login');
  }

  /// Skip onboarding
  Future<void> skipOnboarding() async {
    await completeOnboarding();
  }

  /// Get button text based on current slide
  String get buttonText {
    return currentSlide.value == slides.length - 1 ? 'Get Started' : 'Next';
  }

  /// Check if current slide is the last one
  bool get isLastSlide {
    return currentSlide.value == slides.length - 1;
  }

  /// Navigate to Privacy & Data Control screen (consent screen)
  void navigateToPrivacyDetails() {
    Get.toNamed('/consent');
  }
}
