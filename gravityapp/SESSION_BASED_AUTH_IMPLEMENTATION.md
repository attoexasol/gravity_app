# Session-Based Authentication Implementation

## Overview
This document describes the implementation of session-based authentication in the Gravity app, where users must log in again every time the app is opened, even if they didn't explicitly log out.

## Implementation Strategy

### Approach: Clear Token on App Startup
The most reliable frontend-side approach for session-based authentication is to **clear the authentication token on every app startup**. This ensures that:

1. ✅ Users must log in again every time they open the app
2. ✅ Works reliably even if the app is killed by the OS
3. ✅ No complex lifecycle management needed
4. ✅ Simple and maintainable

### Why This Approach?

**Challenges with App Lifecycle:**
- When an app is **terminated** (killed by OS), we cannot reliably execute code to clear the token
- When an app goes to **background** (paused/inactive), clearing the token would log users out even when they just switch apps temporarily
- Different platforms (iOS/Android) handle app termination differently

**Solution:**
- Clear token **on app startup** (in `main()` function) before checking for existing token
- This is the most reliable method that works across all platforms
- Ensures token is always cleared when app launches, regardless of how it was closed

## Implementation Details

### Changes Made

#### 1. Modified `lib/main.dart`

**Before:**
- Token was checked on startup and persisted across app sessions
- Users remained logged in after closing the app

**After:**
- Token is cleared on every app startup (line 51-53)
- `MyApp` converted from `StatelessWidget` to `StatefulWidget` with `WidgetsBindingObserver`
- Lifecycle observer added for potential future enhancements
- `_getInitialRoute()` always returns `AppRoutes.onboarding` since token is always cleared

**Key Code:**
```dart
// In main() function - before runApp()
await PreferencesService.clearAuthToken();
await PreferencesService.clearUserData();
debugPrint('🔒 Session-based auth: Token cleared on app startup');
```

### How It Works

1. **App Startup Flow:**
   ```
   App Launches
   → Initialize Firebase
   → Initialize Storage
   → Clear Auth Token (NEW)
   → Clear User Data (NEW)
   → Check for Token
   → Always returns null (token was just cleared)
   → Navigate to Onboarding/Login
   ```

2. **User Login Flow:**
   ```
   User Logs In
   → Token Saved to Storage
   → Navigate to Dashboard
   → User Uses App
   → User Closes App
   → Token Remains in Storage (but will be cleared on next startup)
   ```

3. **Next App Launch:**
   ```
   App Launches Again
   → Token Cleared on Startup
   → User Must Log In Again
   ```

## Benefits

1. **Security:**
   - Users must authenticate on every app launch
   - Reduces risk of unauthorized access if device is compromised
   - Token doesn't persist across app sessions

2. **Simplicity:**
   - No complex lifecycle management
   - Works reliably across all platforms
   - Easy to understand and maintain

3. **User Experience:**
   - Clear expectation: users know they need to log in each time
   - No confusion about session state
   - Consistent behavior

## Considerations

### Potential Drawbacks

1. **User Convenience:**
   - Users must enter credentials every time they open the app
   - May be inconvenient for frequent app usage
   - Consider implementing biometric authentication (fingerprint/face ID) for faster login

2. **Network Dependency:**
   - Users need internet connection to log in
   - No offline access to authenticated features

### Future Enhancements

1. **Biometric Authentication:**
   - Add fingerprint/face ID support for faster login
   - Store credentials securely in device keychain/keystore
   - Use biometrics to auto-fill login form

2. **Remember Email:**
   - Store email address (not password) for convenience
   - Pre-fill email field on login screen
   - User only needs to enter password

3. **Session Timeout:**
   - Instead of clearing on every startup, implement timeout-based sessions
   - Clear token after X minutes of inactivity
   - More flexible than always clearing on startup

## Testing

### Test Scenarios

1. **Basic Flow:**
   - ✅ Login → Close app → Reopen app → Should show login screen
   - ✅ Login → Use app → Close app → Reopen app → Should show login screen

2. **Edge Cases:**
   - ✅ Login → Force close app → Reopen → Should show login screen
   - ✅ Login → Switch to another app → Return to app → Should still be logged in (token not cleared on background)
   - ✅ Login → Device restart → Open app → Should show login screen

3. **Logout Flow:**
   - ✅ Login → Explicit logout → Should navigate to login
   - ✅ Login → Explicit logout → Close app → Reopen → Should show login (no token to clear)

## Code Location

- **Main Implementation:** `lib/main.dart`
  - Token clearing: Lines 49-53
  - Lifecycle observer: Lines 71-98
  - Route decision: Lines 103-107

- **Storage Service:** `lib/core/services/preferences_service.dart`
  - `clearAuthToken()`: Clears authentication token
  - `clearUserData()`: Clears user-related data

## Migration Notes

### If You Want to Revert to Persistent Login

To revert to persistent login (token persists across app sessions):

1. Remove token clearing from `main()`:
   ```dart
   // Remove these lines:
   await PreferencesService.clearAuthToken();
   await PreferencesService.clearUserData();
   ```

2. Restore token check in `_getInitialRoute()`:
   ```dart
   String _getInitialRoute() {
     final token = PreferencesService.getAuthToken();
     if (token != null && token.isNotEmpty) {
       return AppRoutes.home;
     }
     return AppRoutes.onboarding;
   }
   ```

3. Optionally remove lifecycle observer if not needed for other purposes

## Summary

The session-based authentication is now implemented by clearing the authentication token on every app startup. This is the most reliable frontend-side approach that works consistently across all platforms and app termination scenarios.

Users will now be required to log in every time they open the app, providing enhanced security while maintaining a simple and maintainable implementation.

