import 'package:get/get.dart';
import '../../presentation/aicoach/screens/ai_coach_screen.dart';
import '../../presentation/main_layout/screens/main_layout_screen.dart';
import '../../presentation/consent/screens/consent_screen.dart';
import '../../presentation/goal_settings/screens/goal_settings_screen.dart';
import '../../presentation/login/screens/login_screen.dart';
import '../../presentation/signup/screens/signup_screen.dart';
import '../../presentation/settings/screens/settings_page.dart';
import '../../presentation/meal_upload/screens/meal_upload_screen.dart';
import 'app_routes.dart';
import '../../presentation/onboarding/screens/onboarding_screen.dart';

class AppPages {
  AppPages._();

  static final routes = [
    // Onboarding
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Login
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Consent
    GetPage(
      name: AppRoutes.consent,
      page: () => const ConsentScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Goal Settings
    GetPage(
      name: AppRoutes.goalSettings,
      page: () => const GoalSettingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Main Layout (Home with tabs) - UPDATED
    GetPage(
      name: AppRoutes.home,
      page: () => const MainLayoutScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.aiCoach,
      page: () => const AiCoachScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Settings
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Meal Upload
    GetPage(
      name: AppRoutes.mealUpload,
      page: () => const MealUploadScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // TODO: Add additional routes as needed
    // Example - Notifications
    // GetPage(
    //   name: AppRoutes.notifications,
    //   page: () => const NotificationsScreen(),
    //   transition: Transition.rightToLeft,
    // ),
  ];
}
