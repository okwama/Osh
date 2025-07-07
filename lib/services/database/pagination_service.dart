import 'package:mysql1/mysql1.dart';
import 'query_executor.dart';

/// Paginated result container for efficient data fetching
class PaginatedResult<T> {
  final List<T> items;
  final dynamic nextCursor;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;
  final bool hasMore;
  final Duration queryDuration;

  PaginatedResult({
    required this.items,
    this.nextCursor,
    this.totalCount,
    this.currentPage,
    this.totalPages,
    required this.hasMore,
    required this.queryDuration,
  });

  @override
  String toString() {
    return 'PaginatedResult(items: ${items.length}, hasMore: $hasMore, duration: ${queryDuration.inMilliseconds}ms)';
  }
}

/// Handles pagination operations with both keyset and offset pagination
class PaginationService {
  static PaginationService? _instance;
  static PaginationService get instance => _instance ??= PaginationService._();

  PaginationService._();

  final QueryExecutor _queryExecutor = QueryExecutor.instance;

  /// Fetch paginated results using keyset pagination (recommended for large datasets)
  Future<PaginatedResult<ResultRow>> fetchKeyset({
    required String table,
    required String cursorField,
    dynamic lastCursorValue,
    int limit = 100,
    Map<String, dynamic> filters = const {},
    String? orderDirection,
    List<String>? columns,
    String? additionalWhere,
  }) async {
    final queryStopwatch = Stopwatch()..start();

    try {
      // Validate and clamp limit
      limit = limit.clamp(1, 1000);

      // Build WHERE clause
      final whereBuffer = StringBuffer();
      final params = <dynamic>[];
      var hasConditions = false;

      // Add cursor condition
      if (lastCursorValue != null) {
        final operator = (orderDirection?.toUpperCase() == 'DESC') ? '<' : '>';
        whereBuffer.write('$cursorField $operator ?');
        params.add(lastCursorValue);
        hasConditions = true;
      }

      // Add filters
      for (final entry in filters.entries) {
        if (entry.value != null) {
          if (hasConditions) whereBuffer.write(' AND ');
          whereBuffer.write('${entry.key} = ?');
          params.add(entry.value);
          hasConditions = true;
        }
      }

      // Add additional WHERE clause
      if (additionalWhere != null && additionalWhere.isNotEmpty) {
        if (hasConditions) whereBuffer.write(' AND ');
        whereBuffer.write('($additionalWhere)');
        hasConditions = true;
      }

      final whereClause =
          hasConditions ? 'WHERE ${whereBuffer.toString()}' : '';

      // Build ORDER BY
      final orderBy = orderDirection?.toUpperCase() == 'DESC'
          ? 'ORDER BY $cursorField DESC'
          : 'ORDER BY $cursorField ASC';

      // Select columns
      final columnList = columns?.join(', ') ?? '*';

      // Execute query with one extra item to check for more
      final sql = '''
        SELECT $columnList FROM $table
        $whereClause
        $orderBy
        LIMIT ?
      ''';

      params.add(limit + 1);

      final results = await _queryExecutor.execute(sql, params);
      final rows = results.toList();

      // Check if there are more items
      bool hasMore = false;
      dynamic nextCursor;

      if (rows.length > limit) {
        hasMore = true;
        rows.removeLast(); // Remove the extra item
      }

      if (rows.isNotEmpty) {
        nextCursor = rows.last[cursorField];
      }

      return PaginatedResult<ResultRow>(
        items: rows,
        nextCursor: nextCursor,
        hasMore: hasMore,
        queryDuration: queryStopwatch.elapsed,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch paginated results using offset pagination (for smaller datasets)
  Future<PaginatedResult<ResultRow>> fetchOffset({
    required String table,
    int page = 1,
    int limit = 100,
    Map<String, dynamic> filters = const {},
    String? orderBy,
    String? orderDirection,
    List<String>? columns,
    String? additionalWhere,
  }) async {
    final queryStopwatch = Stopwatch()..start();

    try {
      page = page > 0 ? page : 1;
      limit = limit.clamp(1, 1000);

      // Build WHERE clause
      final whereBuffer = StringBuffer();
      final params = <dynamic>[];
      var hasConditions = false;

      for (final entry in filters.entries) {
        if (entry.value != null) {
          if (hasConditions) whereBuffer.write(' AND ');
          whereBuffer.write('${entry.key} = ?');
          params.add(entry.value);
          hasConditions = true;
        }
      }

      // Add additional WHERE clause
      if (additionalWhere != null && additionalWhere.isNotEmpty) {
        if (hasConditions) whereBuffer.write(' AND ');
        whereBuffer.write('($additionalWhere)');
        hasConditions = true;
      }

      final whereClause =
          hasConditions ? 'WHERE ${whereBuffer.toString()}' : '';

      // Get total count (only if needed)
      int? total;
      if (page == 1 || limit < 1000) {
        // Only count for first page or reasonable limits
        final countResults = await _queryExecutor.execute(
          'SELECT COUNT(*) as total FROM $table $whereClause',
          params,
        );
        total = countResults.first['total'] as int;
      }

      // Build ORDER BY
      final orderByClause = orderBy != null
          ? 'ORDER BY $orderBy ${orderDirection?.toUpperCase() == 'DESC' ? 'DESC' : 'ASC'}'
          : '';

      // Select columns
      final columnList = columns?.join(', ') ?? '*';

      // Execute paginated query
      final offset = (page - 1) * limit;
      final sql = '''
        SELECT $columnList FROM $table
        $whereClause
        $orderByClause
        LIMIT ? OFFSET ?
      ''';

      final queryParams = [...params, limit, offset];
      final results = await _queryExecutor.execute(sql, queryParams);
      final rows = results.toList();

      // Calculate pagination info
      int? totalPages;
      bool hasMore = false;

      if (total != null) {
        totalPages = (total / limit).ceil();
        hasMore = (page * limit) < total;
      } else {
        // Estimate based on result size
        hasMore = rows.length >= limit;
      }

      return PaginatedResult<ResultRow>(
        items: rows,
        totalCount: total,
        currentPage: page,
        totalPages: totalPages,
        hasMore: hasMore,
        queryDuration: queryStopwatch.elapsed,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Build WHERE clause for filtering
  String buildWhereClause(Map<String, dynamic> filters) {
    if (filters.isEmpty) return '';

    final conditions = <String>[];
    for (final entry in filters.entries) {
      if (entry.value != null) {
        conditions.add('${entry.key} = ?');
      }
    }

    return conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
  }

  /// Build ORDER BY clause
  String buildOrderByClause(String? orderBy, String? orderDirection) {
    if (orderBy == null || orderBy.isEmpty) return '';

    final direction = orderDirection?.toUpperCase() == 'DESC' ? 'DESC' : 'ASC';
    return 'ORDER BY $orderBy $direction';
  }

  /// Build LIMIT clause for pagination
  String buildLimitClause(int? page, int? limit) {
    if (limit == null || limit <= 0) return '';

    final offset = page != null && page > 1 ? (page - 1) * limit : 0;
    return 'LIMIT $limit OFFSET $offset';
  }

  /// Create a search WHERE clause for text fields
  String buildSearchWhereClause(List<String> searchFields, String searchTerm) {
    if (searchFields.isEmpty || searchTerm.isEmpty) return '';

    final conditions = searchFields.map((field) => '$field LIKE ?').toList();
    return '(${conditions.join(' OR ')})';
  }

  /// Create search parameters for text fields
  List<String> buildSearchParameters(
      List<String> searchFields, String searchTerm) {
    if (searchFields.isEmpty || searchTerm.isEmpty) return [];

    final searchPattern = '%$searchTerm%';
    return List.filled(searchFields.length, searchPattern);
  }

  /// Validate pagination parameters
  Map<String, dynamic> validatePaginationParams({
    int? page,
    int? limit,
    String? orderBy,
    String? orderDirection,
  }) {
    final errors = <String>[];

    if (page != null && page < 1) {
      errors.add('Page must be greater than 0');
    }

    if (limit != null && (limit < 1 || limit > 1000)) {
      errors.add('Limit must be between 1 and 1000');
    }

    if (orderDirection != null &&
        !['ASC', 'DESC'].contains(orderDirection.toUpperCase())) {
      errors.add('Order direction must be ASC or DESC');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'validatedParams': {
        'page': page?.clamp(1, double.infinity) ?? 1,
        'limit': limit?.clamp(1, 1000) ?? 100,
        'orderBy': orderBy,
        'orderDirection': orderDirection?.toUpperCase() ?? 'ASC',
      },
    };
  }
}