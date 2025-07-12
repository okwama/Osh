import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/models/client/client_model.dart';

/// Unified search service that consolidates all search functionality
/// Provides efficient server-side search with caching and performance optimizations
class UnifiedSearchService {
  static UnifiedSearchService? _instance;
  static UnifiedSearchService get instance =>
      _instance ??= UnifiedSearchService._();

  UnifiedSearchService._();

  final DatabaseService _db = DatabaseService.instance;
  final PaginationService _paginationService = PaginationService.instance;

  // Search cache for performance
  final Map<String, SearchCacheEntry> _searchCache = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static const int _maxCacheSize = 10000; // Increased cache size

  // Performance monitoring
  final List<SearchMetrics> _searchMetrics = [];
  static const int _maxMetricsHistory = 10000; // Increased metrics history

  /// Main search method with multi-term support and caching
  Future<PaginatedResult<Client>> searchClients({
    required String query,
    int page = 1,
    int limit = 100,
    String? orderBy,
    String? orderDirection,
    int? addedBy,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Normalize query
      final normalizedQuery = _normalizeSearchQuery(query);
      if (normalizedQuery.isEmpty) {
        return _createEmptyResult(page);
      }

      // Check cache first
      final cacheKey = _generateCacheKey(query, page, limit, addedBy);
      if (useCache && !forceRefresh && _isCacheValid(cacheKey)) {
        final cachedResult = _searchCache[cacheKey]!;
        print(
            '🚀 Cache hit for query: "$query" (${cachedResult.result.items.length} results)');
        return cachedResult.result;
      }

      // Get current user's country ID for security filtering
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      // Build search WHERE clause
      final additionalWhere = _buildSearchWhereClause(normalizedQuery);
      final whereParams = _buildSearchParams(normalizedQuery);

      // Execute paginated search query
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: page,
        limit: limit,
        orderBy: orderBy ?? 'id',
        orderDirection: orderDirection ?? 'DESC',
        columns: [
          'id',
          'name',
          'address',
          'contact',
          'latitude',
          'longitude',
          'email',
          'region_id',
          'region',
          'countryId',
          'created_at',
        ],
        additionalWhere: additionalWhere,
        filters: {
          'countryId': userCountryId,
          if (addedBy != null) 'added_by': addedBy,
        },
        whereParams: whereParams,
      );

      // Convert to Client objects
      final clients = result.items
          .map((row) => Client(
                id: row['id'] as int,
                name: row['name'] as String,
                address: row['address'] as String? ?? '',
                latitude: row['latitude'] as double?,
                longitude: row['longitude'] as double?,
                email: row['email'] as String? ?? '',
                contact: row['contact'] as String? ?? '',
                regionId: row['region_id'] as int? ?? 0,
                region: row['region'] as String? ?? '',
                countryId: row['countryId'] as int? ?? 0,
                createdAt: row['created_at'] != null
                    ? DateTime.parse(row['created_at'].toString())
                    : null,
              ))
          .toList();

      final paginatedResult = PaginatedResult<Client>(
        items: clients,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
        queryDuration: Duration(milliseconds: stopwatch.elapsedMilliseconds),
      );

      // Cache the result
      if (useCache) {
        _cacheSearchResult(cacheKey, paginatedResult);
      }

      // Record metrics
      _recordSearchMetrics(
          query, stopwatch.elapsedMilliseconds, clients.length);

      print(
          '🔍 Search completed: "${query}" -> ${clients.length} results (${stopwatch.elapsedMilliseconds}ms)');

      return paginatedResult;
    } catch (e) {
      stopwatch.stop();
      _recordSearchMetrics(query, stopwatch.elapsedMilliseconds, 0,
          error: e.toString());
      rethrow;
    }
  }

  /// Search clients by specific field
  Future<PaginatedResult<Client>> searchClientsByField({
    required String field,
    required String value,
    int page = 1,
    int limit = 100,
    String? orderBy,
    String? orderDirection,
    int? addedBy,
  }) async {
    try {
      // Validate field name to prevent SQL injection
      final validFields = ['name', 'address', 'contact', 'email'];
      if (!validFields.contains(field)) {
        throw ArgumentError('Invalid field name: $field');
      }

      // Get current user's country ID
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      // Build exact match WHERE clause
      final additionalWhere = 'LOWER($field) LIKE ?';
      final searchValue = '%${value.toLowerCase()}%';

      // Execute paginated search query
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: page,
        limit: limit,
        orderBy: orderBy ?? 'id',
        orderDirection: orderDirection ?? 'DESC',
        columns: [
          'id',
          'name',
          'address',
          'contact',
          'latitude',
          'longitude',
          'email',
          'region_id',
          'region',
          'countryId',
        ],
        additionalWhere: additionalWhere,
        filters: {
          'countryId': userCountryId,
          if (addedBy != null) 'added_by': addedBy,
        },
        whereParams: [searchValue],
      );

      // Convert to Client objects
      final clients = result.items
          .map((row) => Client(
                id: row['id'] as int,
                name: row['name'] as String,
                address: row['address'] as String? ?? '',
                latitude: row['latitude'] as double?,
                longitude: row['longitude'] as double?,
                email: row['email'] as String? ?? '',
                contact: row['contact'] as String? ?? '',
                regionId: row['region_id'] as int? ?? 0,
                region: row['region'] as String? ?? '',
                countryId: row['countryId'] as int? ?? 0,
              ))
          .toList();

      return PaginatedResult<Client>(
        items: clients,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
        queryDuration: result.queryDuration,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Search clients near a specific location using Haversine formula
  Future<PaginatedResult<Client>> searchClientsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int page = 1,
    int limit = 100,
    int? addedBy,
  }) async {
    try {
      // Get current user's country ID
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      // Using Haversine formula for distance calculation
      final additionalWhere = '''
        (latitude IS NOT NULL AND longitude IS NOT NULL) AND
        (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * 
         cos(radians(longitude) - radians(?)) + 
         sin(radians(?)) * sin(radians(latitude)))) <= ?
      ''';

      // Execute paginated search query with distance calculation
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: page,
        limit: limit,
        orderBy: '''
          (6371 * acos(cos(radians($latitude)) * cos(radians(latitude)) * 
           cos(radians(longitude) - radians($longitude)) + 
           sin(radians($latitude)) * sin(radians(latitude))))
        ''',
        orderDirection: 'ASC',
        columns: [
          'id',
          'name',
          'address',
          'contact',
          'latitude',
          'longitude',
          'email',
          'region_id',
          'region',
          'countryId',
        ],
        additionalWhere: additionalWhere,
        filters: {
          'countryId': userCountryId,
          if (addedBy != null) 'added_by': addedBy,
        },
        whereParams: [latitude, longitude, latitude, radiusKm],
      );

      // Convert to Client objects
      final clients = result.items
          .map((row) => Client(
                id: row['id'] as int,
                name: row['name'] as String,
                address: row['address'] as String? ?? '',
                latitude: row['latitude'] as double?,
                longitude: row['longitude'] as double?,
                email: row['email'] as String? ?? '',
                contact: row['contact'] as String? ?? '',
                regionId: row['region_id'] as int? ?? 0,
                region: row['region'] as String? ?? '',
                countryId: row['countryId'] as int? ?? 0,
              ))
          .toList();

      return PaginatedResult<Client>(
        items: clients,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
        queryDuration: result.queryDuration,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get search suggestions based on partial input
  Future<List<String>> getSearchSuggestions({
    required String partialQuery,
    int limit = 10,
    int? addedBy,
  }) async {
    try {
      if (partialQuery.length < 2) {
        return [];
      }

      final normalizedQuery = _normalizeSearchQuery(partialQuery);
      if (normalizedQuery.isEmpty) {
        return [];
      }

      // Get current user's country ID
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        return [];
      }

      // Search in name and address fields for suggestions
      final additionalWhere = '''
        (LOWER(name) LIKE ? OR LOWER(address) LIKE ?)
      ''';
      final searchPattern = '%${normalizedQuery.first.toLowerCase()}%';

      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: limit,
        orderBy: 'name',
        orderDirection: 'ASC',
        columns: ['name', 'address'],
        additionalWhere: additionalWhere,
        filters: {
          'countryId': userCountryId,
          if (addedBy != null) 'added_by': addedBy,
        },
        whereParams: [searchPattern, searchPattern],
      );

      // Extract unique suggestions
      final suggestions = <String>{};
      for (final row in result.items) {
        final name = row['name']?.toString() ?? '';
        final address = row['address']?.toString() ?? '';

        if (name.isNotEmpty) suggestions.add(name);
        if (address.isNotEmpty) suggestions.add(address);
      }

      return suggestions.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get search statistics and performance metrics
  Future<Map<String, dynamic>> getSearchStats({
    required String query,
    int? addedBy,
  }) async {
    try {
      final searchTerms = _normalizeSearchQuery(query);
      if (searchTerms.isEmpty) {
        return {
          'totalResults': 0,
          'searchTerms': [],
          'queryDuration': Duration.zero,
          'cacheHitRate': _getCacheHitRate(),
          'averageQueryTime': _getAverageQueryTime(),
        };
      }

      // Get current user's country ID
      final currentUser = await _db.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        return {
          'totalResults': 0,
          'searchTerms': [],
          'error': 'User countryId not found',
        };
      }

      final additionalWhere = _buildSearchWhereClause(searchTerms);
      final whereParams = _buildSearchParams(searchTerms);

      // Get total count for search query
      final countResult = await _db.query(
        'SELECT COUNT(*) as total FROM Clients WHERE countryId = ? AND $additionalWhere',
        [userCountryId, ...whereParams],
      );

      final totalResults = countResult.first['total'] as int;

      return {
        'totalResults': totalResults,
        'searchTerms': searchTerms,
        'cacheHitRate': _getCacheHitRate(),
        'averageQueryTime': _getAverageQueryTime(),
        'cacheSize': _searchCache.length,
      };
    } catch (e) {
      return {
        'totalResults': 0,
        'searchTerms': [],
        'error': e.toString(),
      };
    }
  }

  /// Clear search cache
  Future<void> clearSearchCache() async {
    _searchCache.clear();
    print('🧹 Search cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _searchCache.length,
      'cacheHitRate': _getCacheHitRate(),
      'averageQueryTime': _getAverageQueryTime(),
      'recentSearches': _searchMetrics.take(10).map((m) => m.query).toList(),
    };
  }

  // Private helper methods

  List<String> _normalizeSearchQuery(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.length >= 2)
        .toList();
  }

  String _buildSearchWhereClause(List<String> searchTerms) {
    if (searchTerms.isEmpty) return '';

    final conditions = searchTerms.map((term) => '''
      (LOWER(name) LIKE ? OR 
       LOWER(address) LIKE ? OR 
       LOWER(contact) LIKE ? OR 
       LOWER(email) LIKE ?)
    ''').join(' AND ');

    return conditions;
  }

  List<dynamic> _buildSearchParams(List<String> searchTerms) {
    final params = <dynamic>[];
    for (final term in searchTerms) {
      final searchPattern = '%${term.toLowerCase()}%';
      params
          .addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
    }
    return params;
  }

  String _generateCacheKey(String query, int page, int limit, int? addedBy) {
    return '${query}_${page}_${limit}_${addedBy ?? 0}';
  }

  bool _isCacheValid(String cacheKey) {
    final entry = _searchCache[cacheKey];
    if (entry == null) return false;

    final age = DateTime.now().difference(entry.timestamp);
    return age < _cacheValidityDuration;
  }

  void _cacheSearchResult(String cacheKey, PaginatedResult<Client> result) {
    // Remove oldest entries if cache is full
    if (_searchCache.length >= _maxCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }

    _searchCache[cacheKey] = SearchCacheEntry(
      result: result,
      timestamp: DateTime.now(),
    );
  }

  void _recordSearchMetrics(String query, int durationMs, int resultCount,
      {String? error}) {
    _searchMetrics.add(SearchMetrics(
      query: query,
      durationMs: durationMs,
      resultCount: resultCount,
      error: error,
    ));

    // Keep only recent metrics
    if (_searchMetrics.length > _maxMetricsHistory) {
      _searchMetrics.removeAt(0);
    }
  }

  double _getCacheHitRate() {
    if (_searchMetrics.isEmpty) return 0.0;

    final totalSearches = _searchMetrics.length;
    final cacheHits = _searchMetrics.where((m) => m.durationMs < 50).length;
    return cacheHits / totalSearches;
  }

  double _getAverageQueryTime() {
    if (_searchMetrics.isEmpty) return 0.0;

    final totalTime =
        _searchMetrics.fold<int>(0, (sum, m) => sum + m.durationMs);
    return totalTime / _searchMetrics.length;
  }

  PaginatedResult<Client> _createEmptyResult(int page) {
    return PaginatedResult<Client>(
      items: [],
      totalCount: 0,
      currentPage: page,
      totalPages: 0,
      hasMore: false,
      queryDuration: Duration.zero,
    );
  }
}

/// Cache entry for search results
class SearchCacheEntry {
  final PaginatedResult<Client> result;
  final DateTime timestamp;

  SearchCacheEntry({
    required this.result,
    required this.timestamp,
  });
}

/// Search performance metrics
class SearchMetrics {
  final String query;
  final int durationMs;
  final int resultCount;
  final String? error;
  final DateTime timestamp;

  SearchMetrics({
    required this.query,
    required this.durationMs,
    required this.resultCount,
    this.error,
  }) : timestamp = DateTime.now();
}
