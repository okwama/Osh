# Services - Direct Database Architecture

This directory contains all services for the Woosh application, built with a clean, modular architecture using direct database connections.

## Architecture Overview

```
services/
├── README.md                    # This documentation
├── index.dart                   # Main exports
├── database_service.dart        # Core database connection service
├── auth_service.dart           # Authentication service
├── token_service.dart          # JWT token management
└── core/                       # Business logic services
    ├── index.dart              # Core services exports
    ├── target_service.dart     # Target and dashboard management
    ├── journey_plan_service.dart # Journey plan operations
    └── order_service.dart      # Order management
```

## Key Features

### 🚀 **Direct Database Connections**
- No server API dependencies
- Direct MySQL connections with connection pooling
- Optimized for performance and reliability

### 🔐 **Authentication & Security**
- JWT token-based authentication
- Secure password hashing with bcrypt
- User permission validation

### 📊 **Connection Pooling**
- Automatic connection management
- Configurable pool size (2-10 connections)
- Health monitoring and error recovery

### 🔄 **Transaction Support**
- ACID-compliant database transactions
- Automatic rollback on errors
- Data consistency guarantees

## Core Services

### DatabaseService
The foundation service that manages database connections and provides query execution.

```dart
import 'package:woosh/services/database_service.dart';

final db = DatabaseService.instance;
await db.initialize();

// Execute queries
final results = await db.query('SELECT * FROM Users WHERE id = ?', [userId]);

// Use transactions
await db.transaction((connection) async {
  // Multiple operations in a transaction
});
```

### AuthService
Handles user authentication, profile management, and password operations.

```dart
import 'package:woosh/services/auth_service.dart';

// Login
final result = await AuthService.login(phoneNumber, password);

// Get user profile
final profile = await AuthService.getProfile(userId);

// Update profile
await AuthService.updateProfile(userId, {'name': 'New Name'});
```

### TargetService
Manages sales targets, dashboards, and progress tracking.

```dart
import 'package:woosh/services/core/target_service.dart';

// Get dashboard
final dashboard = await TargetService.getDashboard(userId, period: 'current_month');

// Get targets
final targets = await TargetService.getTargets(userId: userId);

// Update target
await TargetService.updateTarget(targetId: 1, newValue: 50);
```

### JourneyPlanService
Handles journey plan creation, updates, and management.

```dart
import 'package:woosh/services/core/journey_plan_service.dart';

// Get journey plans
final plans = await JourneyPlanService.getJourneyPlans(
  userId: userId,
  status: 0, // pending
);

// Create journey plan
final plan = await JourneyPlanService.createJourneyPlan(
  clientId: clientId,
  date: DateTime.now(),
  time: '09:00',
);

// Update journey plan
await JourneyPlanService.updateJourneyPlan(
  journeyId: planId,
  clientId: clientId,
  status: 1, // checked in
  latitude: 1.234,
  longitude: 5.678,
);
```

### OrderService
Manages order creation, updates, and statistics.

```dart
import 'package:woosh/services/core/order_service.dart';

// Get orders
final orders = await OrderService.getOrders(
  userId: userId,
  status: 1, // approved
);

// Create order
final order = await OrderService.createOrder(
  totalAmount: 1000.0,
  customerName: 'John Doe',
  clientId: clientId,
  orderItems: items,
);

// Get order statistics
final stats = await OrderService.getOrderStats(userId);
```

## Configuration

### Database Configuration
Update `lib/config/database_config.dart` with your database settings:

```dart
class DatabaseConfig {
  static const String host = 'your-database-host';
  static const int port = 3306;
  static const String user = 'your-username';
  static const String password = 'your-password';
  static const String database = 'your-database-name';
}
```

### Dependencies
Add these to your `pubspec.yaml`:

```yaml
dependencies:
  mysql1: ^0.20.0
  jwt_decoder: ^2.0.1
  bcrypt: ^1.1.3
  crypto: ^3.0.3
  get_storage: ^2.1.1
```

## Usage Examples

### Basic Usage
```dart
import 'package:woosh/services/index.dart';

void main() async {
  // Initialize database
  await DatabaseService.instance.initialize();
  
  // Login user
  final loginResult = await AuthService.login('1234567890', 'password');
  
  if (loginResult['success']) {
    // Get dashboard
    final dashboard = await TargetService.getDashboard(loginResult['salesRep']['id']);
    print('Dashboard loaded: ${dashboard.overallStats}');
  }
}
```

### Error Handling
```dart
try {
  final results = await DatabaseService.instance.query('SELECT * FROM Users');
} catch (e) {
  print('Database error: $e');
  // Handle error appropriately
}
```

### Transactions
```dart
await DatabaseService.instance.transaction((connection) async {
  // Create order
  final orderResult = await connection.query(
    'INSERT INTO Orders (amount, userId) VALUES (?, ?)',
    [amount, userId]
  );
  
  // Update user balance
  await connection.query(
    'UPDATE Users SET balance = balance - ? WHERE id = ?',
    [amount, userId]
  );
});
```

## Performance Optimizations

1. **Connection Pooling**: Reuses database connections for better performance
2. **Prepared Statements**: Uses parameterized queries for security and performance
3. **Transaction Batching**: Groups related operations in transactions
4. **Lazy Loading**: Initializes connections only when needed

## Security Features

1. **SQL Injection Prevention**: Uses parameterized queries
2. **Password Hashing**: Bcrypt for secure password storage
3. **JWT Tokens**: Secure authentication tokens
4. **User Permissions**: Role-based access control

## Monitoring & Debugging

The services include comprehensive logging:

```dart
// Enable debug logging
print('🔐 Attempting login for: $phoneNumber');
print('✅ Login successful for user: ${salesRep.name}');
print('❌ Error getting dashboard: $e');
```

## Migration from API Services

To migrate from API-based services:

1. Replace API service imports with direct database services
2. Update method calls to use the new service methods
3. Remove HTTP client dependencies
4. Update error handling for database-specific errors

## Future Enhancements

- [ ] Add caching layer for frequently accessed data
- [ ] Implement database migration system
- [ ] Add connection encryption
- [ ] Create service monitoring dashboard
- [ ] Add automated testing for all services

## Support

For issues or questions about the services architecture, please refer to the main project documentation or create an issue in the project repository. 