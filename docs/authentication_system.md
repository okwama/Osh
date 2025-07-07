# Authentication & Refresh Token System Documentation

## Overview

This API implements a secure JWT-based authentication system with automatic token refresh capabilities. The system uses a dual-token approach with short-lived access tokens and long-lived refresh tokens, providing both security and user convenience.

## Architecture

### Token Types

1. **Access Token**
   - **Lifetime**: 9 hours (32,400 seconds)
   - **Purpose**: Used for API authentication
   - **Storage**: Client-side GetStorage + Server database
   - **Type**: `access`

2. **Refresh Token**
   - **Lifetime**: 7 days
   - **Purpose**: Used to obtain new access tokens
   - **Storage**: Client-side GetStorage + Server database
   - **Type**: `refresh`

### Database Schema

```sql
-- Token table structure
model Token {
  id          Int       @id @default(autoincrement())
  token       String    -- The actual JWT token
  salesRepId  Int       -- User ID
  createdAt   DateTime  @default(now())
  expiresAt   DateTime  -- Token expiration timestamp
  blacklisted Boolean   @default(false) -- Token revocation flag
  lastUsedAt  DateTime? -- Last usage timestamp
  tokenType   String    @default("access") -- "access" or "refresh"
  user        SalesRep  @relation(fields: [salesRepId], references: [id], onDelete: Cascade)
}
```

## Authentication Flow

### 1. User Login

**Endpoint**: `POST /api/auth/login`

**Process**:
1. Validate phoneNumber and password
2. Check if user exists and account is active
3. Verify password using bcrypt
4. Generate new access and refresh tokens
5. Store tokens in database
6. Return user data and tokens

**Request**:
```json
{
  "phoneNumber": "1234567890",
  "password": "password123"
}
```

**Response**:
```json
{
  "success": true,
  "salesRep": {
    "id": 1,
    "name": "John Doe",
    "phoneNumber": "1234567890",
    "email": "john@example.com",
    "role": "SALES_REP"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 32400
}
```

### 2. Token Refresh

**Endpoint**: `POST /api/auth/refresh`

**Process**:
1. Validate refresh token from request body
2. Verify JWT signature and expiration
3. Check if token exists in database and is not blacklisted
4. Generate new access token
5. Keep existing refresh token
6. Update lastUsedAt timestamp
7. Return new access token

**Request**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response**:
```json
{
  "success": true,
  "accessToken": "new_access_token",
  "expiresIn": 32400
}
```

### 3. User Logout

**Endpoint**: `POST /api/auth/logout`

**Process**:
1. Blacklist all tokens (both access and refresh) for the user
2. Return success message

**Headers**: `Authorization: Bearer <accessToken>`

**Response**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

## Flutter Client Implementation

### 1. TokenService (`lib/services/token_service.dart`)

**Purpose**: Centralized token management using GetStorage

**Storage Keys**:
- `access_token` - Current JWT access token
- `refresh_token` - Long-lived refresh token
- `token_expiry` - ISO 8601 timestamp of token expiration

**Core Methods**:
```dart
// Store tokens after login
static Future<void> storeTokens({
  required String accessToken,
  required String refreshToken,
  int? expiresIn,
}) async

// Get access token
static String? getAccessToken()

// Get refresh token
static String? getRefreshToken()

// Check if token is expired
static bool isTokenExpired()

// Clear all tokens
static Future<void> clearTokens() async

// Check if user is authenticated
static bool isAuthenticated()
```

### 2. ApiService Authentication (`lib/services/api_service.dart`)

**Login Implementation**:
```dart
Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Store tokens using TokenService
      await TokenService.storeTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        expiresIn: data['expiresIn'],
      );

      // Store user data
      final box = GetStorage();
      box.write('salesRep', data['salesRep']);

      return {
        'success': true,
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
        'salesRep': data['salesRep']
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error occurred',
    };
  }
}
```

**Token Refresh Implementation**:
```dart
static Future<bool> refreshAccessToken() async {
  try {
    final refreshToken = TokenService.getRefreshToken();
    if (refreshToken == null) {
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
    return false;
  }
}
```

**Automatic Header Preparation**:
```dart
static Future<Map<String, String>> _headers([String? additionalContentType]) async {
  try {
    final token = _getAuthToken();
    
    // Check if token needs refresh before making request
    if (await _shouldRefreshToken()) {
      final refreshed = await _refreshToken();
      if (!refreshed) {
        await logout();
        throw Exception("Session expired. Please log in again.");
      }
    }

    return {
      'Content-Type': additionalContentType ?? 'application/json',
      'Authorization': 'Bearer $token',
    };
  } catch (e) {
    rethrow;
  }
}
```

### 3. SessionService Integration (`lib/services/session_service.dart`)

```dart
class SessionService {
  static const String baseUrl = '${Config.baseUrl}/api';

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
}
```

## Error Handling

### Authentication Errors

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `AUTH_FAILED` | 401 | Invalid credentials |
| `TOKEN_EXPIRED` | 401 | Access token has expired |
| `INVALID_TOKEN` | 401 | Invalid or malformed token |
| `TOKEN_REFRESH_FAILED` | 401 | Failed to refresh tokens |

### Common Error Responses

```json
{
  "success": false,
  "error": "Invalid credentials",
  "code": "AUTH_FAILED"
}
```

```json
{
  "success": false,
  "error": "Access token expired. Please refresh your token.",
  "code": "TOKEN_EXPIRED"
}
```

### Flutter Error Handling
```dart
static void handleNetworkError(dynamic error) {
  String errorMessage = "Unable to connect to the server";

  if (error.toString().contains('SocketException') ||
      error.toString().contains('XMLHttpRequest error') ||
      error.toString().contains('Connection timeout')) {
    errorMessage = "You're offline. Please check your internet connection.";
  } else if (error.toString().contains('TimeoutException')) {
    errorMessage = "Request timed out. Please try again.";
  } else if (error.toString().contains('500')) {
    errorMessage = "Server error. Please try again later.";
  }

  OfflineToastService.showOfflineToast(
    message: errorMessage,
    duration: const Duration(seconds: 4),
    onRetry: () {
      Get.back();
    },
  );
}
```

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

## Usage Examples

### Protecting Routes

```dart
// Check authentication before accessing protected routes
if (!TokenService.isAuthenticated()) {
  Get.offAllNamed('/login');
  return;
}
```

### Client-Side Implementation

```dart
// Login
final loginResponse = await ApiService().login(phoneNumber, password);
if (loginResponse['success'] == true) {
  // Tokens are automatically stored by TokenService
  Get.offAllNamed('/home');
} else {
  // Handle login error
  showError(loginResponse['message']);
}

// API calls with automatic refresh
try {
  final clients = await ApiService.fetchClients(limit: 10);
  // Handle successful response
} catch (e) {
  // Handle error (automatic refresh already attempted)
  handleNetworkError(e);
}
```

## Best Practices

### 1. Token Storage
- Store tokens securely using GetStorage
- Never expose tokens in URLs
- Clear tokens on logout

### 2. Error Handling
- Handle token expiration gracefully
- Implement retry logic for failed requests
- Provide clear error messages to users

### 3. Security
- Use HTTPS in production
- Implement rate limiting
- Monitor for suspicious activity
- Regular token cleanup

### 4. Performance
- Minimize database queries
- Use efficient token validation
- Implement caching where appropriate

## Troubleshooting

### Common Issues

1. **Token Expired Errors**
   - Check if refresh token is valid
   - Ensure proper token storage
   - Verify automatic refresh is working

2. **Network Connectivity Issues**
   - System falls back to JWT-only validation
   - Check database connectivity
   - Monitor token storage operations

3. **Authentication Failures**
   - Verify user credentials
   - Check account status
   - Ensure proper API endpoints

### Debug Information

Enable debug logging by setting environment variables:
```bash
DEBUG=auth:*
NODE_ENV=development
```

## API Endpoints Summary

| Method | Endpoint | Authentication | Description |
|--------|----------|----------------|-------------|
| POST | `/api/auth/login` | None | User login |
| POST | `/api/auth/refresh` | None | Token refresh |
| POST | `/api/auth/logout` | Required | User logout |

## Environment Variables

```bash
JWT_SECRET=your_jwt_secret_key_here
DATABASE_URL=your_database_connection_string
NODE_ENV=production
```

## Database Migrations

The token system requires the following database tables:
- `SalesRep` - User accounts
- `Token` - Token storage and management

Run migrations to ensure proper schema:
```bash
npx prisma migrate dev
npx prisma generate
``` 