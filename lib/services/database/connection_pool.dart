import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'package:woosh/config/database_config.dart';

/// Manages database connection pooling with health monitoring
class ConnectionPool {
  static ConnectionPool? _instance;
  static ConnectionPool get instance => _instance ??= ConnectionPool._();

  ConnectionPool._();

  // Connection pool management
  final Queue<MySqlConnection> _connectionPool = Queue();
  final int _maxConnections = 10; // Reduced from 20
  final int _minConnections = 2; // Reduced from 5
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  // Connection health tracking
  final Map<MySqlConnection, DateTime> _connectionLastUsed = {};
  final Duration _connectionMaxIdleTime =
      const Duration(minutes: 30); // Increased from 10
  Timer? _healthCheckTimer;

  // Performance metrics
  Duration _lastConnectionWaitTime = Duration.zero;
  final Stopwatch _uptimeStopwatch = Stopwatch()..start();

  // Circuit breaker for connection failures
  int _consecutiveFailures = 0;
  DateTime? _circuitBreakerOpenTime;
  static const int _maxConsecutiveFailures = 10; // Increased from 5
  static const Duration _circuitBreakerTimeout =
      Duration(minutes: 5); // Increased from 2

  /// Check network connectivity
  Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('🌐 Network connectivity check failed: $e');
      return false;
    }
  }

  /// Initialize the connection pool
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initCompleter.isCompleted) return;

    try {
      print('🔧 Initializing connection pool...');

      // Create single connection without extra health checks
      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.user,
        password: DatabaseConfig.password,
        db: DatabaseConfig.database,
        timeout: const Duration(seconds: 30),
        useSSL: false,
      );

      final connection = await MySqlConnection.connect(settings);

      // Store the connection
      _connectionPool.add(connection);
      _connectionLastUsed[connection] = DateTime.now();
      _isInitialized = true;
      _initCompleter.complete();

      print('✅ Connection pool initialized');

      // Start health check timer with longer interval
      _healthCheckTimer?.cancel();
      _healthCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
        _cleanupIdleConnections();
      });
    } catch (e) {
      print('❌ Failed to initialize connection pool: $e');
      _isInitialized = false;
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    }
  }

  /// Create additional connections in the background
  Future<void> _createBackgroundConnections() async {
    try {
      for (int i = _connectionPool.length; i < _minConnections; i++) {
        await Future.delayed(
            const Duration(seconds: 2)); // Delay between connections
        if (!_isInitialized) break; // Stop if pool was disposed
        try {
          await _createConnection();
        } catch (e) {
          print('⚠️ Background connection creation failed: $e');
          break; // Stop creating more if one fails
        }
      }
    } catch (e) {
      print('⚠️ Background connection creation stopped: $e');
    }
  }

  /// Create a new database connection with retry logic
  Future<MySqlConnection> _createConnection() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 5);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print(
            '🔄 Attempting to create database connection (attempt $attempt)...');

        final settings = ConnectionSettings(
          host: DatabaseConfig.host,
          port: DatabaseConfig.port,
          user: DatabaseConfig.user,
          password: DatabaseConfig.password,
          db: DatabaseConfig.database,
          timeout: const Duration(seconds: 30),
          useSSL: false,
        );

        final connection = await MySqlConnection.connect(settings);

        // Test the connection immediately
        await connection.query('SELECT 1').timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Connection test timeout');
          },
        );

        print('✅ Database connection created and tested successfully');
        return connection;
      } catch (e) {
        print('❌ Connection attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          throw _formatConnectionError(e);
        }

        final delay = retryDelay * attempt;
        print('⏳ Waiting ${delay.inSeconds} seconds before retry...');
        await Future.delayed(delay);
      }
    }

    throw Exception(
        'Failed to create database connection after $maxRetries attempts');
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

  /// Get a connection from the pool with minimal health checks
  Future<MySqlConnection> getConnection() async {
    try {
      await _initCompleter.future;

      // Return existing connection if available
      if (_connectionPool.isNotEmpty) {
        final connection = _connectionPool.removeFirst();
        _connectionLastUsed[connection] = DateTime.now();
        return connection;
      }

      // Create new connection if needed
      print('🔄 Creating new database connection...');
      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.user,
        password: DatabaseConfig.password,
        db: DatabaseConfig.database,
        timeout: const Duration(seconds: 30),
        useSSL: false,
      );

      final connection = await MySqlConnection.connect(settings);
      _connectionLastUsed[connection] = DateTime.now();
      return connection;
    } catch (e) {
      print('❌ Failed to get database connection: $e');
      rethrow;
    }
  }

  /// Return a connection to the pool
  void returnConnection(MySqlConnection connection) {
    if (_connectionPool.length < _maxConnections) {
      _connectionPool.add(connection);
      _connectionLastUsed[connection] = DateTime.now();
    } else {
      connection.close();
      _connectionLastUsed.remove(connection);
    }
  }

  /// Simplified health check that only removes very old connections
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
      } catch (e) {}
    }

    if (toRemove.isNotEmpty) {}
  }

  /// Check if a connection is healthy with actual test
  bool _isConnectionHealthy(MySqlConnection connection) {
    try {
      final lastUsed = _connectionLastUsed[connection];
      if (lastUsed == null) return false;

      // Check if connection is too old
      if (DateTime.now().difference(lastUsed) > _connectionMaxIdleTime) {
        return false;
      }

      // Test connection with a simple query
      try {
        connection.query('SELECT 1').timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Connection health check timeout');
          },
        );
        return true;
      } catch (e) {
        print('🔍 Connection health check failed: $e');
        return false;
      }
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
      'circuit_breaker': {
        'consecutive_failures': _consecutiveFailures,
        'is_open': _isCircuitBreakerOpen(),
        'open_since': _circuitBreakerOpenTime?.toIso8601String(),
        'max_failures': _maxConsecutiveFailures,
        'timeout_minutes': _circuitBreakerTimeout.inMinutes,
      },
    };
  }

  /// Check if circuit breaker is open
  bool _isCircuitBreakerOpen() {
    if (_circuitBreakerOpenTime == null) return false;

    final timeSinceOpen = DateTime.now().difference(_circuitBreakerOpenTime!);
    if (timeSinceOpen >= _circuitBreakerTimeout) {
      // Reset circuit breaker after timeout
      _circuitBreakerOpenTime = null;
      _consecutiveFailures = 0;
      return false;
    }

    return _consecutiveFailures >= _maxConsecutiveFailures;
  }

  /// Increment circuit breaker failure count
  void _incrementCircuitBreaker() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _circuitBreakerOpenTime = DateTime.now();
      print(
          '🚨 Circuit breaker opened after $_consecutiveFailures consecutive failures');
    }
  }

  /// Reset circuit breaker on success
  void _resetCircuitBreaker() {
    if (_consecutiveFailures > 0) {
      print('✅ Circuit breaker reset after successful connection');
    }
    _consecutiveFailures = 0;
    _circuitBreakerOpenTime = null;
  }

  /// Clean up all connections
  Future<void> dispose() async {
    _healthCheckTimer?.cancel();

    for (final connection in _connectionPool) {
      try {
        await connection.close();
      } catch (e) {}
    }

    _connectionPool.clear();
    _connectionLastUsed.clear();
    _isInitialized = false;
  }
}
