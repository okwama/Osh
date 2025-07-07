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

    // Pagination
    final paginatedResults = await db.fetchPaginated(
      table: 'Clients',
      cursorField: 'id',
      limit: 20,
      filters: {'status': 1},
    );


    // Auth
    final userId = db.getCurrentUserId();
    final isAdmin = await db.isAdmin(userId);
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

    // Pagination service
    final pagination = PaginationService.instance;
    final paginatedResults = await pagination.fetchKeyset(
      table: 'Clients',
      cursorField: 'id',
      limit: 50,
      filters: {'salesRepId': 1},
    );


    // Auth service
    final auth = DatabaseAuthService.instance;
    final userRole = await auth.getUserRole(1);

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
      });
    } catch (e) {
      // Transaction automatically rolls back
    }
  }

  /// Example 5: Performance monitoring
  Future<void> examplePerformanceMonitoring() async {
    final db = DatabaseService.instance;
    await db.initialize();

    // Get comprehensive stats
    final stats = await db.getStats();

    // Test connection
    final connectionTest = await db.testConnection();
  }

  /// Example 6: User permissions and access control
  Future<void> exampleUserPermissions() async {
    final db = DatabaseService.instance;
    await db.initialize();

    final userId = db.getCurrentUserId();

    // Check permissions
    final canAccess = await db.validateUserPermissions(userId, 'READ_CLIENTS');

    // Get user's accessible stores
    final stores = await db.getUserAccessibleStores(userId);

    // Check specific store access
    if (stores.isNotEmpty) {
      final storeId = stores.first['id'];
      final canAccessStore = await db.canAccessStore(userId, storeId);
    }

    // Get user's country
    final countryId = await db.getUserCountryId(userId);
  }
}