import 'package:get/get.dart';
import '../../presentation/aicoach/screens/ai_coach_screen.dart';
import '../../presentation/main_layout/screens/main_layout_screen.dart';
import '../../presentation/consent/screens/consent_screen.dart';
import '../../presentation/goal_settings/screens/goal_settings_screen.dart';
import '../../presentation/login/screens/login_screen.dart';
import '../../presentation/signup/screens/signup_screen.dart';
import '../../presentation/settings/screens/settings_page.dart';
import '../../presentation/meal_upload/screens/meal_upload_screen.dart';
import '../../presentation/today_views/screens/today_screen.dart';
import '../../presentation/today_views/controllers/today_controller.dart';
import '../../presentation/weekly_review/screens/weekly_review_screen.dart';
import '../../presentation/weekly_review/controllers/weekly_review_controller.dart';
import '../../presentation/daily_details/screens/daily_details_screen.dart';
import '../../presentation/daily_details/controllers/daily_details_controller.dart';
import '../../presentation/weight_history/screens/weight_history_screen.dart';
import '../../presentation/weight_history/controllers/weight_history_controller.dart';
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

    // Today Screen (Daily Summary)
    GetPage(
      name: AppRoutes.dailySummary,
      page: () => const TodayScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TodayController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Weekly Review
    GetPage(
      name: AppRoutes.weeklyReview,
      page: () => const WeeklyReviewScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WeeklyReviewController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Daily Details
    GetPage(
      name: AppRoutes.dailyDetails,
      page: () => const DailyDetailsScreen(),
      binding: BindingsBuilder(() {
        final fromScreen = Get.parameters['from'] ?? 'dashboard';
        Get.lazyPut(() => DailyDetailsController(fromScreen: fromScreen));
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Weight History
    GetPage(
      name: AppRoutes.weightHistory,
      page: () => const WeightHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WeightHistoryController());
      }),
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
