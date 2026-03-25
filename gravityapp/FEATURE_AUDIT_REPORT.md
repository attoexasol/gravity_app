# Gravity App – Feature Audit Report

**Date:** March 6, 2025  
**Scope:** Full Flutter codebase (UI, routes, controllers, services, repositories, models, API, Firebase, storage, notifications, auth, settings, and business modules).  
**Method:** Evidence-based analysis; no code written or modified.

---

## 1. Project Overview

**Gravity** is a Flutter wellness and health-tracking app with:

- **Stack:** Flutter (Dart ^3.9.2), GetX (state management), REST API at `https://gravity.attoexasolutions.com/api`, Firebase (Auth, Firestore, Messaging, Storage, Analytics in pubspec).
- **Auth:** Laravel API (email/password, Google); Firebase custom token for chat; TokenManager + refresh; session/device handling.
- **Storage:** GetStorage (preferences, onboarding, auth legacy), Firestore (chat, user presence).
- **Health:** Apple Health / Google Health Connect via `health` package; sync and dashboard integration.
- **Roles:** Customer and Coach; Coach sees Coach Dashboard and different bottom nav; messaging is role-based (customer ↔ coach).

**Findings summary:**

- **Implemented:** Most of auth, onboarding, consent, goals, dashboard, today, weekly review, daily details, weight history, meal upload, AI coach, community (posts/comments/reactions), messaging (Firestore), notifications (in-app + push), settings (profile image, goals, notification prefs, logout), API layer with retry/refresh, error handling.
- **Partially implemented:** Consent (data deletion not backed by API), Coach Dashboard (UI only, mock data), Apple Sign-In (TODO/mock), dedicated Profile/Edit Profile screens (missing; profile only in Settings), localization (intl for dates only).
- **Not implemented:** Splash screen, Payment/Subscription flow, Firebase Analytics usage, dedicated Profile/Edit Profile routes usage, multi-language localization.

---

## 2. Implemented Features

### Module: Splash / Onboarding

- **Feature Name:** Onboarding flow  
- **Status:** Implemented  
- **Evidence Found:**  
  - `lib/presentation/onboarding/screens/onboarding_screen.dart`, `lib/presentation/onboarding/controllers/onboarding_controller.dart`  
  - `OnboardingSlideModel`, slides list, PageController, `completeOnboarding()` calling `PreferencesService.setOnboardingCompleted(true)` and `Get.offAllNamed('/login')`  
  - `main.dart` `_getInitialRoute()`: if not authenticated and onboarding not completed → `AppRoutes.onboarding`  
  - Route: `AppPages` GetPage for `AppRoutes.onboarding`  
- **Reasoning:** UI, state, persistence (GetStorage), and navigation (first launch → onboarding → login) are all in place.

### Module: Authentication

- **Feature Name:** Email/password login  
- **Status:** Implemented  
- **Evidence Found:**  
  - `LoginController.handleLogin()` → `AuthRepository.login()` (POST `/user/login` with device info)  
  - Token save (TokenManager + PreferencesService), session init (SessionManager), Firebase custom token sign-in and Firestore user sync, FCM sync, profile image fetch (`getSingleUser`), consent/goals check, navigation to Goal Settings or Home  
  - `lib/presentation/auth/screens/login_screen.dart`, validation (`validateEmail`, `validatePassword`), error display  
- **Reasoning:** End-to-end: UI, validation, API, token/session persistence, Firebase/FCM, and post-login navigation.

- **Feature Name:** Sign up (email/password)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `SignupController.handleSignup()` → `AuthRepository.createUser()` (POST `/user/create` with name, email, phone, password, role)  
  - Validation, error parsing for email/phone taken, `PreferencesService.setOnboardingCompleted(true)`, success state; user must log in separately (no auto-login)  
  - `lib/presentation/signup/screens/signup_screen.dart`  
- **Reasoning:** Registration with API and validation is complete; post-signup flow is “success message then user goes to login” (by design).

- **Feature Name:** Google Sign-In (login and signup)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `GoogleAuthService.signInWithGoogle(role)` → Laravel `/auth/google` with `firebase_token` and device info; token and user saved; Firebase custom token + Firestore sync; `PushTokenSyncService().syncTokenAfterLogin()`  
  - Login: `LoginController.handleGoogleLogin()`; Signup: `SignupController.handleGoogleSignup()` with `_checkUserDataAndNavigate(token)` (goals check → Goal Settings or Home)  
- **Reasoning:** Backend auth, token storage, Firebase/Firestore, and FCM are wired; role (Coach/Customer) is sent and stored.

- **Feature Name:** Forgot password (send OTP)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `ForgotPasswordController.handleForgotPassword()` → `AuthRepository.sendOtp(email)` (POST `/send-email-otp`)  
  - Email validation, success → `Get.toNamed(AppRoutes.otpVerification, parameters: {'email': email})`  
  - `lib/presentation/auth/screens/forgot_password_screen.dart`, route and binding in `AppPages`  
- **Reasoning:** UI, API, validation, and navigation to OTP screen are implemented.

- **Feature Name:** OTP verification  
- **Status:** Implemented  
- **Evidence Found:**  
  - `OtpVerificationController.handleVerifyOtp()` → `AuthRepository.verifyOtp(email, otp)` (POST `/verify-email-otp`)  
  - Resend OTP with 60s countdown, validation (6 digits), success → `Get.toNamed(AppRoutes.resetPassword, parameters: {'email': email.value})`  
  - `lib/presentation/auth/screens/otp_verification_screen.dart`  
- **Reasoning:** Full flow: API, validation, resend, and navigation to reset password.

- **Feature Name:** Reset password  
- **Status:** Implemented  
- **Evidence Found:**  
  - `ResetPasswordController.handleResetPassword()` → `AuthRepository.resetPassword()` (POST `/forget-password` with email, password, password_confirmation)  
  - Email from route params, password/confirm validation, success → `Get.offAllNamed(AppRoutes.login)`  
  - `lib/presentation/auth/screens/reset_password_screen.dart`  
- **Reasoning:** API and UI flow are complete.

- **Feature Name:** Logout  
- **Status:** Implemented  
- **Evidence Found:**  
  - `AuthRepository.logout()`: POST `/user/logout` with refresh_token, `AuthService().signOutAndSetOffline()`, `TokenManager().clearTokens()`, `PreferencesService.clearAuthToken()`, `SessionManager().clearSession()`  
  - `MainLayoutController.handleLogout()` (and drawer) calls repository and `Get.offAllNamed(AppRoutes.login)`  
- **Reasoning:** Backend logout, Firebase sign-out, Firestore offline, and local clear are all implemented.

- **Feature Name:** Persistent auth and initial route  
- **Status:** Implemented  
- **Evidence Found:**  
  - `main.dart` `_getInitialRoute()`: `PreferencesService.isAuthenticated()` (TokenManager + legacy token) → home; else onboarding completed → login; else onboarding  
  - TokenManager stores access/refresh; ApiService uses TokenManager for Bearer and refresh on 401  
- **Reasoning:** Session persists across restarts; initial route matches auth and onboarding state.

- **Feature Name:** 401 handling and token refresh  
- **Status:** Implemented  
- **Evidence Found:**  
  - `ApiService._executeWithRetryInternal`: on 401, `AuthErrorHandler.handle401Error()` (token expired vs session/device invalid); refresh via `_refreshTokenIfNeeded()` (TokenManager), retry once; else force logout  
  - `AuthErrorHandler`: tokenExpired → let ApiService refresh; tokenInvalidated/sessionExpired/deviceMismatch → forced logout and clear (image cache, etc.)  
- **Reasoning:** Centralized 401 handling, refresh, and forced logout are in place.

### Module: Consent

- **Feature Name:** Consent toggles and continue to app  
- **Status:** Implemented  
- **Evidence Found:**  
  - `ConsentController`: aiFeatures, dataPreferences observables; `continueToApp()` → `ConsentRepository.createConsent()` (API) and local save (`PreferencesService.getStorage().write('ai_features_consent'`, etc.), then `Get.back()`  
  - `lib/presentation/consent/screens/consent_screen.dart`, route in AppPages  
- **Reasoning:** API and local persistence for consent are implemented; navigation back is correct.

### Module: Goal Settings

- **Feature Name:** Goal settings (weight, steps, water, sleep, AI tone) and save  
- **Status:** Implemented  
- **Evidence Found:**  
  - `GoalSettingsController`: currentWeight, targetWeight, stepGoal, waterIntake, sleepHours, selectedAiTone; `GoalsRepository.createGoals()` (POST `/goals/create`) and `getSingleGoal()` (POST `/get_single_goal`)  
  - On save: API create, local `userGoals` and `PreferencesService.saveStartingWeight()`, `setFirstTimeSetupCompleted(true)`, `Get.offAllNamed(AppRoutes.home)`  
  - `lib/presentation/goal_settings/screens/goal_settings_screen.dart`  
- **Reasoning:** Form, validation, API, and local persistence are wired; post-login/signup goals check uses same API.

### Module: Dashboard / Home

- **Feature Name:** Main layout and tab navigation  
- **Status:** Implemented  
- **Evidence Found:**  
  - `MainLayoutScreen`: body by `currentIndex` (0 Dashboard, 1 Community, 2 AI Coach, 3 Messages, 4 Coach Dashboard for coach)  
  - `MainLayoutController.navigateToTab()`, `MainBottomNav`, `MainDrawer`, `MainAppBar` (notifications, settings)  
  - Role from `PreferencesService.getUserType()`; Coach sees 5th tab (Coach Dashboard)  
- **Reasoning:** Tabs, role-based UI, drawer, and app bar are implemented.

- **Feature Name:** Dashboard (health metrics, sync, gravity upsert)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `DashboardController`: `HealthSyncService` stream (steps, sleep, weight, hydration), `UserGravityRepository.upsertTodayGravity()` on sync success, `FastMealService` for fasting ring  
  - Goals from storage, periodic sync timer, lifecycle observer for resume sync  
  - `lib/presentation/dashboard/screens/dashboard_view.dart`, `SyncStatusSection`  
- **Reasoning:** Health sync, persistence to backend via UserGravity, and UI are connected.

### Module: Today (Daily Summary)

- **Feature Name:** Today screen (date-wise gravity, reflection, nutrition, pillars)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `TodayController`: `UserGravityRepository` (`fetchDateWiseGravity`, `getDateWiseGravity`), `GoalsRepository`, `AiCoachRepository` (nutrition); `submitReflection()`, weigh-in modal and log  
  - `lib/presentation/today_views/screens/today_screen.dart`, sections (pillar status, weight journey, reflection, etc.)  
  - Route: `AppRoutes.dailySummary` → `TodayScreen`  
- **Reasoning:** API-driven date-wise data, reflection, and weight entry are implemented.

### Module: Weekly Review

- **Feature Name:** Weekly review (week picker, goal completion)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `WeeklyReviewController`: `UserGravityRepository.getWeekGoalCompletion()` (or equivalent), `_generateWeekOptions()`, `_fetchWeeklyData()`  
  - `lib/presentation/weekly_review/screens/weekly_review_screen.dart`, sections (summary, consistency grid, patterns, etc.)  
- **Reasoning:** Week selection and API-backed weekly data are in place.

### Module: Daily Details

- **Feature Name:** Daily details (day activity, reflection by date)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `DailyDetailsController`: `UserGravityRepository.getDayActivity()`, `getDailyReflectionByDate()`, `selectedDate` navigation  
  - `lib/presentation/daily_details/screens/daily_details_screen.dart`  
  - Route with parameter `from` (dashboard/weekly-review)  
- **Reasoning:** Day-level API and UI are implemented.

### Module: Weight History

- **Feature Name:** Weight history (list, chart, stats)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `WeightHistoryController`: `UserGravityRepository` for weight history API, `_weightHistory` observable, `startingWeight`/`goalWeight` from storage, computed (totalLoss, remaining, weeklyAverage)  
  - `lib/presentation/weight_history/screens/weight_history_screen.dart`, progress chart, recent entries  
- **Reasoning:** Data from repository and UI are connected.

### Module: Meal Upload

- **Feature Name:** Meal photo analysis  
- **Status:** Implemented  
- **Evidence Found:**  
  - `MealUploadController`: `MealAnalysisService.analyzeMeal()` (image + optional details), `ImagePicker` (camera/gallery), usage limits and `showLimitWarning`  
  - `lib/presentation/meal_upload/screens/meal_upload_screen.dart`  
- **Reasoning:** Image capture, analysis service, and limits are implemented.

### Module: AI Coach

- **Feature Name:** AI Coach chat (history, send text/image)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `AiCoachController`: `AiCoachRepository` (send message, fetch history), `_fetchChatHistoryFromServer()`, quick actions, image picker, message list  
  - `lib/presentation/aicoach/screens/ai_coach_screen.dart`  
- **Reasoning:** Server-backed chat history and send flow are implemented.

### Module: Community

- **Feature Name:** Community feed (posts, create, delete, reactions, comments)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `CommunityController`: `CommunityRepository.getAllPosts()`, `createPost()`, `deletePost()`, `reactToPost()`, `createPostComment()`, `deletePostComment()`, `allPostComments`, etc.  
  - `lib/presentation/community/screens/community_page.dart`, `PostCard`, create post UI, comment/reply UI  
- **Reasoning:** CRUD for posts, reactions, and comments with API is implemented.

### Module: Messages / Chat

- **Feature Name:** Real-time chat (Firestore)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `FirestoreChatService`: users collection, conversations subcollection, messages subcollection; `sendMessage`, `streamMessages`, `conversationStream`, `updateUserProfile`, `setUserOffline`, typing, presence  
  - `MessagesController` / `MessagesControllers`: conversation list (Laravel + Firestore), role-based (customer sees coaches, coach sees customers)  
  - `ChatController`: Firestore message stream, send, ensureUserDoc  
  - `lib/presentation/messages/screens/messages_page.dart`, `chat_screen.dart`  
- **Reasoning:** Firestore structure, real-time streams, and role-based inbox are implemented.

### Module: Notifications

- **Feature Name:** In-app notifications (list, unread, mark read, preferences)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `NotificationsController`: `NotificationsApi.listNotifications()`, `unreadCount()`, `markRead()`, `markAllRead()`, `clearAll()`, `getPreferences()`, `updatePreferences()`  
  - `lib/presentation/notifications/screens/notifications_screen.dart`, `NotificationCard`, pagination and load more  
- **Reasoning:** List, pagination, mark read, clear, and preferences are wired to API.

- **Feature Name:** Push notifications (FCM)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `PushTokenSyncService`: `init()` registers `onTokenRefresh`, `onMessage`, `onMessageOpenedApp`; foreground shows local notification; tap → Notifications or Community (post_reaction with post_id)  
  - `main.dart`: `_firebaseMessagingBackgroundHandler`, `PushTokenSyncService().init()`  
  - After login: `PushTokenSyncService().syncTokenAfterLogin()` (permission, get token, `NotificationsApi.storeDeviceToken`)  
- **Reasoning:** Token upload, foreground handling, and tap routing are implemented.

### Module: Settings

- **Feature Name:** Settings (user info, profile image, goals, notifications, health, logout)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `SettingsController`: `AuthRepository.getSingleUser()`, `uploadProfileImage()` (multipart), notification prefs (NotificationsApi), goals (GoalsRepository), HealthSyncService permissions, sync logs, notification logs, logout  
  - `lib/presentation/settings/screens/settings_page.dart`, profile image picker modal, wellness goals section, health integration  
- **Reasoning:** User data, profile image upload, notification settings, goals, and logout are implemented.

### Module: API and Backend

- **Feature Name:** REST API layer (auth, retry, refresh)  
- **Status:** Implemented  
- **Evidence Found:**  
  - `ApiService`: baseUrl, GET/POST with `_getHeaders()` (Bearer from TokenManager), `_executeWithRetry` on 401, `_refreshTokenIfNeeded()`, `_handleResponse()`, `ApiException`  
  - Repositories use ApiService for all endpoints  
- **Reasoning:** Single HTTP layer with auth and refresh is implemented.

### Module: Local Storage

- **Feature Name:** Preferences and auth persistence  
- **Status:** Implemented  
- **Evidence Found:**  
  - `PreferencesService`: GetStorage for onboarding, firstTimeSetup, auth_token (legacy), user name/email/id/type, profile image URL/path, starting weight, userGoals  
  - `TokenManager`: access/refresh token storage (separate from legacy key)  
- **Reasoning:** Critical flags and user data are persisted.

### Module: Role-based access

- **Feature Name:** Customer vs Coach UI and messaging  
- **Status:** Implemented  
- **Evidence Found:**  
  - `MainLayoutController.userType` from PreferencesService; `MainBottomNav`/`MainDrawer` show Coach tab/label for coach  
  - `MessagesController`/conversation list: customer loads coaches, coach loads customers via API role filter  
- **Reasoning:** Role is stored and used for nav and messaging list.

---

## 3. Partially Implemented Features

### Module: Splash / Onboarding

- **Feature Name:** Splash screen  
- **Status:** Partially Implemented  
- **Evidence Found:**  
  - `AppRoutes.splash = '/splash'` in `app_routes.dart`  
  - No `GetPage` for `splash` in `app_pages.dart`; no splash widget or controller; `_getInitialRoute()` never returns splash  
- **Reasoning:** Route constant exists but no screen or navigation; effectively not implemented. Marked “Partially” only because the route name exists.  
- **What’s missing:** A splash widget, optional delay, and either initial route splash or explicit navigate from main.  
- **Suggestion:** Add a GetPage for splash; show a splash widget (logo/branding); after delay or init, navigate to `_getInitialRoute()` (or keep current initial route and remove splash constant if not needed).

### Module: Authentication

- **Feature Name:** Apple Sign-In  
- **Status:** Partially Implemented  
- **Evidence Found:**  
  - `LoginController.handleAppleLogin()`: `TODO: Implement Apple Sign-In`, `Future.delayed` then success snackbar (mock)  
  - `sign_in_with_apple` in pubspec  
- **Reasoning:** UI entry exists but no real Apple Auth or backend call.  
- **What’s missing:** Apple ID credential flow, backend endpoint (e.g. `/auth/apple`) similar to Google, token and user save, Firebase custom token if needed.  
- **Suggestion:** Implement Apple sign-in in a service (like GoogleAuthService), call backend with Apple token/identity, then reuse same token/Firebase/session flow as Google; add same to signup if desired.

### Module: Consent

- **Feature Name:** Data deletion request  
- **Status:** Partially Implemented  
- **Evidence Found:**  
  - `ConsentController.confirmDataDeletion()`: TODO “Implement actual data deletion API call”; shows snackbar “You will receive a confirmation email within 24 hours” and closes modal  
- **Reasoning:** UI and flow exist; no API or backend integration.  
- **What’s missing:** Backend endpoint (e.g. POST `/user/request-deletion` or `/consent/delete-data`) and optional logout/navigation.  
- **Suggestion:** Add repository method for deletion request; call it from controller; optionally log out and redirect to login after success.

### Module: Coach Dashboard

- **Feature Name:** Coach dashboard (client list, summary cards)  
- **Status:** Partially Implemented  
- **Evidence Found:**  
  - `CoachDashboardController._loadUsers()`: hardcoded list of `ClientUser` (no API)  
  - `CoachDashboardScreen`: header, summary cards (high/medium/low compliance), client list  
  - Coach tab in main layout and navigation work  
- **Reasoning:** UI and role-based tab are done; data is mock.  
- **What’s missing:** API to fetch coach’s clients (e.g. compliance, today score, alerts).  
- **Suggestion:** Add a Coach or Clients API (e.g. GET `/coach/clients` or `/users/coach-clients`), repository method, and load in `CoachDashboardController`; replace mock list with API response.

### Module: User profile

- **Feature Name:** Dedicated Profile and Edit Profile screens  
- **Status:** Partially Implemented  
- **Evidence Found:**  
  - `AppRoutes.profile = '/profile'`, `AppRoutes.editProfile = '/edit-profile'`  
  - No GetPage for profile or editProfile in `app_pages.dart`; no navigation to these routes in codebase  
  - Profile editing exists inside Settings: name/email display, profile image picker and upload  
- **Reasoning:** Profile data and photo are editable in Settings; dedicated profile/edit profile routes are unused.  
- **What’s missing:** Screens and routes for `/profile` and `/edit-profile` if product requires them.  
- **Suggestion:** If a separate profile screen is required, add GetPages and screens that either reuse Settings user/preferences or fetch via AuthRepository; otherwise remove unused route constants.

### Module: Localization

- **Feature Name:** Multi-language / localization  
- **Status:** Partially Implemented  
- **Evidence Found:**  
  - `intl` package used for date/number formatting (e.g. `DateFormat`, `NumberFormat`) in multiple screens  
  - No `flutter_localizations`, no `Get.locale`/translations, no ARB or locale switching  
- **Reasoning:** Only formatting is “localized”; no actual multi-language support.  
- **What’s missing:** Translation files, locale list, and UI to switch language.  
- **Suggestion:** Add `flutter_localizations` and a translation approach (e.g. GetX translations or `gen-l10n`), then wrap app and add a language selector (e.g. in Settings).

---

## 4. Not Implemented Features

### Module: Splash

- **Feature Name:** Splash screen (visible screen)  
- **Status:** Not Implemented  
- **Evidence Found:** No splash widget; no GetPage for splash; initial route is onboarding, login, or home  
- **Reasoning:** No splash UI or flow.  
- **Implementation approach:** Create a SplashScreen widget (e.g. logo, loading indicator); add GetPage for `AppRoutes.splash`; either set splash as initialRoute and after init navigate to `_getInitialRoute()`, or keep current initial route and add splash only where needed (e.g. after app open).  
- **Where to add:** e.g. `lib/presentation/splash/screens/splash_screen.dart`, and in `app_pages.dart`.

### Module: Payments

- **Feature Name:** Payment gateway / subscriptions / purchases  
- **Status:** Not Implemented  
- **Evidence Found:**  
  - `NotificationType.payment` and payment-style notification card in notifications (display only)  
  - No Stripe, in_app_purchase, or payment repository/service  
- **Reasoning:** Only notification type exists; no payment or subscription flow.  
- **Implementation approach:** Define product (one-time vs subscription); add backend payment provider (Stripe/RevenueCat/etc.); add in-app purchase or checkout flow; optional subscription status API and UI.  
- **Where to add:** New module e.g. `lib/presentation/subscription/` or `lib/core/services/payment_service.dart`; backend requirements: payment provider integration and user subscription state.

### Module: Analytics

- **Feature Name:** Firebase Analytics (or app analytics)  
- **Status:** Not Implemented  
- **Evidence Found:** `firebase_analytics` in pubspec; no `FirebaseAnalytics.instance.logEvent()` or screen tracking in lib  
- **Reasoning:** Package present but unused.  
- **Implementation approach:** Initialize Firebase Analytics; log key events (login, screen views, goal save, etc.) and optional user properties; consider privacy and consent.  
- **Where to add:** Central service (e.g. `analytics_service.dart`) and call from controllers/screens; ensure consent/permissions if required.

### Module: Dedicated Profile routes

- **Feature Name:** Navigation to Profile / Edit Profile routes  
- **Status:** Not Implemented  
- **Evidence Found:** Profile and editProfile route constants exist; no GetPage and no `Get.toNamed(AppRoutes.profile)` (or editProfile) anywhere  
- **Reasoning:** Routes are dead; all profile editing is in Settings.  
- **Implementation approach:** Either add Profile and Edit Profile screens and GetPages and link from drawer/settings, or remove the unused route constants to avoid confusion.

---

## 5. Missing Integrations

- **Payments:** No SDK or API integration for payments/subscriptions; backend must expose subscription state and payment endpoints if needed.  
- **Firebase Analytics:** Not used; no event or screen logging.  
- **Apple Sign-In:** Not integrated with backend or Firebase.  
- **Data deletion:** No API call for “delete my data” from consent flow.  
- **Coach clients API:** No backend endpoint used for coach dashboard; mock data only.  
- **Splash:** No visual splash screen or delay before first route.

---

## 6. Risky / Incomplete Areas

- **Coach Dashboard:** Fully mock data; coaches see fake client list and metrics until a real API is added.  
- **Apple Sign-In:** Mock success can confuse users; implement or hide the button until ready.  
- **Data deletion:** User expects a real request; current message is misleading without backend.  
- **Profile/Edit Profile routes:** Unused constants can cause confusion or future bugs if someone navigates to them.  
- **Token/refresh:** Logic is sound but depends on backend returning correct 401 body and refresh endpoint; any change in API contract could break auth.  
- **Health sync:** Depends on platform permissions and Health Connect/Apple Health availability; failures are handled but edge cases (e.g. permission denied forever) may need clearer UX.

---

## 7. Suggested Next Priority to Complete

1. **Coach Dashboard API:** Add backend endpoint for coach clients and wire `CoachDashboardController` so coach tab shows real data.  
2. **Apple Sign-In:** Implement or remove; if keeping, add backend and token flow.  
3. **Data deletion:** Add backend “request data deletion” and call from ConsentController.  
4. **Splash (if required):** Add splash screen and route, or remove splash route constant.  
5. **Firebase Analytics:** Add minimal event/screen logging for key flows.  
6. **Profile routes:** Either implement Profile/Edit Profile screens or remove unused route constants.

---

## 8. Plain-English Test Cases for Implemented Features

### Onboarding

- **Functional:** Launch app first time → onboarding slides show; “Next” moves to next slide; on last slide “Get Started” marks onboarding complete and navigates to Login.  
- **User flow:** Complete all slides → land on Login; skip (if available) → same as Get Started.  
- **Edge:** Open app again after completion → no onboarding; go directly to Login or Home if already logged in.  
- **Negative:** Force onboarding completed = false and no token → onboarding shows again.

### Login (email/password)

- **Functional:** Enter valid email and password → loading → success snackbar and navigate to Home or Goal Settings (if no goals).  
- **User flow:** From login, tap Forgot Password → enter email → OTP screen; from login, tap Sign up → signup screen.  
- **Edge:** Already has goals in backend → Home; missing goals → Goal Settings.  
- **Negative:** Wrong password → error message; empty email/password → validation messages; invalid email format → validation.

### Forgot password → OTP → Reset password

- **Functional:** Forgot password → valid email → “OTP sent” and navigate to OTP screen; enter correct OTP → reset password screen; enter new password and confirm → success and navigate to Login.  
- **User flow:** On OTP screen, resend OTP → countdown and new OTP sent; after reset, log in with new password.  
- **Edge:** Invalid or expired OTP → error message; wrong email on forgot → API error message.  
- **Negative:** Passwords don’t match on reset → validation; short password → validation.

### Dashboard and health sync

- **Functional:** Open dashboard as logged-in user → health metrics (steps, sleep, weight, hydration) appear when permissions granted; sync status updates; after sync success, data is sent to backend (gravity upsert).  
- **User flow:** Change day or resume app → periodic sync runs; open Today or Weekly Review → data consistent with dashboard.  
- **Edge:** No health permissions → appropriate message or zeros; Health not available (e.g. emulator) → no crash.  
- **Negative:** Backend error on upsert → user sees error or retry; network off → graceful handling.

### Today screen

- **Functional:** Open Today → date-wise gravity and pillars load; submit reflection → saved; open weigh-in modal and log weight → saved and reflected in weight journey.  
- **User flow:** Navigate to Daily Details from dashboard or weekly review → correct date and activity/reflection.  
- **Edge:** No data for date → empty or defaults; nutrition from AI coach → displayed if implemented.  
- **Negative:** Invalid or empty reflection submit → validation or error; API failure → message to user.

### Weekly review

- **Functional:** Open Weekly Review → current week loads; change week in picker → data for that week loads; summary and consistency grid reflect API data.  
- **User flow:** Tap “View daily details” → Daily Details for selected day.  
- **Edge:** No data for week → empty state.  
- **Negative:** API error → error state or message.

### Weight history

- **Functional:** Open Weight History → list and chart show entries from API; starting/goal weight from storage; total loss and remaining computed correctly.  
- **User flow:** Add weight on Today or elsewhere → weight history updates when re-opened or refreshed.  
- **Edge:** No entries → empty state; single entry → chart still sensible.  
- **Negative:** API failure → error message.

### Community

- **Functional:** Open Community → feed loads (getAllPosts); create post (text/optional image) → appears in feed; tap reaction → count updates (reactToPost); add comment/reply → visible (createPostComment); delete own post → removed (deletePost).  
- **User flow:** Open a post → comments load; reply to comment → reply visible; delete comment if allowed.  
- **Edge:** Empty feed → empty state; long list → pagination or load more if implemented.  
- **Negative:** Create post without auth → error; delete others’ post → forbidden or error; API error → message.

### Messages

- **Functional:** Open Messages → conversation list (role-based: customer sees coaches, coach sees customers); tap conversation → Chat screen; send message → appears in Firestore and in list preview.  
- **User flow:** Real-time: other user’s message appears without refresh; typing/presence if shown.  
- **Edge:** No conversations → empty state; first message creates conversation.  
- **Negative:** No Firebase token (e.g. login without custom token) → chat may not work; offline → Firestore persistence or error handling.

### Notifications

- **Functional:** Open Notifications → list and unread count from API; tap item → mark read; “Mark all read” → all read; “Clear all” → list cleared (and API if supported).  
- **User flow:** Change preferences in settings → saved via API; receive push → foreground notification or in-app update; tap push → open Notifications or Community (post_reaction).  
- **Edge:** No notifications → empty list; pagination → load more.  
- **Negative:** No token → “sign in to load”; API error → error message.

### Settings

- **Functional:** Open Settings → user name/email and profile image from API/storage; tap profile image → picker modal; take/choose photo → upload and show new image; change goals → save to API and storage; change notification toggles → API update; logout → API + Firebase + local clear and navigate to Login.  
- **User flow:** After changing goals, open Dashboard/Today → new goals reflected.  
- **Edge:** No profile image → placeholder; upload failure → error.  
- **Negative:** Logout with network failure → local clear and redirect anyway; invalid image → validation or error.

### Goal settings

- **Functional:** First-time user (no goals in backend) → after login/signup lands on Goal Settings; fill form and save → API create, local write, navigate to Home.  
- **User flow:** Return to Goal Settings from Settings → load current goals from API/storage; save → update.  
- **Edge:** Validation (e.g. target weight vs current) → message.  
- **Negative:** API failure → error; invalid numbers → validation.

### Auth persistence and 401

- **Functional:** Close app and reopen (with valid token) → Home without login; token refresh on 401 → request retried; refresh failure or session/device invalid → logout and redirect to Login.  
- **User flow:** Use app normally → no unnecessary logouts when refresh works.  
- **Edge:** Multiple 401s in parallel → single refresh and retry.  
- **Negative:** Expired refresh token → logout; device mismatch from backend → forced logout.

---

## 9. Implementation Suggestions for Missing Features (no code)

- **Splash:** Add a single splash screen widget and route; on open, show for a short fixed time or until init (e.g. Firebase, storage) completes, then navigate to current initial route logic.  
- **Payments:** Choose provider and backend design (subscription vs one-time); implement backend endpoints and webhook; in app add purchase or checkout flow and subscription status checks; surface status in UI (e.g. premium features or paywall).  
- **Analytics:** Create an analytics service that calls Firebase Analytics (or other) for login, signup, screen views, and key actions; call from controllers/screens; respect user consent if applicable.  
- **Apple Sign-In:** Mirror Google flow: get Apple credential, send to backend (e.g. `/auth/apple`), receive token and user; save token and sync Firebase/FCM; use same post-login/signup navigation as Google.  
- **Data deletion:** Backend: endpoint to record deletion request (and optionally trigger async job); app: call from ConsentController and show confirmation; optionally log out after.  
- **Coach dashboard:** Backend: endpoint returning coach’s clients and metrics; app: repository method and controller to replace mock list; handle loading and error states.  
- **Profile/Edit Profile:** Either add two screens and routes that show/edit name, email, photo (reusing AuthRepository and upload), or remove profile/editProfile route constants and document that profile is under Settings.  
- **Localization:** Add locale resolution and translation files (e.g. ARB + gen-l10n or GetX); set locale in GetMaterialApp; add language selector in Settings and persist choice; use translations for all user-facing strings.

---

## 10. Summary Table

| Feature Name | Status | Confidence | Evidence Reference |
|-------------|--------|------------|--------------------|
| Onboarding flow | Implemented | High | OnboardingController, PreferencesService, main.dart initial route, AppPages |
| Email/password login | Implemented | High | LoginController, AuthRepository.login, token/session, Firebase, FCM |
| Email/password signup | Implemented | High | SignupController, AuthRepository.createUser, validation |
| Google Sign-In (login/signup) | Implemented | High | GoogleAuthService, LoginController, SignupController, backend + Firebase |
| Forgot password (OTP) | Implemented | High | ForgotPasswordController, AuthRepository.sendOtp, AppPages |
| OTP verification | Implemented | High | OtpVerificationController, AuthRepository.verifyOtp, resend, navigation |
| Reset password | Implemented | High | ResetPasswordController, AuthRepository.resetPassword, navigation |
| Logout | Implemented | High | AuthRepository.logout, AuthService, TokenManager, SessionManager |
| Persistent auth / initial route | Implemented | High | main.dart _getInitialRoute, PreferencesService, TokenManager |
| 401 handling / token refresh | Implemented | High | ApiService _executeWithRetry, AuthErrorHandler, TokenManager |
| Consent (toggles + continue) | Implemented | High | ConsentController, ConsentRepository.createConsent, local save |
| Data deletion request | Partially Implemented | High | ConsentController TODO, snackbar only |
| Goal settings | Implemented | High | GoalSettingsController, GoalsRepository, createGoals, getSingleGoal |
| Main layout / tabs | Implemented | High | MainLayoutScreen, MainLayoutController, MainBottomNav, userType |
| Dashboard (health + gravity) | Implemented | High | DashboardController, HealthSyncService, UserGravityRepository |
| Today screen | Implemented | High | TodayController, UserGravityRepository date-wise, reflection, nutrition |
| Weekly review | Implemented | High | WeeklyReviewController, UserGravityRepository week API |
| Daily details | Implemented | High | DailyDetailsController, getDayActivity, getDailyReflectionByDate |
| Weight history | Implemented | High | WeightHistoryController, UserGravityRepository, chart, list |
| Meal upload / analysis | Implemented | High | MealUploadController, MealAnalysisService, ImagePicker |
| AI Coach chat | Implemented | High | AiCoachController, AiCoachRepository, history, send, quick actions |
| Community (posts, comments, reactions) | Implemented | High | CommunityController, CommunityRepository CRUD + reactions |
| Messages (Firestore chat) | Implemented | High | FirestoreChatService, ChatController, MessagesController |
| In-app notifications | Implemented | High | NotificationsController, NotificationsApi list, mark read, prefs |
| Push notifications (FCM) | Implemented | High | PushTokenSyncService, token sync, foreground, tap routing |
| Settings (profile image, goals, logout) | Implemented | High | SettingsController, AuthRepository, NotificationsApi, GoalsRepository |
| API layer (retry, refresh) | Implemented | High | ApiService, TokenManager, AuthErrorHandler |
| Local storage (preferences) | Implemented | High | PreferencesService, TokenManager, GetStorage |
| Role-based (Customer/Coach) | Implemented | High | MainLayoutController userType, MessagesController role filter |
| Splash screen (visible) | Not Implemented | High | No GetPage, no splash widget; route constant only |
| Apple Sign-In | Partially Implemented | High | handleAppleLogin TODO, mock success |
| Coach dashboard (data) | Partially Implemented | High | CoachDashboardController mock list, no API |
| Profile / Edit Profile screens | Partially Implemented | High | Routes exist, no GetPage or navigation; profile in Settings |
| Multi-language localization | Partially Implemented | High | intl for formatting only; no translations |
| Payment / subscription | Not Implemented | High | Notification type only; no payment SDK/API |
| Firebase Analytics | Not Implemented | High | Package in pubspec; no logEvent in lib |

---

*End of Feature Audit Report. No code was written or modified; analysis and documentation only.*
