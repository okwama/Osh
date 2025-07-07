# Offline-First Implementation Guide

## Overview

The Woosh app now implements a comprehensive offline-first architecture that automatically saves data to local storage (Hive/SQLite-like) when server operations fail, and syncs with the API when connectivity is restored.

## Architecture Components

### 1. Local Storage (Hive Database)

The app uses **Hive** as its local database, which provides:
- Fast, NoSQL key-value storage
- Automatic encryption support
- Cross-platform compatibility
- Type-safe storage with generated adapters

### 2. Enhanced Services

#### EnhancedSessionService (`lib/services/enhanced_session_service.dart`)
- Handles session start/end operations with offline support
- Automatically saves pending operations when server errors (500-503) occur
- Provides optimistic UI updates for immediate user feedback

```dart
// Usage Example
final response = await EnhancedSessionService.recordLogin(userId);
if (response['offline'] == true) {
  // Session saved locally, will sync when online
}
```

#### EnhancedJourneyPlanService (`lib/services/enhanced_journey_plan_service.dart`)
- Handles journey plan creation with offline support
- Saves journey plans locally when server is unavailable
- Maintains all original functionality while adding offline capabilities

```dart
// Usage Example
final journeyPlan = await EnhancedJourneyPlanService.createJourneyPlan(
  clientId, dateTime, notes: notes, routeId: routeId);
if (journeyPlan == null) {
  // Saved offline, will sync when server is available
}
```

### 3. Offline Sync Service (`lib/services/offline_sync_service.dart`)

Central service that:
- Monitors network connectivity
- Automatically syncs pending operations when online
- Provides sync status and pending operations count
- Handles retry logic with exponential backoff

### 4. Hive Models for Offline Storage

#### PendingSessionModel
```dart
@HiveType(typeId: 13)
class PendingSessionModel {
  final String userId;
  final String operation; // 'start' or 'end'
  final DateTime timestamp;
  final String status; // 'pending', 'syncing', 'error'
  final String? errorMessage;
  final int retryCount;
}
```

#### PendingJourneyPlanModel
```dart
@HiveType(typeId: 8)
class PendingJourneyPlanModel {
  final int clientId;
  final DateTime date;
  final String? notes;
  final int? routeId;
  final DateTime createdAt;
  final String status; // 'pending', 'syncing', 'error'
}
```

## Implementation Details

### 1. Profile Session Management

**Before (Server-dependent):**
```dart
// Would fail completely if server was down
final response = await SessionService.recordLogin(userId);
```

**After (Offline-first):**
```dart
// Gracefully handles server failures
final response = await EnhancedSessionService.recordLogin(userId);
if (response['offline'] == true) {
  // Show orange indicator: "Session started (will sync when online)"
} else {
  // Show green indicator: "Session started successfully"
}
```

### 2. Journey Plan Creation

**Before (Server-dependent):**
```dart
// Would show error if server was down
final journeyPlan = await JourneyPlanService.createJourneyPlan(...);
```

**After (Offline-first):**
```dart
// Handles offline gracefully
final journeyPlan = await EnhancedJourneyPlanService.createJourneyPlan(...);
if (journeyPlan != null) {
  // Created successfully online
  showSnackBar("Journey plan created successfully", Colors.green);
} else {
  // Saved offline for later sync
  showSnackBar("Journey plan saved offline - will sync when online", Colors.orange);
}
```

### 3. Automatic Sync Process

The sync process runs automatically when:
1. **App comes online** - Connectivity monitor detects network restoration
2. **Manual trigger** - User taps "Sync Now" button
3. **Periodic checks** - Background service checks for failed operations

**Sync Priority Order:**
1. **Session operations** (most critical for user state)
2. **Journey plan creation**
3. **Product reports**

### 4. User Interface Indicators

#### OfflineSyncIndicator Widget
Shows real-time sync status:
- **🔵 Blue**: Currently syncing
- **🟠 Orange**: Items pending sync (online)
- **🔴 Red**: Items saved offline (no connection)

```dart
// Usage in any page
Column(
  children: [
    const OfflineSyncIndicator(), // Shows sync status
    // ... rest of your page content
  ],
)
```

## Error Handling Strategy

### Server Errors (500-503)
- **Action**: Save operation locally
- **User Feedback**: "Operation saved offline - will sync when online"
- **Retry**: Automatic when connectivity restored

### Network Errors
- **Action**: Save operation locally
- **User Feedback**: "No internet connection - operation saved offline"
- **Retry**: Automatic when connectivity restored

### Validation Errors (400, 422)
- **Action**: Show error to user immediately
- **User Feedback**: Specific validation message
- **Retry**: No automatic retry (user must fix and resubmit)

### Authentication Errors (401, 403)
- **Action**: Redirect to login
- **User Feedback**: "Session expired - please log in again"
- **Retry**: No automatic retry

## Benefits

### 1. **Improved User Experience**
- ✅ Operations never "fail" from user perspective
- ✅ Immediate feedback with optimistic UI updates
- ✅ Clear indication of sync status
- ✅ No data loss due to connectivity issues

### 2. **Reliability**
- ✅ Works completely offline for core operations
- ✅ Automatic sync when connectivity restored
- ✅ Retry logic for failed operations
- ✅ Data persistence across app restarts

### 3. **Performance**
- ✅ Faster perceived performance (optimistic updates)
- ✅ Reduced server load (fewer retry attempts)
- ✅ Better handling of intermittent connectivity

## Usage Examples

### 1. Profile Page Session Toggle

```dart
// In profile.dart
try {
  final response = await EnhancedSessionService.recordLogin(userId);
  
  setState(() => isSessionActive = true);
  
  final message = response['offline'] == true 
      ? 'Session started (will sync when online)'
      : 'Session started successfully';
  final color = response['offline'] == true ? Colors.orange : Colors.green;
  
  Get.snackbar('Success', message, colorText: color);
} catch (e) {
  // Only non-server errors reach here
  Get.snackbar('Error', 'Failed to start session', colorText: Colors.red);
}
```

### 2. Journey Plan Creation

```dart
// In createJourneyplan.dart
try {
  final newJourneyPlan = await EnhancedJourneyPlanService.createJourneyPlan(
    clientId, date, notes: notes, routeId: routeId);

  if (newJourneyPlan != null) {
    // Successfully created online
    showSuccessMessage("Journey plan created successfully");
    if (onSuccess != null) onSuccess([newJourneyPlan]);
  } else {
    // Saved offline (server error)
    showOfflineMessage("Journey plan saved offline - will sync when online");
  }
  
  Navigator.pop(context);
} catch (e) {
  // Only non-server errors (validation, etc.)
  showErrorMessage("Failed to create journey plan: $e");
}
```

## Testing the Implementation

### 1. **Test Server Errors**
- Temporarily modify API base URL to cause 500 errors
- Verify operations save locally and show offline indicators
- Restore correct URL and verify automatic sync

### 2. **Test Network Disconnection**
- Turn off WiFi/mobile data
- Perform operations and verify they save locally
- Restore connection and verify automatic sync

### 3. **Test Mixed Scenarios**
- Create some operations online, some offline
- Verify sync processes all pending operations correctly
- Check that no duplicate operations are created

## Monitoring and Debugging

### 1. **Sync Status Monitoring**
```dart
final syncService = OfflineSyncService.instance;
final pendingCounts = syncService.getPendingOperationsCount();
print('Pending: Sessions=${pendingCounts['sessions']}, '
      'Plans=${pendingCounts['journeyPlans']}, '
      'Reports=${pendingCounts['reports']}');
```

### 2. **Manual Sync Trigger**
```dart
await OfflineSyncService.instance.forcSync();
```

### 3. **Check Offline Data**
```dart
final pendingSessions = await EnhancedSessionService.getPendingOperations(userId);
final pendingPlans = await EnhancedJourneyPlanService.getPendingJourneyPlans();
```

## Future Enhancements

1. **Conflict Resolution**: Handle cases where data changed on server while offline
2. **Partial Sync**: Sync individual operations rather than all-or-nothing
3. **Background Sync**: Use background tasks for sync when app is closed
4. **Data Compression**: Compress offline data for storage efficiency
5. **Sync History**: Track sync operations for debugging and analytics

## Conclusion

This offline-first implementation ensures that the Woosh app provides a reliable, fast, and user-friendly experience regardless of network conditions. Users can continue working normally even when servers are down or connectivity is poor, with automatic synchronization when conditions improve. 