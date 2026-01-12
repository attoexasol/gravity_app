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
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    // Check if running on iOS and verify GoogleService-Info.plist exists
    if (!kIsWeb && Platform.isIOS) {
      debugPrint('🔍 Checking Firebase configuration for iOS...');
      // Firebase.initializeApp() should automatically find GoogleService-Info.plist
      // if it's properly added to the Xcode project
    }
    
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    if (!kIsWeb && Platform.isIOS) {
      debugPrint('');
      debugPrint('📱 iOS Firebase Setup Checklist:');
      debugPrint('   1. Verify GoogleService-Info.plist exists in ios/Runner/');
      debugPrint('   2. Open Xcode and ensure GoogleService-Info.plist is added to the Runner target');
      debugPrint('   3. Check that the file is included in "Copy Bundle Resources" build phase');
      debugPrint('   4. Verify the Bundle ID matches: com.attoexa.gravityapp');
      debugPrint('');
    } else if (!kIsWeb) {
      debugPrint('   This may happen if google-services.json (Android) is missing.');
    } else {
      debugPrint('   For web, ensure Firebase is properly configured in your web app.');
    }
    debugPrint('   The app will continue to run, but Firebase features (like Google Sign-In) may not work.');
    // Continue app initialization even if Firebase fails
  }

  // Initialize storage
  await PreferencesService.init();

  // SESSION-BASED AUTHENTICATION: Clear token on app startup
  // This ensures users must log in again every time the app is opened
  await PreferencesService.clearAuthToken();
  await PreferencesService.clearUserData();
  debugPrint('🔒 Session-based auth: Token cleared on app startup');

  // Lock orientation to portrait for consistency (not applicable on web)
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to detect when app goes to background
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Optional: Log lifecycle changes for debugging
    // Note: We don't clear token here because clearing on background
    // would log users out when they just switch apps temporarily.
    // Token is cleared on app startup (in main()) which is more reliable.
    if (kDebugMode) {
      debugPrint('📱 App lifecycle state changed: $state');
    }
  }

  /// Get initial route based on authentication and onboarding state
  /// Note: With session-based auth, token is cleared on startup
  /// Onboarding should only be shown once - on first launch
  String _getInitialRoute() {
    // Check if onboarding has been completed
    final isOnboardingCompleted = PreferencesService.isOnboardingCompleted();
    
    if (isOnboardingCompleted) {
      // Onboarding completed - navigate directly to login
      return AppRoutes.login;
    } else {
      // First time user - show onboarding
      return AppRoutes.onboarding;
    }
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
