import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;
import 'app/bindings/initial_bindings.dart';
import 'app/theme/app_theme.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'core/services/preferences_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    // Check if running on iOS and verify GoogleService-Info.plist exists
    if (Platform.isIOS) {
      debugPrint('🔍 Checking Firebase configuration for iOS...');
      // Firebase.initializeApp() should automatically find GoogleService-Info.plist
      // if it's properly added to the Xcode project
    }
    
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    if (Platform.isIOS) {
      debugPrint('');
      debugPrint('📱 iOS Firebase Setup Checklist:');
      debugPrint('   1. Verify GoogleService-Info.plist exists in ios/Runner/');
      debugPrint('   2. Open Xcode and ensure GoogleService-Info.plist is added to the Runner target');
      debugPrint('   3. Check that the file is included in "Copy Bundle Resources" build phase');
      debugPrint('   4. Verify the Bundle ID matches: com.attoexa.gravityapp');
      debugPrint('');
    } else {
      debugPrint('   This may happen if google-services.json (Android) is missing.');
    }
    debugPrint('   The app will continue to run, but Firebase features (like Google Sign-In) may not work.');
    // Continue app initialization even if Firebase fails
  }

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
          darkTheme: AppTheme.lightTheme, // Force light theme even in dark mode
          themeMode: ThemeMode.light, // Always use light mode
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
