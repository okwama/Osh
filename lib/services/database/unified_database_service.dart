import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:woosh/config/database_config.dart';
import 'package:woosh/utils/safe_error_handler.dart';

/// Unified database service with safe socket access, error handling, and performance optimization
class UnifiedDatabaseService {
  static UnifiedDatabaseService? _instance;
  static UnifiedDatabaseService get instance =>
      _instance ??= UnifiedDatabaseService._();

  UnifiedDatabaseService._();

  // Connection management
  final List<MySqlConnection> _connections = [];
  final Map<MySqlConnection, DateTime> _lastUsed = {};
  final int _maxConnections = 3;
  final Duration _connectionMaxIdleTime = const Duration(minutes: 5);

  // Circuit breaker
  int _consecutiveFailures = 0;
  DateTime? _circuitBreakerOpenTime;
  static const int _maxFailures = 3;
  static const Duration _circuitBreakerTimeout = const Duration(minutes: 1);

  // Performance tracking
  final List<QueryMetrics> _queryMetrics = [];
  final Map<String, Results> _queryCache = {};
  static const int _maxCacheSize = 100;
  static const Duration _cacheValidity = const Duration(minutes: 5);

  // Health monitoring
  Timer? _healthCheckTimer;
  final Stopwatch _uptimeStopwatch = Stopwatch()..start();

  /// Execute a query with safe socket access and error handling
  Future<Results> execute(String sql, [List<Object?>? values]) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Check cache first
      final cacheKey = _generateCacheKey(sql, values);
      final cachedResult = _getCachedResult(cacheKey);
      if (cachedResult != null) {
        _logQueryMetrics(sql, 0, stopwatch, true);
        return cachedResult;
      }

      // Execute query with retry logic
      final results = await _executeWithRetry(sql, values);

      // Cache successful results
      _cacheResult(cacheKey, results);

      _logQueryMetrics(sql, results.length, stopwatch, false);
      return results;
    } catch (e) {
      _logQueryMetrics(sql, 0, stopwatch, false);

      // Return user-friendly error
      throw Exception(SafeErrorHandler.getUserFriendlyMessage(e));
    }
  }

  /// Execute query with retry logic
  Future<Results> _executeWithRetry(String sql, [List<Object?>? values]) async {
    const int maxRetries = 2;
    const Duration retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check circuit breaker
        if (_isCircuitBreakerOpen()) {
          throw Exception(
              'Database temporarily unavailable. Please try again later.');
        }

        final connection = await _getConnection();
        final results = await connection.query(sql, values).timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('Query timeout'),
            );

        _resetCircuitBreaker();
        return results;
      } catch (e) {
        print('❌ Query attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          _incrementCircuitBreaker();
          throw Exception('Query failed after $maxRetries attempts');
        }

        await Future.delayed(retryDelay * attempt);
      }
    }

    throw Exception('Query execution failed');
  }

  /// Get a safe database connection
  Future<MySqlConnection> _getConnection() async {
    // Try to get existing healthy connection
    for (final connection in _connections) {
      if (_isConnectionHealthy(connection)) {
        _lastUsed[connection] = DateTime.now();
        return connection;
      }
    }

    // Create new connection if under limit
    if (_connections.length < _maxConnections) {
      return await _createConnection();
    }

    // Wait for available connection
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 500));

      for (final connection in _connections) {
        if (_isConnectionHealthy(connection)) {
          _lastUsed[connection] = DateTime.now();
          return connection;
        }
      }
    }

    throw Exception('Timeout waiting for database connection');
  }

  /// Create new connection
  Future<MySqlConnection> _createConnection() async {
    const int maxRetries = 2;
    const Duration retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final settings = ConnectionSettings(
          host: DatabaseConfig.host,
          port: DatabaseConfig.port,
          user: DatabaseConfig.user,
          password: DatabaseConfig.password,
          db: DatabaseConfig.database,
          timeout: const Duration(seconds: 10),
          useSSL: false,
        );

        final connection = await MySqlConnection.connect(settings);

        // Test connection
        await connection.query('SELECT 1').timeout(
              const Duration(seconds: 3),
              onTimeout: () =>
                  throw TimeoutException('Connection test timeout'),
            );

        _connections.add(connection);
        _lastUsed[connection] = DateTime.now();

        print('🔗 Database connection created (attempt $attempt)');
        return connection;
      } catch (e) {
        print('❌ Connection attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          throw Exception('Failed to create database connection');
        }

        await Future.delayed(retryDelay * attempt);
      }
    }

    throw Exception('Failed to create database connection');
  }

  /// Check if connection is healthy
  bool _isConnectionHealthy(MySqlConnection connection) {
    try {
      final lastUsed = _lastUsed[connection];
      if (lastUsed == null) return false;

      // Check if too old
      if (DateTime.now().difference(lastUsed) > _connectionMaxIdleTime) {
        return false;
      }

      // Test connection
      try {
        connection.query('SELECT 1').timeout(
              const Duration(seconds: 2),
              onTimeout: () => throw TimeoutException('Health check timeout'),
            );
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Circuit breaker methods
  bool _isCircuitBreakerOpen() {
    if (_circuitBreakerOpenTime == null) return false;

    final timeSinceOpen = DateTime.now().difference(_circuitBreakerOpenTime!);
    if (timeSinceOpen >= _circuitBreakerTimeout) {
      _circuitBreakerOpenTime = null;
      _consecutiveFailures = 0;
      return false;
    }

    return _consecutiveFailures >= _maxFailures;
  }

  void _incrementCircuitBreaker() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _maxFailures) {
      _circuitBreakerOpenTime = DateTime.now();
      print('🚨 Circuit breaker opened after $_consecutiveFailures failures');
    }
  }

  void _resetCircuitBreaker() {
    if (_consecutiveFailures > 0) {
      print('✅ Circuit breaker reset');
    }
    _consecutiveFailures = 0;
    _circuitBreakerOpenTime = null;
  }

  /// Caching methods
  String _generateCacheKey(String sql, [List<Object?>? values]) {
    final valuesString = values?.join(',') ?? '';
    return '$sql$valuesString';
  }

  Results? _getCachedResult(String cacheKey) {
    final cached = _queryCache[cacheKey];
    if (cached != null) {
      // Check if cache is still valid
      final cacheTime = DateTime.now();
      if (cacheTime.difference(DateTime.now()).inMinutes <
          _cacheValidity.inMinutes) {
        return cached;
      } else {
        _queryCache.remove(cacheKey);
      }
    }
    return null;
  }

  void _cacheResult(String cacheKey, Results results) {
    if (_queryCache.length >= _maxCacheSize) {
      final oldestKey = _queryCache.keys.first;
      _queryCache.remove(oldestKey);
    }
    _queryCache[cacheKey] = results;
  }

  /// Metrics and logging
  void _logQueryMetrics(
      String sql, int rowCount, Stopwatch stopwatch, bool fromCache) {
    final metrics = QueryMetrics(
      sql: sql,
      durationMs: stopwatch.elapsedMilliseconds,
      rowCount: rowCount,
      fromCache: fromCache,
    );

    _queryMetrics.add(metrics);

    if (_queryMetrics.length > 100) {
      _queryMetrics.removeAt(0);
    }
  }

  /// Convenience methods
  Future<ResultRow?> executeSingle(String sql, [List<Object?>? values]) async {
    final results = await execute(sql, values);
    return results.isNotEmpty ? results.first : null;
  }

  Future<T?> executeScalar<T>(String sql, [List<Object?>? values]) async {
    final results = await execute(sql, values);
    if (results.isEmpty || results.first.isEmpty) return null;

    final firstRow = results.first;
    final firstValue =
        firstRow.values?.isNotEmpty == true ? firstRow.values!.first : null;

    if (firstValue is T) {
      return firstValue;
    }

    return null;
  }

  Future<int> executeCount(String sql, [List<Object?>? values]) async {
    final result = await executeScalar<int>(sql, values);
    return result ?? 0;
  }

  Future<T> executeTransaction<T>(
      Future<T> Function(MySqlConnection) operation) async {
    MySqlConnection? connection;

    try {
      connection = await _getConnection();

      await connection.query('START TRANSACTION');
      final result = await operation(connection);
      await connection.query('COMMIT');

      return result;
    } catch (e) {
      if (connection != null) {
        try {
          await connection.query('ROLLBACK');
        } catch (rollbackError) {}
      }
      rethrow;
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Create initial connection
      await _createConnection();

      _startHealthCheckTimer();
      print('✅ Unified database service initialized');
    } catch (e) {
      print('⚠️ Database service initialization failed: $e');
      // Continue without initial connection - will create on demand
    }
  }

  /// Start health check timer
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _cleanupIdleConnections();
    });
  }

  /// Clean up idle connections
  void _cleanupIdleConnections() {
    final now = DateTime.now();
    final toRemove = <MySqlConnection>[];

    for (final connection in _connections) {
      final lastUsed = _lastUsed[connection];
      if (lastUsed != null &&
          now.difference(lastUsed) > _connectionMaxIdleTime) {
        toRemove.add(connection);
      }
    }

    for (final connection in toRemove) {
      _connections.remove(connection);
      _lastUsed.remove(connection);
      try {
        connection.close();
      } catch (e) {}
    }

    if (toRemove.isNotEmpty) {
      print('🧹 Cleaned up ${toRemove.length} idle connections');
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    if (_queryMetrics.isEmpty) {
      return {
        'total_queries': 0,
        'average_duration_ms': 0,
        'cache_hit_rate': 0.0,
        'slow_queries': 0,
        'circuit_breaker': {
          'consecutive_failures': _consecutiveFailures,
          'is_open': _isCircuitBreakerOpen(),
        },
      };
    }

    final totalQueries = _queryMetrics.length;
    final totalDuration =
        _queryMetrics.map((m) => m.durationMs).reduce((a, b) => a + b);
    final averageDuration = totalDuration / totalQueries;
    final cacheHits = _queryMetrics.where((m) => m.fromCache).length;
    final cacheHitRate = cacheHits / totalQueries;
    final slowQueries = _queryMetrics.where((m) => m.durationMs > 1000).length;

    return {
      'total_queries': totalQueries,
      'average_duration_ms': averageDuration.round(),
      'cache_hit_rate': (cacheHitRate * 100).roundToDouble(),
      'slow_queries': slowQueries,
      'cache_size': _queryCache.length,
      'circuit_breaker': {
        'consecutive_failures': _consecutiveFailures,
        'is_open': _isCircuitBreakerOpen(),
        'open_since': _circuitBreakerOpenTime?.toIso8601String(),
      },
      'connections': {
        'active': _connections.length,
        'max': _maxConnections,
      },
    };
  }

  /// Clear cache
  void clearCache() {
    _queryCache.clear();
    print('🧹 Query cache cleared');
  }

  /// Dispose resources
  Future<void> dispose() async {
    _healthCheckTimer?.cancel();

    for (final connection in _connections) {
      try {
        await connection.close();
      } catch (e) {}
    }

    _connections.clear();
    _lastUsed.clear();
    _queryCache.clear();
    _queryMetrics.clear();
  }
}

/// Query metrics class
class QueryMetrics {
  final String sql;
  final int durationMs;
  final int rowCount;
  final bool fromCache;
  final DateTime timestamp;

  QueryMetrics({
    required this.sql,
    required this.durationMs,
    required this.rowCount,
    required this.fromCache,
  }) : timestamp = DateTime.now();
}
