# Token Refresh Functionality Documentation

## Overview

This document provides comprehensive documentation of the token refresh functionality implemented in the Whoosh Flutter application. The system implements a secure JWT-based authentication pattern with automatic token refresh, ensuring seamless user experience while maintaining security.

## Architecture Overview

### Token Types
- **Access Token**: Short-lived JWT token (typically 15-60 minutes) used for API authentication
- **Refresh Token**: Long-lived token (typically 7-30 days) used to obtain new access tokens
- **Token Expiry**: Local timestamp tracking when the access token expires

### Key Components

1. **TokenService** - Centralized token management and storage
2. **ApiService** - API communication with automatic token refresh
3. **AuthController** - Authentication state management
4. **SessionService** - Session handling and validation
5. **GlobalErrorHandler** - Unified error handling for auth failures

## Implementation Details

### 1. TokenService (`lib/services/token_service.dart`)

**Purpose**: Centralized token management using GetStorage for persistent storage

**Storage Keys**:
- `access_token` - Current JWT access token
- `refresh_token` - Long-lived refresh token
- `token_expiry` - ISO 8601 timestamp of token expiration

**Core Methods**:

```dart
// Store tokens after successful authentication
static Future<void> storeTokens({
  required String accessToken,
  required String refreshToken,
  int? expiresIn, // seconds until expiration
}) async

// Retrieve current access token
static String? getAccessToken()

// Retrieve refresh token for token renewal
static String? getRefreshToken()

// Check if current token has expired
static bool isTokenExpired()

// Clear all stored tokens (logout)
static Future<void> clearTokens() async

// Check if user has valid authentication
static bool isAuthenticated()
```

**Token Expiration Logic**:
```dart
static bool isTokenExpired() {
  final box = GetStorage();
  final expiryString = box.read<String>(_tokenExpiryKey);
  if (expiryString == null) return true;

  final expiryTime = DateTime.parse(expiryString);
  return DateTime.now().isAfter(expiryTime);
}
```

### 2. ApiService Token Refresh (`lib/services/api_service.dart`)

**Automatic Token Refresh Flow**:

```dart
// Main refresh method
static Future<bool> refreshAccessToken() async {
  try {
    final refreshToken = TokenService.getRefreshToken();
    if (refreshToken == null) {
      print('No refresh token available');
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Store new access token while keeping refresh token
      await TokenService.storeTokens(
        accessToken: data['accessToken'],
        refreshToken: refreshToken, // Keep existing refresh token
        expiresIn: data['expiresIn'],
      );
      
      return true;
    }
    
    return false;
  } catch (e) {
    print('Error refreshing token: $e');
    return false;
  }
}
```

**Concurrent Refresh Prevention**:
```dart
static bool _isRefreshing = false;
static Future<bool>? _refreshFuture;

static Future<bool> _refreshToken() async {
  if (_isRefreshing) {
    // Wait for existing refresh to complete
    final result = await _refreshFuture;
    return result ?? false;
  }

  _isRefreshing = true;
  _refreshFuture = Future<bool>(() async {
    try {
      final refreshed = await refreshAccessToken();
      return refreshed;
    } finally {
      _isRefreshing = false;
    }
  });

  return await _refreshFuture!;
}
```

**Automatic Header Preparation**:
```dart
static Future<Map<String, String>> _headers([String? additionalContentType]) async {
  try {
    final token = _getAuthToken();
    
    // Check if token needs refresh before making request
    if (await _shouldRefreshToken()) {
      print('🔄 Token needs refresh, attempting...');
      final refreshed = await _refreshToken();
      if (!refreshed) {
        print('❌ Token refresh failed');
        await logout();
        throw Exception("Session expired. Please log in again.");
      }
      print('✅ Token refreshed successfully');
    }

    return {
      'Content-Type': additionalContentType ?? 'application/json',
      'Authorization': 'Bearer $token',
    };
  } catch (e) {
    print('❌ Error preparing headers: $e');
    rethrow;
  }
}
```

### 3. Response Handling with Auto-Refresh

**401 Response Handling**:
```dart
static Future<dynamic> _handleResponse(http.Response response) async {
  if (response.statusCode == 401) {
    // Try to refresh token first
    final refreshed = await refreshAccessToken();
    if (!refreshed) {
      // Refresh failed, clear all tokens and logout
      await TokenService.clearTokens();
      
      // Clear other stored data
      final box = GetStorage();
      await box.remove('salesRep');

      // Force logout and redirect to login
      final authController = Get.find<AuthController>();
      await authController.logout();
      Get.offAllNamed('/login');

      throw Exception("Session expired. Please log in again.");
    }
    // If refresh succeeded, the original request should be retried
    throw Exception("Token refreshed, retry request");
  }
  return response;
}
```

### 4. SessionService Integration (`lib/services/session_service.dart`)

**Enhanced Auth Headers**:
```dart
static Future<Map<String, String>> _getAuthHeaders() async {
  final headers = {'Content-Type': 'application/json'};

  // Check if token is expired and refresh if needed
  if (TokenService.isTokenExpired()) {
    final refreshed = await ApiService.refreshAccessToken();
    if (!refreshed) {
      throw Exception('Authentication required');
    }
  }

  final accessToken = TokenService.getAccessToken();
  if (accessToken != null) {
    headers['Authorization'] = 'Bearer $accessToken';
  }

  return headers;
}
```

## API Endpoints

### Authentication Endpoints

#### 1. Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "phoneNumber": "1234567890",
  "password": "password123"
}

Response:
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 900,
  "salesRep": {
    "id": 1,
    "name": "John Doe",
    "phoneNumber": "1234567890"
  }
}
```

#### 2. Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Response:
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 900
}
```

#### 3. Logout
```http
POST /api/auth/logout
Authorization: Bearer <accessToken>

Response:
{
  "success": true,
  "message": "Logged out successfully"
}
```

## User Experience Flow

### 1. Initial Login Process
1. User enters phone number and password
2. App calls `/api/auth/login` endpoint
3. Server validates credentials and returns tokens
4. `TokenService.storeTokens()` stores both tokens securely
5. User is navigated to home screen
6. All subsequent API calls use stored access token

### 2. Normal API Request Flow
1. App makes API request (e.g., fetch clients)
2. `ApiService._headers()` is called automatically
3. System checks if access token is expired
4. If valid, request proceeds with current token
5. If expired, automatic refresh is triggered
6. Original request is retried with new token
7. User sees seamless experience with no interruption

### 3. Token Refresh Flow
1. Access token expires (typically after 15-60 minutes)
2. Next API call detects expiration via `TokenService.isTokenExpired()`
3. `ApiService.refreshAccessToken()` is called automatically
4. App sends refresh token to `/api/auth/refresh`
5. Server validates refresh token and returns new access token
6. New token is stored via `TokenService.storeTokens()`
7. Original API request is retried with new token
8. User continues using app without interruption

### 4. Error Handling Flow
1. API returns 401 Unauthorized response
2. `ApiService._handleResponse()` catches the 401
3. System attempts token refresh automatically
4. If refresh succeeds, original request is retried
5. If refresh fails (refresh token expired/invalid):
   - All tokens are cleared via `TokenService.clearTokens()`
   - User data is cleared from storage
   - User is logged out and redirected to login screen
   - User-friendly error message is displayed

## Security Features

### 1. Token Validation
- **Access Token Validation**: Validated on every API request
- **Refresh Token Validation**: Validated only during refresh attempts
- **Server-side Blacklisting**: Both tokens can be invalidated server-side
- **Local Expiration Tracking**: Prevents unnecessary API calls with expired tokens

### 2. Token Storage Security
- **GetStorage**: Uses Flutter's secure storage solution
- **Token Separation**: Access and refresh tokens stored separately
- **Automatic Cleanup**: Expired tokens are automatically cleared
- **Logout Cleanup**: All tokens cleared on logout

### 3. Concurrent Request Handling
- **Refresh Lock**: Prevents multiple simultaneous refresh attempts
- **Request Queuing**: Concurrent requests wait for refresh to complete
- **Race Condition Prevention**: Ensures only one refresh operation at a time

### 4. Error Recovery
- **Graceful Degradation**: Failed refreshes result in clean logout
- **User Feedback**: Clear error messages for authentication issues
- **Automatic Redirect**: Seamless transition to login on auth failure

## Performance Optimizations

### 1. Token Caching
- **Local Storage**: Tokens cached in GetStorage for fast access
- **Expiration Tracking**: Local timestamp prevents unnecessary API calls
- **Minimal Network Calls**: Refresh only when token is actually expired

### 2. Request Optimization
- **Header Caching**: Auth headers prepared once per request
- **Concurrent Handling**: Multiple requests share single refresh operation
- **Error Recovery**: Failed requests automatically retry after refresh

### 3. User Experience
- **Seamless Refresh**: Users don't see refresh process
- **No Interruption**: App continues working during token refresh
- **Fast Response**: Local token validation before API calls

## Testing and Debugging

### 1. Token State Testing
```dart
// Test current authentication state
print('Is authenticated: ${TokenService.isAuthenticated()}');
print('Access token present: ${TokenService.getAccessToken() != null}');
print('Refresh token present: ${TokenService.getRefreshToken() != null}');
print('Token expired: ${TokenService.isTokenExpired()}');
```

### 2. Manual Refresh Testing
```dart
// Test token refresh manually
final refreshed = await ApiService.refreshAccessToken();
print('Refresh result: $refreshed');
```

### 3. API Call Testing
```dart
// Test API call with automatic refresh
try {
  final clients = await ApiService.fetchClients(limit: 1);
  print('API call successful: ${clients.data.length} clients');
} catch (e) {
  print('API call failed: $e');
}
```

## Common Issues and Solutions

### 1. Token Expiration Issues
**Problem**: Users getting logged out unexpectedly
**Solution**: Check token expiration logic and refresh timing

### 2. Concurrent Request Issues
**Problem**: Multiple refresh attempts causing errors
**Solution**: Ensure refresh lock mechanism is working properly

### 3. Network Connectivity Issues
**Problem**: Refresh fails due to network problems
**Solution**: Implement retry logic and offline handling

### 4. Storage Issues
**Problem**: Tokens not persisting between app sessions
**Solution**: Verify GetStorage initialization and permissions

## Best Practices

### 1. Token Management
- Always check token expiration before API calls
- Implement proper error handling for refresh failures
- Clear tokens on logout and authentication errors
- Use secure storage for sensitive token data

### 2. User Experience
- Provide seamless token refresh without user interruption
- Show appropriate loading states during authentication
- Handle network errors gracefully
- Provide clear feedback for authentication failures

### 3. Security
- Validate tokens on both client and server side
- Implement proper token expiration and rotation
- Handle token revocation and blacklisting
- Use HTTPS for all authentication requests

### 4. Performance
- Minimize unnecessary token refresh attempts
- Cache tokens appropriately
- Handle concurrent requests efficiently
- Implement proper error recovery mechanisms
