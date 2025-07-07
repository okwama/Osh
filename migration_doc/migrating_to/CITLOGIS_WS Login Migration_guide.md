# 🔐 CITLOGIS_WS Login Migration Guide

## Overview

This guide helps you migrate your login authentication from API-based to direct database connection using the `citlogis_ws` database schema.

## 📊 Database Schema Analysis

Based on the `citlogis_ws.sql` file, the main authentication table is `SalesRep` with the following structure:

### SalesRep Table Structure
```sql
CREATE TABLE `SalesRep` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) UNIQUE NOT NULL,
  `phoneNumber` varchar(255) UNIQUE NOT NULL,
  `password` varchar(255) NOT NULL,
  `countryId` int NOT NULL,
  `country` varchar(255) NOT NULL,
  `region_id` int NOT NULL,
  `region` varchar(255) NOT NULL,
  `route_id` int NOT NULL,
  `route` varchar(100) NOT NULL,
  `route_id_update` int DEFAULT NULL,
  `route_name_update` varchar(100) DEFAULT NULL,
  `visits_targets` int DEFAULT 0,
  `new_clients` int DEFAULT 0,
  `vapes_targets` int DEFAULT 0,
  `pouches_targets` int DEFAULT 0,
  `role` varchar(50) DEFAULT 'USER',
  `manager_type` int DEFAULT 0,
  `status` int DEFAULT 0,
  `createdAt` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `retail_manager` int DEFAULT 0,
  `key_channel_manager` int DEFAULT 0,
  `distribution_manager` int DEFAULT 0,
  `photoUrl` varchar(255) DEFAULT '',
  `managerId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status_role` (`status`, `role`),
  KEY `idx_location` (`countryId`, `region_id`, `route_id`),
  KEY `idx_manager` (`managerId`)
);
```

## 🔧 Step 1: Create Database Service

### 1.1 Database Configuration
```dart
// lib/config/database_config.dart
class DatabaseConfig {
  // CITLOGIS_WS Database Settings
  static const String host = '102.218.215.35';
  static const String user = 'citlogis_bryan';
  static const String password = '@bo9511221.qwerty';
  static const String database = 'citlogis_ws';
  static const int port = 3306;

  // Connection settings
  static const int maxRetries = 3;
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration queryTimeout = Duration(seconds: 10);
  static const Duration retryDelay = Duration(seconds: 2);
}
```

### 1.2 Database Service Implementation
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
      print('🔌 Connecting to CITLOGIS_WS database...');
      
      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.user,
        password: DatabaseConfig.password,
        db: DatabaseConfig.database,
        timeout: DatabaseConfig.connectionTimeout,
      );

      _connection = await MySqlConnection.connect(settings);
      print('✅ Successfully connected to CITLOGIS_WS database');
    } catch (e) {
      print('❌ Database connection failed: $e');
      _connection = null;
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
      print('❌ Query error: $e');
      print('SQL: $sql');
      print('Params: $params');
      rethrow;
    }
  }

  /// Execute INSERT/UPDATE/DELETE queries
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    await _ensureConnection();
    
    try {
      final result = await _connection!.query(sql, params);
      return result.affectedRows ?? 0;
    } catch (e) {
      print('❌ Execute error: $e');
      print('SQL: $sql');
      print('Params: $params');
      rethrow;
    }
  }

  /// Ensure database connection is active
  Future<void> _ensureConnection() async {
    if (_connection == null) {
      await initialize();
    }

    if (!_connection!.connected) {
      print('🔄 Reconnecting to database...');
      await initialize();
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('🔌 Database connection closed');
    }
  }

  /// Check if connected
  bool get isConnected => _connection?.connected ?? false;
}
```

## 🔐 Step 2: Create Direct Authentication Service

### 2.1 SalesRep Model
```dart
// lib/models/sales_rep_model.dart
class SalesRepModel {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String country;
  final String region;
  final String route;
  final int visitsTargets;
  final int newClients;
  final int vapesTargets;
  final int pouchesTargets;
  final String role;
  final int status;
  final String? photoUrl;
  final int? managerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SalesRepModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.country,
    required this.region,
    required this.route,
    required this.visitsTargets,
    required this.newClients,
    required this.vapesTargets,
    required this.pouchesTargets,
    required this.role,
    required this.status,
    this.photoUrl,
    this.managerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalesRepModel.fromMap(Map<String, dynamic> map) {
    return SalesRepModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      country: map['country'],
      region: map['region'],
      route: map['route'],
      visitsTargets: map['visits_targets'] ?? 0,
      newClients: map['new_clients'] ?? 0,
      vapesTargets: map['vapes_targets'] ?? 0,
      pouchesTargets: map['pouches_targets'] ?? 0,
      role: map['role'] ?? 'USER',
      status: map['status'] ?? 0,
      photoUrl: map['photoUrl'],
      managerId: map['managerId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'country': country,
      'region': region,
      'route': route,
      'visits_targets': visitsTargets,
      'new_clients': newClients,
      'vapes_targets': vapesTargets,
      'pouches_targets': pouchesTargets,
      'role': role,
      'status': status,
      'photoUrl': photoUrl,
      'managerId': managerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
```

### 2.2 Direct Authentication Service
```dart
// lib/services/direct_auth_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/sales_rep_model.dart';
import 'database_service.dart';
import 'token_service.dart';

class DirectAuthService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Login with phone number and password
  static Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      print('🔐 Attempting direct database login for: $phoneNumber');

      // Hash password (assuming SHA-256 like the original system)
      final hashedPassword = _hashPassword(password);

      // Query SalesRep table
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, country, region, route,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          role, status, photoUrl, managerId, createdAt, updatedAt
        FROM SalesRep 
        WHERE phoneNumber = ? AND password = ? AND status = 0
      ''';

      final results = await _db.query(sql, [phoneNumber, hashedPassword]);

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid phone number or password',
        };
      }

      final userData = results.first.fields;
      final salesRep = SalesRepModel.fromMap(userData);

      // Generate session token
      final sessionToken = _generateSessionToken(salesRep.id);

      // Store session token
      await _storeSessionToken(salesRep.id, sessionToken);

      // Record login history
      await _recordLoginHistory(salesRep.id);

      print('✅ Direct login successful for user: ${salesRep.name}');

      return {
        'success': true,
        'message': 'Login successful',
        'salesRep': salesRep.toMap(),
        'sessionToken': sessionToken,
      };

    } catch (e) {
      print('❌ Direct login error: $e');
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  /// Login with QR code
  static Future<Map<String, dynamic>> loginWithQrCode(String qrCode) async {
    try {
      print('🔐 Attempting QR code login');

      // Query SalesRep table by QR code (assuming QR code is stored in a field)
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, country, region, route,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          role, status, photoUrl, managerId, createdAt, updatedAt
        FROM SalesRep 
        WHERE qr_code = ? AND status = 0
      ''';

      final results = await _db.query(sql, [qrCode]);

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid QR code',
        };
      }

      final userData = results.first.fields;
      final salesRep = SalesRepModel.fromMap(userData);

      // Generate session token
      final sessionToken = _generateSessionToken(salesRep.id);

      // Store session token
      await _storeSessionToken(salesRep.id, sessionToken);

      // Record login history
      await _recordLoginHistory(salesRep.id);

      print('✅ QR code login successful for user: ${salesRep.name}');

      return {
        'success': true,
        'message': 'Login successful',
        'salesRep': salesRep.toMap(),
        'sessionToken': sessionToken,
      };

    } catch (e) {
      print('❌ QR code login error: $e');
      return {
        'success': false,
        'message': 'QR code login failed: $e',
      };
    }
  }

  /// Get user by ID
  static Future<SalesRepModel?> getUserById(int userId) async {
    try {
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, country, region, route,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          role, status, photoUrl, managerId, createdAt, updatedAt
        FROM SalesRep 
        WHERE id = ? AND status = 0
      ''';

      final results = await _db.query(sql, [userId]);

      if (results.isEmpty) {
        return null;
      }

      return SalesRepModel.fromMap(results.first.fields);
    } catch (e) {
      print('❌ Get user error: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<bool> updateProfile(int userId, Map<String, dynamic> data) async {
    try {
      final updateFields = <String>[];
      final params = <dynamic>[];

      // Build dynamic update query
      data.forEach((key, value) {
        if (value != null) {
          updateFields.add('$key = ?');
          params.add(value);
        }
      });

      if (updateFields.isEmpty) {
        return false;
      }

      params.add(userId);

      final sql = '''
        UPDATE SalesRep 
        SET ${updateFields.join(', ')}, updatedAt = CURRENT_TIMESTAMP
        WHERE id = ?
      ''';

      final affectedRows = await _db.execute(sql, params);
      return affectedRows > 0;
    } catch (e) {
      print('❌ Update profile error: $e');
      return false;
    }
  }

  /// Change password
  static Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final hashedCurrentPassword = _hashPassword(currentPassword);
      final hashedNewPassword = _hashPassword(newPassword);

      // Verify current password
      const verifySql = 'SELECT id FROM SalesRep WHERE id = ? AND password = ?';
      final verifyResults = await _db.query(verifySql, [userId, hashedCurrentPassword]);

      if (verifyResults.isEmpty) {
        return false;
      }

      // Update password
      const updateSql = 'UPDATE SalesRep SET password = ? WHERE id = ?';
      final affectedRows = await _db.execute(updateSql, [hashedNewPassword, userId]);

      return affectedRows > 0;
    } catch (e) {
      print('❌ Change password error: $e');
      return false;
    }
  }

  /// Logout user
  static Future<bool> logout(int userId) async {
    try {
      // Remove session token
      await _removeSessionToken(userId);

      // Record logout history
      await _recordLogoutHistory(userId);

      return true;
    } catch (e) {
      print('❌ Logout error: $e');
      return false;
    }
  }

  // Helper methods

  /// Hash password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate session token
  static String _generateSessionToken(int userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${userId}_${timestamp}_$random';
  }

  /// Store session token
  static Future<void> _storeSessionToken(int userId, String token) async {
    try {
      // Store in TokenService for local access
      await TokenService.storeTokens(
        accessToken: token,
        refreshToken: token, // Using same token for simplicity
        expiresIn: 86400, // 24 hours
      );

      // Optionally store in database for server-side tracking
      const sql = '''
        INSERT INTO LoginHistory (salesRepId, loginTime, sessionToken, status)
        VALUES (?, CURRENT_TIMESTAMP, ?, 'active')
        ON DUPLICATE KEY UPDATE 
        sessionToken = VALUES(sessionToken),
        loginTime = CURRENT_TIMESTAMP,
        status = 'active'
      ''';

      await _db.execute(sql, [userId, token]);
    } catch (e) {
      print('❌ Store session token error: $e');
    }
  }

  /// Remove session token
  static Future<void> _removeSessionToken(int userId) async {
    try {
      // Clear from TokenService
      await TokenService.clearTokens();

      // Update database status
      const sql = '''
        UPDATE LoginHistory 
        SET status = 'inactive', logoutTime = CURRENT_TIMESTAMP
        WHERE salesRepId = ? AND status = 'active'
      ''';

      await _db.execute(sql, [userId]);
    } catch (e) {
      print('❌ Remove session token error: $e');
    }
  }

  /// Record login history
  static Future<void> _recordLoginHistory(int userId) async {
    try {
      const sql = '''
        INSERT INTO LoginHistory (salesRepId, loginTime, status)
        VALUES (?, CURRENT_TIMESTAMP, 'active')
      ''';

      await _db.execute(sql, [userId]);
    } catch (e) {
      print('❌ Record login history error: $e');
    }
  }

  /// Record logout history
  static Future<void> _recordLogoutHistory(int userId) async {
    try {
      const sql = '''
        UPDATE LoginHistory 
        SET logoutTime = CURRENT_TIMESTAMP, status = 'inactive'
        WHERE salesRepId = ? AND status = 'active'
      ''';

      await _db.execute(sql, [userId]);
    } catch (e) {
      print('❌ Record logout history error: $e');
    }
  }
}
```

## 🔄 Step 3: Update Auth Controller

### 3.1 Updated Auth Controller
```dart
// lib/controllers/auth_controller.dart
import 'package:get/get.dart';
import '../services/direct_auth_service.dart';
import '../services/token_service.dart';
import '../models/sales_rep_model.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final _isLoggedIn = false.obs;
  final _currentUser = Rxn<SalesRepModel>();
  final _isInitialized = false.obs;

  RxBool get isLoggedIn => _isLoggedIn;
  SalesRepModel? get currentUser => _currentUser.value;
  RxBool get isInitialized => _isInitialized;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize database connection
      await DirectAuthService._db.initialize();
      
      // Check for existing session
      await _loadUserFromStorage();
      _isInitialized.value = true;
    } catch (e) {
      print('❌ Auth controller initialization error: $e');
      _isInitialized.value = true;
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final box = GetStorage();
      final userData = box.read('salesRep');
      
      if (userData != null && TokenService.isAuthenticated()) {
        _currentUser.value = SalesRepModel.fromMap(userData);
        _isLoggedIn.value = true;
        print('✅ User loaded from storage: ${_currentUser.value?.name}');
      }
    } catch (e) {
      print('❌ Load user from storage error: $e');
    }
  }

  Future<void> login(String phoneNumber, String password) async {
    try {
      print('🔐 AuthController: Starting login process');
      
      final result = await DirectAuthService.login(phoneNumber, password);
      
      if (result['success'] == true && result['salesRep'] != null) {
        final user = SalesRepModel.fromMap(result['salesRep']);
        
        // Store user data
        final box = GetStorage();
        box.write('salesRep', user.toMap());
        box.write('userId', user.id.toString());

        _currentUser.value = user;
        _isLoggedIn.value = true;

        print('✅ AuthController: Login successful for ${user.name}');
        print('✅ AuthController: User role: ${user.role}');
      } else {
        throw Exception(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ AuthController login error: $e');
      rethrow;
    }
  }

  Future<void> loginWithQrCode(String qrCode) async {
    try {
      print('🔐 AuthController: Starting QR code login');
      
      final result = await DirectAuthService.loginWithQrCode(qrCode);
      
      if (result['success'] == true && result['salesRep'] != null) {
        final user = SalesRepModel.fromMap(result['salesRep']);
        
        // Store user data
        final box = GetStorage();
        box.write('salesRep', user.toMap());
        box.write('userId', user.id.toString());

        _currentUser.value = user;
        _isLoggedIn.value = true;

        print('✅ AuthController: QR login successful for ${user.name}');
      } else {
        throw Exception(result['message'] ?? 'QR code login failed');
      }
    } catch (e) {
      print('❌ AuthController QR login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (_currentUser.value != null) {
        await DirectAuthService.logout(_currentUser.value!.id);
      }

      // Clear local storage
      final box = GetStorage();
      box.remove('salesRep');
      box.remove('userId');

      _currentUser.value = null;
      _isLoggedIn.value = false;

      print('✅ AuthController: Logout successful');
    } catch (e) {
      print('❌ AuthController logout error: $e');
      rethrow;
    }
  }

  bool isAuthenticated() {
    return TokenService.isAuthenticated() && _isLoggedIn.value;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_currentUser.value == null) {
        throw Exception('No user logged in');
      }

      final success = await DirectAuthService.updateProfile(
        _currentUser.value!.id,
        data,
      );

      if (success) {
        // Reload user data
        final updatedUser = await DirectAuthService.getUserById(_currentUser.value!.id);
        if (updatedUser != null) {
          _currentUser.value = updatedUser;
          
          // Update stored data
          final box = GetStorage();
          box.write('salesRep', updatedUser.toMap());
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      rethrow;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUser.value == null) {
        return false;
      }

      return await DirectAuthService.changePassword(
        _currentUser.value!.id,
        currentPassword,
        newPassword,
      );
    } catch (e) {
      print('❌ Change password error: $e');
      return false;
    }
  }
}
```

## 🔄 Step 4: Update Login Page

### 4.1 Updated Login Page
```dart
// lib/pages/login/login_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10,12}$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _showToast(String message, bool isError) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: isError ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: isError ? 3 : 1,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.login(
        _phoneNumberController.text.trim(),
        _passwordController.text,
      );

      // Get user role for navigation
      final userRole = _authController.currentUser?.role ?? '';

      // Navigate based on role
      if (userRole.toLowerCase() == 'manager') {
        