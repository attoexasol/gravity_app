# Gravity App - Comprehensive Project Analysis

## 📱 Project Overview

**Gravity** is a Flutter-based wellness and health tracking mobile application that integrates with health platforms (Apple Health, Google Health Connect) to sync user health data. The app provides features for goal setting, community engagement, AI coaching, meal tracking, and messaging.

### Key Characteristics
- **Platform**: Flutter (Dart)
- **State Management**: GetX
- **Backend API**: REST API at `https://gravity.attoexasolutions.com/api`
- **Authentication**: Firebase Auth with Google Sign-In and Apple Sign-In support
- **Storage**: GetStorage for local preferences
- **Health Integration**: Apple Health (iOS) and Google Health Connect (Android)
- **Target Platforms**: iOS, Android, Web, Windows, macOS, Linux

---

## 🏗️ Architecture Overview

### Architecture Pattern
The app follows a **layered architecture** with clear separation of concerns:

```
Presentation Layer (UI)
    ↓
Controllers (GetX - State Management)
    ↓
Repositories (Data Access)
    ↓
Services (API, Health, Storage)
    ↓
Models (Data Structures)
```

### Dependency Flow
```
ApiService (Singleton)
    ↓
Repositories (7 total)
    ↓
Controllers (11 total)
    ↓
Screens/Widgets
```

---

## 📂 Project Structure

```
lib/
├── app/                          # App configuration
│   ├── bindings/                 # GetX dependency injection
│   ├── routes/                   # Navigation routes
│   └── theme/                    # App theming (colors, text styles, etc.)
│
├── core/                         # Core services and utilities
│   ├── services/                 # Business logic services
│   │   ├── api_service.dart      # HTTP client wrapper
│   │   ├── preferences_service.dart  # Local storage
│   │   ├── google_auth_service.dart  # Google authentication
│   │   ├── health_sync_service.dart  # Health data sync
│   │   ├── meal_analysis_service.dart # Meal image analysis
│   │   └── network_info_service.dart  # Network connectivity
│   └── utils/                    # Utility functions
│       └── safe_logger.dart      # Debug logging helper
│
├── data/                         # Data layer
│   ├── model/                    # Data models (20 models)
│   └── repositories/             # API repositories (7 repositories)
│
└── presentation/                  # UI layer
    ├── aicoach/                  # AI Coach feature
    ├── coach_dashboard/          # Coach-specific dashboard
    ├── community/                 # Community/social features
    ├── consent/                  # User consent screens
    ├── dashboard/                # Main dashboard
    ├── goal_settings/            # Wellness goals configuration
    ├── login/                    # Authentication
    ├── main_layout/              # Main app layout with bottom nav
    ├── meal_upload/              # Meal photo upload
    ├── messages/                 # Messaging feature
    ├── onboarding/               # First-time user onboarding
    ├── settings/                 # App settings
    ├── signup/                   # User registration
    └── widgets/                  # Reusable widgets
```

---

## 🔑 Key Features

### 1. **Authentication & User Management**
- Email/Password authentication
- Google Sign-In (Firebase)
- Apple Sign-In
- User profile management
- Profile image upload

### 2. **Health Data Integration**
- **iOS**: Apple Health integration
- **Android**: Google Health Connect integration
- Syncs: Steps, Sleep, Weight, Hydration
- Manual data entry support
- Sync status tracking

### 3. **Dashboard & Progress Tracking**
- Progress rings for goals
- Health metrics visualization
- Sync status indicators
- User gravity entries tracking

### 4. **Wellness Goals**
- Goal setting and management
- Progress tracking
- Goal-based recommendations

### 5. **AI Coach**
- AI-powered coaching conversations
- Quick action suggestions
- Personalized wellness advice

### 6. **Community Features**
- Community posts
- Comments and replies
- Reactions (likes, etc.)
- Pinned posts
- User profiles

### 7. **Messaging**
- Direct messaging between users
- Message history
- User search

### 8. **Meal Tracking**
- Photo upload for meals
- AI-powered meal analysis (external API)
- Nutrition tracking

### 9. **Settings & Preferences**
- Account management
- Notification preferences
- Health integration settings
- Profile customization
- Account deletion

---

## 🗂️ Data Models (20 Models)

1. **ai_coach.dart** - AI coach conversation data
2. **api_response.dart** - Generic API response wrapper
3. **client_user.dart** - Client user information
4. **comment.dart** - Community post comments
5. **conversation.dart** - Message conversations
6. **health_permissions.dart** - Health permission status
7. **meal_analysis.dart** - Meal analysis results
8. **message.dart** - Individual messages
9. **navigation_item.dart** - Navigation menu items
10. **notification_log.dart** - Notification history
11. **notification_preferences.dart** - User notification settings
12. **onboarding_slide_model.dart** - Onboarding slide data
13. **post_user.dart** - Post author information
14. **post.dart** - Community posts
15. **reactions.dart** - Post reactions
16. **reply.dart** - Comment replies
17. **sync_log.dart** - Health sync history
18. **user_account_info.dart** - User account details
19. **user_gravity_entry.dart** - User health entries
20. **user_model.dart** - Core user model

---

## 🔌 Repositories (7 Repositories)

### 1. **AuthRepository**
- `createUser()` - User registration
- `login()` - User authentication
- `getUserProfile()` - Fetch user profile
- `getSingleUser()` - Get user by ID
- `logout()` - User logout
- `googleSignIn()` - Google OAuth
- `uploadProfileImage()` - Profile picture upload

### 2. **AiCoachRepository**
- `getAiCoachReply()` - Get AI coach responses

### 3. **MessagesRepository**
- `getSingleMessage()` - Get message by ID
- `getAllMessages()` - Get all messages for user
- `createMessage()` - Send new message
- `getAllUsers()` - Get user list for messaging
- `updateMessage()` - Edit message
- `deleteMessage()` - Delete message

### 4. **CommunityRepository**
- `getAllCommunities()` - List all communities
- `getSingleCommunity()` - Get community details
- `createCommunity()` - Create new community
- `updateCommunity()` - Update community
- `deleteCommunity()` - Delete community
- `getAllPosts()` - List all posts
- `getSinglePost()` - Get post details
- `createPost()` - Create new post
- `updatePost()` - Update post
- `deletePost()` - Delete post
- `createPostComment()` - Add comment
- `getAllPostComments()` - Get post comments
- `getSinglePostComment()` - Get comment details
- `updatePostComment()` - Update comment
- `deletePostComment()` - Delete comment
- `reactToPost()` - Add reaction to post
- `getUserWiseReact()` - Get user reactions
- `pinCommunityPost()` - Pin post
- `unpinCommunityPost()` - Unpin post
- `getUserWisePinnedPosts()` - Get user's pinned posts

### 5. **GoalsRepository**
- `createGoals()` - Create wellness goals
- `getSingleGoal()` - Get goal details

### 6. **ConsentRepository**
- `createConsent()` - Create user consent
- `getSingleConsent()` - Get consent details

### 7. **UserGravityRepository**
- `createUserGravity()` - Create health entry
- `updateUserGravity()` - Update health entry
- `getAllUserGravity()` - Get all user entries
- `getSingleUserGravity()` - Get entry by ID
- `deleteUserGravity()` - Delete entry
- `createManualUserGravity()` - Manual entry creation

---

## 🎮 Controllers (11 Controllers)

All controllers use GetX for state management and are registered in `initial_bindings.dart`:

1. **MainLayoutController** - Main app navigation and layout
2. **OnboardingController** - First-time user flow
3. **LoginController** - Authentication logic
4. **SignupController** - User registration
5. **ConsentController** - User consent management
6. **GoalSettingsController** - Wellness goals configuration
7. **DashboardController** - Dashboard data and health sync
8. **AiCoachController** - AI coach interactions
9. **MessagesController** - Messaging functionality
10. **SettingsController** - App settings and preferences
11. **MealUploadController** - Meal photo upload and analysis

---

## 🌐 API Integration

### Base Configuration
- **Base URL**: `https://gravity.attoexasolutions.com/api`
- **HTTP Client**: Singleton `ApiService` class
- **Timeout**: 60 seconds (default)
- **Headers**: JSON content type by default

### Authentication Methods
The API uses three different authentication patterns:

1. **Token in Request Body** (Most common)
   - Field: `api_token` or `token`
   - Used in: POST requests

2. **Token in Headers**
   - Format: `Authorization: Bearer {token}`
   - Used in: `/user/profile` endpoint

3. **Token in Query Parameters**
   - Field: `api_token`
   - Used in: GET requests (e.g., `/all_user_gravity`)

### Token Storage
- Stored via `PreferencesService` using GetStorage
- Key: `'auth_token'`
- Retrieved automatically for authenticated requests

### Total Endpoints
**40+ API endpoints** across 7 repositories

---

## 🔐 Authentication Flow

1. **Initial Check** (`main.dart`)
   - Checks for stored auth token
   - If token exists → Navigate to `/home`
   - If no token → Navigate to `/onboarding`

2. **Onboarding Flow**
   - First-time user introduction
   - Navigate to login/signup

3. **Login/Signup**
   - Email/Password or OAuth (Google/Apple)
   - Token stored in PreferencesService
   - Navigate to consent screen

4. **Consent**
   - User consent collection
   - Navigate to goal settings

5. **Goal Settings**
   - Wellness goals configuration
   - Navigate to main dashboard

6. **Main App**
   - Dashboard with bottom navigation
   - Tabs: Dashboard, Community, AI Coach, Messages, Coach Dashboard (if coach)

---

## 📱 Navigation Structure

### Routes (`app_routes.dart`)
- `/onboarding` - First-time user introduction
- `/login` - User login
- `/signup` - User registration
- `/consent` - User consent
- `/goal-settings` - Wellness goals
- `/home` - Main layout (dashboard with tabs)
- `/ai-coach` - AI coach screen
- `/meal-upload` - Meal photo upload
- `/settings` - App settings

### Main Layout Tabs (`main_layout_screen.dart`)
- **Tab 0**: Dashboard (Home)
- **Tab 1**: Community
- **Tab 2**: AI Coach (navigates to separate route)
- **Tab 3**: Messages
- **Tab 4**: Coach Dashboard (coach users only)

---

## 🎨 UI/UX Features

### Theme
- **Forced Light Mode**: App always uses light theme
- **Design Size**: 375x812 (iPhone X/11/12 Pro standard)
- **Screen Adaptation**: Flutter ScreenUtil for responsive design
- **Text Scaling**: Fixed at 1.0 to prevent layout breaks

### Key UI Components
- **MainAppBar** - Top navigation bar with user info
- **MainBottomNav** - Bottom navigation tabs
- **MainDrawer** - Side drawer menu
- **ProgressRing** - Circular progress indicators
- **SyncStatusSection** - Health sync status display

---

## 🔧 Core Services

### 1. **ApiService**
- Singleton HTTP client
- Handles POST and GET requests
- Error handling with `ApiException`
- Request/response logging (debug mode only)

### 2. **PreferencesService**
- Local storage using GetStorage
- Stores: auth token, user info, onboarding status
- Methods for save/get/clear operations

### 3. **HealthSyncService**
- Platform-specific health integration
- Syncs: Steps, Sleep, Weight, Hydration
- Permission management
- Sync status tracking

### 4. **GoogleAuthService**
- Google Sign-In integration
- Firebase authentication

### 5. **MealAnalysisService**
- External API for meal image analysis
- Multipart form data upload
- Nutrition information extraction

### 6. **NetworkInfoService**
- Network connectivity checking

---

## 📦 Dependencies

### State Management & Navigation
- `get: ^4.6.5` - GetX for state management and routing
- `get_storage: ^2.1.1` - Local storage

### UI & Design
- `flutter_screenutil: ^5.9.3` - Responsive design
- `flutter_svg: ^2.2.3` - SVG support
- `flutter_animate: ^4.5.2` - Animations
- `cached_network_image: ^3.4.1` - Image caching

### Networking
- `http: ^1.2.0` - HTTP client

### Authentication
- `firebase_core: ^3.6.0` - Firebase core
- `firebase_auth: ^5.3.1` - Firebase authentication
- `google_sign_in: ^6.2.1` - Google Sign-In
- `sign_in_with_apple: ^6.1.0` - Apple Sign-In

### Health Integration
- `health: ^12.0.0` - Health data access
- `permission_handler: ^11.3.0` - Permission management

### Media
- `image_picker: ^1.0.7` - Image selection
- `image_cropper: ^8.0.2` - Image cropping
- `image: ^4.1.7` - Image processing

### Utilities
- `intl: ^0.19.0` - Internationalization
- `path_provider: ^2.1.2` - File system paths
- `scrollable_positioned_list: ^0.3.8` - Scrollable lists

---

## 🔒 Permissions Required

### Android (`AndroidManifest.xml`)
- `INTERNET` - Network access
- `ACTIVITY_RECOGNITION` - Activity tracking
- `health.READ_STEPS` - Steps data
- `health.READ_WEIGHT` - Weight data
- `health.READ_HYDRATION` - Hydration data
- `health.READ_SLEEP` - Sleep data
- `ACCESS_COARSE_LOCATION` - Location (optional)
- `ACCESS_FINE_LOCATION` - Location (optional)
- `READ_EXTERNAL_STORAGE` - Image access (Android < 13)
- `READ_MEDIA_IMAGES` - Image access (Android 13+)
- `CAMERA` - Camera access

### iOS
- HealthKit permissions (configured in Info.plist)
- Camera and Photo Library access

---

## 🚀 App Initialization Flow

1. **WidgetsFlutterBinding.ensureInitialized()**
2. **Firebase.initializeApp()** (with error handling)
3. **PreferencesService.init()** - Initialize local storage
4. **SystemChrome.setPreferredOrientations()** - Lock to portrait
5. **ScreenUtilInit** - Initialize responsive design
6. **GetMaterialApp** - Initialize GetX app
7. **Route Decision** - Check auth token → Navigate accordingly

---

## 📊 Key Statistics

- **Total Models**: 20
- **Total Repositories**: 7
- **Total Controllers**: 11
- **Total API Endpoints**: 40+
- **Total Screens**: 10+
- **Supported Platforms**: iOS, Android, Web, Windows, macOS, Linux

---

## 🔍 Code Quality Features

### Logging
- **SafeLogger** utility for debug-only logging
- Prevents performance impact in production
- Methods: log, error, warning, info, success, debug

### Error Handling
- Custom `ApiException` class
- Try-catch blocks in repositories
- User-friendly error messages
- Graceful degradation

### State Management
- GetX reactive programming
- Lazy loading with `fenix: true` for auto-recreation
- Proper controller lifecycle management

---

## 🎯 User Roles

The app supports different user types:
- **Regular Users**: Standard features
- **Coach Users**: Additional coach dashboard tab
- Role stored in `PreferencesService` as `user_type`

---

## 📝 Notable Implementation Details

1. **Firebase Error Handling**: Comprehensive error messages for iOS setup
2. **Token Management**: Automatic token injection for authenticated requests
3. **Health Platform Detection**: Automatic detection of iOS/Android health platforms
4. **Image Handling**: Support for large image uploads with timeout adjustments
5. **Responsive Design**: ScreenUtil for consistent UI across devices
6. **Orientation Lock**: Portrait-only mode enforced
7. **Theme Consistency**: Forced light mode for uniform appearance

---

## 🔄 Data Flow Example

**User Login Flow:**
1. User enters credentials in `LoginScreen`
2. `LoginController.login()` called
3. `AuthRepository.login()` makes API call via `ApiService`
4. Token received and stored via `PreferencesService`
5. User data saved to local storage
6. Navigation to consent/goal settings
7. Finally to main dashboard

**Health Sync Flow:**
1. User grants health permissions
2. `HealthSyncService` requests data from platform
3. Data formatted and sent via `UserGravityRepository`
4. Sync status updated in `DashboardController`
5. UI reflects sync status in `SyncStatusSection`

---

## 🐛 Known Considerations

1. **Firebase Setup**: Requires proper configuration files (google-services.json, GoogleService-Info.plist)
2. **Health Permissions**: Platform-specific permission handling required
3. **Token Expiration**: No automatic token refresh mechanism visible
4. **Offline Support**: Limited offline functionality
5. **Error Recovery**: Some endpoints may need better error recovery

---

## 📚 Documentation Files

- `PROJECT_ANALYSIS.md` - Previous analysis (network calls, dependencies)
- `GOOGLE_SERVICES_SETUP.md` - Firebase setup instructions
- `README.md` - Basic project info (needs update)

---

## 🎓 Development Recommendations

1. **Add Unit Tests**: Currently minimal test coverage
2. **Add Integration Tests**: Test critical user flows
3. **Token Refresh**: Implement automatic token refresh
4. **Offline Support**: Add local caching and sync
5. **Error Analytics**: Integrate error tracking (e.g., Sentry)
6. **Performance Monitoring**: Add performance tracking
7. **Documentation**: Expand README with setup instructions
8. **Code Comments**: Add more inline documentation

---

## ✅ Summary

The **Gravity App** is a well-structured Flutter application with:
- ✅ Clean architecture with separation of concerns
- ✅ Comprehensive health data integration
- ✅ Social features (community, messaging)
- ✅ AI-powered coaching
- ✅ Robust authentication system
- ✅ Modern UI with responsive design
- ✅ Cross-platform support

The codebase follows Flutter best practices and uses GetX for efficient state management. The app is production-ready with proper error handling, logging, and user experience considerations.

