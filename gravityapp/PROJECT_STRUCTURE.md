# Gravity App — Project Structure

Flutter app (GetX, Firebase/Firestore) for weight/wellness tracking, messaging, AI coach, and community.

---

## Root

```
gravityapp/
├── lib/                    # Application source code
├── assets/                 # Images, fonts, etc.
├── test/                   # Unit & widget tests
├── android/                # Android platform
├── ios/                    # iOS platform
├── linux/                  # Linux platform
├── macos/                  # macOS platform
├── web/                    # Web platform
├── windows/                # Windows platform
├── pubspec.yaml            # Dependencies & project config
├── analysis_options.yaml   # Lint rules
└── README.md
```

---

## `lib/`

### `lib/app/` — App bootstrap, theme, routing

| Path | Description |
|------|-------------|
| **bindings/** | GetX dependency injection |
| `bindings/initial_bindings.dart` | Initial controllers/services registration |
| **routes/** | Navigation |
| `routes/app_routes.dart` | Route name constants |
| `routes/app_pages.dart` | Page definitions, bindings, transitions |
| **theme/** | Global UI theme |
| `theme/app_theme.dart` | Main theme config |
| `theme/app_colors.dart` | Color palette |
| `theme/app_text_styles.dart` | Typography (ResponsiveTextStyles) |
| `theme/app_gradients.dart` | Gradient definitions |
| `theme/app_shadows.dart` | Shadow styles |

---

### `lib/core/` — Shared services & utilities

| Path | Description |
|------|-------------|
| **services/** | Cross-cutting services |
| `services/api_service.dart` | HTTP client, base API calls |
| `services/preferences_service.dart` | Local preferences (GetStorage) |
| `services/token_manager.dart` | Auth token handling |
| `services/session_manager.dart` | Session state |
| `services/auth_error_handler.dart` | Auth error handling |
| `services/google_auth_service.dart` | Google Sign-In |
| `services/app_lifecycle_service.dart` | App resume/pause |
| `services/network_info_service.dart` | Connectivity |
| `services/device_manager.dart` | Device info |
| `services/health_sync_service.dart` | Health kit sync |
| `services/meal_analysis_service.dart` | Meal analysis |
| `services/fast_meal_service.dart` | Fast meal flow |
| `services/image_cache_service.dart` | Image caching |
| **utils/** | Helpers |
| `utils/safe_logger.dart` | Safe logging |
| `utils/app_snackbar.dart` | Snackbar helpers |

---

### `lib/data/` — Data layer (models, repositories, Firestore/API)

| Path | Description |
|------|-------------|
| **model/** | Domain & API models |
| `model/message.dart` | Chat message (Firestore) |
| `model/message_user_model.dart` | Inbox user row |
| `model/conversation.dart` | Conversation |
| `model/conversation_firestore_model.dart` | Firestore conversation |
| `model/user_model.dart` | User |
| `model/user_account_info.dart` | Account info |
| `model/ai_coach.dart` | AI coach chat message |
| `model/post.dart`, `model/comment.dart`, `model/reply.dart`, `model/reactions.dart` | Community |
| `model/weight_history.dart`, `model/user_gravity_entry.dart` | Weight / gravity |
| `model/weekly_review.dart`, `model/daily_details.dart`, `model/day_activity.dart` | Reviews & daily |
| `model/meal_analysis.dart` | Meals & goals-related models |
| `model/api_response.dart` | Generic API response |
| (+ other domain models) | |
| **repositories/** | Data access |
| `repositories/auth_repository.dart` | Auth API |
| `repositories/messages_repository.dart` | Messages API (REST) |
| `repositories/ai_coach_repository.dart` | AI coach API |
| `repositories/community_repository.dart` | Community API |
| `repositories/user_gravity_repository.dart` | Gravity/weight API |
| `repositories/goals_repository.dart` | Goals API |
| `repositories/consent_repository.dart` | Consent API |
| **services/** | Backend clients |
| `services/auth_service.dart` | Firebase Auth + API auth |
| `services/firestore_chat_service.dart` | Firestore chat (conversations, messages, typing, unread) |
| `services/user_api_service.dart` | User API (e.g. fetch users for inbox) |

---

### `lib/presentation/` — UI by feature

Features follow a pattern: **controllers/**, **screens/**, **views/**, **sections/** (or **modals/**), and sometimes **utils/**, **models/**.

---

#### **main_layout/** — Bottom nav & shell

| Path | Description |
|------|-------------|
| `controllers/main_layout_controller.dart` | Tab state, navigation |
| `screens/main_layout_screen.dart` | Shell with bottom nav (Home, Community, AI Coach, Messages) |

---

#### **today_views/** — Today / daily screen

| Path | Description |
|------|-------------|
| `controllers/today_controller.dart` | Today state, goals, weigh-in |
| `screens/today_screen.dart` | Main “Today” tab |
| `screens/sections/` | today_header, weight_journey_section, pillar_status_section, wins_today_section, reflection_section, one_thing_to_watch_section, done_button_section |
| `screens/modals/` | log_weigh_in_modal, weight_goals_modal |

---

#### **dashboard/** — Dashboard (home)

| Path | Description |
|------|-------------|
| `screens/` | Dashboard screen and sections (e.g. quick_actions_section, weight_journey_section) |

---

#### **messages/** — Inbox & chat (GetX + Firestore)

| Path | Description |
|------|-------------|
| `controllers/messages_controller.dart` | **InboxController** — user list, conversation previews, unread, typing (Firestore streams) |
| `controllers/chat_controller.dart` | **ChatController** — single chat, send/edit/delete, mark read |
| `controllers/messages_controllers.dart` | **MessagesController** — optional REST-based inbox logic |
| `screens/messages_page.dart` | Messages tab — inbox UI (search, user tiles, unread badge), opens ChatScreen |
| `screens/chat_screen.dart` | Single conversation screen |
| `utils/message_utils.dart` | Helpers, unread count, mapping |

---

#### **aicoach/** — AI Coach

| Path | Description |
|------|-------------|
| `controllers/ai_coach_controller.dart` | Chat with AI, send, delete |
| `screens/ai_coach_screen.dart` | AI coach chat UI |

---

#### **weight_history/** — Weight history & progress

| Path | Description |
|------|-------------|
| `controllers/weight_history_controller.dart` | Entries, chart data |
| `screens/weight_history_screen.dart` | Weight history screen |
| `screens/sections/` | weight_history_header, progress_chart_section, recent_entries_section, journey_stats_section, estimated_target_date_section |

---

#### **weekly_review/** — Weekly review

| Path | Description |
|------|-------------|
| `controllers/weekly_review_controller.dart` | Week data, daily details |
| `screens/weekly_review_screen.dart` | Weekly review screen |
| `screens/sections/` | weekly_review_header, weekly_summary_card, weekly_consistency_grid, status_insight_cards, patterns_section, week_picker_modal, view_daily_details_button |

---

#### **meal_upload/** — Meal upload

| Path | Description |
|------|-------------|
| `controllers/meal_upload_controller.dart` | Meal upload flow |
| `screens/meal_upload_screen.dart` | Meal upload UI |

---

#### **goal_settings/** — Goal configuration

| Path | Description |
|------|-------------|
| `controllers/goal_settings_controller.dart` | Goal settings state |
| `screens/goal_settings_screen.dart` | Goal settings screen |
| `screens/sections/goal_settings_header.dart` | Header section |

---

#### **login/** — Auth (login, forgot, OTP, reset)

| Path | Description |
|------|-------------|
| `controllers/login_controller.dart` | Login |
| `controllers/forgot_password_controller.dart` | Forgot password |
| `controllers/otp_verification_controller.dart` | OTP verification |
| `controllers/reset_password_controller.dart` | Reset password |
| `screens/login_screen.dart` | Login screen |
| `screens/forgot_password_screen.dart` | Forgot password |
| `screens/otp_verification_screen.dart` | OTP screen |
| `screens/reset_password_screen.dart` | Reset password |

---

#### **signup/** — Registration

| Path | Description |
|------|-------------|
| `controllers/signup_controller.dart` | Sign-up flow |
| `screens/signup_screen.dart` | Sign-up screen |

---

#### **onboarding/** — Onboarding

| Path | Description |
|------|-------------|
| `controllers/onboarding_controller.dart` | Onboarding state |
| `screens/onboarding_screen.dart` | Onboarding screen |
| `screens/sections/onboarding_slides.dart` | Slides content |

---

#### **settings/** — Settings & profile

| Path | Description |
|------|-------------|
| `controllers/settings_controller.dart` | Settings state |
| `screens/settings_page.dart` | Settings page |
| `screens/sections/` | account_section, profile_image_picker_modal, section_title_widget, wellness_goals_section, health_integration |

---

#### **widgets/** — Shared UI components

| Path | Description |
|------|-------------|
| `main_app_bar.dart` | App bar |
| `main_bottom_nav.dart` | Bottom navigation |
| `main_drawer.dart` | Drawer |
| `bottom_nav.dart` | Nav widget |
| `progress_ring.dart` | Progress ring |
| `progress_over_time_chart.dart` | Progress chart |
| `progress_over_time_chart_example.dart` | Chart example |

---

#### **community/** — Community feed (if present)

Community-related screens/controllers live under a dedicated feature folder (e.g. community feed, posts, comments).

---

## `assets/`

```
assets/
└── images/
    ├── home.svg
    ├── community.svg
    ├── messages.svg
    ├── aicoach.svg
    └── google_logo.svg
```

---

## Main entry & flow

- **`lib/main.dart`** — Firebase init, Firestore persistence, GetMaterialApp, initial bindings, route table.
- **Routes** — Defined in `app_routes.dart` and `app_pages.dart` (e.g. onboarding, login, signup, home, settings, chat, ai-coach, meal-upload, weekly-review, weight-history, goal-settings).
- **Main shell** — `MainLayoutScreen` with bottom tabs; each tab loads its feature (today, community, AI coach, messages).

---

## Tech stack (summary)

| Layer | Tech |
|-------|------|
| UI | Flutter, GetX (GetView, Obx, Get.find) |
| State | GetX (Rx, controllers) |
| Routing | GetX (Get.toNamed, Get.back, app_pages) |
| Auth | Firebase Auth, Google Sign-In, Sign in with Apple |
| Chat | Cloud Firestore (conversations, messages, typing, unread) |
| API | HTTP (REST), ApiService, repositories |
| Local | GetStorage (preferences), token/session managers |
| Theme | app_theme, app_colors, app_text_styles, ScreenUtil |

---

*Generated for the gravityapp Flutter project.*
