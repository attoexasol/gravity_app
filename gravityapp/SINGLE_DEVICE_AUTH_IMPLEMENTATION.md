# Single-Device Authentication System Implementation

## Overview
This document describes the implementation of a single-device authentication system that ensures only one active session per user. When a user logs in from a new device, all previous active tokens are invalidated.

## Architecture

### Components

1. **DeviceManager** (`lib/core/services/device_manager.dart`)
   - Generates and manages unique device IDs
   - Provides device information (device_id, platform, app_version) for API requests
   - Persists device ID across app sessions

2. **SessionManager** (`lib/core/services/session_manager.dart`)
   - Tracks active sessions per device
   - Validates if current device is the active session
   - Handles session initialization and invalidation

3. **AuthErrorHandler** (`lib/core/services/auth_error_handler.dart`)
   - Intercepts 401 Unauthorized responses
   - Distinguishes between different error types:
     - Token expired (can refresh)
     - Token invalidated (forced logout)
     - Session expired
     - Device mismatch (logged in from another device)
   - Shows appropriate dialogs and handles logout

4. **ApiService** (Enhanced)
   - Automatically attaches access token in Authorization header
   - Handles 401 responses with intelligent retry logic
   - Prevents multiple simultaneous refresh attempts
   - Integrates with AuthErrorHandler for error management

## Frontend Implementation

### 1. Device Identification

**DeviceManager** generates a unique device ID on first launch:
- Uses platform-specific identifiers
- Creates a hash-based ID for consistency
- Persists across app sessions

```dart
final deviceManager = DeviceManager();
final deviceId = await deviceManager.getDeviceId();
final deviceInfo = await deviceManager.getDeviceInfo();
// Returns: { device_id, platform, app_version }
```

### 2. Login Flow with Device Info

**Login requests include device information:**
```dart
POST /user/login
{
  "email": "user@example.com",
  "password": "password",
  "device_id": "abc123...",
  "platform": "android",
  "app_version": "1.0.0"
}
```

**After successful login:**
1. Save access and refresh tokens
2. Initialize session with device ID and user ID
3. Mark current device as active session

### 3. Session Management

**Session initialization:**
```dart
await sessionManager.initializeSession(
  userId: userId,
  deviceId: deviceId,
);
```

**Session validation:**
- Checks if current device matches session device
- Verifies session is marked as active
- Validates tokens exist

### 4. API Request Flow

**Every API request:**
1. Automatically attaches `Authorization: Bearer {access_token}` header
2. Backend verifies:
   - Token validity
   - Token active status
   - User match
   - Device match (if implemented)

**On 401 Unauthorized:**
1. AuthErrorHandler intercepts the error
2. Parses error type from response
3. If token expired → Attempts refresh
4. If invalidated/mismatch → Forces logout

### 5. Error Handling

**Error Types:**
- **Token Expired**: Token expired but can be refreshed
  - Action: Attempt token refresh, retry request
- **Token Invalidated**: Token invalidated by backend (new device login)
  - Action: Clear tokens, show dialog, redirect to login
- **Session Expired**: Session expired
  - Action: Clear tokens, show dialog, redirect to login
- **Device Mismatch**: Logged in from another device
  - Action: Clear tokens, show dialog, redirect to login

**Error Response Format (Backend should return):**
```json
{
  "status": false,
  "message": "Session expired",
  "error_code": "session_expired" // or "token_invalidated", "device_mismatch"
}
```

### 6. Token Refresh Flow

**When access token expires:**
1. ApiService detects 401 response
2. Checks if error is "token_expired"
3. Attempts to refresh using refresh token
4. If refresh succeeds → Retries original request
5. If refresh fails → Forces logout

**Prevents multiple simultaneous refreshes:**
- Uses `_isRefreshing` flag
- Uses `Completer` to queue waiting requests
- Limits retry attempts to prevent loops

### 7. Forced Logout Flow

**When session is invalidated:**
1. AuthErrorHandler detects invalidated session
2. Clears tokens (access + refresh)
3. Clears session data
4. Clears user data
5. Shows session expired dialog
6. Redirects to login page

## Backend Requirements

### 1. Token Management

**On Login:**
1. Invalidate all existing active tokens for the user
2. Generate new access token and refresh token
3. Store token with:
   - User ID
   - Device ID
   - Active status (true)
   - Expiration time
   - Created timestamp

**Token Storage Schema:**
```
tokens {
  id: string
  user_id: string
  device_id: string
  access_token: string (hashed)
  refresh_token: string (hashed)
  is_active: boolean
  expires_at: timestamp
  created_at: timestamp
}
```

### 2. Request Validation

**On Every Protected Request:**
1. Extract access token from `Authorization: Bearer {token}` header
2. Verify token exists and is valid
3. Check `is_active = true`
4. Verify `user_id` matches
5. Verify `device_id` matches (optional but recommended)
6. Check token hasn't expired

**Validation Logic:**
```python
# Pseudo-code
def validate_token(token, user_id, device_id):
    token_record = get_token(token)
    
    if not token_record:
        return 401, "Token not found"
    
    if not token_record.is_active:
        return 401, "Token invalidated", error_code="token_invalidated"
    
    if token_record.user_id != user_id:
        return 401, "User mismatch"
    
    if token_record.device_id != device_id:
        return 401, "Device mismatch", error_code="device_mismatch"
    
    if token_record.expires_at < now():
        return 401, "Token expired", error_code="token_expired"
    
    return 200, "Valid"
```

### 3. Error Responses

**Return appropriate error codes:**
```json
// Token expired (can refresh)
{
  "status": false,
  "message": "Token expired",
  "error_code": "token_expired"
}

// Token invalidated (forced logout)
{
  "status": false,
  "message": "Token invalidated",
  "error_code": "token_invalidated"
}

// Device mismatch
{
  "status": false,
  "message": "Logged in from another device",
  "error_code": "device_mismatch"
}

// Session expired
{
  "status": false,
  "message": "Session expired",
  "error_code": "session_expired"
}
```

### 4. Token Refresh Endpoint

**POST /auth/refresh**
```json
Request:
{
  "refresh_token": "..."
}

Response (Success):
{
  "status": true,
  "access_token": "...",
  "refresh_token": "..." // Optional: new refresh token
}

Response (Failure):
{
  "status": false,
  "message": "Refresh token invalid",
  "error_code": "refresh_token_invalid"
}
```

**On Refresh:**
- Verify refresh token is valid and active
- Generate new access token
- Optionally generate new refresh token (rotate)
- Return new tokens

### 5. Logout Endpoint

**POST /user/logout**
```json
Request:
{
  "refresh_token": "..." // or access_token
}

Response:
{
  "status": true,
  "message": "Logged out successfully"
}
```

**On Logout:**
- Mark token as inactive (`is_active = false`)
- Optionally delete token record

## Security Considerations

### 1. Token Storage
- Tokens stored securely using GetStorage (encrypted on supported platforms)
- Never log tokens in production
- Clear tokens on logout

### 2. Token Transmission
- Always use HTTPS
- Tokens sent in Authorization header (not in URL or body for GET requests)
- Refresh tokens only sent to refresh endpoint

### 3. Device Identification
- Device ID is persistent but can be regenerated
- Device ID alone is not a security measure
- Always verify token validity on backend

### 4. Session Management
- Only one active session per user
- New login invalidates previous sessions
- Backend is source of truth for active sessions

## Testing

### Test Scenarios

1. **Normal Login Flow**
   - Login from Device A
   - Verify session initialized
   - Make API requests
   - Verify requests succeed

2. **New Device Login**
   - Login from Device A
   - Login from Device B
   - Verify Device A receives 401 on next request
   - Verify Device A is logged out
   - Verify Device B can make requests

3. **Token Expiration**
   - Login successfully
   - Wait for token to expire (or manually expire)
   - Make API request
   - Verify token refresh is attempted
   - Verify request succeeds after refresh

4. **Token Refresh Failure**
   - Login successfully
   - Invalidate refresh token on backend
   - Wait for access token to expire
   - Make API request
   - Verify forced logout occurs

5. **Concurrent Requests**
   - Login successfully
   - Make multiple simultaneous requests
   - Expire token during requests
   - Verify only one refresh attempt occurs
   - Verify all requests eventually succeed or fail appropriately

## Migration Guide

### For Existing Users

1. On next login, device information will be sent
2. Backend will create new token with device ID
3. Old tokens without device ID can be marked inactive
4. Users will be logged out if they don't re-login

### Backward Compatibility

- Frontend supports APIs that don't return device_id
- Frontend supports APIs that only return `token` (not `access_token`/`refresh_token`)
- Session management gracefully handles missing device info

## Troubleshooting

### Issue: User logged out unexpectedly
- Check if another device logged in
- Check token expiration time
- Check backend logs for token validation errors

### Issue: Multiple refresh attempts
- Verify `_isRefreshing` flag is working
- Check for race conditions in concurrent requests
- Review retry logic in ApiService

### Issue: Session not invalidated
- Verify backend is checking device_id
- Verify backend is invalidating old tokens on new login
- Check session initialization in login flow

## Future Enhancements

1. **Device Management UI**
   - Show list of active devices
   - Allow users to revoke specific devices
   - Show device information (platform, last active)

2. **Biometric Authentication**
   - Use device biometrics for faster login
   - Store encrypted tokens in secure storage

3. **Token Rotation**
   - Rotate refresh tokens on each refresh
   - Implement token family tracking
   - Detect token reuse attacks

4. **Session Analytics**
   - Track login locations
   - Detect suspicious login patterns
   - Implement rate limiting per device