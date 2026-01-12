# Gravity App - Complete Project Analysis

## 📱 Project Overview

**Gravity** is a Flutter-based wellness and health tracking mobile application that integrates with health platforms (Apple Health, Google Health Connect) to sync user health data. The app provides features for goal setting, community engagement, AI coaching, meal tracking, messaging, and weight progress tracking.

### Key Characteristics
- **Platform**: Flutter (Dart SDK ^3.9.2)
- **State Management**: GetX (v4.6.5)
- **Backend API**: REST API at `https://gravity.attoexasolutions.com/api`
- **Authentication**: Firebase Auth with Google Sign-In and Apple Sign-In support
- **Storage**: GetStorage (v2.1.1) for local preferences
- **Health Integration**: Apple Health (iOS) and Google Health Connect (Android) via `health` package (v12.0.0)
- **Target Platforms**: iOS, Android, Web, Windows, macOS, Linux
- **Session-Based Auth**: Token cleared on app startup (users must log in each session)

---

## 🏗️ Architecture Overview

### Architecture Pattern: Layered Architecture

```
┌─────────────────────────────────────┐
│   Presentation Layer (UI/Screens)   │
│   - 83 Dart files in presentation/  │
│   - Screens, Widgets, Sections      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Controllers (GetX State Mgmt)    │
│   - 17 Controllers                  │
│   - Reactive state management      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Repositories (Data Access Layer)  │
│   - 8 Repositories                  │
│   - API communication abstraction   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Services (Business Logic)         │
│   - ApiService (Singleton)         │
│   - HealthSyncService               │
│   - PreferencesService              │
│   - GoogleAuthService               │
│   - MealAnalysisService             │
│   - NetworkInfoService              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Models (Data Structures)         │
│   - 25 Data Models                  │
└─────────────────────────────────────┘
```

### Dependency Injection Flow

```
ApiService (Singleton)
    ↓
Repositories (8 total)
    ├── AuthRepository
    ├── AiCoachRepository
    ├── MessagesRepository
    ├── CommunityRepository
    ├── GoalsRepository
    ├── ConsentRepository
    ├── UserGravityRepository
    └── DailySummaryRepository
    ↓
Controllers (17 total)
    ├── MainLayoutController
    ├── OnboardingController
    ├── LoginController
    ├── SignupController
    ├── ConsentController
    ├── GoalSettingsController
    ├── DashboardController
    ├── AiCoachController
    ├── MessagesController
    ├── SettingsController
    ├── MealUploadController
    ├── TodayController
    ├── WeeklyReviewController
    ├── DailyDetailsController
    ├── WeightHistoryController
    ├── CommunityController
    └── CoachDashboardController
    ↓
Screens/Widgets
```

---

## 📂 Project Structure

```
lib/
├── app/                          # App Configuration
│   ├── bindings/
│   │   └── initial_bindings.dart    # GetX dependency injection (11 controllers)
│   ├── routes/
│   │   ├── app_routes.dart          # Route constants (15+ routes)
│   │   └── app_pages.dart            # Route definitions with transitions
│   └── theme/
│       ├── app_colors.dart           # Color definitions
│       ├── app_gradients.dart        # Gradient definitions
│       ├── app_shadows.dart          # Shadow definitions
│       ├── app_text_styles.dart      # Responsive text styles
│       └── app_theme.dart            # Theme configuration (light mode only)
│
├── core/                         # Core Services & Utilities
│   ├── services/
│   │   ├── api_service.dart          # HTTP client (Singleton, baseUrl: gravity.attoexasolutions.com/api)
│   │   ├── preferences_service.dart  # Local storage (GetStorage wrapper)
│   │   ├── google_auth_service.dart  # Google authentication
│   │   ├── health_sync_service.dart  # Health data sync (Apple Health/Google Health)
│   │   ├── meal_analysis_service.dart # Meal image analysis (external API)
│   │   └── network_info_service.dart  # Network connectivity checking
│   └── utils/
│       └── safe_logger.dart          # Debug logging helper (kDebugMode only)
│
├── data/                         # Data Layer
│   ├── model/                    # Data Models (25 files)
│   │   ├── ai_coach.dart
│   │   ├── api_response.dart
│   │   ├── client_user.dart
│   │   ├── comment.dart
│   │   ├── conversation.dart
│   │   ├── daily_details.dart
│   │   ├── health_permissions.dart
│   │   ├── meal_analysis.dart
│   │   ├── message.dart
│   │   ├── navigation_item.dart
│   │   ├── notification_log.dart
│   │   ├── notification_preferences.dart
│   │   ├── onboarding_slide_model.dart
│   │   ├── post_user.dart
│   │   ├── post.dart
│   │   ├── reactions.dart
│   │   ├── reply.dart
│   │   ├── sync_log.dart
│   │   ├── today_screen.dart
│   │   ├── trend_data.dart
│   │   ├── user_account_info.dart
│   │   ├── user_gravity_entry.dart
│   │   ├── user_model.dart
│   │   ├── weekly_review.dart
│   │   └── weight_history.dart
│   └── repositories/             # API Repositories (8 files)
│       ├── ai_coach_repository.dart
│       ├── auth_repository.dart
│       ├── community_repository.dart
│       ├── consent_repository.dart
│       ├── daily_summary_repository.dart
│       ├── goals_repository.dart
│       ├── messages_repository.dart
│       └── user_gravity_repository.dart
│
└── presentation/                # Presentation Layer (83 files)
    ├── aicoach/
    │   ├── controllers/
    │   └── screens/
    ├── coach_dashboard/
    ├── community/
    ├── consent/
    ├── daily_details/
    ├── dashboard/
    ├── goal_settings/
    ├── login/
    ├── main_layout/
    ├── meal_upload/
    ├── messages/
    ├── onboarding/
    ├── settings/
    ├── signup/
    ├── today_views/
    ├── weekly_review/
    ├── weight_history/
    └── widgets/
        ├── bottom_nav.dart
        ├── main_app_bar.dart
        ├── main_bottom_nav.dart
        ├── main_drawer.dart
        └── progress_ring.dart
```

---

## 🔑 Key Components

### 1. Main Entry Point (`lib/main.dart`)

**Features:**
- Firebase initialization with error handling
- Session-based authentication (token cleared on startup)
- Portrait-only orientation lock (mobile only)
- ScreenUtil initialization (design size: 375x812)
- Light theme only (forced)
- Text scaling disabled (prevents layout breaks)

**Key Initialization:**
```dart
- Firebase.initializeApp()
- PreferencesService.init()
- PreferencesService.clearAuthToken() // Session-based auth
- SystemChrome.setPreferredOrientations([portrait])
```

### 2. API Service (`lib/core/services/api_service.dart`)

**Pattern:** Singleton
**Base URL:** `https://gravity.attoexasolutions.com/api`

**Methods:**
- `post(String endpoint, {body, headers, timeout})` - POST requests with 60s default timeout
- `get(String endpoint, {headers})` - GET requests
- Response handling with JSON parsing
- Error handling and logging

**Features:**
- Automatic JSON encoding/decoding
- Large data detection (truncates logging)
- Custom timeout support
- Default headers (Content-Type, Accept, User-Agent)

### 3. Controllers (17 Total)

All controllers extend `GetxController` and are registered in `initial_bindings.dart`:

| Controller | Fenix Mode | Purpose |
|------------|------------|---------|
| MainLayoutController | ✅ | Main app layout with bottom navigation |
| OnboardingController | ✅ | Onboarding flow |
| LoginController | ✅ | User authentication |
| SignupController | ✅ | User registration |
| ConsentController | ✅ | Health data consent |
| GoalSettingsController | ✅ | Goal configuration |
| DashboardController | ✅ | Main dashboard |
| AiCoachController | ❌ | AI coaching chat |
| MessagesController | ✅ | Messaging system |
| SettingsController | ✅ | User settings |
| MealUploadController | ✅ | Meal photo upload |
| TodayController | ✅ | Daily summary view |
| WeeklyReviewController | ✅ | Weekly progress review |
| DailyDetailsController | ✅ | Detailed daily view |
| WeightHistoryController | ✅ | Weight tracking history |
| CommunityController | ✅ | Community feed |
| CoachDashboardController | ✅ | Coach dashboard |

**Note:** `fenix: true` allows controllers to be recreated after disposal, useful for navigation.

### 4. Repositories (8 Total)

**Pattern:** Repository pattern for API abstraction

| Repository | Endpoints | Purpose |
|------------|-----------|---------|
| AuthRepository | 7 | Authentication, user profile, Google sign-in |
| AiCoachRepository | 1 | AI coach interactions |
| MessagesRepository | 6 | Messaging system |
| CommunityRepository | 15+ | Community posts, comments, reactions |
| GoalsRepository | 2 | User goals management |
| ConsentRepository | 2 | Health data consent |
| UserGravityRepository | 5 | Weight/gravity entries |
| DailySummaryRepository | ? | Daily summary data |

### 5. Routes (15+ Routes)

**Navigation:** GetX routing with custom transitions

| Route | Screen | Transition |
|-------|--------|------------|
| `/onboarding` | OnboardingScreen | Fade |
| `/login` | LoginScreen | RightToLeft |
| `/signup` | SignupScreen | RightToLeft |
| `/consent` | ConsentScreen | RightToLeft |
| `/goal-settings` | GoalSettingsScreen | RightToLeft |
| `/home` | MainLayoutScreen | FadeIn |
| `/ai-coach` | AiCoachScreen | RightToLeft |
| `/settings` | SettingsPage | RightToLeft |
| `/meal-upload` | MealUploadScreen | RightToLeft |
| `/daily-summary` | TodayScreen | RightToLeft |
| `/weekly-review` | WeeklyReviewScreen | RightToLeft |
| `/daily-details` | DailyDetailsScreen | RightToLeft |
| `/weight-history` | WeightHistoryScreen | RightToLeft |

---

## 📦 Dependencies

### Core Dependencies

```yaml
# State Management
get: ^4.6.5                    # GetX (state management, routing, DI)

# Storage
get_storage: ^2.1.1            # Local key-value storage

# UI/UX
flutter_screenutil: ^5.9.3     # Responsive design
flutter_svg: ^2.2.3             # SVG support
flutter_animate: ^4.5.2         # Animations
cached_network_image: ^3.4.1    # Image caching

# Networking
http: ^1.2.0                    # HTTP client

# Firebase
firebase_core: ^3.6.0           # Firebase core
firebase_auth: ^5.3.1           # Firebase authentication
google_sign_in: ^6.2.1          # Google Sign-In
sign_in_with_apple: ^6.1.0      # Apple Sign-In

# Health Integration
health: ^12.0.0                 # Health data sync (Apple Health/Google Health)
permission_handler: ^11.3.0     # Permission management

# Media
image_picker: ^1.0.7            # Image selection
image_cropper: ^8.0.2           # Image cropping
image: ^4.1.7                   # Image processing

# Utilities
intl: ^0.19.0                   # Internationalization
path_provider: ^2.1.2           # File system paths
scrollable_positioned_list: ^0.3.8  # Scrollable lists
fl_chart: ^0.68.0               # Charts (used in weight history)
```

### Dev Dependencies

```yaml
flutter_test: sdk: flutter
flutter_lints: ^5.0.0           # Linting rules
```

---

## 🎯 Features

### 1. Authentication
- Email/password login
- Google Sign-In
- Apple Sign-In
- Session-based authentication (token cleared on app restart)
- User profile management

### 2. Health Integration
- Apple Health sync (iOS)
- Google Health Connect sync (Android)
- Permission handling
- Health data sync service

### 3. Weight Tracking
- Weight history with charts (fl_chart)
- Progress visualization
- Goal weight tracking
- Trend analysis

### 4. AI Coaching
- AI-powered coaching chat
- Conversation management
- Quick actions

### 5. Community
- Community feed
- Posts and comments
- Reactions (likes, etc.)
- Pinned posts
- User interactions

### 6. Messaging
- Direct messaging
- Conversation management
- Message CRUD operations
- User search

### 7. Meal Tracking
- Meal photo upload
- Image cropping
- External meal analysis API
- Meal logging

### 8. Daily/Weekly Views
- Today screen (daily summary)
- Weekly review
- Daily details
- Progress tracking

### 9. Settings
- Profile management
- Notification preferences
- Account deletion
- Profile image upload

### 10. Goal Management
- Goal creation
- Goal tracking
- Goal settings screen

---

## 🔐 Authentication & Security

### Session-Based Authentication

**Implementation:**
- Token cleared on app startup (`main.dart`)
- Token stored in GetStorage via `PreferencesService`
- Token passed in request body (most endpoints) or headers (some endpoints)

**Token Storage:**
```dart
PreferencesService.saveAuthToken(token)
PreferencesService.getAuthToken()
PreferencesService.clearAuthToken()
```

### Token Passing Methods

1. **Request Body (POST):** `api_token` or `token` field
2. **Headers (GET/POST):** `Authorization: Bearer {token}`
3. **Query Parameter (GET):** `?api_token={token}`

### Endpoints Not Requiring Auth
- `/user/create` (signup)
- `/user/login` (login)
- `/auth/google` (Google sign-in)
- `/all_communities` (public)
- `/all_posts` (public)

---

## 📊 Code Quality Observations

### ✅ Strengths

1. **Clear Architecture:** Well-organized layered architecture
2. **Separation of Concerns:** Clear separation between UI, business logic, and data
3. **Repository Pattern:** Good abstraction of API calls
4. **GetX Integration:** Proper use of GetX for state management and routing
5. **Responsive Design:** ScreenUtil for responsive layouts
6. **Error Handling:** Firebase initialization with error handling
7. **Safe Logging:** SafeLogger utility for debug-only logging
8. **Code Organization:** Feature-based folder structure

### ⚠️ Areas for Improvement

1. **Commented Code:** Large commented-out code block in `progress_chart_section.dart` (lines 269-481)
2. **Hardcoded Values:** Some hardcoded colors and values (e.g., `Color(0xFF0A2342)`)
3. **Error Handling:** Some repositories may need more comprehensive error handling
4. **Testing:** No visible test files (only default `widget_test.dart`)
5. **Documentation:** Limited inline documentation
6. **API Service:** Still uses `debugPrint` instead of `SafeLogger` in some places
7. **Token Management:** Inconsistent token field names (`api_token` vs `token`)

### 🔍 Code Issues Found

1. **progress_chart_section.dart:**
   - Large commented-out code block (213 lines) should be removed
   - Could be cleaned up

2. **api_service.dart:**
   - Uses `debugPrint` instead of `SafeLogger` (inconsistent with other files)

3. **Missing Tests:**
   - No unit tests for repositories
   - No widget tests for screens
   - No integration tests

---

## 🚀 Potential Improvements

### 1. Code Cleanup
- Remove commented-out code in `progress_chart_section.dart`
- Standardize token field names across all endpoints
- Replace remaining `debugPrint` calls with `SafeLogger`

### 2. Testing
- Add unit tests for repositories
- Add widget tests for key screens
- Add integration tests for critical flows

### 3. Error Handling
- Implement consistent error handling across all repositories
- Add user-friendly error messages
- Implement retry logic for network failures

### 4. Documentation
- Add inline documentation for complex methods
- Document API endpoints and their requirements
- Add README with setup instructions

### 5. Performance
- Implement image caching strategy
- Optimize chart rendering for large datasets
- Add pagination for lists (community, messages)

### 6. Security
- Implement token refresh mechanism
- Add certificate pinning for production
- Encrypt sensitive data in local storage

### 7. Accessibility
- Add semantic labels
- Improve screen reader support
- Add accessibility testing

---

## 📈 Statistics

- **Total Dart Files:** 100+ files
- **Controllers:** 17
- **Repositories:** 8
- **Models:** 25
- **Services:** 6
- **Routes:** 15+
- **API Endpoints:** 40+
- **Screens:** 15+
- **Widgets:** 5+ reusable widgets

---

## 🔄 Development Workflow

### State Management Flow
```
User Action → Screen → Controller → Repository → ApiService → Backend
                ↓
            Update UI (Reactive)
```

### Navigation Flow
```
Onboarding → Login/Signup → Consent → Goal Settings → Main Layout
                                                          ↓
                                    Today / Weekly / Details / Weight History / AI Coach / Messages / Settings
```

---

## 📝 Notes

1. **Session-Based Auth:** The app implements session-based authentication where tokens are cleared on app startup. This means users must log in every time they open the app.

2. **Theme:** The app forces light theme only, even in dark mode.

3. **Orientation:** Portrait-only on mobile devices.

4. **Responsive Design:** Uses ScreenUtil with design size 375x812 (iPhone X/11/12 Pro standard).

5. **Health Integration:** Supports both Apple Health (iOS) and Google Health Connect (Android).

6. **Chart Library:** Uses `fl_chart` for weight progress visualization.

---

## 🎨 UI/UX Features

- Responsive text styles (`ResponsiveTextStyles`)
- Custom color scheme (`app_colors.dart`)
- Gradient support (`app_gradients.dart`)
- Shadow definitions (`app_shadows.dart`)
- Smooth page transitions (GetX transitions)
- Bottom navigation (main layout)
- Drawer navigation
- Custom app bar

---

## 📱 Platform Support

- ✅ iOS (with Firebase, Apple Health, Apple Sign-In)
- ✅ Android (with Firebase, Google Health Connect, Google Sign-In)
- ✅ Web (with Firebase)
- ✅ Windows
- ✅ macOS
- ✅ Linux

---

## 🔗 External Services

1. **Backend API:** `https://gravity.attoexasolutions.com/api`
2. **Firebase:** Authentication and backend services
3. **Meal Analysis API:** External service for meal image analysis
4. **Apple Health:** iOS health data
5. **Google Health Connect:** Android health data

---

## 📄 Additional Documentation Files

The project includes several analysis documents:
- `PROJECT_ANALYSIS.md` - Network calls and dependency graph
- `PROJECT_ANALYSIS_DETAILED.md` - Detailed architecture analysis
- `PROJECT_ANALYSIS_COMPREHENSIVE.md` - Comprehensive overview
- `SESSION_BASED_AUTH_IMPLEMENTATION.md` - Auth implementation details
- `GOOGLE_SERVICES_SETUP.md` - Firebase setup guide
- `WEB_DEPLOYMENT_GUIDE.md` - Web deployment instructions

---

**Last Updated:** Based on current codebase analysis
**Flutter Version:** SDK ^3.9.2
**Project Status:** Active Development

