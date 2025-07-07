import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:woosh/services/database/connection_pool.dart';
import 'package:woosh/services/database/query_executor.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database/auth_service.dart';

/// Core database service facade that coordinates between specialized services
/// Provides a unified interface for database operations
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  // Specialized services
  final ConnectionPool _connectionPool = ConnectionPool.instance;
  final QueryExecutor _queryExecutor = QueryExecutor.instance;
  final PaginationService _paginationService = PaginationService.instance;
  final DatabaseAuthService _authService = DatabaseAuthService.instance;

  /// Initialize the database service
  Future<void> initialize() async {
    try {
      await _connectionPool.initialize();
    } catch (e) {
      rethrow;
    }
  }

  /// Execute a query with automatic connection management
  Future<Results> query(String sql, [List<Object?>? values]) async {
    return _queryExecutor.execute(sql, values);
  }

  /// Execute a transaction
  Future<T> transaction<T>(
      Future<T> Function(MySqlConnection) operation) async {
    return _queryExecutor.executeTransaction(operation);
  }

  /// Fetch paginated results using keyset pagination
  Future<PaginatedResult<ResultRow>> fetchPaginated({
    required String table,
    required String cursorField,
    dynamic lastCursorValue,
    int limit = 100,
    Map<String, dynamic> filters = const {},
    String? orderDirection,
    List<String>? columns,
    String? additionalWhere,
  }) async {
    return _paginationService.fetchKeyset(
      table: table,
      cursorField: cursorField,
      lastCursorValue: lastCursorValue,
      limit: limit,
      filters: filters,
      orderDirection: orderDirection,
      columns: columns,
      additionalWhere: additionalWhere,
    );
  }

  /// Fetch paginated results using offset pagination
  Future<PaginatedResult<ResultRow>> fetchOffsetPaginated({
    required String table,
    int page = 1,
    int limit = 100,
    Map<String, dynamic> filters = const {},
    String? orderBy,
    String? orderDirection,
    List<String>? columns,
    String? additionalWhere,
  }) async {
    return _paginationService.fetchOffset(
      table: table,
      page: page,
      limit: limit,
      filters: filters,
      orderBy: orderBy,
      orderDirection: orderDirection,
      columns: columns,
      additionalWhere: additionalWhere,
    );
  }

  /// Get current user ID from JWT token
  int getCurrentUserId() {
    return _authService.getCurrentUserId();
  }

  /// Get current user details from token
  Future<Map<String, dynamic>> getCurrentUserDetails() async {
    return await _authService.getCurrentUserDetails();
  }

  /// Validate user permissions for operation
  Future<bool> validateUserPermissions(int userId, String operation) async {
    return _authService.validateUserPermissions(userId, operation);
  }

  /// Build WHERE clause for filtering
  String buildWhereClause(Map<String, dynamic> filters) {
    return _paginationService.buildWhereClause(filters);
  }

  /// Build ORDER BY clause
  String buildOrderByClause(String? orderBy, String? orderDirection) {
    return _paginationService.buildOrderByClause(orderBy, orderDirection);
  }

  /// Build LIMIT clause for pagination
  String buildLimitClause(int? page, int? limit) {
    return _paginationService.buildLimitClause(page, limit);
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _connectionPool.dispose();
  }

  /// Health check
  Future<bool> isHealthy() async {
    try {
      final results = await query('SELECT 1 as health_check').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Health check timed out');
        },
      );
      final isHealthy = results.isNotEmpty;
      return isHealthy;
    } catch (e) {
      return false;
    }
  }

  /// Test database connectivity
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final startTime = DateTime.now();

      // Test connection pool
      final connection = await _connectionPool.getConnection();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Test a simple query
      final results = await connection.query('SELECT 1 as test').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Query test timed out');
        },
      );

      _connectionPool.returnConnection(connection);

      return {
        'success': true,
        'message': 'Database connection and query test successful',
        'response_time_ms': duration.inMilliseconds,
        'query_test_passed': results.isNotEmpty,
        'pool_metrics': _connectionPool.getMetrics(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Database connection failed: $e',
        'pool_metrics': _connectionPool.getMetrics(),
      };
    }
  }

  /// Get comprehensive database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final poolMetrics = _connectionPool.getMetrics();
      final queryMetrics = _queryExecutor.getMetrics();

      return {
        ...poolMetrics,
        ...queryMetrics,
        'is_healthy': await isHealthy(),
        'connection_timeout_seconds': 30,
        'max_wait_time_seconds': 25,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Convenience methods for common operations

  /// Execute a single row query
  Future<ResultRow?> querySingle(String sql, [List<Object?>? values]) async {
    return _queryExecutor.executeSingle(sql, values);
  }

  /// Execute a scalar query
  Future<T?> queryScalar<T>(String sql, [List<Object?>? values]) async {
    return _queryExecutor.executeScalar<T>(sql, values);
  }

  /// Execute a count query
  Future<int> queryCount(String sql, [List<Object?>? values]) async {
    return _queryExecutor.executeCount(sql, values);
  }

  /// Check if table exists
  Future<bool> tableExists(String tableName) async {
    return _queryExecutor.tableExists(tableName);
  }

  /// Get table row count
  Future<int> getTableRowCount(String tableName, [String? whereClause]) async {
    return _queryExecutor.getTableRowCount(tableName, whereClause);
  }

  // Auth convenience methods

  /// Get user role and permissions
  Future<Map<String, dynamic>?> getUserRole(int userId) async {
    return _authService.getUserRole(userId);
  }

  /// Check if user has specific role
  Future<bool> hasRole(int userId, String requiredRole) async {
    return _authService.hasRole(userId, requiredRole);
  }

  /// Check if user is admin
  Future<bool> isAdmin(int userId) async {
    return _authService.isAdmin(userId);
  }

  /// Check if user is manager
  Future<bool> isManager(int userId) async {
    return _authService.isManager(userId);
  }

  /// Get user's sales representative ID
  Future<int?> getSalesRepId(int userId) async {
    return _authService.getSalesRepId(userId);
  }

  /// Validate token and get user info
  Future<Map<String, dynamic>?> validateToken() async {
    return _authService.validateToken();
  }

  /// Get user's accessible regions
  Future<List<Map<String, dynamic>>> getUserAccessibleRegions(
      int userId) async {
    return _authService.getUserAccessibleRegions(userId);
  }

  /// Get user's accessible stores
  Future<List<Map<String, dynamic>>> getUserAccessibleStores(int userId) async {
    return _authService.getUserAccessibleStores(userId);
  }

  /// Check if user can access specific store
  Future<bool> canAccessStore(int userId, int storeId) async {
    return _authService.canAccessStore(userId, storeId);
  }

  /// Get user's country ID
  Future<int?> getUserCountryId(int userId) async {
    return _authService.getUserCountryId(userId);
  }
}