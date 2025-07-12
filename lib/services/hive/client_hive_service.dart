import 'package:hive_flutter/hive_flutter.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/hive/client_model.dart' as HiveClient;
import 'package:woosh/services/core/client_service.dart';
import 'package:woosh/services/database_service.dart';
import 'package:get/get.dart';
import 'dart:async';

/// Enhanced Hive-based client service with opportunistic UI flow
/// Implements caching, retry logic, and status tracking for instant UI updates
class ClientHiveService {
  static ClientHiveService? _instance;
  static ClientHiveService get instance => _instance ??= ClientHiveService._();

  ClientHiveService._();

  late Box<HiveClient.ClientModel> _clientBox;
  late Box _statusBox;
  late Box _queueBox;
  late Box _operationBox;
  bool _isInitialized = false;

  // Sync status enum
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_SUCCESS = 'success';
  static const String STATUS_FAILED = 'failed';
  static const String STATUS_SYNCING = 'syncing';

  /// Initialize Hive boxes and services
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _clientBox = await Hive.openBox<HiveClient.ClientModel>('clients');
      _statusBox = await Hive.openBox('client_sync_status');
      _queueBox = await Hive.openBox('client_sync_queue');
      _operationBox = await Hive.openBox('background_sync_operations');
      _isInitialized = true;

      print('🔍 ClientHiveService initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize ClientHiveService: $e');
      rethrow;
    }
  }

  /// Get all cached clients with sync status
  List<Client> getAllClients() {
    if (!_isInitialized) return [];

    try {
      return _clientBox.values
          .map((hiveClient) => _hiveToClient(hiveClient))
          .toList();
    } catch (e) {
      print('❌ Error getting cached clients: $e');
      return [];
    }
  }

  /// Add client with opportunistic UI (immediate UI update + background sync)
  Future<void> addClientOptimistic(Client client) async {
    if (!_isInitialized) return;

    try {
      // 1. Add to UI instantly (optimistic update)
      final hiveClient = _clientToHive(client);
      await _clientBox.put(client.id, hiveClient);

      // 2. Set status to pending
      await _setSyncStatus(client.id, STATUS_PENDING);

      // 3. Add to sync queue
      await _addToSyncQueue(client.id, 'add');

      print('✅ Added client ${client.name} optimistically');

      // 4. Background sync
      _processSyncQueue();
    } catch (e) {
      print('❌ Error in optimistic add: $e');
    }
  }

  /// Update client with optimistic UI
  Future<void> updateClientOptimistic(Client client) async {
    if (!_isInitialized) return;

    try {
      // 1. Update UI instantly
      final hiveClient = _clientToHive(client);
      await _clientBox.put(client.id, hiveClient);

      // 2. Set status to syncing
      await _setSyncStatus(client.id, STATUS_SYNCING);

      // 3. Add to sync queue
      await _addToSyncQueue(client.id, 'update');

      print('✅ Updated client ${client.name} optimistically');

      // 4. Background sync
      _processSyncQueue();
    } catch (e) {
      print('❌ Error in optimistic update: $e');
    }
  }

  /// Delete client with optimistic UI
  Future<void> deleteClientOptimistic(int clientId) async {
    if (!_isInitialized) return;

    try {
      // 1. Remove from UI instantly
      await _clientBox.delete(clientId);

      // 2. Set status to pending
      await _setSyncStatus(clientId, STATUS_PENDING);

      // 3. Add to sync queue
      await _addToSyncQueue(clientId, 'delete');

      print('✅ Deleted client $clientId optimistically');

      // 4. Background sync
      _processSyncQueue();
    } catch (e) {
      print('❌ Error in optimistic delete: $e');
    }
  }

  /// Get sync status for a client
  String getSyncStatus(int clientId) {
    if (!_isInitialized) return STATUS_SUCCESS;

    try {
      return _statusBox.get(clientId.toString(), defaultValue: STATUS_SUCCESS);
    } catch (e) {
      return STATUS_SUCCESS;
    }
  }

  /// Set sync status for a client
  Future<void> _setSyncStatus(int clientId, String status) async {
    if (!_isInitialized) return;

    try {
      await _statusBox.put(clientId.toString(), status);
    } catch (e) {
      print('❌ Error setting sync status: $e');
    }
  }

  /// Add operation to sync queue
  Future<void> _addToSyncQueue(int clientId, String operation) async {
    if (!_isInitialized) return;

    try {
      final queueItem = {
        'clientId': clientId,
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _queueBox.add(queueItem);
    } catch (e) {
      print('❌ Error adding to sync queue: $e');
    }
  }

  /// Process sync queue in background
  Future<void> _processSyncQueue() async {
    if (!_isInitialized) return;

    try {
      final queueItems = _queueBox.values.toList();

      for (final item in queueItems) {
        final clientId = item['clientId'] as int;
        final operation = item['operation'] as String;

        try {
          // Get client data from cache
          final hiveClient = _clientBox.get(clientId);
          if (hiveClient == null) continue;

          final client = _hiveToClient(hiveClient);

          // Perform operation based on type
          switch (operation) {
            case 'add':
              await _syncAddClient(client);
              break;
            case 'update':
              await _syncUpdateClient(client);
              break;
            case 'delete':
              await _syncDeleteClient(clientId);
              break;
          }

          // Remove from queue on success
          await _queueBox.deleteAt(_queueBox.values.toList().indexOf(item));
        } catch (e) {
          print('❌ Sync failed for client $clientId: $e');
          await _setSyncStatus(clientId, STATUS_FAILED);
        }
      }
    } catch (e) {
      print('❌ Error processing sync queue: $e');
    }
  }

  /// Sync add operation
  Future<void> _syncAddClient(Client client) async {
    try {
      // Use the existing client service method
      await ClientService.instance.createClient(client);
      await _setSyncStatus(client.id, STATUS_SUCCESS);
      print('✅ Synced add for client ${client.name}');
    } catch (e) {
      await _setSyncStatus(client.id, STATUS_FAILED);
      rethrow;
    }
  }

  /// Sync update operation
  Future<void> _syncUpdateClient(Client client) async {
    try {
      // Use the existing client service method
      await ClientService.instance.updateClient(client);
      await _setSyncStatus(client.id, STATUS_SUCCESS);
      print('✅ Synced update for client ${client.name}');
    } catch (e) {
      await _setSyncStatus(client.id, STATUS_FAILED);
      rethrow;
    }
  }

  /// Sync delete operation
  Future<void> _syncDeleteClient(int clientId) async {
    try {
      // Use the existing client service method
      await ClientService.instance.deleteClient(clientId);
      await _setSyncStatus(clientId, STATUS_SUCCESS);
      print('✅ Synced delete for client $clientId');
    } catch (e) {
      await _setSyncStatus(clientId, STATUS_FAILED);
      rethrow;
    }
  }

  /// Refresh all clients from database
  Future<void> refreshFromDatabase() async {
    if (!_isInitialized) return;

    try {
      // Use the existing client service method
      final result = await ClientService.instance.fetchClientsOffset(
        page: 1,
        limit: 10000,
      );

      // Clear existing cache
      await _clientBox.clear();
      await _statusBox.clear();

      // Add fresh data
      for (final client in result.items) {
        final hiveClient = _clientToHive(client);
        await _clientBox.put(client.id, hiveClient);
        await _setSyncStatus(client.id, STATUS_SUCCESS);
      }

      print('✅ Refreshed ${result.items.length} clients from database');
    } catch (e) {
      print('❌ Error refreshing from database: $e');
    }
  }

  /// Retry failed operations
  Future<void> retryFailedOperations() async {
    if (!_isInitialized) return;

    try {
      final failedClients = _statusBox.values
          .where((status) => status == STATUS_FAILED)
          .map((status) => int.parse(status.toString()))
          .toList();

      for (final clientId in failedClients) {
        await _setSyncStatus(clientId, STATUS_PENDING);
      }

      await _processSyncQueue();
      print('✅ Retrying ${failedClients.length} failed operations');
    } catch (e) {
      print('❌ Error retrying failed operations: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    if (!_isInitialized) return;

    try {
      await _clientBox.clear();
      await _statusBox.clear();
      await _queueBox.clear();
      print('✅ Cleared all client cache');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Convert Hive client to regular client
  Client _hiveToClient(HiveClient.ClientModel hiveClient) {
    return Client(
      id: hiveClient.id,
      name: hiveClient.name,
      address: hiveClient.address,
      contact: hiveClient.phone, // Use phone field from Hive model
      latitude: hiveClient.latitude,
      longitude: hiveClient.longitude,
      email: hiveClient.email,
      regionId: 0, // Default values for Hive model
      region: '',
      countryId: 0,
    );
  }

  /// Convert regular client to Hive client
  HiveClient.ClientModel _clientToHive(Client client) {
    return HiveClient.ClientModel(
      id: client.id,
      name: client.name,
      address: client.address,
      phone: client.contact ?? '', // Use phone field for Hive model
      email: client.email ?? '',
      latitude: client.latitude ?? 0.0, // Handle nullable double
      longitude: client.longitude ?? 0.0, // Handle nullable double
      status: 'active',
      countryId: client.countryId
      , // Default to 0 if null
    );
  }
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _clientBox.close();
      await _statusBox.close();
      await _queueBox.close();
      _isInitialized = false;
    } catch (e) {
      print('❌ Error disposing ClientHiveService: $e');
    }
  }

  /// Get operation box for background sync
  Future<Box> getOperationBox() async {
    if (!_isInitialized) await init();
    return _operationBox;
  }

  /// Add operation to background sync queue
  Future<void> addBackgroundOperation(
      String type, int entityId, Map<String, dynamic> data) async {
    if (!_isInitialized) return;

    try {
      final operationId =
          '${type}_${entityId}_${DateTime.now().millisecondsSinceEpoch}';

      await _operationBox.put(operationId, {
        'type': type,
        'entityId': entityId,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      });

      print('📝 Added background operation: $type for ID $entityId');
    } catch (e) {
      print('❌ Error adding background operation: $e');
    }
  }

  /// Get all pending background operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    if (!_isInitialized) return [];

    try {
      return _operationBox.values
          .where((op) => op['status'] == 'pending')
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('❌ Error getting pending operations: $e');
      return [];
    }
  }

  /// Mark operation as completed
  Future<void> markOperationCompleted(String operationId) async {
    if (!_isInitialized) return;

    try {
      await _operationBox.delete(operationId);
      print('✅ Marked operation as completed: $operationId');
    } catch (e) {
      print('❌ Error marking operation as completed: $e');
    }
  }

  /// Clear all background operations
  Future<void> clearBackgroundOperations() async {
    if (!_isInitialized) return;

    try {
      await _operationBox.clear();
      print('🧹 Cleared all background operations');
    } catch (e) {
      print('❌ Error clearing background operations: $e');
    }
  }

  /// Add a generic sync operation to the background sync operations box
  Future<void> addSyncOperation(Map<String, dynamic> operation) async {
    if (!_isInitialized) return;
    try {
      await _operationBox.add(operation);
      print(
          '📝 Added sync operation to background_sync_operations: ${operation['type']}');
    } catch (e) {
      print('❌ Error adding sync operation: $e');
    }
  }
}
