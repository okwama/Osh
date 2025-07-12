import 'package:hive_flutter/hive_flutter.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/hive/client_model.dart' as HiveClient;
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/utils/safe_error_handler.dart';
import 'package:get/get.dart';
import 'dart:async';

/// Enhanced client storage service with incremental updates and smart synchronization
/// Downloads and stores client lists locally, then only fetches new additions
class ClientStorageService {
  static ClientStorageService? _instance;
  static ClientStorageService get instance =>
      _instance ??= ClientStorageService._();

  ClientStorageService._();

  late Box<HiveClient.ClientModel> _clientBox;
  late Box _metadataBox;
  late Box _syncQueueBox;
  bool _isInitialized = false;

  // Storage keys
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _lastClientIdKey = 'last_client_id';
  static const String _totalClientsKey = 'total_clients_count';
  static const String _userCountryKey = 'user_country_id';
  static const String _syncStatusKey = 'sync_status';

  // Sync status constants
  static const String STATUS_IDLE = 'idle';
  static const String STATUS_SYNCING = 'syncing';
  static const String STATUS_ERROR = 'error';

  /// Initialize the storage service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 🚀 FAST INITIALIZATION: Open boxes concurrently
      final futures = await Future.wait([
        Hive.openBox<HiveClient.ClientModel>('client_storage'),
        Hive.openBox('client_metadata'),
        Hive.openBox('client_sync_queue'),
      ]);

      _clientBox = futures[0] as Box<HiveClient.ClientModel>;
      _metadataBox = futures[1] as Box;
      _syncQueueBox = futures[2] as Box;
      _isInitialized = true;

      print('📦 ClientStorageService initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize ClientStorageService: $e');

      // 🔧 AUTO-FIX: Clear corrupted data and retry
      if (e
          .toString()
          .contains('type \'Null\' is not a subtype of type \'int\'')) {
        print('🔧 Detected corrupted Hive data, clearing and retrying...');
        await clearCorruptedData();

        // Retry initialization
        final futures = await Future.wait([
          Hive.openBox<HiveClient.ClientModel>('client_storage'),
          Hive.openBox('client_metadata'),
          Hive.openBox('client_sync_queue'),
        ]);

        _clientBox = futures[0] as Box<HiveClient.ClientModel>;
        _metadataBox = futures[1] as Box;
        _syncQueueBox = futures[2] as Box;
        _isInitialized = true;

        print(
            '✅ ClientStorageService initialized after clearing corrupted data');
        return;
      }

      rethrow;
    }
  }

  /// Get current user's country ID for security filtering
  Future<int> _getCurrentUserCountryId() async {
    try {
      final currentUser =
          await DatabaseService.instance.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      if (countryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      return countryId;
    } catch (e) {
      print('❌ Error getting user country ID: $e');
      rethrow;
    }
  }

  /// Get all stored clients (from local storage)
  Future<List<Client>> getAllStoredClients() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final userCountryId = await _getCurrentUserCountryId();

      // Filter clients by user's country for security
      final hiveClients = _clientBox.values
          .where((hiveClient) => hiveClient.countryId == userCountryId)
          .toList();

      return hiveClients
          .map((hiveClient) => _hiveToClient(hiveClient))
          .toList();
    } catch (e) {
      print('❌ Error getting stored clients: $e');
      return [];
    }
  }

  /// Smart sync: Download all clients initially, then only fetch new additions
  Future<List<Client>> syncClients({bool forceFullSync = false}) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final userCountryId = await _getCurrentUserCountryId();

      // Store user country for future reference
      await _metadataBox.put(_userCountryKey, userCountryId);

      if (forceFullSync) {
        return await _performFullSync(userCountryId);
      } else {
        return await _performIncrementalSync(userCountryId);
      }
    } catch (e) {
      print('❌ Error syncing clients: $e');

      // Check if it's a circuit breaker issue
      if (e.toString().contains('Circuit breaker is open')) {
        print('🚨 Circuit breaker is open - using stored data only');
        return await getAllStoredClients();
      }

      // Check if it's a timeout issue
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        print('⏰ Database timeout - using stored data only');
        return await getAllStoredClients();
      }

      // Return stored clients as fallback for any other error
      return await getAllStoredClients();
    }
  }

  /// Perform full sync (download all clients)
  Future<List<Client>> _performFullSync(int userCountryId) async {
    print('🔄 Performing full client sync for country $userCountryId...');

    try {
      // Set sync status
      await _setSyncStatus(STATUS_SYNCING);

      // Fetch all clients from database with resilient handling
      final paginationService = PaginationService.instance;
      final result = await paginationService
          .fetchOffset(
        table: 'Clients',
        page: 1,
        limit: 10000, // Comprehensive sync limit
        filters: {'countryId': userCountryId},
        additionalWhere: 'countryId IS NOT NULL AND countryId > 0',
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: [], // Add empty whereParams array
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
          'created_at'
        ],
      )
          .timeout(
        const Duration(seconds: 30), // Increased timeout for larger dataset
        onTimeout: () {
          throw TimeoutException('Client sync timeout after 30 seconds');
        },
      );

      // Clear existing storage
      await _clientBox.clear();

      // Store new clients
      final clients = <Client>[];
      for (final row in result.items) {
        final client = Client(
          id: row['id'] as int,
          name: row['name'] as String,
          address: row['address'] as String? ?? '',
          latitude: row['latitude'] as double?,
          longitude: row['longitude'] as double?,
          email: row['email'] as String? ?? '',
          contact: row['contact'] as String? ?? '',
          regionId: row['region_id'] as int,
          region: row['region'] as String? ?? '',
          countryId: row['countryId'] as int,
        );

        // Store in Hive
        final hiveClient = _clientToHive(client);
        await _clientBox.put(client.id, hiveClient);
        clients.add(client);
      }

      // Update metadata
      await _updateMetadata(
        lastSync: DateTime.now(),
        lastClientId: clients.isNotEmpty ? clients.first.id : 0,
        totalClients: clients.length,
      );

      await _setSyncStatus(STATUS_IDLE);
      print('✅ Full sync completed: ${clients.length} clients stored');

      return clients;
    } catch (e) {
      await _setSyncStatus(STATUS_ERROR);
      print('❌ Full sync failed: $e');
      rethrow;
    }
  }

  /// Perform incremental sync (only fetch new clients)
  Future<List<Client>> _performIncrementalSync(int userCountryId) async {
    print(
        '🔄 Performing incremental client sync for country $userCountryId...');

    try {
      // Get last sync info
      final lastSync = await _getLastSyncTime();
      final lastClientId = await _getLastClientId();

      // Set sync status
      await _setSyncStatus(STATUS_SYNCING);

      // Fetch only new clients since last sync
      final paginationService = PaginationService.instance;
      final result = await paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: 10000, // Increased incremental sync limit
        filters: {
          'countryId': userCountryId,
          if (lastClientId > 0) 'id': '> $lastClientId',
        },
        additionalWhere: 'countryId IS NOT NULL AND countryId > 0',
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: [], // Add empty whereParams array
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
          'created_at'
        ],
      );

      final newClients = <Client>[];
      for (final row in result.items) {
        final client = Client(
          id: row['id'] as int,
          name: row['name'] as String,
          address: row['address'] as String? ?? '',
          latitude: row['latitude'] as double?,
          longitude: row['longitude'] as double?,
          email: row['email'] as String? ?? '',
          contact: row['contact'] as String? ?? '',
          regionId: row['region_id'] as int,
          region: row['region'] as String? ?? '',
          countryId: row['countryId'] as int,
        );

        // Store in Hive
        final hiveClient = _clientToHive(client);
        await _clientBox.put(client.id, hiveClient);
        newClients.add(client);
      }

      // Update metadata if new clients found
      if (newClients.isNotEmpty) {
        await _updateMetadata(
          lastSync: DateTime.now(),
          lastClientId: newClients.first.id,
          totalClients: await _getTotalClients() + newClients.length,
        );
      }

      await _setSyncStatus(STATUS_IDLE);
      print(
          '✅ Incremental sync completed: ${newClients.length} new clients added');

      // Return all clients (stored + new)
      return await getAllStoredClients();
    } catch (e) {
      await _setSyncStatus(STATUS_ERROR);
      print('❌ Incremental sync failed: $e');
      rethrow;
    }
  }

  /// Check if sync is needed
  Future<bool> isSyncNeeded() async {
    try {
      final lastSync = await _getLastSyncTime();
      if (lastSync == null) return true;

      // Sync if last sync was more than 1 hour ago
      final timeSinceLastSync = DateTime.now().difference(lastSync);
      return timeSinceLastSync.inHours >= 1;
    } catch (e) {
      return true; // Sync if we can't determine last sync time
    }
  }

  /// Get sync status
  Future<String> getSyncStatus() async {
    try {
      return _metadataBox.get(_syncStatusKey, defaultValue: STATUS_IDLE);
    } catch (e) {
      return STATUS_IDLE;
    }
  }

  /// Set sync status
  Future<void> _setSyncStatus(String status) async {
    try {
      await _metadataBox.put(_syncStatusKey, status);
    } catch (e) {
      print('❌ Error setting sync status: $e');
    }
  }

  /// Get last sync time
  Future<DateTime?> _getLastSyncTime() async {
    try {
      final timestamp = _metadataBox.get(_lastSyncKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  /// Get last client ID
  Future<int> _getLastClientId() async {
    try {
      return _metadataBox.get(_lastClientIdKey, defaultValue: 0);
    } catch (e) {
      return 0;
    }
  }

  /// Get total clients count
  Future<int> _getTotalClients() async {
    try {
      return _metadataBox.get(_totalClientsKey, defaultValue: 0);
    } catch (e) {
      return 0;
    }
  }

  /// Update metadata
  Future<void> _updateMetadata({
    required DateTime lastSync,
    required int lastClientId,
    required int totalClients,
  }) async {
    try {
      await _metadataBox.put(_lastSyncKey, lastSync.toIso8601String());
      await _metadataBox.put(_lastClientIdKey, lastClientId);
      await _metadataBox.put(_totalClientsKey, totalClients);
    } catch (e) {
      print('❌ Error updating metadata: $e');
    }
  }

  /// Add new client to storage
  Future<void> addClient(Client client) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final hiveClient = _clientToHive(client);
      await _clientBox.put(client.id, hiveClient);

      // Update metadata
      final currentTotal = await _getTotalClients();
      await _updateMetadata(
        lastSync: DateTime.now(),
        lastClientId: client.id,
        totalClients: currentTotal + 1,
      );

      print('✅ Added client ${client.name} to storage');
    } catch (e) {
      print('❌ Error adding client to storage: $e');
    }
  }

  /// Update existing client in storage
  Future<void> updateClient(Client client) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final hiveClient = _clientToHive(client);
      await _clientBox.put(client.id, hiveClient);

      print('✅ Updated client ${client.name} in storage');
    } catch (e) {
      print('❌ Error updating client in storage: $e');
    }
  }

  /// Delete client from storage
  Future<void> deleteClient(int clientId) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _clientBox.delete(clientId);

      // Update metadata
      final currentTotal = await _getTotalClients();
      await _updateMetadata(
        lastSync: DateTime.now(),
        lastClientId: await _getLastClientId(),
        totalClients: currentTotal - 1,
      );

      print('✅ Deleted client $clientId from storage');
    } catch (e) {
      print('❌ Error deleting client from storage: $e');
    }
  }

  /// Clear all stored data
  Future<void> clearStorage() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _clientBox.clear();
      await _metadataBox.clear();
      await _syncQueueBox.clear();
      print('✅ Cleared all client storage');
    } catch (e) {
      print('❌ Error clearing storage: $e');
    }
  }

  /// Clear corrupted Hive data (emergency fix)
  static Future<void> clearCorruptedData() async {
    try {
      // Close boxes if they're open
      try {
        await Hive.box('client_storage').close();
      } catch (e) {}

      try {
        await Hive.box('client_metadata').close();
      } catch (e) {}

      try {
        await Hive.box('client_sync_queue').close();
      } catch (e) {}

      // Delete boxes from disk
      await Hive.deleteBoxFromDisk('client_storage');
      await Hive.deleteBoxFromDisk('client_metadata');
      await Hive.deleteBoxFromDisk('client_sync_queue');

      print('✅ Cleared corrupted Hive data');
    } catch (e) {
      print('❌ Error clearing corrupted data: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final userCountryId = await _getCurrentUserCountryId();
      final storedClients = _clientBox.values
          .where((hiveClient) => hiveClient.countryId == userCountryId)
          .length;

      final lastSync = await _getLastSyncTime();
      final syncStatus = await getSyncStatus();

      return {
        'storedClients': storedClients,
        'lastSync': lastSync?.toIso8601String(),
        'syncStatus': syncStatus,
        'userCountryId': userCountryId,
        'totalClients': await _getTotalClients(),
        'lastClientId': await _getLastClientId(),
      };
    } catch (e) {
      print('❌ Error getting storage stats: $e');
      return {};
    }
  }

  /// Convert Client to HiveClient
  HiveClient.ClientModel _clientToHive(Client client) {
    return HiveClient.ClientModel(
      id: client.id,
      name: client.name,
      address: client.address,
      phone: client.contact ?? '',
      latitude: client.latitude ?? 0.0,
      longitude: client.longitude ?? 0.0,
      email: client.email ?? '',
      status: 'active', // Default status
      countryId: client.countryId,
    );
  }

  /// Convert HiveClient to Client
  Client _hiveToClient(HiveClient.ClientModel hiveClient) {
    return Client(
      id: hiveClient.id,
      name: hiveClient.name,
      address: hiveClient.address,
      contact: hiveClient.phone,
      latitude: hiveClient.latitude,
      longitude: hiveClient.longitude,
      email: hiveClient.email,
      regionId: 0, // Default values for Hive model
      region: '',
      countryId: hiveClient.countryId,
    );
  }

  /// Sync clients with enhanced error handling
  Future<List<Client>> syncClientsWithRetry(
      {bool forceFullSync = false}) async {
    try {
      return await syncClients(forceFullSync: forceFullSync);
    } catch (e) {
      if (e.toString().contains('Circuit breaker is open')) {
        print('🔄 Circuit breaker is open, using stored data as fallback');
      }

      // Return stored data as fallback
      return await getAllStoredClients();
    }
  }

  /// Check if database is healthy
  Future<bool> isDatabaseHealthy() async {
    try {
      final db = DatabaseService.instance;
      return await db.isHealthy();
    } catch (e) {
      return false;
    }
  }

  /// Load more clients incrementally (for pagination)
  Future<List<Client>> loadMoreClients({
    int page = 1,
    int limit = 100,
    bool appendToExisting = true,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final userCountryId = await _getCurrentUserCountryId();

      print('📄 Loading more clients: page $page, limit $limit');

      final paginationService = PaginationService.instance;
      final result = await paginationService
          .fetchOffset(
        table: 'Clients',
        page: page,
        limit: 10000, // Increased load more limit
        filters: {'countryId': userCountryId},
        additionalWhere: 'countryId IS NOT NULL AND countryId > 0',
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: [], // Add empty whereParams array
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
          'created_at'
        ],
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Load more timeout after 15 seconds');
        },
      );

      final newClients = <Client>[];
      for (final row in result.items) {
        final client = Client(
          id: row['id'] as int,
          name: row['name'] as String,
          address: row['address'] as String? ?? '',
          latitude: row['latitude'] as double?,
          longitude: row['longitude'] as double?,
          email: row['email'] as String? ?? '',
          contact: row['contact'] as String? ?? '',
          regionId: row['region_id'] as int,
          region: row['region'] as String? ?? '',
          countryId: row['countryId'] as int,
        );

        // Store in Hive
        final hiveClient = _clientToHive(client);
        await _clientBox.put(client.id, hiveClient);
        newClients.add(client);
      }

      print('✅ Loaded ${newClients.length} more clients');

      if (appendToExisting) {
        // Return all clients (existing + new)
        return await getAllStoredClients();
      } else {
        // Return only new clients
        return newClients;
      }
    } catch (e) {
      print('❌ Error loading more clients: $e');
      return [];
    }
  }

  /// Get total client count for pagination
  Future<int> getTotalClientCount() async {
    try {
      final userCountryId = await _getCurrentUserCountryId();

      final paginationService = PaginationService.instance;
      final result = await paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: 1,
        filters: {'countryId': userCountryId},
        additionalWhere: 'countryId IS NOT NULL AND countryId > 0',
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: [], // Add empty whereParams array
        columns: ['COUNT(*) as total'],
      );

      if (result.items.isNotEmpty) {
        return result.items.first['total'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting total client count: $e');
      return 0;
    }
  }
}
