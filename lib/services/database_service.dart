import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:woosh/services/database/connection_pool.dart';
import 'package:woosh/services/database/unified_database_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database/auth_service.dart';

/// Core database service facade that coordinates between specialized services
/// Provides a unified interface for database operations
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Specialized services
  final ConnectionPool _connectionPool = ConnectionPool.instance;
  final UnifiedDatabaseService _queryExecutor = UnifiedDatabaseService.instance;
  final PaginationService _paginationService = PaginationService.instance;
  final DatabaseAuthService _authService = DatabaseAuthService.instance;

  /// Initialize the database service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _connectionPool.initialize();
      _isInitialized = true;
      print('✅ Database service initialized successfully');
    } catch (e) {
      print('❌ Database service initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Execute a query with automatic connection management and error handling
  Future<Results> query(String sql, [List<Object?>? values]) async {
    try {
      return await _queryExecutor.execute(sql, values);
    } catch (e) {
      // Handle socket connection issues
      if (e.toString().contains('Socket has been closed') ||
          e.toString().contains('SocketException')) {
        print('🔌 Socket connection issue detected, attempting recovery...');

        // Try to reinitialize the connection pool
        try {
          await _connectionPool.dispose();
          await _connectionPool.initialize();
          print('✅ Connection pool reinitialized successfully');

          // Retry the query once
          return await _queryExecutor.execute(sql, values);
        } catch (retryError) {
          print('❌ Recovery failed: $retryError');
          throw Exception(
              'Database connection failed after recovery attempt: $e');
        }
      }

      rethrow;
    }
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
      whereParams: [], // Add empty whereParams array
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
    const int maxRetries = 2;
    const Duration baseDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔍 Testing database connection (attempt $attempt)...');

        // First check if pool is initialized
        if (!_isInitialized) {
          print(
              '⚠️ Database service not initialized, attempting initialization...');
          await initialize();
        }

        final startTime = DateTime.now();

        // Get connection from pool
        print('🔄 Getting connection from pool...');
        final connection = await _connectionPool.getConnection();

        // Test a simple query
        print('🔄 Testing query execution...');
        final results = await connection.query('SELECT 1 as test').timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Query test timed out');
          },
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        _connectionPool.returnConnection(connection);

        // Get pool metrics for diagnostics
        final metrics = _connectionPool.getMetrics();

        print('✅ Database connection test successful');
        print('📊 Response time: ${duration.inMilliseconds}ms');
        print('📊 Pool metrics: $metrics');

        return {
          'success': true,
          'message': 'Database connection and query test successful',
          'response_time_ms': duration.inMilliseconds,
          'query_test_passed': results.isNotEmpty,
          'pool_metrics': metrics,
        };
      } catch (e) {
        print('❌ Database test failed on attempt $attempt: $e');

        // If this is the last attempt, return detailed error
        if (attempt == maxRetries) {
          final metrics = _connectionPool.getMetrics();
          final errorMessage = _getDetailedErrorMessage(e);

          return {
            'success': false,
            'message': errorMessage,
            'error_details': e.toString(),
            'pool_metrics': metrics,
          };
        }

        // Calculate delay with exponential backoff
        final delay = Duration(seconds: baseDelay.inSeconds * attempt);
        print('⏳ Waiting ${delay.inSeconds} seconds before retry...');
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but just in case
    return {
      'success': false,
      'message': 'Database connection test failed after $maxRetries attempts',
      'pool_metrics': _connectionPool.getMetrics(),
    };
  }

  /// Get detailed error message based on exception type
  String _getDetailedErrorMessage(dynamic e) {
    final error = e.toString().toLowerCase();

    if (error.contains('timeout')) {
      return 'Database connection timed out. The server might be overloaded or your network connection is slow.';
    } else if (error.contains('refused')) {
      return 'Database connection refused. The server might be down or blocking your connection.';
    } else if (error.contains('access denied') ||
        error.contains('authentication')) {
      return 'Database authentication failed. Please verify your credentials.';
    } else if (error.contains('circuit breaker')) {
      return 'Too many failed connection attempts. Please wait a few minutes and try again.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Database connection failed. Please try again or contact support if the issue persists.';
    }
  }

  /// Get comprehensive database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final poolMetrics = _connectionPool.getMetrics();

      return {
        ...poolMetrics,
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
    try {
      final results = await _queryExecutor.execute(
        "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?",
        [tableName],
      );
      return results.isNotEmpty && results.first['count'] > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get table row count
  Future<int> getTableRowCount(String tableName, [String? whereClause]) async {
    try {
      final sql = whereClause != null && whereClause.isNotEmpty
          ? "SELECT COUNT(*) as count FROM $tableName WHERE $whereClause"
          : "SELECT COUNT(*) as count FROM $tableName";

      final results = await _queryExecutor.execute(sql);
      return results.isNotEmpty ? results.first['count'] : 0;
    } catch (e) {
      return 0;
    }
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
