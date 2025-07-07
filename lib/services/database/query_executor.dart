import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'connection_pool.dart';

/// Handles query execution with retry logic and performance monitoring
class QueryExecutor {
  static QueryExecutor? _instance;
  static QueryExecutor get instance => _instance ??= QueryExecutor._();

  QueryExecutor._();

  final ConnectionPool _connectionPool = ConnectionPool.instance;

  // Performance metrics
  int _totalQueriesExecuted = 0;
  int _totalQueryTimeouts = 0;
  final Map<String, int> _queryTypeCounts = {};

  /// Execute a query with automatic connection management and retry logic
  Future<Results> execute(String sql, [List<Object?>? values]) async {
    MySqlConnection? connection;
    final queryStopwatch = Stopwatch()..start();

    try {
      connection = await _connectionPool.getConnection();

      Results? results;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount <= maxRetries) {
        try {
          results = await connection.query(sql, values).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                  'Query execution timed out after 30 seconds');
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          if (retryCount > maxRetries) {
            _totalQueryTimeouts++;
            rethrow; // Give up after max retries
          }

          await Future.delayed(
              Duration(seconds: retryCount * 2)); // Exponential backoff
        }
      }

      if (results == null) {
        throw Exception('Query failed after all retries');
      }

      _totalQueriesExecuted++;
      _incrementQueryTypeCount(sql);
      final duration = queryStopwatch.elapsed;

      if (duration.inMilliseconds > 1000) {
        print(
            '🐢 Slow query (${duration.inMilliseconds}ms): ${_abbreviateSql(sql)}');
      } else {
        print(
            '✅ Query executed successfully, ${results.length} rows affected (${duration.inMilliseconds}ms)');
      }

      return results;
    } catch (e) {
      if (values != null) print('📋 Values: $values');
      rethrow;
    } finally {
      if (connection != null) {
        _connectionPool.returnConnection(connection);
      }
    }
  }

  /// Execute a transaction with improved error handling
  Future<T> executeTransaction<T>(
      Future<T> Function(MySqlConnection) operation) async {
    MySqlConnection? connection;
    try {
      connection = await _connectionPool.getConnection();

      await connection.query('START TRANSACTION');

      final result = await operation(connection);

      await connection.query('COMMIT');
      return result;
    } catch (e) {
      if (connection != null) {
        try {
          await connection.query('ROLLBACK');
        } catch (rollbackError) {
        }
      }
      rethrow;
    } finally {
      if (connection != null) {
        _connectionPool.returnConnection(connection);
      }
    }
  }

  /// Execute a batch of queries
  Future<List<Results>> executeBatch(List<String> queries,
      [List<List<Object?>>? valuesList]) async {
    final results = <Results>[];

    for (int i = 0; i < queries.length; i++) {
      final values =
          valuesList != null && i < valuesList.length ? valuesList[i] : null;
      final result = await execute(queries[i], values);
      results.add(result);
    }

    return results;
  }

  /// Execute a query and return the first row
  Future<ResultRow?> executeSingle(String sql, [List<Object?>? values]) async {
    final results = await execute(sql, values);
    return results.isNotEmpty ? results.first : null;
  }

  /// Execute a query and return a single value
  Future<T?> executeScalar<T>(String sql, [List<Object?>? values]) async {
    final row = await executeSingle(sql, values);
    if (row == null || row.fields.isEmpty) return null;

    final value = row.fields.values.first;
    return value as T?;
  }

  /// Execute a count query
  Future<int> executeCount(String sql, [List<Object?>? values]) async {
    final count = await executeScalar<int>(sql, values);
    return count ?? 0;
  }

  /// Check if a table exists
  Future<bool> tableExists(String tableName) async {
    try {
      final sql = '''
        SELECT COUNT(*) as count 
        FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
        AND table_name = ?
      ''';

      final count = await executeCount(sql, [tableName]);
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get table row count
  Future<int> getTableRowCount(String tableName, [String? whereClause]) async {
    try {
      String sql = 'SELECT COUNT(*) as count FROM $tableName';
      List<Object?> values = [];

      if (whereClause != null && whereClause.isNotEmpty) {
        sql += ' WHERE $whereClause';
      }

      return await executeCount(sql, values);
    } catch (e) {
      return 0;
    }
  }

  /// Abbreviate SQL for logging
  String _abbreviateSql(String sql) {
    if (sql.length <= 100) return sql;
    return '${sql.substring(0, 100)}...';
  }

  /// Increment query type count for analytics
  void _incrementQueryTypeCount(String sql) {
    final queryType = _getQueryType(sql);
    _queryTypeCounts[queryType] = (_queryTypeCounts[queryType] ?? 0) + 1;
  }

  /// Get query type for analytics
  String _getQueryType(String sql) {
    final upperSql = sql.trim().toUpperCase();
    if (upperSql.startsWith('SELECT')) return 'SELECT';
    if (upperSql.startsWith('INSERT')) return 'INSERT';
    if (upperSql.startsWith('UPDATE')) return 'UPDATE';
    if (upperSql.startsWith('DELETE')) return 'DELETE';
    if (upperSql.startsWith('CREATE')) return 'CREATE';
    if (upperSql.startsWith('ALTER')) return 'ALTER';
    if (upperSql.startsWith('DROP')) return 'DROP';
    return 'OTHER';
  }

  /// Get query execution metrics
  Map<String, dynamic> getMetrics() {
    return {
      'total_queries_executed': _totalQueriesExecuted,
      'total_query_timeouts': _totalQueryTimeouts,
      'query_type_counts': Map.from(_queryTypeCounts),
      'success_rate': _totalQueriesExecuted > 0
          ? ((_totalQueriesExecuted - _totalQueryTimeouts) /
                  _totalQueriesExecuted *
                  100)
              .toStringAsFixed(2)
          : '0.00',
    };
  }

  /// Reset metrics (useful for testing)
  void resetMetrics() {
    _totalQueriesExecuted = 0;
    _totalQueryTimeouts = 0;
    _queryTypeCounts.clear();
  }
}