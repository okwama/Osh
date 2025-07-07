# Authentication System Implementation Guide

## Quick Setup

### Environment Variables
```bash
JWT_SECRET=your_jwt_secret_key_here
DATABASE_URL=mysql://user:password@localhost:3306/database
NODE_ENV=production
```

### Database Schema
```prisma
model Token {
  id          Int       @id @default(autoincrement())
  token       String
  salesRepId  Int
  createdAt   DateTime  @default(now())
  expiresAt   DateTime
  blacklisted Boolean   @default(false)
  lastUsedAt  DateTime?
  tokenType   String    @default("access")
  user        SalesRep  @relation(fields: [salesRepId], references: [id], onDelete: Cascade)
}
```

## Server API Endpoints

### Base URL Configuration
```dart
// Flutter client configuration
static const String baseUrl = 'http://192.168.100.2:5000'; // Development
// static const String baseUrl = 'https://woosh-api.vercel.app'; // Production
static const String apiUrl = '$baseUrl/api';
```

### 1. User Login
**Endpoint**: `POST /api/auth/login`

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
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 32400
}
```

### 3. User Logout
**Endpoint**: `POST /api/auth/logout`

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

```dart
class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  // Store tokens after login
  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
  }) async {
    final box = GetStorage();
    await box.write(_accessTokenKey, accessToken);
    await box.write(_refreshTokenKey, refreshToken);

    if (expiresIn != null) {
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
      await box.write(_tokenExpiryKey, expiryTime.toIso8601String());
    }
  }

  // Get access token
  static String? getAccessToken() {
    final box = GetStorage();
    return box.read<String>(_accessTokenKey);
  }

  // Get refresh token
  static String? getRefreshToken() {
    final box = GetStorage();
    return box.read<String>(_refreshTokenKey);
  }

  // Check if token is expired
  static bool isTokenExpired() {
    final box = GetStorage();
    final expiryString = box.read<String>(_tokenExpiryKey);
    if (expiryString == null) return true;

    final expiryTime = DateTime.parse(expiryString);
    return DateTime.now().isAfter(expiryTime);
  }

  // Clear all tokens
  static Future<void> clearTokens() async {
    final box = GetStorage();
    await box.remove(_accessTokenKey);
    await box.remove(_refreshTokenKey);
    await box.remove(_tokenExpiryKey);
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    final accessToken = getAccessToken();
    return accessToken != null && !isTokenExpired();
  }
}
```

### 2. ApiService Authentication (`lib/services/api_service.dart`)

**Login Implementation**:
```dart
Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
  try {
    print('🔐 Attempting login for: $phoneNumber');

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

      // Validate response structure
      if (data['accessToken'] == null || data['refreshToken'] == null) {
        return {
          'success': false,
          'message': 'Invalid response format: missing tokens',
        };
      }

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
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['error'] ?? 'Login failed',
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
      print('No refresh token available');
      return false;
    }

    print('Attempting to refresh access token');
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

      print('Access token refreshed successfully');
      return true;
    }

    print('Token refresh failed: ${response.body}');
    return false;
  } catch (e) {
    print('Error refreshing token: $e');
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

## Security Features

### 1. Token Validation
- **Access Token Validation**: Validated on every API request
- **Refresh Token Validation**: Validated only during refresh attempts
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

## Error Handling

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

## Testing

### Token State Testing
```dart
// Test current authentication state
print('Is authenticated: ${TokenService.isAuthenticated()}');
print('Access token present: ${TokenService.getAccessToken() != null}');
print('Refresh token present: ${TokenService.getRefreshToken() != null}');
print('Token expired: ${TokenService.isTokenExpired()}');
```

### Manual Refresh Testing
```dart
// Test token refresh manually
final refreshed = await ApiService.refreshAccessToken();
print('Refresh result: $refreshed');
```

### API Call Testing
```dart
// Test API call with automatic refresh
try {
  final clients = await ApiService.fetchClients(limit: 1);
  print('API call successful: ${clients.data.length} clients');
} catch (e) {
  print('API call failed: $e');
}
```

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

## API Endpoints Summary

| Method | Endpoint | Authentication | Description |
|--------|----------|----------------|-------------|
| POST | `/api/auth/login` | None | User login |
| POST | `/api/auth/refresh` | None | Token refresh |
| POST | `/api/auth/logout` | Required | User logout |

## Environment Configuration

### Development
```dart
static const String baseUrl = 'http://192.168.100.2:5000';
```

### Production
```dart
static const String baseUrl = 'https://woosh-api.vercel.app';
```

### API Version
```dart
static const String apiVersion = 'v1';
``` 