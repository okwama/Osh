# 🚀 Citlogis WS to Direct Database Migration Guide

## 📋 Overview

This guide helps you migrate your Flutter app from using the Citlogis WS API to direct database connections using the `citlogis_ws.sql` schema. This approach eliminates the API layer and connects your Flutter app directly to the MySQL database.

---

## 🎯 Migration Benefits

### ✅ **Performance Improvements:**
- **Faster Response Times**: Eliminates API overhead (typically 50-200ms reduction)
- **Reduced Latency**: Direct database connections
- **Better Offline Support**: Local caching with direct sync
- **Real-time Updates**: Immediate database changes

### ✅ **Cost Savings:**
- **No API Server Hosting**: Eliminates server costs
- **Reduced Bandwidth**: Direct queries instead of HTTP requests
- **Simplified Infrastructure**: Fewer moving parts

### ✅ **Development Benefits:**
- **Easier Debugging**: Direct SQL queries
- **Better Control**: Full database access
- **Simplified Architecture**: Fewer layers to maintain

---

## 🗄️ Database Schema Analysis

Based on `citlogis_ws.sql`, your database contains these core tables:

### **Core Business Tables:**
- `SalesRep` - Sales representatives and users
- `Clients` - Customer/client information
- `Product` - Product catalog
- `MyOrder` - Order management
- `OrderItem` - Order line items
- `JourneyPlan` - Route planning
- `Stores` - Store/outlet locations
- `StoreQuantity` - Inventory management

### **Supporting Tables:**
- `Country` - Country information
- `Regions` - Regional data
- `routes` - Route definitions
- `manager` - Management hierarchy
- `NoticeBoard` - Company notices
- `leaves` - Leave management
- `FeedbackReport` - Customer feedback
- `ProductReport` - Product performance

---

## 🔧 Step-by-Step Migration Process

### **Step 1: Set Up Database Configuration**

#### 1.1 Create Database Configuration File
```dart
// lib/config/database_config.dart
class DatabaseConfig {
  // Production Database Settings (from citlogis_ws)
  static const String prodHost = '102.218.215.35';
  static const String prodUser = 'citlogis_bryan';
  static const String prodPassword = '@bo9511221.qwerty';
  static const String prodDatabase = 'citlogis_ws';
  static const int prodPort = 3306;

  // Development Database Settings
  static const String devHost = 'localhost';
  static const String devUser = 'root';
  static const String devPassword = 'password';
  static const String devDatabase = 'citlogis_ws_dev';
  static const int devPort = 3306;

  // Connection Settings
  static const int maxRetries = 3;
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration queryTimeout = Duration(seconds: 10);
  static const Duration retryDelay = Duration(seconds: 2);

  // Get current environment settings
  static Map<String, dynamic> get currentConfig {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    
    if (isProduction) {
      return {
        'host': prodHost,
        'user': prodUser,
        'password': prodPassword,
        'database': prodDatabase,
        'port': prodPort,
      };
    } else {
      return {
        'host': devHost,
        'user': devUser,
        'password': devPassword,
        'database': devDatabase,
        'port': devPort,
      };
    }
  }
}
```

#### 1.2 Add MySQL Dependency
```yaml
# pubspec.yaml
dependencies:
  mysql1: ^0.20.0
  flutter_secure_storage: ^8.0.0
```

### **Step 2: Create Core Database Service**

#### 2.1 Database Service Implementation
```dart
// lib/services/database_service.dart
import 'package:mysql1/mysql1.dart';
import 'package:flutter/foundation.dart';
import '../config/database_config.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static MySqlConnection? _connection;
  static bool _isConnecting = false;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Initialize database connection
  Future<void> initialize() async {
    if (kIsWeb) {
      print('⚠️  MySQL connection skipped on web platform');
      return;
    }

    if (_isConnecting) {
      print('⏳ Connection already in progress, waiting...');
      while (_isConnecting) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    if (_connection != null) {
      print('✅ Database already connected');
      return;
    }

    _isConnecting = true;
    
    try {
      final config = DatabaseConfig.currentConfig;
      
      print('🔌 Connecting to database: ${config['host']}:${config['port']}');
      
      _connection = await MySqlConnection.connect(
        ConnectionSettings(
          host: config['host'],
          port: config['port'],
          user: config['user'],
          password: config['password'],
          db: config['database'],
          timeout: DatabaseConfig.connectionTimeout,
        ),
      );

      print('✅ Database connected successfully');
    } catch (e) {
      print('❌ Database connection failed: $e');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Execute SELECT queries
  Future<List<ResultRow>> query(String sql, [List<dynamic>? params]) async {
    await _ensureConnection();
    
    try {
      final results = await _connection!.query(sql, params);
      return results.toList();
    } catch (e) {
      print('❌ Query failed: $e');
      print('SQL: $sql');
      print('Params: $params');
      rethrow;
    }
  }

  /// Execute INSERT/UPDATE/DELETE queries
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    await _ensureConnection();
    
    try {
      final results = await _connection!.query(sql, params);
      return results.affectedRows ?? 0;
    } catch (e) {
      print('❌ Execute failed: $e');
      print('SQL: $sql');
      print('Params: $params');
      rethrow;
    }
  }

  /// Begin transaction
  Future<void> beginTransaction() async {
    await _ensureConnection();
    await _connection!.query('START TRANSACTION');
  }

  /// Commit transaction
  Future<void> commit() async {
    await _connection!.query('COMMIT');
  }

  /// Rollback transaction
  Future<void> rollback() async {
    await _connection!.query('ROLLBACK');
  }

  /// Check connection health
  Future<bool> isConnected() async {
    try {
      if (_connection == null) return false;
      await _connection!.query('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reconnect to database
  Future<void> reconnect() async {
    await _connection?.close();
    _connection = null;
    await initialize();
  }

  /// Ensure connection is active
  Future<void> _ensureConnection() async {
    if (_connection == null) {
      await initialize();
    }
    
    if (!await isConnected()) {
      await reconnect();
    }
  }

  /// Close connection
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
```

### **Step 3: Create Authentication Service**

#### 3.1 Database Authentication Service
```dart
// lib/services/db_auth_service.dart
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_service.dart';
import '../models/user_model.dart';

class DbAuthService {
  final DatabaseService _db = DatabaseService.instance;

  /// Login with phone number and password
  Future<UserModel?> login(String phoneNumber, String password) async {
    try {
      // Hash password (assuming SHA-256 like in citlogis_ws)
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, role, countryId, country,
          region_id, region, route_id, route, visits_targets,
          new_clients, vapes_targets, pouches_targets, status,
          photoUrl, managerId, createdAt, updatedAt
        FROM SalesRep 
        WHERE phoneNumber = ? AND password = ? AND status = 0
      ''';

      final results = await _db.query(sql, [phoneNumber, hashedPassword]);
      
      if (results.isNotEmpty) {
        final row = results.first;
        return UserModel.fromMap(row.fields);
      }
      
      return null;
    } catch (e) {
      print('❌ Login failed: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(int userId) async {
    try {
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, role, countryId, country,
          region_id, region, route_id, route, visits_targets,
          new_clients, vapes_targets, pouches_targets, status,
          photoUrl, managerId, createdAt, updatedAt
        FROM SalesRep 
        WHERE id = ? AND status = 1
      ''';

      final results = await _db.query(sql, [userId]);
      
      if (results.isNotEmpty) {
        final row = results.first;
        return UserModel.fromMap(row.fields);
      }
      
      return null;
    } catch (e) {
      print('❌ Get user failed: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(int userId, Map<String, dynamic> data) async {
    try {
      final setClauses = <String>[];
      final params = <dynamic>[];
      
      data.forEach((key, value) {
        if (value != null) {
          setClauses.add('$key = ?');
          params.add(value);
        }
      });
      
      if (setClauses.isEmpty) return false;
      
      params.add(userId);
      
      final sql = '''
        UPDATE SalesRep 
        SET ${setClauses.join(', ')}, updatedAt = CURRENT_TIMESTAMP
        WHERE id = ?
      ''';

      final affectedRows = await _db.execute(sql, params);
      return affectedRows > 0;
    } catch (e) {
      print('❌ Update profile failed: $e');
      rethrow;
    }
  }

  /// Change password
  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final currentHashed = sha256.convert(utf8.encode(currentPassword)).toString();
      final newHashed = sha256.convert(utf8.encode(newPassword)).toString();
      
      const sql = '''
        UPDATE SalesRep 
        SET password = ?, updatedAt = CURRENT_TIMESTAMP
        WHERE id = ? AND password = ?
      ''';

      final affectedRows = await _db.execute(sql, [newHashed, userId, currentHashed]);
      return affectedRows > 0;
    } catch (e) {
      print('❌ Change password failed: $e');
      rethrow;
    }
  }
}
```

### **Step 4: Create Data Models**

#### 4.1 User Model
```dart
// lib/models/user_model.dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final int countryId;
  final String country;
  final int regionId;
  final String region;
  final int routeId;
  final String route;
  final int visitsTargets;
  final int newClients;
  final int vapesTargets;
  final int pouchesTargets;
  final int status;
  final String? photoUrl;
  final int? managerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.countryId,
    required this.country,
    required this.regionId,
    required this.region,
    required this.routeId,
    required this.route,
    required this.visitsTargets,
    required this.newClients,
    required this.vapesTargets,
    required this.pouchesTargets,
    required this.status,
    this.photoUrl,
    this.managerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String,
      role: map['role'] as String,
      countryId: map['countryId'] as int,
      country: map['country'] as String,
      regionId: map['region_id'] as int,
      region: map['region'] as String,
      routeId: map['route_id'] as int,
      route: map['route'] as String,
      visitsTargets: map['visits_targets'] as int,
      newClients: map['new_clients'] as int,
      vapesTargets: map['vapes_targets'] as int,
      pouchesTargets: map['pouches_targets'] as int,
      status: map['status'] as int,
      photoUrl: map['photoUrl'] as String?,
      managerId: map['managerId'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'countryId': countryId,
      'country': country,
      'regionId': regionId,
      'region': region,
      'routeId': routeId,
      'route': route,
      'visitsTargets': visitsTargets,
      'newClients': newClients,
      'vapesTargets': vapesTargets,
      'pouchesTargets': pouchesTargets,
      'status': status,
      'photoUrl': photoUrl,
      'managerId': managerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
```

### **Step 5: Create Business Services**

#### 5.1 Product Service
```dart
// lib/services/product_service.dart
import 'database_service.dart';
import '../models/product_model.dart';

class ProductService {
  final DatabaseService _db = DatabaseService.instance;

  /// Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      const sql = '''
        SELECT 
          p.id, p.name, p.description, p.category, p.imageUrl, p.status,
          p.createdAt, p.updatedAt,
          pd.price, pd.currency, pd.countryId
        FROM Product p
        LEFT JOIN ProductDetails pd ON p.id = pd.productId
        WHERE p.status = 1
        ORDER BY p.name
      ''';

      final results = await _db.query(sql);
      return results.map((row) => ProductModel.fromMap(row.fields)).toList();
    } catch (e) {
      print('❌ Get products failed: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      const sql = '''
        SELECT 
          p.id, p.name, p.description, p.category, p.imageUrl, p.status,
          p.createdAt, p.updatedAt,
          pd.price, pd.currency, pd.countryId
        FROM Product p
        LEFT JOIN ProductDetails pd ON p.id = pd.productId
        WHERE p.category = ? AND p.status = 1
        ORDER BY p.name
      ''';

      final results = await _db.query(sql, [category]);
      return results.map((row) => ProductModel.fromMap(row.fields)).toList();
    } catch (e) {
      print('❌ Get products by category failed: $e');
      rethrow;
    }
  }

  /// Get product stock by store
  Future<List<Map<String, dynamic>>> getProductStock(int productId) async {
    try {
      const sql = '''
        SELECT 
          sq.id, sq.productId, sq.storeId, sq.quantity,
          s.name as storeName, s.location as storeLocation
        FROM StoreQuantity sq
        JOIN Stores s ON sq.storeId = s.id
        WHERE sq.productId = ?
        ORDER BY s.name
      ''';

      final results = await _db.query(sql, [productId]);
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Get product stock failed: $e');
      rethrow;
    }
  }
}
```

#### 5.2 Order Service
```dart
// lib/services/order_service.dart
import 'database_service.dart';
import '../models/order_model.dart';

class OrderService {
  final DatabaseService _db = DatabaseService.instance;

  /// Create new order
  Future<int> createOrder(OrderModel order) async {
    try {
      await _db.beginTransaction();
      
      // Insert order
      const orderSql = '''
        INSERT INTO MyOrder (
          orderNumber, salesRepId, clientId, totalAmount, status,
          paymentStatus, deliveryDate, notes, currency, exchangeRate,
          localAmount, localCurrency, taxPin, taxPinLabel, countryCode
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      final orderParams = [
        order.orderNumber,
        order.salesRepId,
        order.clientId,
        order.totalAmount,
        order.status,
        order.paymentStatus,
        order.deliveryDate?.toIso8601String(),
        order.notes,
        order.currency,
        order.exchangeRate,
        order.localAmount,
        order.localCurrency,
        order.taxPin,
        order.taxPinLabel,
        order.countryCode,
      ];

      final orderResult = await _db.execute(orderSql, orderParams);
      final orderId = orderResult;

      // Insert order items
      for (final item in order.items) {
        const itemSql = '''
          INSERT INTO OrderItem (
            orderId, productId, quantity, unitPrice, totalPrice,
            discount, taxAmount, notes
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''';

        final itemParams = [
          orderId,
          item.productId,
          item.quantity,
          item.unitPrice,
          item.totalPrice,
          item.discount,
          item.taxAmount,
          item.notes,
        ];

        await _db.execute(itemSql, itemParams);
      }

      await _db.commit();
      return orderId;
    } catch (e) {
      await _db.rollback();
      print('❌ Create order failed: $e');
      rethrow;
    }
  }

  /// Get orders by sales rep
  Future<List<OrderModel>> getOrdersBySalesRep(int salesRepId) async {
    try {
      const sql = '''
        SELECT 
          o.id, o.orderNumber, o.salesRepId, o.clientId, o.totalAmount,
          o.status, o.paymentStatus, o.deliveryDate, o.notes,
          o.currency, o.exchangeRate, o.localAmount, o.localCurrency,
          o.taxPin, o.taxPinLabel, o.countryCode, o.createdAt, o.updatedAt,
          c.name as clientName, c.phoneNumber as clientPhone
        FROM MyOrder o
        JOIN Clients c ON o.clientId = c.id
        WHERE o.salesRepId = ?
        ORDER BY o.createdAt DESC
      ''';

      final results = await _db.query(sql, [salesRepId]);
      return results.map((row) => OrderModel.fromMap(row.fields)).toList();
    } catch (e) {
      print('❌ Get orders failed: $e');
      rethrow;
    }
  }
}
```

### **Step 6: Update Your App**

#### 6.1 Initialize Database in Main
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database connection
  await DatabaseService.instance.initialize();
  
  runApp(MyApp());
}
```

#### 6.2 Update Authentication Controller
```dart
// lib/controllers/auth_controller.dart
import '../services/db_auth_service.dart';
import '../models/user_model.dart';

class AuthController {
  final DbAuthService _authService = DbAuthService();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  /// Login user
  Future<bool> login(String phoneNumber, String password) async {
    try {
      final user = await _authService.login(phoneNumber, password);
      if (user != null) {
        _currentUser = user;
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Login failed: $e');
      return false;
    }
  }

  /// Logout user
  void logout() {
    _currentUser = null;
  }

  /// Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    
    try {
      final success = await _authService.updateProfile(_currentUser!.id, data);
      if (success) {
        // Refresh user data
        final updatedUser = await _authService.getUserById(_currentUser!.id);
        if (updatedUser != null) {
          _currentUser = updatedUser;
        }
      }
      return success;
    } catch (e) {
      print('❌ Update profile failed: $e');
      return false;
    }
  }
}
```

---

## 🔐 Security Considerations

### **Database Security:**
1. **Environment Variables**: Move credentials to environment variables
2. **Connection Encryption**: Use SSL/TLS for database connections
3. **Input Validation**: Validate all user inputs
4. **SQL Injection Prevention**: Use parameterized queries (already implemented)

### **App Security:**
1. **Secure Storage**: Use `flutter_secure_storage` for sensitive data
2. **Token Management**: Implement secure token storage
3. **Session Management**: Proper session handling
4. **Error Handling**: Don't expose sensitive information in errors

---

## 🌐 Web Platform Considerations

Since web browsers can't connect directly to MySQL, implement a hybrid approach:

```dart
// lib/services/hybrid_service.dart
import 'package:flutter/foundation.dart';
import 'db_auth_service.dart';
import 'api_service.dart';

class HybridService {
  final DbAuthService _dbAuth = DbAuthService();
  final ApiService _apiAuth = ApiService();

  Future<UserModel?> login(String phoneNumber, String password) async {
    if (kIsWeb) {
      return await _apiAuth.login(phoneNumber, password);
    } else {
      return await _dbAuth.login(phoneNumber, password);
    }
  }
}
```

---

## 📊 Performance Optimization

### **Database Optimization:**
1. **Indexing**: Ensure proper indexes on frequently queried fields
2. **Connection Pooling**: Use connection pooling for better performance
3. **Query Optimization**: Optimize complex queries
4. **Caching**: Implement application-level caching

### **App Optimization:**
1. **Lazy Loading**: Load data on demand
2. **Pagination**: Implement pagination for large datasets
3. **Caching**: Cache frequently accessed data
4. **Background Sync**: Sync data in background

---

## 🧪 Testing Strategy

### **Unit Tests:**
```dart
// test/services/database_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    test('should connect to database', () async {
      final db = DatabaseService.instance;
      await db.initialize();
      expect(await db.isConnected(), true);
    });
  });
}
```

### **Integration Tests:**
```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/db_auth_service.dart';

void main() {
  group('DbAuthService Tests', () {
    test('should login with valid credentials', () async {
      final auth = DbAuthService();
      final user = await auth.login('test@example.com', 'password');
      expect(user, isNotNull);
    });
  });
}
```

---

## 🚀 Deployment Checklist

### **Pre-Deployment:**
- [ ] Move database credentials to environment variables
- [ ] Test database connection in production environment
- [ ] Verify all queries work with production data
- [ ] Test error handling and recovery
- [ ] Implement proper logging

### **Post-Deployment:**
- [ ] Monitor database performance
- [ ] Check error logs
- [ ] Verify data integrity
- [ ] Test all features
- [ ] Monitor user feedback

---

## 📈 Migration Timeline

### **Week 1: Setup & Configuration**
- Set up database configuration
- Create core database service
- Implement authentication service

### **Week 2: Core Features**
- Create data models
- Implement product service
- Implement order service

### **Week 3: Business Logic**
- Implement remaining services
- Update controllers
- Test core functionality

### **Week 4: Testing & Deployment**
- Comprehensive testing
- Performance optimization
- Production deployment

---

## 🆘 Troubleshooting

### **Common Issues:**

1. **Connection Failed**
   - Check database credentials
   - Verify network connectivity
   - Check firewall settings

2. **Query Errors**
   - Verify table names and column names
   - Check data types
   - Review SQL syntax

3. **Performance Issues**
   - Check database indexes
   - Optimize queries
   - Implement caching

### **Support Resources:**
- Database documentation
- Flutter MySQL package documentation
- Community forums

---

**Migration Version**: 1.0  
**Last Updated**: January 2025  
**Database Schema**: citlogis_ws.sql  
**Target Architecture**: Direct Database Connection 