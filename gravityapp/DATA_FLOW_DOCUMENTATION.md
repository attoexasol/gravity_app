# Data Flow Documentation: Steps, Sleep, Hydration & Fasting

## Overview
This document explains how **Steps**, **Sleep**, **Hydration**, and **Fasting** progress data flows from the UI to the database through the API.

---

## 📍 API Endpoints

### Base URL
```
https://gravity.attoexasolutions.com/api
```

### Endpoints Used

#### 1. **Create User Gravity Entry**
- **Endpoint**: `POST /create_user_gravity`
- **Location**: `lib/data/repositories/user_gravity_repository.dart:47`
- **Purpose**: Creates a new daily entry with all metrics
- **Used for**: Bulk saves (e.g., after health sync)

**When is this API called?**
- **Situation**: When health sync completes successfully AND there's NO existing entry for today
- **Trigger**: Health sync from Google Fit/HealthKit finishes successfully
- **Condition**: `todayEntryId.value == null` (no entry exists for today yet)
- **Location**: `dashboard_controller.dart:362` → `upsertTodayGravity()` method
- **Data Source**: `dataSource = 'google_fit'` (Android) or `'health_connect'` (iOS)

**Specific Scenarios:**
1. **First health sync of the day** - When user opens app and health sync runs for the first time today
2. **After app restart** - If no entry exists for today, creates new entry with synced data
3. **New day** - When it's a new day and no entry has been created yet

**Note**: If an entry already exists (`todayEntryId.value != null`), it uses `POST /update_user_gravity` instead.

#### 2. **Update User Gravity Entry**
- **Endpoint**: `POST /update_user_gravity`
- **Location**: `lib/data/repositories/user_gravity_repository.dart:118`
- **Purpose**: Updates an existing daily entry
- **Used for**: Updating existing entries

#### 3. **Create Manual User Gravity Entry** ⭐ **PRIMARY FOR MANUAL INPUTS**
- **Endpoint**: `POST /create_manual_user_gravity`
- **Location**: `lib/data/repositories/user_gravity_repository.dart:301`
- **Purpose**: Creates/updates a single metric for today
- **Used for**: Manual user inputs (Steps, Sleep, Hydration, Fasting)
- **Request Body**:
  ```json
  {
    "api_token": "user_token",
    "date": "YYYY-MM-DD",
    "type": "steps" | "sleep_hours" | "hydration" | "meals_eaten",
    "value": "numeric_value_as_string"
  }
  ```

#### 4. **Get All User Gravity Entries**
- **Endpoint**: `GET /all_user_gravity?api_token={token}`
- **Location**: `lib/data/repositories/user_gravity_repository.dart:159`
- **Purpose**: Retrieves all daily entries for the user

---

## 🔄 Data Flow Paths

### Path 1: Manual User Input (Steps, Sleep, Hydration, Fasting)

```
User Input (UI)
    ↓
DashboardController.handle[Steps/Sleep/Hydration/Fasting]Submit()
    ↓
_saveManualEntry(type, value)
    ↓
UserGravityRepository.createManualUserGravity()
    ↓
ApiService.post('/create_manual_user_gravity')
    ↓
API Server (https://gravity.attoexasolutions.com/api/create_manual_user_gravity)
    ↓
Database (Backend handles INSERT/UPDATE)
```

**File Locations:**
- **UI Handler**: `lib/presentation/dashboard/controllers/dashboard_controller.dart`
  - `handleStepsSubmit()` → Line 502
  - `handleSleepSubmit()` → Line 524
  - `handleHydrationSubmit()` → Line 546
  - `handleFastingSubmit()` → Line 559
- **Save Method**: `_saveManualEntry()` → Line 572
- **Repository**: `lib/data/repositories/user_gravity_repository.dart:282`
- **API Service**: `lib/core/services/api_service.dart:26`

**Code Flow Example (Steps):**
```dart
// 1. User enters steps in modal
handleStepsSubmit() {
  // 2. Update local state
  healthMetrics.value = HealthMetrics(steps: value, ...);
  
  // 3. Save to database
  await _saveManualEntry(type: 'steps', value: value.toString());
}

// 4. Repository method
createManualUserGravity({
  apiToken: token,
  date: today,
  type: 'steps',  // or 'sleep_hours', 'hydration', 'meals_eaten'
  value: '5000'
})

// 5. API call
POST /create_manual_user_gravity
Body: {
  "api_token": "...",
  "date": "2024-01-15",
  "type": "steps",
  "value": "5000"
}
```

---

### Path 2: Health Sync (Steps, Sleep, Hydration from HealthKit/Google Fit)

```
HealthKit/Google Fit
    ↓
HealthSyncService.syncHealthData()
    ↓
Fetch from Health Platform
    ↓
Update HealthMetrics (local state)
    ↓
DashboardController subscribes to HealthSyncService
    ↓
upsertTodayGravity(dataSource: 'health_sync')
    ↓
UserGravityRepository.createUserGravity() OR updateUserGravity()
    ↓
ApiService.post('/create_user_gravity') OR '/update_user_gravity'
    ↓
API Server
    ↓
Database
```

**File Locations:**
- **Health Sync**: `lib/core/services/health_sync_service.dart`
- **Dashboard Integration**: `lib/presentation/dashboard/controllers/dashboard_controller.dart:307`
- **Repository**: `lib/data/repositories/user_gravity_repository.dart:11` (create) or `:79` (update)

**Code Flow:**
```dart
// 1. Health sync service fetches from HealthKit/Google Fit
HealthSyncService.syncHealthData() {
  // Fetch steps, sleep, weight, water
  // Update _metrics
}

// 2. Dashboard controller subscribes
_healthService.subscribe((metrics) {
  healthMetrics.value = metrics;
  // Auto-save to DB
  upsertTodayGravity(dataSource: 'health_sync');
});

// 3. Upsert method
upsertTodayGravity() {
  if (todayEntryId.value != null) {
    // Update existing
    updateUserGravity(id, steps, sleepHours, hydrationLiters, ...);
  } else {
    // Create new
    createUserGravity(steps, sleepHours, hydrationLiters, ...);
  }
}
```

---

## ⏰ When Data is Saved to Database

### ❌ **NOT Real-Time (Does NOT save as you walk)**

The app does **NOT** save data in real-time as you walk or perform activities. Instead, it uses **scheduled syncing** and **event-based triggers**.

### Manual Entries (Steps, Sleep, Hydration, Fasting)
- **Timing**: ✅ **Immediate** - Saved instantly when user submits
- **Trigger**: User clicks "Save" or submits the input modal
- **API Call**: Happens immediately after user action
- **Location**: `dashboard_controller.dart` → `handle[Type]Submit()` → `_saveManualEntry()`

### Health Sync (Steps, Sleep, Hydration from HealthKit/Google Fit)
- **Timing**: ⏱️ **Periodic** - Every **2 minutes** while app is open
- **Additional Triggers**:
  1. **App Startup**: When dashboard initializes
  2. **App Resume**: When app comes back to foreground
  3. **After Successful Sync**: Automatically saves to DB (with 3-second debounce)
- **Location**: `dashboard_controller.dart:159` - Periodic timer

**Code Reference:**
```dart
// Periodic health data sync every 2 minutes to refresh data after walking
_healthSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
  _healthService.syncHealthData();
});

// Also syncs when app resumes
onResumed: () {
  _healthService.syncHealthData();
}
```

### Save Debouncing
- **Debounce Period**: 3 seconds minimum between saves
- **Purpose**: Prevents multiple rapid API calls
- **Location**: `dashboard_controller.dart:136-141`

```dart
// Debounce: only save if last save was more than 3 seconds ago
if (_lastSaveTime == null || 
    now.difference(_lastSaveTime!).inSeconds >= 3) {
  upsertTodayGravity(dataSource: dataSource);
}
```

### Summary Table

| Data Source | Save Timing | Frequency | Real-Time? |
|------------|-------------|-----------|------------|
| **Manual Steps** | On user submit | Immediate | ✅ Yes (on action) |
| **Manual Sleep** | On user submit | Immediate | ✅ Yes (on action) |
| **Manual Hydration** | On user submit | Immediate | ✅ Yes (on action) |
| **Manual Fasting** | On user submit | Immediate | ✅ Yes (on action) |
| **Synced Steps** | Every 2 min + app events | Periodic | ❌ No |
| **Synced Sleep** | Every 2 min + app events | Periodic | ❌ No |
| **Synced Hydration** | Every 2 min + app events | Periodic | ❌ No |

### Example Scenario: Walking

1. **You start walking** → Steps increase in HealthKit/Google Fit
2. **App is open** → Every 2 minutes, app syncs from HealthKit/Google Fit
3. **After sync** → If sync successful, data is saved to database (with 3-sec debounce)
4. **You close app** → No more syncing until app reopens
5. **You reopen app** → Syncs immediately on resume

**So if you walk and close the app, your steps won't be saved until:**
- You reopen the app (triggers sync on resume)
- OR the next time the 2-minute timer fires (if app stays open)

---

## 📺 Where Progress Data is Displayed From

### Data Source Priority System

The app uses a **priority-based merge system** to determine what data to display:

**Priority Order:**
1. **Google Fit/HealthKit (Health Sync)** - If sync is successful ✅
2. **Database** - If health sync is NOT successful or unavailable
3. **Default/Initial values** - Fallback

### Steps, Sleep, Hydration Display Logic

**Source**: `healthMetrics.value` (merged from multiple sources)

**Priority Logic** (from `dashboard_controller.dart:244-275`):
```dart
// Priority: Health Sync (if successful) > Database Entry > Default
if (healthSyncSuccessful && hasHealthSyncPlatform) {
  // Use Google Fit/HealthKit data (most recent, even if 0)
  displayValue = healthSyncData;
} else {
  // Use database data
  displayValue = databaseEntry ?? defaultValue;
}
```

**When Health Sync is Active:**
- ✅ **Steps**: From Google Fit/HealthKit (real-time from health platform)
- ✅ **Sleep**: From Google Fit/HealthKit (real-time from health platform)
- ✅ **Hydration**: From Google Fit/HealthKit (real-time from health platform)

**When Health Sync is NOT Active:**
- 📊 **Steps**: From Database via `GET /all_user_gravity` API
- 📊 **Sleep**: From Database via `GET /all_user_gravity` API
- 📊 **Hydration**: From Database via `GET /all_user_gravity` API

### Fasting Display Logic

**Source**: `mealsEaten.value` (local state)

- **Fasting data**: Only from **local state** (not synced from health platforms)
- **Initial value**: `0` (default)
- **Updated**: When user manually submits fasting data
- **Saved to DB**: Via `/create_manual_user_gravity` API
- **Loaded from DB**: ⚠️ **Currently NOT loaded back** - only saved, not retrieved

### Database API for Display

**API Endpoint**: `GET /all_user_gravity?api_token={token}`
- **Location**: `lib/data/repositories/user_gravity_repository.dart:159`
- **Called in**: `dashboard_controller.dart:230` → `loadTodayFromDb()`
- **When**: On app startup/dashboard initialization
- **Returns**: All user gravity entries (day-wise list)
- **Used for**: Loading today's entry from database when health sync is not available

**Code Flow:**
```dart
// On dashboard init
loadTodayFromDb() {
  // 1. Call API
  final response = await _gravityRepository.getAllUserGravity(apiToken);
  
  // 2. Find today's entry
  final todayEntry = response.data.firstWhere(
    (entry) => entry.date == todayStr
  );
  
  // 3. Merge with health sync data (priority logic)
  healthMetrics.value = mergeData(todayEntry, healthSyncData);
}
```

### Summary Table: Data Source for Display

| Metric | Primary Source | Fallback Source | API Used (if from DB) |
|--------|---------------|-----------------|----------------------|
| **Steps** | Google Fit/HealthKit (if sync successful) | Database | `GET /all_user_gravity` |
| **Sleep** | Google Fit/HealthKit (if sync successful) | Database | `GET /all_user_gravity` |
| **Hydration** | Google Fit/HealthKit (if sync successful) | Database | `GET /all_user_gravity` |
| **Fasting** | Local state only | N/A | ❌ Not loaded from DB |

### Key Points

1. **If Google Fit/HealthKit sync is successful**: Progress shows **live data from health platforms** (not from database)
2. **If Google Fit/HealthKit sync fails/is unavailable**: Progress shows **data from database** via `GET /all_user_gravity` API
3. **Fasting**: Always from local state, saved to DB but not loaded back (starts at 0 on app restart)
4. **Database is used as fallback**: Only when health sync is not available or unsuccessful

---

## 📊 Field Mappings

### API Request Fields → Database Columns

| Metric | API Field Name | Type | Example Value | Notes |
|--------|---------------|------|---------------|-------|
| **Steps** | `steps` | String | `"5000"` | Converted to string in API |
| **Sleep** | `sleep_hours` | String | `"7.5"` | Hours as string |
| **Hydration** | `hydration` | String | `"3L"` or `"3.5L"` | Formatted as "XL" |
| **Fasting** | `meals_eaten` | String | `"1"` or `"2"` | Via manual entry API only |
| **Weight** | `weight` | Number | `75.5` | Direct number |
| **Date** | `date` | String | `"2024-01-15"` | YYYY-MM-DD format |
| **Source** | `data_source` | String | `"manual"` or `"health_sync"` | Tracks origin |

### Manual Entry API Types

For `/create_manual_user_gravity`, the `type` field accepts:
- `"steps"` → Maps to `steps` column
- `"sleep_hours"` → Maps to `sleep_hours` column
- `"hydration"` → Maps to `hydration` column (value should be like "3L")
- `"meals_eaten"` → Maps to fasting/meals column

---

## 🗄️ Database Storage

### Where Data Goes

The API endpoints (`/create_user_gravity`, `/update_user_gravity`, `/create_manual_user_gravity`) are handled by the **backend server** at `https://gravity.attoexasolutions.com/api`.

The backend:
1. Receives the API request with authentication token
2. Validates the data
3. **Inserts or Updates** the `user_gravity` table (or equivalent) in the database
4. Returns success/error response

**Database Table Structure** (inferred from API):
- `id` - Primary key
- `user_id` - Foreign key (derived from api_token)
- `date` - Date of entry
- `steps` - Integer
- `sleep_hours` - Decimal
- `hydration` - String (e.g., "3L")
- `weight` - Decimal
- `meals_eaten` - Integer (for fasting)
- `data_source` - String (tracks if from manual or health_sync)
- `nutration` - String
- `created_at` - Timestamp
- `updated_at` - Timestamp

---

## 🔑 Key Points

1. **Two Main Entry Points:**
   - **Manual Input**: Uses `/create_manual_user_gravity` (single metric at a time)
   - **Health Sync**: Uses `/create_user_gravity` or `/update_user_gravity` (all metrics at once)

2. **Fasting Data:**
   - Only saved via manual entry (`type: "meals_eaten"`)
   - Not synced from HealthKit/Google Fit
   - Value represents number of meals eaten (0-2)

3. **Hydration Format:**
   - Stored as string with "L" suffix (e.g., "3L", "3.5L")
   - Converted in `createUserGravity()` method (line 23-27)

4. **Authentication:**
   - All requests require `api_token` in request body
   - Token retrieved from `PreferencesService.getAuthToken()`
   - Stored in GetStorage with key `'auth_token'`

5. **Date Format:**
   - Always `YYYY-MM-DD` format
   - Generated in `DashboardController._todayString` getter

---

## 📝 Summary

| Metric | Manual Input API | Health Sync API | Save Timing | Database Column |
|--------|-----------------|-----------------|-------------|----------------|
| **Steps** | `/create_manual_user_gravity` (type: "steps") | `/create_user_gravity` or `/update_user_gravity` (steps) | Manual: Immediate<br>Sync: Every 2 min | `steps` |
| **Sleep** | `/create_manual_user_gravity` (type: "sleep_hours") | `/create_user_gravity` or `/update_user_gravity` (sleep_hours) | Manual: Immediate<br>Sync: Every 2 min | `sleep_hours` |
| **Hydration** | `/create_manual_user_gravity` (type: "hydration") | `/create_user_gravity` or `/update_user_gravity` (hydration) | Manual: Immediate<br>Sync: Every 2 min | `hydration` |
| **Fasting** | `/create_manual_user_gravity` (type: "meals_eaten") | ❌ Not synced | Manual: Immediate only | `meals_eaten` |

**All data flows to the backend database via the API endpoints listed above.**

### ⚠️ Important Notes:
- **Manual entries**: Saved **immediately** when user submits
- **Health sync**: **NOT real-time** - syncs every **2 minutes** while app is open
- **App events**: Also syncs on app startup and when app resumes from background
- **Debouncing**: Minimum 3 seconds between database saves to prevent API spam

### 📺 Display Data Source:
- **Steps, Sleep, Hydration**: 
  - **Primary**: Google Fit/HealthKit (if sync successful) ✅
  - **Fallback**: Database via `GET /all_user_gravity` API
- **Fasting**: Local state only (not loaded from database)
