import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:woosh/services/token_service.dart';
import 'query_executor.dart';

/// Handles user authentication and permission validation
class DatabaseAuthService {
  static DatabaseAuthService? _instance;
  static DatabaseAuthService get instance =>
      _instance ??= DatabaseAuthService._();

  DatabaseAuthService._();

  final QueryExecutor _queryExecutor = QueryExecutor.instance;

  /// Get current user ID from JWT token
  int getCurrentUserId() {
    try {
      final token = TokenService.getAccessToken();
      if (token == null) {
        throw Exception('No access token found');
      }

      final payload = JwtDecoder.decode(token);
      final userId = payload['userId'];

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      return userId is int ? userId : int.parse(userId.toString());
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      throw Exception('Failed to get current user ID: $e');
    }
  }

  /// Get current user details from token
  Future<Map<String, dynamic>> getCurrentUserDetails() async {
    try {
      final token = TokenService.getAccessToken();
      if (token == null) {
        throw Exception('No access token found');
      }

      final payload = JwtDecoder.decode(token);
      
      // Check if countryId is in the token payload (new tokens)
      if (payload['countryId'] != null) {
        return payload;
      }
      
      // For backward compatibility: fetch countryId from database if missing from token
      final userId = payload['userId'];
      if (userId == null) {
        throw Exception('User ID not found in token');
      }
      
      // Fetch countryId from database asynchronously (this is a fallback)
      final countryId = await _fetchUserCountryId(userId);
      
      if (countryId == null) {
        throw Exception('User countryId not found in database - access denied');
      }
      
      // Add countryId to payload
      payload['countryId'] = countryId;
      
      print('⚠️ Token missing countryId - fetched from database: $countryId');
      return payload;
    } catch (e) {
      print('❌ Error getting current user details: $e');
      throw Exception('Failed to get current user details: $e');
    }
  }
  
  /// Fetch user's countryId from database (for backward compatibility)
  Future<int?> _fetchUserCountryId(dynamic userId) async {
    try {
      final userIdInt = userId is int ? userId : int.parse(userId.toString());
      
      final results = await _queryExecutor.execute(
        'SELECT countryId FROM SalesRep WHERE id = ? AND status = 0',
        [userIdInt],
      );
      
      if (results.isEmpty) return null;
      return results.first['countryId'] as int?;
    } catch (e) {
      print('❌ Error fetching countryId from database: $e');
      return null;
    }
  }

  /// Validate user permissions for operation
  Future<bool> validateUserPermissions(int userId, String operation) async {
    try {
      final results = await _queryExecutor.execute(
        'SELECT role, status FROM SalesRep WHERE id = ?',
        [userId],
      );

      if (results.isEmpty) {
        print('❌ User not found: $userId');
        return false;
      }

      final row = results.first;
      final role = row['role']?.toString() ?? 'USER';
      final status = row['status'] as int? ?? 0;

      // Check if user is active
      if (status != 1) {
        print('❌ User is not active: $userId');
        return false;
      }

      print('✅ User permissions validated for $userId, role: $role');
      return true;
    } catch (e) {
      print('❌ Error validating user permissions: $e');
      return false;
    }
  }

  /// Get user role and permissions
  Future<Map<String, dynamic>?> getUserRole(int userId) async {
    try {
      final results = await _queryExecutor.execute(
        'SELECT role, status, name, email FROM SalesRep WHERE id = ?',
        [userId],
      );

      if (results.isEmpty) {
        return null;
      }

      final row = results.first;
      return {
        'role': row['role']?.toString() ?? 'USER',
        'status': row['status'] as int? ?? 0,
        'name': row['name']?.toString() ?? '',
        'email': row['email']?.toString() ?? '',
        'isActive': (row['status'] as int? ?? 0) == 1,
      };
    } catch (e) {
      print('❌ Error getting user role: $e');
      return null;
    }
  }

  /// Check if user has specific role
  Future<bool> hasRole(int userId, String requiredRole) async {
    try {
      final userRole = await getUserRole(userId);
      if (userRole == null) return false;

      return userRole['role'] == requiredRole && userRole['isActive'] == true;
    } catch (e) {
      print('❌ Error checking user role: $e');
      return false;
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin(int userId) async {
    return hasRole(userId, 'ADMIN');
  }

  /// Check if user is manager
  Future<bool> isManager(int userId) async {
    final userRole = await getUserRole(userId);
    if (userRole == null) return false;

    final role = userRole['role'] as String;
    return (role == 'ADMIN' || role == 'MANAGER') &&
        userRole['isActive'] == true;
  }

  /// Get user's sales representative ID
  Future<int?> getSalesRepId(int userId) async {
    try {
      final results = await _queryExecutor.execute(
        'SELECT id FROM SalesRep WHERE id = ? AND status = 1',
        [userId],
      );

      if (results.isEmpty) {
        return null;
      }

      return results.first['id'] as int;
    } catch (e) {
      print('❌ Error getting sales rep ID: $e');
      return null;
    }
  }

  /// Validate token and get user info
  Future<Map<String, dynamic>?> validateToken() async {
    try {
      final token = TokenService.getAccessToken();
      if (token == null) {
        return null;
      }

      final payload = JwtDecoder.decode(token);
      final userId = payload['userId'];

      if (userId == null) {
        return null;
      }

      final userRole = await getUserRole(userId);
      if (userRole == null) {
        return null;
      }

      return {
        'userId': userId,
        'role': userRole['role'],
        'name': userRole['name'],
        'email': userRole['email'],
        'isActive': userRole['isActive'],
      };
    } catch (e) {
      print('❌ Error validating token: $e');
      return null;
    }
  }

  /// Get user's accessible regions/stores
  Future<List<Map<String, dynamic>>> getUserAccessibleRegions(
      int userId) async {
    try {
      final results = await _queryExecutor.execute(
        '''
        SELECT DISTINCT r.id, r.name, r.countryId
        FROM Regions r
        INNER JOIN SalesRep sr ON sr.regionId = r.id
        WHERE sr.id = ? AND sr.status = 1
        ''',
        [userId],
      );

      return results
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'countryId': row['countryId'],
              })
          .toList();
    } catch (e) {
      print('❌ Error getting user accessible regions: $e');
      return [];
    }
  }

  /// Get user's accessible stores
  Future<List<Map<String, dynamic>>> getUserAccessibleStores(int userId) async {
    try {
      final results = await _queryExecutor.execute(
        '''
        SELECT DISTINCT s.id, s.name, s.regionId, s.status
        FROM Stores s
        INNER JOIN SalesRep sr ON sr.regionId = s.regionId
        WHERE sr.id = ? AND sr.status = 1 AND s.status = 1
        ''',
        [userId],
      );

      return results
          .map((row) => {
                'id': row['id'],
                'name': row['name'],
                'regionId': row['regionId'],
                'status': row['status'],
              })
          .toList();
    } catch (e) {
      print('❌ Error getting user accessible stores: $e');
      return [];
    }
  }

  /// Check if user can access specific store
  Future<bool> canAccessStore(int userId, int storeId) async {
    try {
      final results = await _queryExecutor.execute(
        '''
        SELECT COUNT(*) as count
        FROM Stores s
        INNER JOIN SalesRep sr ON sr.regionId = s.regionId
        WHERE sr.id = ? AND s.id = ? AND sr.status = 1 AND s.status = 1
        ''',
        [userId, storeId],
      );

      return results.first['count'] as int > 0;
    } catch (e) {
      print('❌ Error checking store access: $e');
      return false;
    }
  }

  /// Get user's country ID
  Future<int?> getUserCountryId(int userId) async {
    try {
      final results = await _queryExecutor.execute(
        'SELECT countryId FROM SalesRep WHERE id = ? AND status = 1',
        [userId],
      );

      if (results.isEmpty) {
        return null;
      }

      return results.first['countryId'] as int;
    } catch (e) {
      print('❌ Error getting user country ID: $e');
      return null;
    }
  }
}
