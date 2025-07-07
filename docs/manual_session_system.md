# Standardized Session Status System

## Overview
The session status field in the `LoginHistory` table has been standardized to use consistent numeric values for better clarity and consistency.

## Status Values

| Status | Description | When Set |
|--------|-------------|----------|
| `'1'` | **Active** | When session is started (loginAt + sessionStart) |
| `'2'` | **Ended** | When session is manually ended (logoutAt + sessionEnd) |

## Implementation Details

### Database Schema
```sql
CREATE TABLE LoginHistory (
  -- ... other fields ...
  status VARCHAR(191) DEFAULT '1',  -- Standardized default
  -- ... other fields ...
);
```

### Session Lifecycle

1. **Session Start** (`status = '1'`)
   - User logs into app (`loginAt`)
   - User starts work session (`sessionStart`)
   - Status remains `'1'` until session ends

2. **Session End** (`status = '2'`)
   - User manually ends work session (`sessionEnd`)
   - User logs out of app (`logoutAt`)
   - Status updated to `'2'`

### Code Implementation

#### Starting Session
```dart
const sql = '''
  INSERT INTO LoginHistory (
    userId, loginAt, sessionStart, status, isLate
  ) VALUES (?, ?, ?, '1', 0)
''';
```

#### Ending Session
```dart
const sql = '''
  UPDATE LoginHistory 
  SET logoutAt