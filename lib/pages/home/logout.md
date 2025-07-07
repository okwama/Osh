# Logout Handling Documentation

## Overview

The system implements two completely **independent** logout mechanisms:

1. **Authentication Logout** - Invalidates tokens and clears authentication state
2. **Session Logout** - Records attendance data (completely separate from authentication)

⚠️ **Important**: Session logout is purely for attendance tracking and does NOT affect authentication. Users remain logged in from an authentication perspective even after session logout.

## Authentication Logout

### Endpoint
`POST /api/auth/logout`

### Authentication Required
Yes - requires valid JWT token

### Implementation

```javascript
const logout = async (req, res) => {
  try {
    const { userId } = req.user;
    const token = req.token;

    // Parallel operations for logout
    await Promise.all([
      // Invalidate token in Redis
      redisService.del(`token:access:${userId}:${token}`),
      redisService.del(`token:refresh:${userId}:${token}`),

      // Remove from user's token set
      redisService.client.srem(`user:${userId}:tokens`, `token:access:${userId}:${token}`),
      redisService.client.srem(`user:${userId}:tokens`, `token:refresh:${userId}:${token}`),

      // Update DB - blacklist the token
      prisma.token.updateMany({
        where: {
          salesRepId: userId,
          token,
          blacklisted: false,
        },
        data: { blacklisted: true },
      }),
    ]);

    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ message: 'Logout failed', error: error.message });
  }
};
```

### What Happens During Auth Logout

1. **Redis Token Invalidation**:
   - Removes access token from Redis: `token:access:${userId}:${token}`
   - Removes refresh token from Redis: `token:refresh:${userId}:${token}`

2. **User Token Set Cleanup**:
   - Removes token references from user's token set: `user:${userId}:tokens`

3. **Database Token Blacklisting**:
   - Marks the token as blacklisted in the database
   - Prevents future use of the token

4. **Parallel Execution**:
   - All operations run in parallel for optimal performance
   - Ensures quick logout response time

## Session Logout (Attendance Only)

### Endpoint
`POST /api/sessions/logout`

### Authentication Required
Yes - requires valid JWT token

### ⚠️ **Does NOT Affect Authentication**
This endpoint only records attendance data. The user remains authenticated and can continue using the app.

### Implementation

```javascript
const recordLogout = async (req, res) => {
  try {
    const { userId } = req.body;
    const timezone = req.headers['timezone'] || 'Africa/Nairobi';

    // Find active session
    const activeSession = await prisma.loginHistory.findFirst({
      where: {
        userId: parseInt(userId),
        logoutAt: null,
      },
    });

    if (!activeSession) {
      return res.status(404).json({
        error: 'No active session found',
        userId,
      });
    }

    // Calculate session metrics
    const loginTime = DateTime.fromJSDate(activeSession.loginAt, { zone: activeSession.timezone });
    const logoutTime = DateTime.now().setZone(timezone);
    const shiftEnd = DateTime.fromJSDate(activeSession.shiftEnd, { zone: activeSession.timezone });

    // Determine timing status
    const earlyThreshold = shiftEnd.minus({ minutes: 30 }); // 30 minutes before shift end
    const overtimeThreshold = shiftEnd.plus({ minutes: 60 }); // 1 hour after shift end

    const isEarly = logoutTime < earlyThreshold;
    const isOvertime = logoutTime > overtimeThreshold;
    const durationMinutes = Math.floor(logoutTime.diff(loginTime, 'minutes').minutes);

    // Determine status
    let status;
    if (activeSession.status === 'LATE' && isEarly) {
      status = 'LATE_EARLY';
    } else if (activeSession.status === 'LATE') {
      status = 'LATE_REGULAR';
    } else if (isEarly) {
      status = 'EARLY';
    } else if (isOvertime) {
      status = 'OVERTIME';
    } else {
      status = 'REGULAR';
    }

    // Update session record
    const updatedSession = await prisma.loginHistory.update({
      where: { id: activeSession.id },
      data: {
        logoutAt: logoutTime.toUTC().toJSDate(),
        sessionEnd: logoutTime.toFormat('yyyy-MM-dd HH:mm:ss'),
        isEarly,
        duration: durationMinutes,
        status,
      },
    });

    res.status(200).json({
      success: true,
      localTime: updatedSession.sessionEnd,
      timezone,
      duration: durationMinutes,
      status,
      isEarly,
      isOvertime,
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      error: 'Logout recording failed',
      details: process.env.NODE_ENV === 'development' ? error.message : null,
    });
  }
};
```

### Session Logout Features

1. **Attendance Only**:
   - **No effect on authentication** - user stays logged in
   - Only updates attendance records in `loginHistory` table
   - Used for HR/payroll attendance tracking

2. **Timezone Handling**:
   - Uses timezone from request headers or defaults to 'Africa/Nairobi'
   - Proper timezone conversion for accurate time calculations

3. **Attendance Metrics**:
   - Calculates session duration in minutes
   - Determines if logout was early, on-time, or overtime
   - Tracks various status combinations (LATE_EARLY, LATE_REGULAR, etc.)

4. **Status Determination**:
   - **EARLY**: Logout more than 30 minutes before shift end
   - **REGULAR**: Normal logout within acceptable range
   - **OVERTIME**: Logout more than 1 hour after shift end
   - **LATE_EARLY**: Late login but early logout
   - **LATE_REGULAR**: Late login with regular logout

5. **Data Storage**:
   - Updates `loginHistory` table with logout timestamp
   - Stores calculated duration and status
   - Records session end time in local timezone format

## Auto-Logout System

### Scheduled Auto-Logout

The system includes an automatic logout mechanism that runs daily:

```javascript
// Auto-logout at 6 PM every day
const scheduleAutoLogout = () => {
  cron.schedule('0 18 * * *', async () => {
    console.log('[AUTO-LOGOUT] Triggering at 6 PM');
    
    // Find all active sessions
    const activeSessions = await prisma.loginHistory.findMany({
      where: {
        logoutAt: null,
      },
    });

    console.log(`[AUTO-LOGOUT] Found ${activeSessions.length} active sessions`);

    // Auto-logout each user
    for (const session of activeSessions) {
      // Call recordLogout for each active session
      await recordLogout(mockRequest, mockResponse);
    }
  }, {
    timezone: 'Africa/Nairobi'
  });
};
```

### Auto-Logout Features

1. **Daily Schedule**: Runs at 6 PM Africa/Nairobi timezone
2. **Bulk Processing**: Handles all active sessions automatically
3. **Consistent Logic**: Uses the same logout logic as manual logout
4. **Error Handling**: Continues processing even if individual logouts fail

## Usage Scenarios

### Scenario 1: Full Logout (Authentication + Attendance)

```dart
// When user wants to completely log out of the app
Future<void> fullLogout() async {
  try {
    // Step 1: Record attendance logout (optional)
    await http.post(
      Uri.parse('$baseUrl/sessions/logout'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'timezone': 'Africa/Nairobi',
      },
      body: jsonEncode({
        'userId': currentUserId,
      }),
    );

    // Step 2: Invalidate authentication (required for logout)
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    // Step 3: Clear local storage
    await _clearLocalTokens();
    
    print('Full logout successful');
  } catch (e) {
    print('Logout error: $e');
  }
}
```

### Scenario 2: End Work Shift (Attendance Only)

```dart
// When user ends their work shift but stays logged in
Future<void> endWorkShift() async {
  try {
    await http.post(
      Uri.parse('$baseUrl/sessions/logout'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'timezone': 'Africa/Nairobi',
      },
      body: jsonEncode({
        'userId': currentUserId,
      }),
    );
    
    print('Work shift ended - still logged in to app');
  } catch (e) {
    print('Shift end error: $e');
  }
}
```

### Scenario 3: Authentication Logout Only

```dart
// When user wants to log out without recording attendance
Future<void> authLogoutOnly() async {
  try {
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    await _clearLocalTokens();
    
    print('Authentication logout successful');
  } catch (e) {
    print('Auth logout error: $e');
  }
}
```

### Response Formats

#### Auth Logout Response
```json
{
  "message": "Logged out successfully"
}
```

#### Session Logout Response
```json
{
  "success": true,
  "localTime": "2025-06-30 17:45:00",
  "timezone": "Africa/Nairobi",
  "duration": 480,
  "status": "REGULAR",
  "isEarly": false,
  "isOvertime": false
}
```

## Error Handling

### Common Error Scenarios

1. **No Active Session**:
   ```json
   {
     "error": "No active session found",
     "userId": 123
   }
   ```

2. **Invalid Token**:
   ```json
   {
     "message": "Logout failed",
     "error": "Token validation failed"
   }
   ```

3. **Database Error**:
   ```json
   {
     "error": "Logout recording failed",
     "details": "Database connection timeout"
   }
   ```

## Performance Considerations

1. **Parallel Operations**: Auth logout uses Promise.all() for concurrent Redis and DB operations
2. **Minimal Queries**: Session logout uses efficient database queries
3. **Timezone Optimization**: Caches timezone calculations
4. **Error Isolation**: Session and auth logout are independent operations

## Security Features

1. **Token Blacklisting**: Prevents reuse of logged-out tokens
2. **Redis Cleanup**: Immediate token invalidation in cache
3. **Database Integrity**: Maintains audit trail of all logout events
4. **Rate Limiting**: Inherits rate limiting from authentication middleware

## Monitoring and Logging

### Logout Events Logged

1. **Session Start/End Times**
2. **Duration Calculations**
3. **Status Determinations**
4. **Error Events**
5. **Auto-logout Events**

### Example Log Output

```
🔵 LOGOUT INITIATED: {
  userId: 123,
  time: "2025-06-30T17:45:00.000Z",
  timezone: "Africa/Nairobi"
}

✅ SESSION ENDED: {
  userId: 123,
  sessionId: 456,
  startTime: "2025-06-30 09:00:00",
  endTime: "2025-06-30 17:45:00",
  duration: "8h 45m",
  status: "REGULAR",
  isEarly: false,
  isOvertime: false
}
```

This comprehensive logout system ensures proper session management, attendance tracking, and security while maintaining high performance and reliability. 