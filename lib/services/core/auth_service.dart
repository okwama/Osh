import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';

/// Service for managing authentication using direct database connections
class AuthService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get user profile by ID
  static Future<Map<String, dynamic>?> getProfile(int userId) async {
    try {
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, password, countryId, country,
          region_id, region, route_id, route, route_id_update, route_name_update,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          role, manager_type, status, createdAt, updatedAt,
          retail_manager, key_channel_manager, distribution_manager,
          photoUrl, managerId
        FROM SalesRep 
        WHERE id = ? AND status = 0
      ''';

      final results = await _db.query(sql, [userId]);

      if (results.isEmpty) return null;

      final fields = results.first.fields;
      final salesRep = SalesRepModel.fromMap(fields);

      return {
        'salesRep': salesRep.toMap(),
        'success': true,
      };
    } catch (e) {
      return null;
    }
  }

  /// Update user profile photo
  static Future<String?> updateProfilePhoto(int userId, String photoUrl) async {
    try {
      final now = DateTime.now().toIso8601String();

      const sql = '''
        UPDATE SalesRep 
        SET photoUrl = ?, updatedAt = ?
        WHERE id = ?
      ''';

      final result = await _db.query(sql, [photoUrl, now, userId]);

      if ((result.affectedRows ?? 0) > 0) {
        return photoUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user password
  static Future<Map<String, dynamic>> updatePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // First, verify current password
      const verifySql = '''
        SELECT password FROM SalesRep 
        WHERE id = ? AND status = 0
      ''';

      final verifyResults = await _db.query(verifySql, [userId]);

      if (verifyResults.isEmpty) {
        return {
          'success': false,
          'message': 'User not found or inactive',
        };
      }

      final storedPassword = verifyResults.first.fields['password'];

      // In a real implementation, you would hash and compare passwords
      // For now, we'll do a simple comparison
      if (storedPassword != currentPassword) {
        return {
          'success': false,
          'message': 'Current password is incorrect',
        };
      }

      // Update password
      final now = DateTime.now().toIso8601String();

      const updateSql = '''
        UPDATE SalesRep 
        SET password = ?, updatedAt = ?
        WHERE id = ?
      ''';

      final result = await _db.query(updateSql, [newPassword, now, userId]);

      if ((result.affectedRows ?? 0) > 0) {
        return {
          'success': true,
          'message': 'Password updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while updating password',
      };
    }
  }

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required int countryId,
    required String country,
    required int regionId,
    required String region,
    required int routeId,
    required String route,
    String role = 'USER',
    int managerType = 0,
    int? managerId,
  }) async {
    try {
      // Check if user already exists
      const checkSql = '''
        SELECT id FROM SalesRep 
        WHERE email = ? OR phoneNumber = ?
      ''';

      final checkResults = await _db.query(checkSql, [email, phoneNumber]);

      if (checkResults.isNotEmpty) {
        return {
          'success': false,
          'message': 'User with this email or phone number already exists',
        };
      }

      // Insert new user
      const insertSql = '''
        INSERT INTO SalesRep (
          name, email, phoneNumber, password, countryId, country,
          region_id, region, route_id, route, route_id_update, route_name_update,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          role, manager_type, status, createdAt, updatedAt,
          retail_manager, key_channel_manager, distribution_manager,
          photoUrl, managerId
        ) VALUES (
          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, ?, ?, 0, NOW(), NOW(), 0, 0, 0, '', ?
        )
      ''';

      final result = await _db.query(insertSql, [
        name,
        email,
        phoneNumber,
        password,
        countryId,
        country,
        regionId,
        region,
        routeId,
        route,
        routeId,
        route,
        role,
        managerType,
        managerId,
      ]);

      if (result.insertId != null) {
        return {
          'success': true,
          'message': 'User registered successfully',
          'userId': result.insertId,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to register user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while registering user',
      };
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      const sql = '''
        SELECT 
          id, name, email, phoneNumber, password, countryId, country,
          region_id, region, route_id, route, route_id_update, route_name_update,
          visits_targets, new_clients, vapes_targets, pouches_targets,
          role, manager_type, status, createdAt, updatedAt,
          retail_manager, key_channel_manager, distribution_manager,
          photoUrl, managerId
        FROM SalesRep 
        WHERE email = ? AND password = ? AND status = 0
      ''';

      final results = await _db.query(sql, [email, password]);

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      final fields = results.first.fields;
      final salesRep = SalesRepModel.fromMap(fields);

      // Generate a simple token (in real implementation, use JWT)
      final token =
          'token_${DateTime.now().millisecondsSinceEpoch}_${salesRep.id}';

      return {
        'success': true,
        'message': 'Login successful',
        'token': token,
        'salesRep': salesRep.toMap(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during login',
      };
    }
  }

  /// Logout user (invalidate token)
  static Future<bool> logout(String token) async {
    try {
      const sql = '''
        UPDATE Token 
        SET blacklisted = 1, lastUsedAt = NOW()
        WHERE token = ?
      ''';

      final result = await _db.query(sql, [token]);
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }
}