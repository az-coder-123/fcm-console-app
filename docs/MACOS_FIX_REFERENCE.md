# macOS Downloads Folder Fix - Quick Reference

## Issue
Firebase Service Account JSON files stored in the macOS Downloads folder could not be accessed due to sandboxing restrictions, causing this error:
```
FileSystemException: Cannot access service account file. This usually happens when the file is in the Downloads folder on macOS.
```

## Solution Overview
The fix implements a three-layer approach:

### Layer 1: Intelligent File Handling
When users upload a service account JSON from the file picker:
1. Read the content immediately using `file.readAsString()` with fallback to `readAsBytes()`
2. Store a backup copy in the app's accessible directory
3. Save the JSON content directly in the database

**File:** `lib/components/profile_selector.dart` (lines 44-75)

### Layer 2: Database Persistence
The service account's full JSON content is now stored in the database, eliminating file system dependency:
1. Added new `json_content` column to `service_accounts` table
2. Updated database version from 1 to 2
3. Automatic migration for existing databases

**Files:** 
- `lib/services/database_service.dart` (migration + CRUD updates)
- `lib/core/constants.dart` (version bump)

### Layer 3: Service Usage
The `FCMService` already had support for using `jsonContent` parameter:
- When authenticating, it now always has access to the stored JSON content from the database
- No longer depends on file system access to the original file

**File:** `lib/services/fcm_service.dart` (no changes needed - already supports jsonContent)

## What Changed

### Before
```
User selects file from Downloads → Try to read from Downloads path → macOS denies access → Fails ❌
```

### After
```
User selects file from Downloads → Read content immediately ✓
→ Store JSON in database ✓ → Save copy to app directory ✓ → Future auth uses stored content ✓
→ Works offline and from any file location ✓
```

## No User Action Required
The fix is transparent to users:
1. **New Users**: Service accounts work from any location (including Downloads)
2. **Existing Users**: Database automatically migrates on first app launch
3. **File Deletion**: Service accounts continue to work even if original file is deleted

## Testing Checklist
- [ ] Upload service account from Downloads folder → Verify it saves successfully
- [ ] Send notification with uploaded service account → Verify it works
- [ ] Delete original file → Verify service account still works
- [ ] Upgrade existing app → Verify database migration completes without errors
- [ ] Check that `json_content` field is populated in database

## Technical Details

### Database Migration
```sql
-- Executed automatically on app version update
ALTER TABLE service_accounts
ADD COLUMN json_content TEXT
```

### Error Handling
The implementation includes multiple fallbacks:
1. Direct string read: `file.readAsString()`
2. Bytes read fallback: `file.readAsBytes()` → `String.fromCharCodes()`
3. Local copy backup: Always saved to app support directory
4. Non-critical copy errors: Logged but don't prevent operation

This ensures robustness across different file picker implementations and OS behaviors.
