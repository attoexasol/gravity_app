import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app/bindings/initial_bindings.dart';
import 'app/theme/app_theme.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'core/services/preferences_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();

  // Initialize storage
  await PreferencesService.init();

  // Lock orientation to portrait for consistency
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Get initial route based on authentication state
  String _getInitialRoute() {
    // Check if user has a valid auth token
    final token = PreferencesService.getAuthToken();

    if (token != null && token.isNotEmpty) {
      // User is logged in, redirect to home/dashboard
      return AppRoutes.home;
    }

    // No token found, show onboarding
    return AppRoutes.onboarding;
  }

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil with design size
    // Design size should match your Figma/design dimensions
    // Standard: 375w x 812h (iPhone X/11/12 Pro)
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Gravity',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialBinding: InitialBinding(),
          initialRoute: _getInitialRoute(),
          getPages: AppPages.routes,
          debugShowCheckedModeBanner: false,
          builder: (context, widget) {
            // Ensure text scaling doesn't break layout
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: widget!,
            );
          },
        );
      },
    );
  }
}
