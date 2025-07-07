# Session Status System (0-1 Only)

## Overview
The session system now uses a simplified status approach with only two states: 0 (Inactive) and 1 (Active). Complete sessions are determined by having both `sessionStart` and `sessionEnd` timestamps.

## Status Values

| Status | Description | When Set |
|--------|-------------|----------|
| `'0'` | **Inactive** | Default state, session ended, or no active session |
| `'1'` | **Active** | Session is currently active and running |

## Session Types

### 1. Active Session
- **Status**: `'1'`
- **Criteria**: `status = '1'`
- **Usage**: Currently working session

### 2. Complete Session
- **Status**: `'0'` (after ending)
- **Criteria**: `sessionStart IS NOT NULL AND sessionEnd IS NOT NULL`
- **Usage**: Finished work sessions with both start and end times

### 3. Incomplete Session
- **Status**: `'0'`
- **Criteria**: Missing either `sessionStart` or `sessionEnd`
- **Usage**: Abandoned or interrupted sessions

## Implementation

### Session Detection
```sql
-- Get current active session
WHERE userId = ? AND status = '1'

-- Get complete sessions
WHERE userId = ? AND sessionStart IS NOT NULL AND sessionEnd IS NOT NULL
```

### Code Logic
```dart
// Check if session is active
bool get isActive => status == '1';

// Check if session is complete
bool get isComplete => sessionStart != null && sessionEnd != null;
```

## Session Lifecycle

```
Initial State: 0 (Inactive)
    ↓
Start Session: 1 (Active)
    ↓
End Session: 0 (Inactive) + Complete (if both start/end times set)
    ↓
Ready for next session...
```

## Database Operations

### Starting Session
```sql
INSERT INTO LoginHistory (
  userId, loginAt, sessionStart, status, isLate
) VALUES (?, ?, ?, '1', 0)
```

### Ending Session
```sql
UPDATE LoginHistory 
SET logoutAt = ?, sessionEnd = ?, status = '0'
WHERE id = ? AND logoutAt IS NULL
```

## Statistics

The system now tracks:
- **Total Sessions**: All session records
- **Active Sessions**: `status = '1'`
- **Inactive Sessions**: `status = '0'`
- **Complete Sessions**: `sessionStart IS NOT NULL AND sessionEnd IS NOT NULL`
- **Late Sessions**: `isLate = 1`

## Benefits

1. **Simplified Logic**: Only 0 and 1 states
2. **Clear Completion**: Complete sessions have both start and end times
3. **Consistent Checking**: All session state checks use status field
4. **Better Tracking**: Separate tracking for active, inactive, and complete sessions
5. **Future Proof**: Easy to extend with additional status values if needed

## Migration Notes

- Removed status `'2'` from the system
- Updated all session detection to use `status = '1'` instead of `logoutAt IS NULL`
- Added `isComplete` property to Session model
- Updated statistics to include complete session counts 