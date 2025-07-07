import 'dart:async';
import 'dart:collection';
import 'package:mysql1/mysql1.dart';
import 'package:woosh/config/database_config.dart';

/// Manages database connection pooling with health monitoring
class ConnectionPool {
  static ConnectionPool? _instance;
  static ConnectionPool get instance => _instance ??= ConnectionPool._();

  ConnectionPool._();

  // Connection pool management
  final Queue<MySqlConnection> _connectionPool = Queue();
  final int _maxConnections = 20;
  final int _minConnections = 5;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  // Connection health tracking
  final Map<MySqlConnection, DateTime> _connectionLastUsed = {};
  final Duration _connectionMaxIdleTime = const Duration(minutes: 10);
  Timer? _healthCheckTimer;

  // Performance metrics
  Duration _lastConnectionWaitTime = Duration.zero;
  final Stopwatch _uptimeStopwatch = Stopwatch()..start();

  /// Initialize the connection pool
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initCompleter.isCompleted) return;

    try {

      // Create minimum connections concurrently
      final connectionFutures =
          List.generate(_minConnections, (i) => _createConnection());
      await Future.wait(connectionFutures);

      _isInitialized = true;
      _initCompleter.complete();
      _startHealthCheckTimer();

      print(
          '✅ Connection pool initialized with ${_connectionPool.length} connections');
    } catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Create a new database connection
  Future<MySqlConnection> _createConnection() async {
    try {
      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.user,
        password: DatabaseConfig.password,
        db: DatabaseConfig.database,
        timeout: const Duration(seconds: 20),
      );

      final connection = await MySqlConnection.connect(settings);
      _connectionLastUsed[connection] = DateTime.now();
      _connectionPool.add(connection);
      return connection;
    } catch (e) {
      throw _formatConnectionError(e);
    }
  }

  /// Format connection error messages
  Exception _formatConnectionError(dynamic e) {
    if (e.toString().contains('timeout')) {
      return Exception(
          'Database connection timeout. Please check your internet connection and try again.');
    } else if (e.toString().contains('refused')) {
      return Exception(
          'Database connection refused. The database server may be down or the port is blocked.');
    } else if (e.toString().contains('authentication')) {
      return Exception(
          'Database authentication failed. Please check your credentials.');
    } else {
      return Exception('Database connection failed: $e');
    }
  }

  /// Get a connection from the pool
  Future<MySqlConnection> getConnection() async {
    final stopwatch = Stopwatch()..start();

    try {
      await _initCompleter.future;

      // Return existing connection if available
      if (_connectionPool.isNotEmpty) {
        final connection = _connectionPool.removeFirst();
        _connectionLastUsed[connection] = DateTime.now();
        return connection;
      }

      // Create new connection if under max limit
      if (_connectionLastUsed.length < _maxConnections) {
        print(
            '🔗 Creating new database connection (pool size: ${_connectionPool.length})');
        return await _createConnection();
      }

      // Wait for available connection with timeout
      const maxWaitTime = Duration(seconds: 25);
      final startTime = DateTime.now();

      while (DateTime.now().difference(startTime) < maxWaitTime) {
        await Future.delayed(const Duration(milliseconds: 250));

        if (_connectionPool.isNotEmpty) {
          final connection = _connectionPool.removeFirst();
          _connectionLastUsed[connection] = DateTime.now();
          return connection;
        }
      }

      throw Exception(
          'Timeout waiting for available database connection after ${maxWaitTime.inSeconds} seconds');
    } finally {
      _lastConnectionWaitTime = stopwatch.elapsed;
      if (stopwatch.elapsedMilliseconds > 500) {
        print(
            '⚠️ Slow connection acquisition: ${stopwatch.elapsedMilliseconds}ms');
      }
    }
  }

  /// Return a connection to the pool
  void returnConnection(MySqlConnection connection) {
    try {
      if (_isConnectionHealthy(connection)) {
        if (_connectionPool.length < _maxConnections) {
          _connectionPool.add(connection);
          _connectionLastUsed[connection] = DateTime.now();
        } else {
          connection.close();
          _connectionLastUsed.remove(connection);
        }
      } else {
        connection.close();
        _connectionLastUsed.remove(connection);
      }
    } catch (e) {
      try {
        connection.close();
      } catch (closeError) {
      }
      _connectionLastUsed.remove(connection);
    }
  }

  /// Check if a connection is healthy
  bool _isConnectionHealthy(MySqlConnection connection) {
    try {
      final lastUsed = _connectionLastUsed[connection];
      if (lastUsed == null) return false;

      return DateTime.now().difference(lastUsed) <= _connectionMaxIdleTime;
    } catch (e) {
      return false;
    }
  }

  /// Start health check timer
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      _cleanupIdleConnections();
    });
  }

  /// Clean up idle connections
  void _cleanupIdleConnections() {
    final now = DateTime.now();
    final toRemove = <MySqlConnection>[];

    for (final connection in _connectionPool) {
      final lastUsed = _connectionLastUsed[connection];
      if (lastUsed != null &&
          now.difference(lastUsed) > _connectionMaxIdleTime) {
        toRemove.add(connection);
      }
    }

    for (final connection in toRemove) {
      _connectionPool.remove(connection);
      _connectionLastUsed.remove(connection);
      try {
        connection.close();
      } catch (e) {
      }
    }

    if (toRemove.isNotEmpty) {
    }
  }

  /// Get connection pool metrics
  Map<String, dynamic> getMetrics() {
    final now = DateTime.now();
    final idleConnections = _connectionPool.length;
    final activeConnections = _connectionLastUsed.length - idleConnections;

    int oldestConnectionMinutes = 0;
    if (_connectionLastUsed.isNotEmpty) {
      oldestConnectionMinutes = _connectionLastUsed.values
          .map((time) => now.difference(time).inMinutes)
          .reduce((a, b) => a > b ? a : b);
    }

    return {
      'pool_size': _connectionPool.length,
      'max_connections': _maxConnections,
      'min_connections': _minConnections,
      'idle_connections': idleConnections,
      'active_connections': activeConnections,
      'is_initialized': _isInitialized,
      'connection_wait_time_ms': _lastConnectionWaitTime.inMilliseconds,
      'oldest_connection_minutes': oldestConnectionMinutes,
      'uptime_minutes': _uptimeStopwatch.elapsed.inMinutes,
    };
  }

  /// Clean up all connections
  Future<void> dispose() async {

    _healthCheckTimer?.cancel();

    for (final connection in _connectionPool) {
      try {
        await connection.close();
      } catch (e) {
      }
    }

    _connectionPool.clear();
    _connectionLastUsed.clear();
    _isInitialized = false;
  }
}