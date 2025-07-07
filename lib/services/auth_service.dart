import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/token_service.dart';

// 1 is inactive 0 is active
/// Authentication service using direct database connections
class AuthService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Login with phone number and password
  static Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    try {

      // Test database connectivity first
      final connectionTest = await _db.testConnection();
      if (!connectionTest['success']) {
        return {
          'success': false,
          'message':
              'Database connection failed. Please check your internet connection and try again.',
          'error': connectionTest['message'],
        };
      }

      // Query SalesRep table to get user and stored password
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, password, country, region, route,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          role, status, photoUrl, managerId, createdAt, updatedAt
        FROM SalesRep 
        WHERE phoneNumber = ? AND status = 0
      ''';

      final results = await _db.query(sql, [phoneNumber]);

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid phone number or password',
        };
      }

      final userData = results.first.fields;
      final storedPassword = userData['password']?.toString();

      // Check if password exists
      if (storedPassword == null || storedPassword.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid phone number or password',
        };
      }

      // Verify password using bcrypt
      if (!BCrypt.checkpw(password, storedPassword)) {
        print(
            '❌ Password verification failed for user: ${userData['phoneNumber']}');
        return {
          'success': false,
          'message': 'Wrong password',
        };
      }

      final salesRep = SalesRepModel.fromMap(userData);
      print(
          '✅ SalesRepModel created successfully: ${salesRep.name} (ID: ${salesRep.id})');

      // Generate JWT token
      final jwtToken = await _generateToken(salesRep.id);

      // Store token
      await TokenService.storeTokens(
        accessToken: jwtToken,
        refreshToken:
            jwtToken, // In a real app, you'd generate a separate refresh token
      );


      return {
        'success': true,
        'message': 'Login successful',
        'salesRep': salesRep.toMap(),
        'token': jwtToken,
      };
    } catch (e) {

      // Provide more specific error messages
      String errorMessage = 'Login failed';
      if (e.toString().contains('timeout')) {
        errorMessage =
            'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('refused')) {
        errorMessage =
            'Database connection refused. The server may be down or temporarily unavailable.';
      } else if (e.toString().contains('authentication')) {
        errorMessage =
            'Database authentication failed. Please contact support.';
      } else {
        errorMessage = 'Login failed: $e';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData) async {
    try {

      // Check if user already exists
      const checkSql = 'SELECT id FROM SalesRep WHERE phoneNumber = ?';
      final checkResults = await _db.query(checkSql, [userData['phoneNumber']]);

      if (checkResults.isNotEmpty) {
        return {
          'success': false,
          'message': 'User with this phone number already exists',
        };
      }

      // Hash password using bcrypt
      final hashedPassword =
          BCrypt.hashpw(userData['password'], BCrypt.gensalt());

      // Insert new user
      const insertSql = '''
        INSERT INTO SalesRep (
          name, email, phoneNumber, password, country, countryId, 
          region_id, region, route_id, route, role, department,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          status, createdAt, updatedAt
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ''';

      final insertParams = [
        userData['name'],
        userData['email'],
        userData['phoneNumber'],
        hashedPassword,
        userData['country'],
        userData['countryId'],
        userData['region_id'],
        userData['region'],
        userData['route_id'],
        userData['route'],
        userData['role'],
        userData['department'],
      ];

      final results = await _db.query(insertSql, insertParams);

      if ((results.affectedRows ?? 0) > 0) {
        return {
          'success': true,
          'message': 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e',
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
          role, status, photoUrl, managerId, createdAt, updatedAt, countryId
        FROM SalesRep 
        WHERE id = ? AND status = 0
      ''';

      final results = await _db.query(sql, [userId]);

      if (results.isEmpty) {
        return null;
      }

      return SalesRepModel.fromMap(results.first.fields);
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  static Future<bool> updateProfile(
      int userId, Map<String, dynamic> data) async {
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

      final results = await _db.query(sql, params);
      return (results.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Change password
  static Future<bool> changePassword(
      int userId, String currentPassword, String newPassword) async {
    try {
      // Get current password hash
      const getSql = 'SELECT password FROM SalesRep WHERE id = ?';
      final getResults = await _db.query(getSql, [userId]);

      if (getResults.isEmpty) {
        return false;
      }

      final storedPassword = getResults.first.fields['password'];

      // Verify current password using bcrypt
      if (!BCrypt.checkpw(currentPassword, storedPassword)) {
        return false;
      }

      // Hash new password using bcrypt
      final hashedNewPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // Update password
      const updateSql = 'UPDATE SalesRep SET password = ? WHERE id = ?';
      final results = await _db.query(updateSql, [hashedNewPassword, userId]);

      return (results.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Logout user
  static Future<bool> logout(int userId) async {
    try {
      // Clear tokens
      await TokenService.clearTokens();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get profile data for current user
  static Future<Map<String, dynamic>?> getProfile(int userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        return null;
      }

      return {
        'salesRep': user.toMap(),
      };
    } catch (e) {
      return null;
    }
  }

  /// Update profile photo
  static Future<String?> updateProfilePhoto(int userId, String photoUrl) async {
    try {
      final success = await updateProfile(userId, {'photoUrl': photoUrl});
      if (success) {
        return photoUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate JWT token (simplified version)
  static Future<String> _generateToken(int userId) async {
    try {
      // Get user's countryId from database to include in token
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found when generating token');
      }

      final header = {'alg': 'HS256', 'typ': 'JWT'};
      final payload = {
        'userId': userId,
        'countryId': user.countryId, // Include countryId in token payload
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': (DateTime.now().add(const Duration(days: 1)))
                .millisecondsSinceEpoch ~/
            1000,
      };

      final encodedHeader = _base64UrlEncode(json.encode(header));
      final encodedPayload = _base64UrlEncode(json.encode(payload));
      final signature = _generateSignature('$encodedHeader.$encodedPayload');

      return '$encodedHeader.$encodedPayload.$signature';
    } catch (e) {
      rethrow;
    }
  }

  /// Generate signature for JWT
  static String _generateSignature(String data) {
    const secret = 'woosh_secret_key_2024'; // Change this in production
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return _base64UrlEncode(digest.bytes);
  }

  /// Base64 URL encoding
  static String _base64UrlEncode(dynamic data) {
    String encoded;
    if (data is String) {
      encoded = base64Url.encode(utf8.encode(data));
    } else if (data is List<int>) {
      encoded = base64Url.encode(data);
    } else {
      encoded = base64Url.encode(utf8.encode(data.toString()));
    }
    return encoded
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }
}