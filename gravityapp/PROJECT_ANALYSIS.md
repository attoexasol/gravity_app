# Flutter Project Analysis

## 1. Dependency Graph: ApiService → Repositories → Controllers (GetX)

```
ApiService (Singleton)
│
├── AiCoachRepository
│   └── AiCoachController
│
├── AuthRepository
│   ├── LoginController
│   ├── SignupController
│   ├── SettingsController
│   └── GoogleAuthService
│
├── MessagesRepository
│   └── MessagesController
│
├── CommunityRepository
│   └── CommunityController
│
├── GoalsRepository
│   ├── LoginController
│   ├── SignupController
│   ├── GoalSettingsController
│   └── SettingsController
│
├── ConsentRepository
│   ├── LoginController
│   ├── SignupController
│   └── ConsentController
│
├── UserGravityRepository
│   └── DashboardController
│
└── Direct Usage (bypassing repositories)
    └── SettingsController (for profile image upload)
        └── AuthRepository.uploadProfileImage() uses http directly
```

### Controller Initialization (GetX Bindings)
All controllers are registered in `lib/app/bindings/initial_bindings.dart`:
- MainLayoutController
- OnboardingController
- LoginController
- SignupController
- ConsentController
- GoalSettingsController
- DashboardController
- AiCoachController
- MessagesController
- SettingsController
- MealUploadController

All use `Get.lazyPut()` with `fenix: true` for automatic recreation after disposal.

---

## 2. Network Calls Inventory

### ApiService Methods
- `POST(String endpoint, {body, headers, timeout})`
- `GET(String endpoint, {headers})`

### Network Calls by Repository

#### AiCoachRepository
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `getAiCoachReply()` | `/ai_coach/reply` | POST | `lib/data/repositories/ai_coach_repository.dart` | 64 |

#### AuthRepository
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `createUser()` | `/user/create` | POST | `lib/data/repositories/auth_repository.dart` | 25 |
| `login()` | `/user/login` | POST | `lib/data/repositories/auth_repository.dart` | 69 |
| `getUserProfile()` | `/user/profile` | GET | `lib/data/repositories/auth_repository.dart` | 155 |
| `getSingleUser()` | `/single_user` | POST | `lib/data/repositories/auth_repository.dart` | 200 |
| `logout()` | `/user/logout` | POST | `lib/data/repositories/auth_repository.dart` | 237 |
| `googleSignIn()` | `/auth/google` | POST | `lib/data/repositories/auth_repository.dart` | 273 |
| `uploadProfileImage()` | `/user/profile_upload` | POST (multipart) | `lib/data/repositories/auth_repository.dart` | 322 |

#### MessagesRepository
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `getSingleMessage()` | `/single_message` | POST | `lib/data/repositories/messages_repository.dart` | 23 |
| `getAllMessages()` | `/all_messages?id={user_id}` | GET | `lib/data/repositories/messages_repository.dart` | 68 |
| `createMessage()` | `/create_message` | POST | `lib/data/repositories/messages_repository.dart` | 120 |
| `getAllUsers()` | `/all_users` or `/users?role={role}` | POST/GET | `lib/data/repositories/messages_repository.dart` | 164/191 |
| `updateMessage()` | `/update_message` | POST | `lib/data/repositories/messages_repository.dart` | 257 |
| `deleteMessage()` | `/delete_message` | POST | `lib/data/repositories/messages_repository.dart` | 297 |

#### CommunityRepository
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `getAllCommunities()` | `/all_communities` | GET | `lib/data/repositories/community_repository.dart` | 12 |
| `getSingleCommunity()` | `/single_communities` | POST | `lib/data/repositories/community_repository.dart` | 43 |
| `createCommunity()` | `/create_communities` | POST | `lib/data/repositories/community_repository.dart` | 80 |
| `updateCommunity()` | `/update_communities` | POST | `lib/data/repositories/community_repository.dart` | 119 |
| `deleteCommunity()` | `/delete_communities` | POST | `lib/data/repositories/community_repository.dart` | 157 |
| `getAllPosts()` | `/all_posts` | GET | `lib/data/repositories/community_repository.dart` | 191 |
| `getSinglePost()` | `/single_post` | POST | `lib/data/repositories/community_repository.dart` | 223 |
| `createPost()` | `/create_post` | POST | `lib/data/repositories/community_repository.dart` | 284 |
| `updatePost()` | `/update_post` | POST | `lib/data/repositories/community_repository.dart` | 354 |
| `deletePost()` | `/delete_post` | POST | `lib/data/repositories/community_repository.dart` | 391 |
| `createPostComment()` | `/create_post_comment` | POST | `lib/data/repositories/community_repository.dart` | 453 |
| `getAllPostComments()` | `/all_post_comments` | POST | `lib/data/repositories/community_repository.dart` | 490 |
| `getSinglePostComment()` | `/single_post_comment` | POST | `lib/data/repositories/community_repository.dart` | 529 |
| `updatePostComment()` | `/update_post_comment` | POST | `lib/data/repositories/community_repository.dart` | 571 |
| `deletePostComment()` | `/delete_post_comment` | POST | `lib/data/repositories/community_repository.dart` | 614 |
| `reactToPost()` | `/post/react` | POST | `lib/data/repositories/community_repository.dart` | 693 |
| `getUserWiseReact()` | `/user_wise_react` | POST | `lib/data/repositories/community_repository.dart` | 734 |
| `pinCommunityPost()` | `/pin_community_post` | POST | `lib/data/repositories/community_repository.dart` | 779 |
| `unpinCommunityPost()` | `/unpin_community_post` | POST | `lib/data/repositories/community_repository.dart` | 826 |
| `getUserWisePinnedPosts()` | `/user_wise_pinned_posts` | POST | `lib/data/repositories/community_repository.dart` | 871 |

#### GoalsRepository
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `createGoals()` | `/goals/create` | POST | `lib/data/repositories/goals_repository.dart` | 19 |
| `getSingleGoal()` | `/get_single_goal` | POST | `lib/data/repositories/goals_repository.dart` | 60 |

#### ConsentRepository
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `createConsent()` | `/consent/create` | POST | `lib/data/repositories/consent_repository.dart` | 17 |
| `getSingleConsent()` | `/get_single_consent` | POST | `lib/data/repositories/consent_repository.dart` | 56 |

#### UserGravityRepository
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `createUserGravity()` | `/create_user_gravity` | POST | `lib/data/repositories/user_gravity_repository.dart` | 47 |
| `updateUserGravity()` | `/update_user_gravity` | POST | `lib/data/repositories/user_gravity_repository.dart` | 118 |
| `getAllUserGravity()` | `/all_user_gravity?api_token={token}` | GET | `lib/data/repositories/user_gravity_repository.dart` | 159 |
| `getSingleUserGravity()` | `/single_user_gravity` | POST | `lib/data/repositories/user_gravity_repository.dart` | 206 |
| `deleteUserGravity()` | `/delete_user_gravity` | POST | `lib/data/repositories/user_gravity_repository.dart` | 250 |
| `createManualUserGravity()` | `/create_manual_user_gravity` | POST | `lib/data/repositories/user_gravity_repository.dart` | 301 |

#### SettingsController (Direct API Usage)
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `_updateNotificationPreferences()` | `/update_notification_preferences` | POST | `lib/presentation/settings/controllers/settings_controller.dart` | 1335 |
| `_deleteUserAccount()` | `/delete_user_account` | POST | `lib/presentation/settings/controllers/settings_controller.dart` | 1842 |

#### MealAnalysisService (External API)
| Method | Endpoint | HTTP Method | File | Line |
|--------|----------|-------------|------|------|
| `analyzeMeal()` | External API (not using ApiService) | POST (multipart) | `lib/core/services/meal_analysis_service.dart` | 97 |

**Total Network Calls: 40+ endpoints**

---

## 3. Authentication Requirements & Token Passing

### Endpoints Requiring Authentication

#### Token in Request Body (POST)
Most endpoints use `api_token` or `token` in the request body:

| Endpoint | Token Field | Location |
|----------|-------------|----------|
| `/ai_coach/reply` | `api_token` | Body |
| `/single_message` | `api_token` | Body |
| `/create_message` | `api_token` | Body |
| `/update_message` | `api_token` | Body |
| `/delete_message` | `id` only (no token) | Body |
| `/create_post` | `api_token` | Body |
| `/update_post` | `api_token` | Body |
| `/create_post_comment` | `api_token` | Body |
| `/update_post_comment` | `api_token` | Body |
| `/delete_post_comment` | `api_token` | Body |
| `/post/react` | `api_token` | Body |
| `/user_wise_react` | `api_token` | Body |
| `/pin_community_post` | `api_token` | Body |
| `/unpin_community_post` | `api_token` | Body |
| `/user_wise_pinned_posts` | `api_token` | Body |
| `/goals/create` | `token` | Body |
| `/get_single_goal` | `token` | Body |
| `/consent/create` | `token` | Body |
| `/get_single_consent` | `token` | Body |
| `/create_user_gravity` | `api_token` | Body |
| `/update_user_gravity` | `api_token` | Body |
| `/delete_user_gravity` | `api_token` | Body |
| `/create_manual_user_gravity` | `api_token` | Body |
| `/single_user` | `token` | Body |
| `/user/logout` | `token` | Body |
| `/user/profile_upload` | `token` | Multipart form field |
| `/update_notification_preferences` | `token` | Body |
| `/delete_user_account` | `token` | Body |

#### Token in Headers (GET/POST)
| Endpoint | Token Field | Location |
|----------|-------------|----------|
| `/user/profile` | `Authorization: Bearer {token}` | Header |

#### Token in Query Parameter (GET)
| Endpoint | Token Field | Location |
|----------|-------------|----------|
| `/all_user_gravity` | `api_token` | Query parameter |

#### Endpoints NOT Requiring Authentication
| Endpoint | Method |
|----------|--------|
| `/user/create` | POST |
| `/user/login` | POST |
| `/auth/google` | POST |
| `/all_communities` | GET |
| `/all_posts` | GET |
| `/all_messages?id={user_id}` | GET (Note: May require auth in production) |
| `/users?role={role}` | GET (fallback) |
| `/single_communities` | POST |
| `/single_post` | POST |
| `/all_post_comments` | POST |
| `/single_post_comment` | POST |
| `/delete_post` | POST |
| `/delete_message` | POST (only requires `id`) |

### Token Retrieval Pattern
All authenticated endpoints retrieve token from:
```dart
final apiToken = PreferencesService.getAuthToken();
if (apiToken == null || apiToken.isEmpty) {
  // Handle error - show snackbar or return early
}
```

### Token Storage
- Stored in: `GetStorage` via `PreferencesService`
- Key: `'auth_token'`
- Methods: `saveAuthToken()`, `getAuthToken()`, `clearAuthToken()`

---

## 4. Safe Logging Implementation

### Created Safe Logger Helper
**File:** `lib/core/utils/safe_logger.dart`

A lightweight logging helper that wraps `debugPrint` behind `kDebugMode`:
- `SafeLogger.log()` - General logging
- `SafeLogger.error()` - Error messages (prefixes with ❌)
- `SafeLogger.warning()` - Warning messages (prefixes with ⚠️)
- `SafeLogger.info()` - Info messages (prefixes with ℹ️)
- `SafeLogger.success()` - Success messages (prefixes with ✅)
- `SafeLogger.debug()` - Debug messages (prefixes with 🔍)

All methods only execute in debug mode (`kDebugMode`), ensuring zero performance impact in production builds.

### Replaced Noisy debugPrint Calls

The following files have been updated to use `SafeLogger` instead of direct `debugPrint`:

1. **lib/core/services/api_service.dart**
   - Replaced all `debugPrint` calls with `SafeLogger` methods
   - Network request/response logging now only occurs in debug mode

2. **lib/data/repositories/ai_coach_repository.dart**
   - Replaced all `debugPrint` calls with `SafeLogger` methods
   - AI Coach API call logging now only occurs in debug mode

3. **lib/data/repositories/messages_repository.dart**
   - Replaced all `debugPrint` calls with `SafeLogger` methods
   - Messages API call logging now only occurs in debug mode

**Note:** Other files still contain `debugPrint` calls but were not modified as they are less noisy or used for critical error handling. The most frequently called network-related logging has been optimized.

---

## 5. Files Changed Checklist

### New Files Created
- [x] `lib/core/utils/safe_logger.dart` - Safe logging helper

### Files Modified
- [x] `lib/core/services/api_service.dart` - Replaced debugPrint with SafeLogger
- [x] `lib/data/repositories/ai_coach_repository.dart` - Replaced debugPrint with SafeLogger
- [x] `lib/data/repositories/messages_repository.dart` - Replaced debugPrint with SafeLogger

### Analysis Document
- [x] `PROJECT_ANALYSIS.md` - This comprehensive analysis document

---

## Summary

- **Total Repositories:** 7
- **Total Controllers:** 13
- **Total Network Endpoints:** 40+
- **Authentication Methods:** 3 (body, header, query parameter)
- **Files with Safe Logging:** 3 core files updated
- **No Logic Changes:** All changes are logging-only, no API behavior modified

