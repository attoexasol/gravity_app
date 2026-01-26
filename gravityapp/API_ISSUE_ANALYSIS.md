# API Issue Analysis: Update User Gravity 404 Error

## Problem Summary

The app is repeatedly getting **404 "Record not found"** errors when trying to update user gravity entries.

## Console Log Analysis

### Error Pattern
```
📤 UPDATE User Gravity Request:
   ID: 201
   Keys: [id, api_token, date, data_source, nutration, weight, steps, sleep_hours]
   Date: 2026-01-26
   Data Source: google_fit

📡 Response Status: 404
📄 Response Body: {"status":false,"message":"Record not found."}
❌ API Error: Record not found.
❌ UpdateUserGravity API Error: Record not found.
```

### What's Happening

1. **Health Sync Success**: Health data is successfully synced from Google Fit
   - Steps: 3034
   - Sleep: 8.0h
   - Weight: 75.02411651611328 kg
   - Water: 0.0 L

2. **Update Attempt**: App tries to UPDATE entry with ID 201 for date 2026-01-26

3. **404 Error**: API returns "Record not found" - meaning:
   - Record with ID 201 doesn't exist in database
   - OR record exists but for a different date
   - OR record was deleted

4. **Repeated Failures**: Error occurs multiple times (every time health sync runs)

## Root Cause

### The Problem Flow

1. **Initial Load** (`loadTodayFromDb()`):
   - App fetches all user gravity entries
   - Finds entry for today (2026-01-26) with ID 201
   - Sets `todayEntryId.value = 201`

2. **Health Sync Trigger**:
   - Health sync completes successfully
   - Triggers `upsertTodayGravity(dataSource: 'google_fit')`

3. **Update Decision**:
   - Code checks: `if (todayEntryId.value != null)` → TRUE (ID is 201)
   - Decides to UPDATE instead of CREATE

4. **Update Fails**:
   - API returns 404 because record 201 doesn't exist for date 2026-01-26
   - Possible reasons:
     - Record was deleted from database
     - ID is stale (from previous day/session)
     - Date mismatch between app and database
     - Database was reset/cleared

5. **No Fallback**:
   - App doesn't handle 404 error
   - Doesn't retry as CREATE
   - `todayEntryId` remains 201 (stale)
   - Next sync will fail again with same error

## Why This Happens

### Scenario 1: Stale ID Cache
- User had entry with ID 201 for a previous date
- Entry was deleted or date changed
- App still has ID 201 cached in `todayEntryId`
- Tries to update non-existent record

### Scenario 2: Database Cleanup
- Admin/backend deleted old entries
- App still has cached IDs
- Update fails because record no longer exists

### Scenario 3: Date Mismatch
- Entry exists with ID 201 but for different date
- App thinks it's for today (2026-01-26)
- Update fails because date doesn't match

### Scenario 4: Race Condition
- Multiple health syncs happening simultaneously
- First one creates entry, gets ID 201
- Second one tries to update ID 201 but it was deleted/updated
- 404 error occurs

## Impact

- ❌ Health sync data is NOT saved to database
- ❌ User's daily progress is lost
- ❌ Repeated error logs clutter console
- ❌ Poor user experience (data not persisting)
- ❌ Wasted API calls

## Solution Required

### Fix Strategy: Upsert with Fallback

When UPDATE fails with 404, automatically fallback to CREATE:

1. **Detect 404 Error**: Check if response is 404 "Record not found"
2. **Clear Stale ID**: Set `todayEntryId.value = null`
3. **Retry as CREATE**: Call `createUserGravity()` instead
4. **Update State**: Set new ID from create response

### Implementation

```dart
if (todayEntryId.value != null) {
  // Try UPDATE first
  response = await _gravityRepository.updateUserGravity(...);
  
  // If 404, fallback to CREATE
  if (!response.isSuccess && 
      response.message.toLowerCase().contains('record not found')) {
    debugPrint('⚠️ Update failed with 404, falling back to CREATE');
    todayEntryId.value = null; // Clear stale ID
    response = await _gravityRepository.createUserGravity(...);
  }
} else {
  // CREATE new entry
  response = await _gravityRepository.createUserGravity(...);
}
```

## Files to Modify

1. `lib/presentation/dashboard/controllers/dashboard_controller.dart`
   - Method: `upsertTodayGravity()`
   - Add 404 fallback logic

2. Optional: `lib/data/repositories/user_gravity_repository.dart`
   - Add helper method for upsert with automatic fallback

## Testing Checklist

- [ ] Test when record doesn't exist (should CREATE)
- [ ] Test when record exists (should UPDATE)
- [ ] Test when record was deleted (should CREATE after 404)
- [ ] Test with stale ID (should CREATE after 404)
- [ ] Test multiple rapid syncs (should handle gracefully)
- [ ] Verify no duplicate entries created
- [ ] Verify data persists correctly

## Prevention

1. **Validate ID Before Update**: Check if record exists before updating
2. **Date Validation**: Ensure entry date matches today before using cached ID
3. **Periodic Refresh**: Reload today's entry ID periodically
4. **Error Recovery**: Always have fallback to CREATE on update failures
