import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/token_service.dart';
import 'package:woosh/services/database/connection_pool.dart';
import 'package:mysql1/mysql1.dart';
import 'package:uuid/uuid.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// 1 is inactive 0 is active
/// Authentication service using direct database connections
class AuthService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Login with phone number and password
  static Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    try {
      // Ensure database is initialized (only once)
      if (!_db.isInitialized) {
        print('🔄 Initializing database before login...');
        await _db.initialize();
      }

      // Get a connection from the pool
      final connection = await ConnectionPool.instance.getConnection();
      try {
        // First, get user by phone number only (don't compare password in SQL)
        final results = await connection.query(
          'SELECT * FROM SalesRep WHERE phoneNumber = ? AND status = 0',
          [phoneNumber],
        );

        if (results.isEmpty) {
          return {
            'success': false,
            'message': 'Invalid phone number or password',
          };
        }

        final user = results.first;
        final storedPassword = user.fields['password'];

        // Verify password using BCrypt
        if (!BCrypt.checkpw(password, storedPassword)) {
          return {
            'success': false,
            'message': 'Invalid phone number or password',
          };
        }

        final userId = user.fields['id'];

        // 1. Generate access token (JWT, 5 hours)
        final accessToken = _generateJwtToken(userId, expiresIn: const Duration(hours: 5));
        final accessTokenExp = DateTime.now().add(const Duration(hours: 5));

        // 2. Generate refresh token (random string, 7 days)
        final refreshToken = const Uuid().v4();
        final refreshTokenExp = DateTime.now().add(const Duration(days: 7));

        // 3. Store both tokens in DB
        await _db.query(
          'INSERT INTO Token (token, salesRepId, createdAt, expiresAt, tokenType) VALUES (?, ?, NOW(), ?, ?)',
          [accessToken, userId, accessTokenExp, 'access']
        );
        await _db.query(
          'INSERT INTO Token (token, salesRepId, createdAt, expiresAt, tokenType) VALUES (?, ?, NOW(), ?, ?)',
          [refreshToken, userId, refreshTokenExp, 'refresh']
        );

        // 4. Return both tokens
        return {
          'success': true,
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'user': user,
          'message': 'Login successful',
        };
      } finally {
        // Always return the connection to the pool
        ConnectionPool.instance.returnConnection(connection);
      }
    } catch (e) {
      print('❌ Login failed: $e');
      return {
        'success': false,
        'message': 'Login failed. Please try again.',
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

  /// Generate JWT token with custom expiry
  static String _generateJwtToken(int userId, {required Duration expiresIn}) {
    // You can use your preferred JWT package and secret
    // This is a placeholder for actual JWT generation logic
    final payload = {
      'userId': userId,
      'exp': (DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000),
    };
    // Replace with your JWT signing logic
    return base64Url.encode(utf8.encode(json.encode(payload)));
  }

  /// Refresh token method
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      // 1. Look up the refresh token in DB
      final results = await _db.query(
        'SELECT * FROM Token WHERE token = ? AND tokenType = ? AND blacklisted = 0 AND expiresAt > NOW()',
        [refreshToken, 'refresh']
      );
      if (results.isEmpty) {
        return {'success': false, 'message': 'Invalid or expired refresh token'};
      }
      final tokenRow = results.first;
      final userId = tokenRow.fields['salesRepId'];

      // 2. Generate new access token (5 hours)
      final newAccessToken = _generateJwtToken(userId, expiresIn: const Duration(hours: 5));
      final newAccessTokenExp = DateTime.now().add(const Duration(hours: 5));

      // 3. Store new access token in DB
      await _db.query(
        'INSERT INTO Token (token, salesRepId, createdAt, expiresAt, tokenType) VALUES (?, ?, NOW(), ?, ?)',
        [newAccessToken, userId, newAccessTokenExp, 'access']
      );

      // 4. Optionally, rotate refresh token (not implemented here)

      return {
        'success': true,
        'accessToken': newAccessToken,
        'refreshToken': refreshToken, // or new one if rotating
      };
    } catch (e) {
      print('❌ Refresh token failed: $e');
      return {'success': false, 'message': 'Refresh token failed'};
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

  /// Test retry logic (for debugging)
  static Future<Map<String, dynamic>> testRetryLogic() async {
    const testPhoneNumber = '1234567890';
    const testPassword = 'testpassword';

    final result = await login(testPhoneNumber, testPassword);

    return result;
  }
}
