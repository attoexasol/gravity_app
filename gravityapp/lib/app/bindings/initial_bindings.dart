import 'package:get/get.dart';
import '../../presentation/aicoach/controllers/ai_coach_controller.dart';
import '../../presentation/main_layout/controllers/main_layout_controller.dart';
import '../../presentation/consent/controllers/consent_controller.dart';
import '../../presentation/goal_settings/controllers/goal_settings_controller.dart';
import '../../presentation/login/controllers/login_controller.dart';
import '../../presentation/messages/controllers/messages_controllers.dart';
import '../../presentation/onboarding/controllers/onboarding_controller.dart';
import '../../presentation/dashboard/controllers/dashboard_controller.dart';
import '../../presentation/signup/controllers/signup_controller.dart';
import '../../presentation/settings/controllers/settings_controller.dart';
import '../../presentation/meal_upload/controllers/meal_upload_controller.dart';

/// InitialBinding - Common binding for all controllers
/// This binding initializes all controllers that need to be available app-wide
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Main Layout Controller
    Get.lazyPut<MainLayoutController>(
      () => MainLayoutController(),
      fenix: true, // Recreate when needed after disposal
    );

    // Onboarding Controller
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(),
      fenix: true,
    );

    // Login Controller - UPDATED WITH FENIX
    Get.lazyPut<LoginController>(
      () => LoginController(),
      fenix: true, // This ensures controller is recreated after disposal
    );

    // Signup Controller - UPDATED WITH FENIX
    Get.lazyPut<SignupController>(() => SignupController(), fenix: true);

    // Consent Controller
    Get.lazyPut<ConsentController>(() => ConsentController(), fenix: true);

    // Goal Settings Controller
    Get.lazyPut<GoalSettingsController>(
      () => GoalSettingsController(),
      fenix: true,
    );

    // Dashboard Controller
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);

    // AI Coach Controller
    Get.lazyPut<AiCoachController>(() => AiCoachController(), fenix: false);

    // Messages Controller
    Get.lazyPut<MessagesController>(() => MessagesController(), fenix: true);

    // Settings Controller
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);

    // Meal Upload Controller
    Get.lazyPut<MealUploadController>(
      () => MealUploadController(),
      fenix: true,
    );
  }
}
