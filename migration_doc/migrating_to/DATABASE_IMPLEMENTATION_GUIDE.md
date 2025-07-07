# MOTORGAS Database Implementation Guide

## Quick Start Guide

### 1. Database Setup

#### Prerequisites
- MySQL Server 8.0 or higher
- Flutter SDK 3.0 or higher
- Dart SDK 2.19 or higher

#### Database Installation
```bash
# Connect to MySQL server
mysql -u root -p

# Create database
CREATE DATABASE citlogis_forecourt CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Create user and grant permissions
CREATE USER 'citlogis_bryan'@'%' IDENTIFIED BY '@bo9511221.qwerty';
GRANT ALL PRIVILEGES ON citlogis_forecourt.* TO 'citlogis_bryan'@'%';
FLUSH PRIVILEGES;

# Use the database
USE citlogis_forecourt;
```

#### Schema Installation
```bash
# Run the database setup script
mysql -u citlogis_bryan -p citlogis_forecourt < database_setup.sql
```

### 2. Flutter Dependencies

#### Add Required Packages
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  mysql1: ^0.20.0
  get_storage: ^2.1.1
  crypto: ^3.0.3
  http: ^1.1.0
  geolocator: ^10.1.0
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1
```

#### Install Dependencies
```bash
flutter pub get
```

### 3. Configuration Setup

#### Database Configuration
```dart
// lib/services/database_service.dart
class DatabaseService {
  // Update these values for your environment
  static const String _host = 'your_database_host';
  static const String _user = 'your_database_user';
  static const String _password = 'your_database_password';
  static const String _database = 'your_database_name';
  static const int _port = 3306;
}
```

#### Environment Variables (Recommended)
```bash
# Create .env file
DB_HOST=102.218.215.35
DB_USER=citlogis_bryan
DB_PASSWORD=@bo9511221.qwerty
DB_NAME=citlogis_forecourt
DB_PORT=3306
```

## Service Layer Implementation

### 1. Database Service Usage

#### Initialize Database Connection
```dart
// In your main.dart or app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database service
  await DatabaseService.instance.initialize();
  
  runApp(MyApp());
}
```

#### Basic Database Operations
```dart
// Query example
final results = await DatabaseService.instance.query(
  'SELECT * FROM users WHERE status = ?',
  ['active']
);

// Insert example
final affectedRows = await DatabaseService.instance.execute(
  'INSERT INTO users (phone_number, first_name, last_name, password) VALUES (?, ?, ?, ?)',
  ['1234567890', 'John', 'Doe', hashedPassword]
);

// Update example
final updatedRows = await DatabaseService.instance.execute(
  'UPDATE users SET status = ? WHERE id = ?',
  ['inactive', userId]
);
```

### 2. Authentication Service Usage

#### User Login
```dart
// Standard login
final loginResult = await HybridAuthService.login(
  '1234567890',
  'password123'
);

if (loginResult['success']) {
  final user = User.fromJson(loginResult['user']);
  // Navigate to home page
} else {
  // Show error message
  print(loginResult['message']);
}

// QR code login
final qrLoginResult = await HybridAuthService.loginWithQrCode(
  'qr_code_string'
);
```

#### Session Management
```dart
// Check if user is logged in
if (HybridAuthService.isLoggedIn()) {
  final user = HybridAuthService.getCurrentUser();
  // User is authenticated
}

// Logout
await HybridAuthService.logout();
```

### 3. Attendance Service Usage

#### Check-in Operations
```dart
// Record check-in
final checkinResult = await AttendanceService.checkIn(
  userId: 1,
  latitude: -1.2921,
  longitude: 36.8219,
  locationId: 1,
  method: 'qr'
);

// Record check-out
final checkoutResult = await AttendanceService.checkOut(
  userId: 1,
  latitude: -1.2921,
  longitude: 36.8219,
  locationId: 1
);

// Get attendance history
final attendanceHistory = await AttendanceService.getAttendanceHistory(
  userId: 1,
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now()
);
```

### 4. QR Code Service Usage

#### Generate QR Session
```dart
// Create QR session for location
final qrSession = await QRSessionService.createSession(
  locationId: 1,
  validFrom: DateTime.now(),
  validTo: DateTime.now().add(Duration(hours: 8)),
  createdBy: 1
);

// Validate QR code
final isValid = await QRSessionService.validateQRCode(
  qrCode: 'qr_session_token',
  locationId: 1
);
```

## Data Models Implementation

### 1. User Model
```dart
// Create user
final user = User(
  id: 1,
  employeeId: 'EMP001',
  name: 'John Doe',
  email: 'john@company.com',
  phoneNumber: '1234567890',
  role: 'employee',
  department: 'Sales',
  position: 'Sales Representative',
  status: 'active'
);

// Convert to JSON
final userJson = user.toJson();

// Create from JSON
final userFromJson = User.fromJson(userJson);
```

### 2. Attendance Model
```dart
// Create attendance record
final attendance = Attendance(
  id: 1,
  userId: 1,
  date: DateTime.now(),
  checkIn: DateTime.now(),
  checkInLatitude: -1.2921,
  checkInLongitude: 36.8219,
  locationId: 1,
  status: 'present',
  hoursWorked: 8.0,
  checkInMethod: 'qr'
);
```

## Error Handling and Logging

### 1. Database Error Handling
```dart
try {
  final results = await DatabaseService.instance.query(
    'SELECT * FROM users WHERE id = ?',
    [userId]
  );
} catch (e) {
  print('Database error: $e');
  // Handle error appropriately
}
```

### 2. Connection Health Monitoring
```dart
// Check connection health
final isHealthy = await DatabaseService.instance.isConnected();

if (!isHealthy) {
  // Attempt reconnection
  await DatabaseService.instance.reconnect();
}
```

### 3. Transaction Management
```dart
try {
  await DatabaseService.instance.beginTransaction();
  
  // Perform multiple operations
  await DatabaseService.instance.execute(
    'INSERT INTO orders (user_id, product_id, quantity) VALUES (?, ?, ?)',
    [userId, productId, quantity]
  );
  
  await DatabaseService.instance.execute(
    'UPDATE products SET stock = stock - ? WHERE id = ?',
    [quantity, productId]
  );
  
  await DatabaseService.instance.commit();
} catch (e) {
  await DatabaseService.instance.rollback();
  print('Transaction failed: $e');
}
```

## Performance Optimization

### 1. Query Optimization
```dart
// Use prepared statements
final stmt = await connection.prepare(
  'SELECT * FROM users WHERE department = ? AND status = ?'
);

// Execute multiple times with different parameters
for (final dept in departments) {
  final results = await stmt.execute([dept, 'active']);
}
```

### 2. Connection Pooling
```dart
// Database service already implements connection pooling
// Use singleton pattern for connection management
final dbService = DatabaseService.instance;
```

### 3. Caching Strategy
```dart
// Cache frequently accessed data
class CacheService {
  static final Map<String, dynamic> _cache = {};
  
  static Future<T> getOrSet<T>(
    String key,
    Future<T> Function() fetcher,
    {Duration? expiry}
  ) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }
    
    final data = await fetcher();
    _cache[key] = data;
    
    if (expiry != null) {
      Timer(expiry, () => _cache.remove(key));
    }
    
    return data;
  }
}
```

## Security Implementation

### 1. Password Hashing
```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

// Usage
final hashedPassword = hashPassword('userPassword');
```

### 2. Input Validation
```dart
class ValidationService {
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(phone);
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidLatitude(double lat) {
    return lat >= -90 && lat <= 90;
  }
  
  static bool isValidLongitude(double lng) {
    return lng >= -180 && lng <= 180;
  }
}
```

### 3. SQL Injection Prevention
```dart
// Always use parameterized queries
// ❌ Bad - vulnerable to SQL injection
final query = "SELECT * FROM users WHERE name = '$userInput'";

// ✅ Good - parameterized query
final query = "SELECT * FROM users WHERE name = ?";
final results = await dbService.query(query, [userInput]);
```

## Testing Implementation

### 1. Unit Tests
```dart
// test/database_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_gas/services/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    test('should connect to database', () async {
      await DatabaseService.instance.initialize();
      final isConnected = await DatabaseService.instance.isConnected();
      expect(isConnected, true);
    });
    
    test('should execute query successfully', () async {
      final results = await DatabaseService.instance.query(
        'SELECT 1 as test'
      );
      expect(results.isNotEmpty, true);
      expect(results.first['test'], 1);
    });
  });
}
```

### 2. Integration Tests
```dart
// test/integration/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_gas/services/hybrid_auth_service.dart';

void main() {
  group('Authentication Integration Tests', () {
    test('should login with valid credentials', () async {
      final result = await HybridAuthService.login(
        '1234567890',
        'admin'
      );
      
      expect(result['success'], true);
      expect(result['user'], isNotNull);
    });
    
    test('should reject invalid credentials', () async {
      final result = await HybridAuthService.login(
        'invalid',
        'invalid'
      );
      
      expect(result['success'], false);
    });
  });
}
```

## Deployment Checklist

### 1. Production Database Setup
- [ ] Create production database
- [ ] Set up database user with minimal required permissions
- [ ] Configure SSL/TLS connections
- [ ] Set up automated backups
- [ ] Configure connection pooling
- [ ] Set up monitoring and alerting

### 2. Application Configuration
- [ ] Update database connection settings
- [ ] Configure environment variables
- [ ] Set up error logging
- [ ] Configure performance monitoring
- [ ] Set up health checks

### 3. Security Configuration
- [ ] Enable SSL/TLS for database connections
- [ ] Configure firewall rules
- [ ] Set up access logging
- [ ] Implement rate limiting
- [ ] Configure backup encryption

### 4. Performance Configuration
- [ ] Optimize database indexes
- [ ] Configure connection pool size
- [ ] Set up query caching
- [ ] Configure read replicas (if needed)
- [ ] Set up performance monitoring

## Troubleshooting Guide

### Common Issues

#### 1. Connection Timeout
```dart
// Increase timeout in database service
static const Duration _timeout = Duration(seconds: 60);
```

#### 2. Connection Lost
```dart
// Implement automatic reconnection
if (!await DatabaseService.instance.isConnected()) {
  await DatabaseService.instance.reconnect();
}
```

#### 3. Query Performance Issues
```sql
-- Check query execution plan
EXPLAIN SELECT * FROM users WHERE department = 'Sales';

-- Add missing indexes
CREATE INDEX idx_users_department ON users(department);
```

#### 4. Memory Issues
```dart
// Implement pagination for large datasets
final results = await DatabaseService.instance.query(
  'SELECT * FROM attendance LIMIT ? OFFSET ?',
  [pageSize, pageSize * pageNumber]
);
```

## Monitoring and Maintenance

### 1. Database Monitoring
```sql
-- Check database size
SELECT 
  table_schema AS 'Database',
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'citlogis_forecourt'
GROUP BY table_schema;

-- Check slow queries
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';
```

### 2. Application Monitoring
```dart
// Add performance monitoring
class PerformanceMonitor {
  static void logQueryTime(String query, Duration duration) {
    if (duration.inMilliseconds > 1000) {
      print('Slow query detected: $query (${duration.inMilliseconds}ms)');
    }
  }
}
```

---

*This implementation guide provides comprehensive instructions for setting up and working with the MOTORGAS database system. Follow these guidelines to ensure proper implementation and maintenance.* 