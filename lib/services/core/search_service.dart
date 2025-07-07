import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/models/client_model.dart';

/// Modularized search service for efficient server-side searching
class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._();

  SearchService._();

  final DatabaseService _db = DatabaseService.instance;
  final PaginationService _paginationService = PaginationService.instance;

  /// Search clients with server-side filtering and pagination
  Future<PaginatedResult<Client>> searchClients({
    required String query,
    int page = 1,
    int limit = 100,
    String? orderBy,
    String? orderDirection,
    int? addedBy,
  }) async {
    try {
      // Normalize and split search query into terms
      final searchTerms = _normalizeSearchQuery(query);

      if (searchTerms.isEmpty) {
        // If no valid search terms, return empty result
        return PaginatedResult<Client>(
          items: [],
          totalCount: 0,
          currentPage: page,
          totalPages: 0,
          hasMore: false,
          queryDuration: Duration.zero,
        );
      }

      // Build search WHERE clause for multiple terms
      final additionalWhere = _buildSearchWhereClause(searchTerms);

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
        ],
        additionalWhere: additionalWhere,
        filters: addedBy != null ? {'added_by': addedBy} : {},
      );

      // Convert to Client objects
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
      print('❌ Error searching clients: $e');
      rethrow;
    }
  }

  /// Search clients by specific field with exact matching
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
        ],
        additionalWhere: additionalWhere,
        filters: addedBy != null ? {'added_by': addedBy} : {},
      );

      // Convert to Client objects
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
      print('❌ Error searching clients by field: $e');
      rethrow;
    }
  }

  /// Search clients near a specific location
  Future<PaginatedResult<Client>> searchClientsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int page = 1,
    int limit = 100,
    int? addedBy,
  }) async {
    try {
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
        ],
        additionalWhere: additionalWhere,
        filters: addedBy != null ? {'added_by': addedBy} : {},
      );

      // Convert to Client objects
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
      print('❌ Error searching clients near location: $e');
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
        filters: addedBy != null ? {'added_by': addedBy} : {},
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
      print('❌ Error getting search suggestions: $e');
      return [];
    }
  }

  /// Normalize search query and split into terms
  List<String> _normalizeSearchQuery(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.length >= 2)
        .toList();
  }

  /// Build WHERE clause for multi-term search
  String _buildSearchWhereClause(List<String> searchTerms) {
    if (searchTerms.isEmpty) return '';

    final conditions = searchTerms.map((term) => '''
      (LOWER(name) LIKE '%$term%' OR 
       LOWER(address) LIKE '%$term%' OR 
       LOWER(contact) LIKE '%$term%' OR 
       LOWER(email) LIKE '%$term%')
    ''').join(' AND ');

    return conditions;
  }

  /// Get search statistics
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
        };
      }

      final additionalWhere = _buildSearchWhereClause(searchTerms);

      // Get total count for search query
      final countResult = await _db.query(
        'SELECT COUNT(*) as total FROM Clients WHERE $additionalWhere',
        addedBy != null ? [addedBy] : [],
      );

      final totalResults = countResult.first['total'] as int;

      return {
        'totalResults': totalResults,
        'searchTerms': searchTerms,
        'queryDuration': Duration.zero, // Could be enhanced with actual timing
      };
    } catch (e) {
      print('❌ Error getting search stats: $e');
      return {
        'totalResults': 0,
        'searchTerms': [],
        'error': e.toString(),
      };
    }
  }

  /// Clear search cache (if implemented)
  Future<void> clearSearchCache() async {
    // Implementation for search result caching could be added here
    print('🔍 Search cache cleared');
  }
}
