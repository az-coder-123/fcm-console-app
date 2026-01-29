# Fix Summary: macOS Downloads Folder File Access Issue

## Problem Analysis

**Error Message:**
```
FileSystemException: Cannot access service account file. This usually happens when the file is in the Downloads folder on macOS. Please re-upload the service account JSON from Settings to fix this issue., path = '/Users/trannamlong/Downloads/isearch-social-firebase-adminsdk-zivuk-66a7670c1a.json'
```

### Root Causes

1. **macOS Sandbox Restrictions**: Files in the Downloads folder on macOS have restricted access permissions. Even though the file exists and is readable by the user, the Flutter application running in a sandbox cannot read it directly without explicit user permission.

2. **Missing Database Storage**: The `ServiceAccount` model had a `jsonContent` field designed to store the full JSON content, but the SQLite database schema only stored `filePath`. When the app tried to send notifications, it would always attempt to read from the file path first (which would fail for Downloads files) instead of using the stored JSON content.

3. **File Access Fallback**: The `FCMService` could accept `jsonContent` as a parameter, but there was no mechanism to persist it in the database or retrieve it reliably.

## Solution Implemented

### 1. **Improved File Picker Logic** (`profile_selector.dart`)

Changed the file handling to:
- **Read file content immediately** when selected (before any file system checks)
- **Store a copy** in the application support directory (which is always accessible)
- **Persist the JSON content** in the database
- **Use error handling** to gracefully handle file access issues

```dart
// Always read file content immediately to avoid permission issues on macOS
late String content;
try {
  content = await file.readAsString();
} catch (e) {
  // Fallback: read as bytes if direct read fails
  final bytes = await file.readAsBytes();
  content = String.fromCharCodes(bytes);
}

// Save a copy to application support directory for future access
final bytes = await file.readAsBytes();
final Directory appDocDir = await getApplicationSupportDirectory();
final localCopy = await File(localPath).writeAsBytes(bytes);
```

### 2. **Database Schema Enhancement** (`database_service.dart`)

Added migration to persist JSON content:
- **New column**: `json_content TEXT` in `service_accounts` table
- **Migration version**: Bumped from `1` to `2`
- **Upgrade handler**: Handles old databases gracefully with `onUpgrade` callback

```sql
ALTER TABLE service_accounts
ADD COLUMN json_content TEXT
```

### 3. **Updated CRUD Operations** (`database_service.dart`)

Modified all database operations to handle the new column:
- `createServiceAccount()`: Now saves `jsonContent`
- `getAllServiceAccounts()`: Retrieves `jsonContent` from database
- `getServiceAccount()`: Includes `jsonContent` in the result
- `updateServiceAccount()`: Updates `jsonContent` when account is modified

### 4. **Service Account Model** (`service_account.dart`)

The model already had support for `jsonContent`, but now it's properly:
- Stored in the database
- Retrieved when loading service accounts
- Passed to `FCMService` for authentication

## Benefits

1. **No More File Access Issues**: The JSON content is stored in the database and doesn't depend on the original file location
2. **Offline Support**: Service accounts work even if the original file is moved or deleted
3. **Backup**: A local copy is saved to the app's application support directory
4. **Backward Compatible**: Existing databases are automatically migrated
5. **Robust Error Handling**: Multiple fallback mechanisms ensure reliability

## Testing Recommendations

1. **Test Initial Upload**:
   - Upload a service account JSON from the Downloads folder
   - Verify it successfully saves to the database with both path and content

2. **Test Existing Data**:
   - Upgrade the app with existing service accounts
   - Verify migration runs successfully
   - Verify service accounts still work after migration

3. **Test Offline Scenario**:
   - Delete the original service account file from Downloads
   - Verify the app can still send notifications using the stored JSON content

4. **Test Fallback Paths**:
   - Test with various JSON file sources (Downloads, Documents, etc.)
   - Verify graceful error handling if file reading fails

## Files Modified

1. [lib/components/profile_selector.dart](lib/components/profile_selector.dart#L44-L75) - Improved file handling
2. [lib/services/database_service.dart](lib/services/database_service.dart) - Added migration and updated CRUD operations
3. [lib/core/constants.dart](lib/core/constants.dart#L5) - Bumped database version to 2

## Database Migration Details

The migration is automatic and handles:
- Creating the new `json_content` column for new installs
- Adding the column for existing databases via `onUpgrade`
- Graceful error handling if column already exists
