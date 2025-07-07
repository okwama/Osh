# Secure Authentication Storage Documentation

## Overview
This document outlines the authentication storage strategy for the Woosh Flutter application, providing guidelines for both client-side and server-side implementation to ensure secure session management.

## Client-Side Storage Strategy

### 1. Sensitive Data Storage (GetStorage - Encrypted)
**Location**: `GetStorage()` - Local encrypted storage
**Purpose**: Store authentication tokens and user session data

#### Authentication Data (Cleared on Logout)
```dart
// Primary authentication tokens
'authToken'         // Main authentication token
'accessToken'       // OAuth/JWT access token  
'refreshToken'      // Token for refreshing access token
'sessionId'         // Server session identifier

// User identification
'userId'            // User's unique identifier
'salesRep'          // Sales representative data (contains sensitive info)
'userCredentials'   // Any cached credential data
'userSession'       // Session-specific user data
'loginTime'         // When user logged in (for session timeout)
```

### 2. Non-Sensitive Data Storage (Preserved on Logout)
**Location**: `GetStorage()` - Local storage
**Purpose**: Store user preferences and app configuration

#### Preserved Data (NOT cleared on logout)
```dart
// User preferences
'themeMode'         // Light/dark theme preference
'language'          // User's preferred language
'fontSize'          // Accessibility font size settings
'notificationSettings' // Push notification preferences

// App configuration
'apiBaseUrl'        // API endpoint configuration
'appVersion'        // Last known app version
'cacheExpiry'       // Cache expiration settings
'offlineMode'       // Offline mode preferences

// Non-sensitive cached data
'productCategories' // Product category cache
'regions'           // Available regions cache
'countries'         // Countries list cache
'currencies'        // Currency information
```

### 3. Hive Storage (Session-Specific)
**Location**: Hive boxes
**Purpose**: Offline-first data storage

#### Cleared on Logout
```dart
// Session data
SessionHiveService.clearSession()           // Current session info
PendingSessionHiveService.clearAllPendingSessions() // Offline session data

// User-specific cached data
CartHiveService.clearCart()                 // Shopping cart items
```

#### Preserved on Logout
```dart
// Non-sensitive cached data (preserved for performance)
ProductHiveService (products cache)         // Product catalog
ClientHiveService (non-sensitive client data) // Client information
RouteHiveService (routes cache)             // Available routes
```

## Server-Side Authentication Requirements

### 1. Session Management Endpoints

#### Logout Endpoint
```http
POST /api/logout
Authorization: Bearer {access_token}
Content-Type: application/json

Request Body:
{
  "sessionId": "string",
  "deviceId": "string" // Optional: for device-specific logout
}

Response:
{
  "success": boolean,
  "message": "string",
  "timestamp": "ISO8601 datetime"
}
```

#### Token Refresh Endpoint
```http
POST /api/auth/refresh
Content-Type: application/json

Request Body:
{
  "refreshToken": "string",
  "userId": "string"
}

Response:
{
  "accessToken": "string",
  "refreshToken": "string", // New refresh token
  "expiresIn": number,      // Seconds until expiration
  "tokenType": "Bearer"
}
```

### 2. Session Validation
```http
GET /api/auth/validate
Authorization: Bearer {access_token}

Response:
{
  "valid": boolean,
  "userId": "string",
  "sessionId": "string",
  "expiresAt": "ISO8601 datetime",
  "permissions": ["string"] // User permissions/roles
}
```

## Security Best Practices

### 1. Token Management
- **Access Token Lifetime**: 15-60 minutes
- **Refresh Token Lifetime**: 7-30 days
- **Session Timeout**: 24 hours of inactivity
- **Token Rotation**: Issue new refresh token on each refresh

### 2. Server-Side Session Storage
```json
{
  "sessionId": "uuid",
  "userId": "string",
  "deviceId": "string",
  "ipAddress": "string",
  "userAgent": "string",
  "createdAt": "datetime",
  "lastActivity": "datetime",
  "expiresAt": "datetime",
  "isActive": boolean,
  "permissions": ["string"]
}
```

### 3. Logout Security Flow
1. **Client initiates logout** with current session token
2. **Server validates token** and marks session as inactive
3. **Server blacklists tokens** (both access and refresh)
4. **Server responds with confirmation**
5. **Client clears authentication data** (regardless of server response)
6. **Client preserves non-sensitive preferences**

## Implementation Checklist

### Client-Side Security
- [ ] Implement selective data clearing on logout
- [ ] Preserve user preferences and app settings
- [ ] Handle server logout failures gracefully
- [ ] Clear all authentication tokens
- [ ] Clear session-specific Hive data
- [ ] Implement proper error handling

### Server-Side Security
- [ ] Implement `/api/logout` endpoint
- [ ] Token blacklisting mechanism
- [ ] Session management database
- [ ] Token refresh rotation
- [ ] Session timeout handling
- [ ] Device-specific session tracking

## Error Handling Strategy

### Network Failures During Logout
```dart
// Always perform local logout, even if server is unreachable
try {
  await ApiService.logout(); // Attempt server logout
} catch (e) {
  print('Server logout failed: $e');
  // Continue with local logout regardless
}
// Proceed with clearing local authentication data
```

### Server Error Responses
- **5xx Errors**: Perform local logout, show warning
- **4xx Errors**: Handle based on specific error code
- **Network Timeout**: Perform local logout, show offline message

## Migration Notes

### From Current Implementation
1. **Replace** `box.erase()` with selective key removal
2. **Add** server-side logout API call
3. **Implement** proper error handling for network failures
4. **Preserve** user preferences and app settings
5. **Add** session-specific Hive data clearing

### Testing Scenarios
- [ ] Logout with network connectivity
- [ ] Logout without network connectivity
- [ ] Logout with server errors (5xx)
- [ ] Logout with invalid tokens (4xx)
- [ ] Verify preferences are preserved
- [ ] Verify authentication data is cleared
- [ ] Test session timeout scenarios

## Security Considerations

### Data Classification
- **Critical**: Authentication tokens, user credentials
- **Sensitive**: User ID, session data, personal information
- **Non-sensitive**: Preferences, app settings, public cache data

### Compliance
- Ensure compliance with data protection regulations
- Implement proper data retention policies
- Consider regional privacy laws (GDPR, CCPA, etc.)

---

**Last Updated**: Current Date
**Version**: 1.0
**Next Review**: Quarterly security review 