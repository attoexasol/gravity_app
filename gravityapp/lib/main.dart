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
import 'core/services/app_lifecycle_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase must initialize first (before GetStorage/PreferencesService or any Firebase-dependent code).
  //    Android: requires android/app/google-services.json
  //    iOS: requires ios/Runner/GoogleService-Info.plist added to Xcode Runner target.
  try {
    if (!kIsWeb && Platform.isIOS) {
      debugPrint('🔍 Checking Firebase configuration for iOS...');
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

  // 2. Initialize storage (GetStorage) after Firebase
  await PreferencesService.init();

  // PERSISTENT AUTHENTICATION: Token persists across app sessions
  // Users remain logged in until they explicitly log out
  debugPrint('🔐 Persistent auth: Checking authentication state on app startup');

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
    AppLifecycleService().updateState(state);
    if (kDebugMode) {
      debugPrint('📱 App lifecycle state changed: $state');
    }
  }

  /// Get initial route based on authentication and onboarding state
  /// Flow:
  /// - First launch: Onboarding → Login → Home
  /// - User logged in (token exists): Home (skip onboarding and login)
  /// - User logged out (no token) but onboarding completed: Login
  /// - First time user (onboarding not completed): Onboarding
  String _getInitialRoute() {
    // Check if user is authenticated (has valid token)
    final isAuthenticated = PreferencesService.isAuthenticated();
    final token = PreferencesService.getAuthToken();
    
    // Check onboarding status
    final isOnboardingCompleted = PreferencesService.isOnboardingCompleted();
    
    if (kDebugMode) {
      debugPrint('🔍 Initial Route Decision:');
      debugPrint('   - Has Token: ${token != null && token.isNotEmpty}');
      debugPrint('   - Token Value: ${token != null ? (token.isEmpty ? "empty" : "${token.substring(0, token.length > 10 ? 10 : token.length)}...") : "null"}');
      debugPrint('   - Is Authenticated: $isAuthenticated');
      debugPrint('   - Onboarding Completed: $isOnboardingCompleted');
    }
    
    // If authenticated, go directly to home
    if (isAuthenticated) {
      if (kDebugMode) {
        debugPrint('✅ User is authenticated → Navigating to Home');
      }
      return AppRoutes.home;
    }
    
    // Not authenticated - check onboarding status
    if (isOnboardingCompleted) {
      // Onboarding completed but not logged in - navigate to login
      if (kDebugMode) {
        debugPrint('📝 Onboarding completed but not authenticated → Navigating to Login');
      }
      return AppRoutes.login;
    } else {
      // First time user - show onboarding
      if (kDebugMode) {
        debugPrint('🆕 First time user → Navigating to Onboarding');
      }
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
