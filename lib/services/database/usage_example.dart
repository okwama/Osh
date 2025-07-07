import 'package:woosh/services/database/index.dart';

/// Example usage of the modularized database services
class DatabaseUsageExample {
  /// Example 1: Using the main DatabaseService (facade pattern)
  Future<void> exampleUsingMainService() async {
    final db = DatabaseService.instance;

    // Initialize
    await db.initialize();

    // Simple query
    final results = await db.query('SELECT * FROM Clients LIMIT 10');
    print('Found ${results.length} clients');

    // Pagination
    final paginatedResults = await db.fetchPaginated(
      table: 'Clients',
      cursorField: 'id',
      limit: 20,
      filters: {'status': 1},
    );

    print('Paginated results: ${paginatedResults.items.length} items');
    print('Has more: ${paginatedResults.hasMore}');
    print('Query duration: ${paginatedResults.queryDuration.inMilliseconds}ms');

    // Auth
    final userId = db.getCurrentUserId();
    final isAdmin = await db.isAdmin(userId);
    print('User $userId is admin: $isAdmin');
  }

  /// Example 2: Using individual services directly
  Future<void> exampleUsingIndividualServices() async {
    // Connection pool
    final pool = ConnectionPool.instance;
    await pool.initialize();

    // Query executor
    final executor = QueryExecutor.instance;
    final results =
        await executor.execute('SELECT COUNT(*) as count FROM Clients');
    print('Total clients: ${results.first['count']}');

    // Pagination service
    final pagination = PaginationService.instance;
    final paginatedResults = await pagination.fetchKeyset(
      table: 'Clients',
      cursorField: 'id',
      limit: 50,
      filters: {'salesRepId': 1},
    );

    print('Keyset pagination: ${paginatedResults.items.length} items');

    // Auth service
    final auth = DatabaseAuthService.instance;
    final userRole = await auth.getUserRole(1);
    print('User role: ${userRole?['role']}');

    // Cleanup
    await pool.dispose();
  }

  /// Example 3: Advanced pagination with search
  Future<void> exampleAdvancedPagination() async {
    final db = DatabaseService.instance;
    await db.initialize();

    // Search with pagination
    final searchResults = await db.fetchPaginated(
      table: 'Clients',
      cursorField: 'id',
      limit: 25,
      additionalWhere: '''
        (name LIKE '%John%' OR 
         email LIKE '%john%' OR 
         phone LIKE '%123%')
      ''',
      orderDirection: 'DESC',
    );

    print('Search results: ${searchResults.items.length} items');

    // Offset pagination for smaller datasets
    final offsetResults = await db.fetchOffsetPaginated(
      table: 'Clients',
      page: 2,
      limit: 10,
      orderBy: 'createdAt',
      orderDirection: 'DESC',
    );

    print(
        'Offset pagination: Page ${offsetResults.currentPage} of ${offsetResults.totalPages}');
    print('Total count: ${offsetResults.totalCount}');
  }

  /// Example 4: Transaction handling
  Future<void> exampleTransaction() async {
    final db = DatabaseService.instance;
    await db.initialize();

    try {
      await db.transaction((connection) async {
        // Insert new client
        await connection.query(
          'INSERT INTO Clients (name, email, salesRepId) VALUES (?, ?, ?)',
          ['New Client', 'new@example.com', 1],
        );

        // Update some other data
        await connection.query(
          'UPDATE Clients SET status = 1 WHERE email = ?',
          ['new@example.com'],
        );

        // If everything succeeds, transaction commits automatically
        print('Transaction completed successfully');
      });
    } catch (e) {
      print('Transaction failed: $e');
      // Transaction automatically rolls back
    }
  }

  /// Example 5: Performance monitoring
  Future<void> examplePerformanceMonitoring() async {
    final db = DatabaseService.instance;
    await db.initialize();

    // Get comprehensive stats
    final stats = await db.getStats();
    print('Database Stats:');
    print('- Pool size: ${stats['pool_size']}');
    print('- Active connections: ${stats['active_connections']}');
    print('- Total queries: ${stats['total_queries_executed']}');
    print('- Query timeouts: ${stats['total_query_timeouts']}');
    print('- Success rate: ${stats['success_rate']}%');
    print('- Is healthy: ${stats['is_healthy']}');

    // Test connection
    final connectionTest = await db.testConnection();
    print('Connection test: ${connectionTest['success']}');
    print('Response time: ${connectionTest['response_time_ms']}ms');
  }

  /// Example 6: User permissions and access control
  Future<void> exampleUserPermissions() async {
    final db = DatabaseService.instance;
    await db.initialize();

    final userId = db.getCurrentUserId();

    // Check permissions
    final canAccess = await db.validateUserPermissions(userId, 'READ_CLIENTS');
    print('User can access clients: $canAccess');

    // Get user's accessible stores
    final stores = await db.getUserAccessibleStores(userId);
    print('User can access ${stores.length} stores');

    // Check specific store access
    if (stores.isNotEmpty) {
      final storeId = stores.first['id'];
      final canAccessStore = await db.canAccessStore(userId, storeId);
      print('Can access store $storeId: $canAccessStore');
    }

    // Get user's country
    final countryId = await db.getUserCountryId(userId);
    print('User country ID: $countryId');
  }
}
