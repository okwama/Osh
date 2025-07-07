import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:mysql1/mysql1.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/core/search_service.dart';
import 'package:woosh/models/client_model.dart';

/// Query metrics class for performance monitoring
class QueryMetrics {
  final String sql;
  final int durationMs;
  final int rowCount;
  final DateTime timestamp;
  QueryMetrics(this.sql, this.durationMs, this.rowCount)
      : timestamp = DateTime.now();
}

/// Enhanced client service with efficient pagination, caching, and performance monitoring
class ClientService {
  static ClientService? _instance;
  static ClientService get instance => _instance ??= ClientService._();

  ClientService._();

  final DatabaseService _db = DatabaseService.instance;
  final SearchService _searchService = SearchService.instance;

  // Query performance monitoring
  final List<QueryMetrics> _queryMetrics = [];
  final Map<String, Results> _queryCache = {};

  /// Fetch clients using optimized keyset pagination (recommended for large datasets)
  /// Supports multi-term search and efficient index usage
  Future<PaginatedResult<Client>> fetchClientsKeyset({
    dynamic lastClientId,
    int limit = 100,
    Map<String, dynamic> filters = const {},
    String? orderDirection,
    int? addedBy,
    String? searchQuery,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Get current user's countryId for mandatory security filtering
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      // Build WHERE clause for keyset pagination
      final List<String> whereConditions = [
        'countryId = ?'
      ]; // Mandatory country filter
      final List<dynamic> params = [userCountryId];

      // Keyset pagination condition
      if (lastClientId != null) {
        whereConditions.add('id > ?');
        params.add(lastClientId);
      }
      // Add filters
      if (addedBy != null) {
        whereConditions.add('added_by = ?');
        params.add(addedBy);
      }

      // Apply additional filters (but countryId is already mandatory)
      filters.forEach((key, value) {
        if (key != 'countryId') {
          // Skip countryId as it's already added
          whereConditions.add('$key = ?');
          params.add(value);
        }
      });

      // Add search conditions (multi-term)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerms = searchQuery.toLowerCase().split(' ');
        final searchConditions = searchTerms.map((term) => '''
          (LOWER(name) LIKE ? OR 
           LOWER(contact) LIKE ? OR 
           LOWER(email) LIKE ? OR
           LOWER(address) LIKE ?)
        ''').join(' AND ');
        whereConditions.add('($searchConditions)');
        for (final term in searchTerms) {
          final searchPattern = '%$term%';
          params.addAll(
              [searchPattern, searchPattern, searchPattern, searchPattern]);
        }
      }
      // Build final WHERE clause
      final whereClause = 'WHERE ${whereConditions.join(' AND ')}';

      // Optimized query with index hint
      final sql = '''
        SELECT /*+ INDEX(Clients PRIMARY) */ 
          id, name, address, contact, latitude, longitude 
        FROM Clients
        $whereClause
        ORDER BY id ${orderDirection ?? 'ASC'}
        LIMIT ?
      ''';
      params.add(limit + 1); // +1 to check for more results
      final results = await _cachedQuery(sql, params);
      final rows = results.toList();
      bool hasMore = false;
      dynamic nextCursor;
      if (rows.length > limit) {
        hasMore = true;
        rows.removeLast();
      }
      if (rows.isNotEmpty) {
        nextCursor = rows.last['id'];
      }
      stopwatch.stop();
      // Convert to Client objects
      final clients = rows.map((row) => Client.fromJson(row.fields)).toList();
      return PaginatedResult<Client>(
        items: clients,
        nextCursor: nextCursor,
        hasMore: hasMore,
        queryDuration: Duration(milliseconds: stopwatch.elapsedMilliseconds),
      );
    } catch (e) {
      print('❌ Error fetching clients with keyset pagination: $e');
      rethrow;
    }
  }

  /// Fetch clients using offset pagination (for smaller datasets or when total count is needed)
  Future<PaginatedResult<Client>> fetchClientsOffset({
    int page = 1,
    int limit = 50,
    Map<String, dynamic> filters = const {},
    String? orderBy,
    String? orderDirection,
    int? addedBy,
    String? searchQuery,
  }) async {
    try {
      // Build filters
      final Map<String, dynamic> queryFilters = Map.from(filters);
      if (addedBy != null) {
        queryFilters['added_by'] = addedBy;
      }
      // Build additional WHERE clause for search
      String? additionalWhere;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        additionalWhere = '''
          (name LIKE '%$searchQuery%' OR 
           contact LIKE '%$searchQuery%' OR 
           email LIKE '%$searchQuery%' OR
           address LIKE '%$searchQuery%')
        ''';
      }
      // Execute paginated query
      final result = await _db.fetchOffsetPaginated(
        table: 'Clients',
        page: page,
        limit: limit,
        filters: queryFilters,
        orderBy: orderBy ?? 'id',
        orderDirection: orderDirection ?? 'DESC',
        columns: [
          'id',
          'name',
          'address',
          'contact',
          'latitude',
          'longitude',
        ],
        additionalWhere: additionalWhere,
      );
      final clients =
          result.items.map((row) => Client.fromJson(row.fields)).toList();
      return PaginatedResult<Client>(
        items: clients,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
        queryDuration: result.queryDuration,
      );
    } catch (e) {
      print('❌ Error fetching clients with offset pagination: $e');
      rethrow;
    }
  }

  /// Search clients with server-side filtering and pagination
  Future<PaginatedResult<Client>> searchClients({
    required String query,
    int page = 1,
    int limit = 100,
    String? orderBy,
    String? orderDirection,
    int? addedBy,
  }) async {
    return _searchService.searchClients(
      query: query,
      page: page,
      limit: limit,
      orderBy: orderBy,
      orderDirection: orderDirection,
      addedBy: addedBy,
    );
  }

  /// Get client by ID
  Future<Client?> getClientById(int clientId) async {
    try {
      // Get current user's countryId for security filtering
      final currentUserId = _db.getCurrentUserId();
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      final sql = 'SELECT * FROM Clients WHERE id = ? AND countryId = ?';
      final results = await _cachedQuery(sql, [clientId, userCountryId]);
      if (results.isEmpty) {
        return null;
      }
      return Client.fromJson(results.first.fields);
    } catch (e) {
      print('❌ Error fetching client by ID: $e');
      rethrow;
    }
  }

  /// Create a new client
  Future<Client> createClient(Client client) async {
    try {
      // Get current user ID for audit trail
      final currentUserId = _db.getCurrentUserId();

      final results = await _db.query(
        '''
        INSERT INTO Clients (name, contact, email, address, client_type, countryId, region_id, added_by, latitude, longitude, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ''',
        [
          client.name,
          client.contact,
          client.email,
          client.address,
          client.clientType ?? 1,
          client.countryId,
          client.regionId,
          currentUserId, // Use current user ID for audit trail
          client.latitude,
          client.longitude,
        ],
      );
      final newClientId = results.insertId;
      if (newClientId != null) {
        return await getClientById(newClientId) ?? client;
      }
      return client;
    } catch (e) {
      print('❌ Error creating client: $e');
      rethrow;
    }
  }

  /// Update an existing client
  Future<Client> updateClient(Client client) async {
    try {
      // Get current user's countryId for security filtering
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      await _db.query(
        '''
        UPDATE Clients 
        SET name = ?, contact = ?, email = ?, address = ?, status = ?, updatedAt = NOW()
        WHERE id = ? AND countryId = ?
        ''',
        [
          client.name,
          client.contact,
          client.email,
          client.address,
          client.clientType ?? 1,
          client.id,
          userCountryId, // Add countryId verification
        ],
      );
      return await getClientById(client.id) ?? client;
    } catch (e) {
      print('❌ Error updating client: $e');
      rethrow;
    }
  }

  /// Delete a client
  Future<bool> deleteClient(int clientId) async {
    try {
      // Get current user's countryId for security filtering
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      final results = await _db.query(
        'DELETE FROM Clients WHERE id = ? AND countryId = ?',
        [clientId, userCountryId],
      );
      return (results.affectedRows ?? 0) > 0;
    } catch (e) {
      print('❌ Error deleting client: $e');
      rethrow;
    }
  }

  /// Get client statistics
  Future<Map<String, dynamic>> getClientStats() async {
    try {
      final sql = '''
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN status = 1 THEN 1 END) as active,
          COUNT(CASE WHEN status = 0 THEN 1 END) as inactive
        FROM Clients
      ''';
      final results = await _cachedQuery(sql);
      final row = results.first;
      return {
        'total': row['total'],
        'active': row['active'],
        'inactive': row['inactive'],
      };
    } catch (e) {
      print('❌ Error getting client stats: $e');
      rethrow;
    }
  }

  /// Get database performance metrics (including query metrics)
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final dbStats = await _db.getStats();
      if (_queryMetrics.isNotEmpty) {
        final avgDuration =
            _queryMetrics.map((m) => m.durationMs).reduce((a, b) => a + b) /
                _queryMetrics.length;
        final slowQueries =
            _queryMetrics.where((m) => m.durationMs > 1000).length;
        dbStats.addAll({
          'query_metrics': {
            'total_queries': _queryMetrics.length,
            'average_duration_ms': avgDuration.round(),
            'slow_queries_count': slowQueries,
            'cache_size': _queryCache.length,
            'recent_queries': _queryMetrics
                .take(10)
                .map((m) => {
                      'sql': m.sql.split(' ').take(5).join(' ') + '...',
                      'duration_ms': m.durationMs,
                      'row_count': m.rowCount,
                      'timestamp': m.timestamp.toIso8601String(),
                    })
                .toList(),
          }
        });
      }
      return dbStats;
    } catch (e) {
      print('❌ Error getting performance metrics: $e');
      rethrow;
    }
  }

  /// Get recent query metrics (for UI/debugging)
  List<QueryMetrics> getRecentQueryMetrics([int count = 10]) {
    return _queryMetrics.reversed.take(count).toList();
  }

  /// Cached query execution with performance monitoring
  Future<Results> _cachedQuery(String sql, [List<Object?>? values]) async {
    final cacheKey = '$sql${values?.join(',') ?? ''}';
    if (_queryCache.containsKey(cacheKey)) {
      return _queryCache[cacheKey]!;
    }
    final stopwatch = Stopwatch()..start();
    final results = await _db.query(sql, values);
    stopwatch.stop();
    _logQueryMetrics(sql, results.length, stopwatch);
    if (_queryCache.length < 50) {
      _queryCache[cacheKey] = results;
    }
    return results;
  }

  /// Log query performance metrics
  void _logQueryMetrics(String sql, int rowCount, Stopwatch stopwatch) {
    final metrics = QueryMetrics(sql, stopwatch.elapsedMilliseconds, rowCount);
    _queryMetrics.add(metrics);
    if (_queryMetrics.length > 100) {
      _queryMetrics.removeAt(0);
    }
  }

  // --- UI Prefetching Example (for integration in your widget) ---
  //
  // final scrollController = ScrollController();
  // void _setupPrefetch() {
  //   scrollController.addListener(() {
  //     final maxScroll = scrollController.position.maxScrollExtent;
  //     final currentScroll = scrollController.position.pixels;
  //     if (maxScroll - currentScroll < 0.25 * maxScroll) {
  //       _loadMoreClients();
  //     }
  //   });
  // }
  //
  // Use this pattern in your UI to prefetch the next page when the user scrolls near the end.

  // --- Backward compatibility methods (unchanged) ---
  Future<List<Client>> getClients({
    int page = 1,
    int limit = 20,
    String? search,
    int? countryId, // Add country filtering
  }) async {
    // Get current user's countryId for mandatory security filtering
    final currentUser = await _db.getCurrentUserDetails();
    final userCountryId = currentUser['countryId'];

    if (userCountryId == null) {
      throw Exception('User countryId not found - access denied');
    }

    final result = await fetchClientsOffset(
      page: page,
      limit: limit,
      searchQuery: search,
      filters: {
        'countryId': userCountryId
      }, // Always use user's country, ignore provided countryId
    );
    return result.items;
  }

  Future<List<Client>> getClientsForJourneyPlan({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    // Get current user's countryId for security filtering
    final currentUser = await _db.getCurrentUserDetails();
    final userCountryId = currentUser['countryId'];

    if (userCountryId == null) {
      throw Exception('User countryId not found - access denied');
    }

    final result = await fetchClientsOffset(
      page: page,
      limit: limit,
      searchQuery: search,
      filters: {'countryId': userCountryId}, // Add mandatory country filter
    );
    return result.items;
  }

  Future<List<Client>> getClientsByRegion(int regionId) async {
    // Get current user's countryId for security filtering
    final currentUser = await _db.getCurrentUserDetails();
    final userCountryId = currentUser['countryId'];

    if (userCountryId == null) {
      throw Exception('User countryId not found - access denied');
    }

    final result = await fetchClientsKeyset(
      filters: {
        'regionId': regionId,
        'countryId': userCountryId, // Add mandatory country filter
      },
      limit: 1000,
    );
    return result.items;
  }

  Future<Client> updateClientLocation({
    required int clientId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.query(
        'UPDATE Clients SET latitude = ?, longitude = ?, updatedAt = NOW() WHERE id = ?',
        [latitude, longitude, clientId],
      );
      return await getClientById(clientId) ??
          Client(
              id: clientId,
              name: '',
              address: '',
              regionId: 0,
              region: '',
              countryId: 0);
    } catch (e) {
      print('❌ Error updating client location: $e');
      rethrow;
    }
  }

  Future<List<Client>> getClientsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      // Get current user's countryId for security filtering
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      final sql = '''
        SELECT *, 
          (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * 
           cos(radians(longitude) - radians(?)) + 
           sin(radians(?)) * sin(radians(latitude)))) AS distance
        FROM Clients
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
        AND countryId = ?
        HAVING distance <= ?
        ORDER BY distance
        LIMIT ?
      ''';
      final results = await _cachedQuery(
          sql, [latitude, longitude, latitude, userCountryId, radiusKm, limit]);
      return results.map((row) => Client.fromJson(row.fields)).toList();
    } catch (e) {
      print('❌ Error getting clients near location: $e');
      rethrow;
    }
  }
}
