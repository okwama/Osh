import 'dart:async';
import 'dart:collection';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/hive/client_hive_service.dart';
import 'package:woosh/services/core/client_cache_service.dart';
import 'dart:io';
import 'package:woosh/services/core/upload_service.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/services/core/reports/index.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';

/// Background sync handler for managing failed operations and network recovery
class BackgroundSyncHandler {
  static BackgroundSyncHandler? _instance;
  static BackgroundSyncHandler get instance =>
      _instance ??= BackgroundSyncHandler._();

  BackgroundSyncHandler._();

  // Queue management
  final Queue<SyncOperation> _pendingOperations = Queue();
  final Map<String, int> _retryCounts = {};
  final Map<String, DateTime> _lastRetryTimes = {};

  // Network state tracking
  bool _isOnline = true;
  bool _isProcessing = false;
  Timer? _retryTimer;
  Timer? _networkCheckTimer;

  // Configuration
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(minutes: 2);
  static const Duration _networkCheckInterval = Duration(seconds: 30);
  static const Duration _maxRetryDelay = Duration(hours: 1);

  // Service instances
  final DatabaseService _db = DatabaseService.instance;
  final ClientHiveService _hiveService = ClientHiveService.instance;
  final ClientCacheService _cacheService = ClientCacheService.instance;

  /// Initialize the background sync handler
  Future<void> initialize() async {
    print('🔄 Initializing background sync handler...');

    // Start network monitoring
    _startNetworkMonitoring();

    // Process any pending operations
    _processPendingOperations();
  }

  /// Add a failed operation to the retry queue
  Future<void> addFailedOperation(SyncOperation operation) async {
    try {
      // Generate unique operation ID
      final operationId =
          '${operation.type}_${operation.entityId}_${DateTime.now().millisecondsSinceEpoch}';

      // Store operation in Hive for persistence
      await _storeOperation(operationId, operation);

      // Add to memory queue
      _pendingOperations.add(operation);

      print(
          '📝 Added failed operation to retry queue: ${operation.type} for ID ${operation.entityId}');

      // Start processing if not already running
      if (!_isProcessing) {
        _processPendingOperations();
      }
    } catch (e) {
      print('❌ Error adding failed operation: $e');
    }
  }

  /// Add journey plan operation to background queue
  Future<void> addJourneyPlanOperation({
    required String operationType,
    required Map<String, dynamic> data,
    String? description,
  }) async {
    try {
      final operation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'journey_plan',
        'operation': operationType,
        'data': data,
        'description': description ?? 'Journey plan operation',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'pending',
      };

      await _hiveService.addSyncOperation(operation);
      print('🔄 Added journey plan operation to queue: $operationType');

      // Trigger background processing
      _processPendingOperations();
    } catch (e) {
      print('❌ Failed to add journey plan operation: $e');
    }
  }

  /// Add report submission to background queue
  Future<void> addReportSubmission({
    required int journeyPlanId,
    required int clientId,
    required int salesRepId,
    required ReportType reportType,
    required Map<String, dynamic> reportData,
    String? description,
  }) async {
    try {
      final operation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'report_submission',
        'operation': 'submit_report',
        'data': {
          'journeyPlanId': journeyPlanId,
          'clientId': clientId,
          'salesRepId': salesRepId,
          'reportType': reportType.toString(),
          'reportData': reportData,
        },
        'description':
            description ?? 'Report submission: ${reportType.toString()}',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'pending',
      };

      await _hiveService.addSyncOperation(operation);
      print('📝 Added report submission to queue: ${reportType.toString()}');

      // Trigger background processing
      _processPendingOperations();
    } catch (e) {
      print('❌ Failed to add report submission: $e');
    }
  }

  /// Add checkout operation to background queue
  Future<void> addCheckoutOperation({
    required int journeyPlanId,
    required int clientId,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final operation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'journey_plan',
        'operation': 'checkout',
        'data': {
          'journeyPlanId': journeyPlanId,
          'clientId': clientId,
          'checkoutTime': DateTime.now().toIso8601String(),
          'checkoutLatitude': latitude,
          'checkoutLongitude': longitude,
        },
        'description': description ?? 'Journey plan checkout',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'pending',
      };

      await _hiveService.addSyncOperation(operation);
      print('✅ Added checkout operation to queue');

      // Trigger background processing
      _processPendingOperations();
    } catch (e) {
      print('❌ Failed to add checkout operation: $e');
    }
  }

  /// Store operation in Hive for persistence across app restarts
  Future<void> _storeOperation(
      String operationId, SyncOperation operation) async {
    try {
      final operationBox = await _hiveService.getOperationBox();
      await operationBox.put(operationId, {
        'type': operation.type,
        'entityId': operation.entityId,
        'data': operation.data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0,
      });
    } catch (e) {
      print('❌ Error storing operation: $e');
    }
  }

  /// Load pending operations from Hive on app start
  Future<void> loadPendingOperations() async {
    try {
      final operationBox = await _hiveService.getOperationBox();
      final operations = operationBox.values.toList();

      for (final operationData in operations) {
        final operation = SyncOperation(
          type: operationData['type'],
          entityId: operationData['entityId'],
          data: operationData['data'],
        );

        _pendingOperations.add(operation);
        _retryCounts[operation.entityId.toString()] =
            operationData['retryCount'] ?? 0;
      }

      print(
          '📋 Loaded ${_pendingOperations.length} pending operations from storage');
    } catch (e) {
      print('❌ Error loading pending operations: $e');
    }
  }

  /// Process pending operations in background
  Future<void> _processPendingOperations() async {
    if (_isProcessing || _pendingOperations.isEmpty) return;

    _isProcessing = true;

    try {
      while (_pendingOperations.isNotEmpty && _isOnline) {
        final operation = _pendingOperations.removeFirst();
        final operationKey = operation.entityId.toString();

        // Check retry limits
        final retryCount = _retryCounts[operationKey] ?? 0;
        if (retryCount >= _maxRetries) {
          print(
              '⚠️ Operation ${operation.type} for ID ${operation.entityId} exceeded max retries');
          await _removeOperation(operationKey);
          continue;
        }

        // Check retry delay
        final lastRetry = _lastRetryTimes[operationKey];
        if (lastRetry != null) {
          final timeSinceLastRetry = DateTime.now().difference(lastRetry);
          final delay =
              Duration(minutes: _retryDelay.inMinutes * (retryCount + 1));

          if (timeSinceLastRetry < delay) {
            // Put operation back in queue
            _pendingOperations.add(operation);
            break;
          }
        }

        // Attempt to process operation
        final success = await _executeOperation(operation);

        if (success) {
          // Remove from storage on success
          await _removeOperation(operationKey);
          _retryCounts.remove(operationKey);
          _lastRetryTimes.remove(operationKey);

          print(
              '✅ Successfully processed operation: ${operation.type} for ID ${operation.entityId}');
        } else {
          // Update retry count and timestamp
          _retryCounts[operationKey] = retryCount + 1;
          _lastRetryTimes[operationKey] = DateTime.now();

          // Put back in queue for retry
          _pendingOperations.add(operation);

          print(
              '🔄 Failed to process operation: ${operation.type} for ID ${operation.entityId} (retry ${retryCount + 1}/$_maxRetries)');

          // Add delay before next retry
          await Future.delayed(Duration(seconds: (retryCount + 1) * 10));
        }
      }
    } catch (e) {
      print('❌ Error processing pending operations: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a specific operation
  Future<void> _processOperation(SyncOperation operation) async {
    try {
      print('🔄 Processing operation: ${operation.type}');

      switch (operation.type) {
        case 'add_client':
          await _processAddClient(operation);
          break;
        case 'update_client':
          await _processUpdateClient(operation);
          break;
        case 'delete_client':
          await _processDeleteClient(operation);
          break;
        case 'add_journey_plan':
          await _processAddJourneyPlan(operation);
          break;
        case 'update_journey_plan':
          await _processUpdateJourneyPlan(operation);
          break;
        case 'delete_journey_plan':
          await _processDeleteJourneyPlan(operation);
          break;
      }

      // Remove successful operation
      await _removeOperation(operation.entityId.toString());
      print('✅ Operation completed successfully: ${operation.type}');
    } catch (e) {
      print('❌ Operation failed: ${operation.type} - $e');
      await _markOperationAsFailed(operation.entityId.toString(), e.toString());
    }
  }

  /// Process client add operation
  Future<void> _processAddClient(SyncOperation operation) async {
    final clientData = operation.data;

    // Execute database operation
    final result = await _db.query(
      'INSERT INTO Clients (name, address, contact, latitude, longitude, email, region_id, region, countryId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        clientData['name'],
        clientData['address'],
        clientData['contact'],
        clientData['latitude'],
        clientData['longitude'],
        clientData['email'],
        clientData['regionId'],
        clientData['region'],
        clientData['countryId'],
      ],
    );

    if (result.affectedRows! > 0) {
      print('✅ Client added successfully: ${clientData['name']}');
    } else {
      print('❌ Failed to add client: ${clientData['name']}');
    }
  }

  /// Process client update operation
  Future<void> _processUpdateClient(SyncOperation operation) async {
    final clientData = operation.data;

    // Execute database operation
    final result = await _db.query(
      'UPDATE Clients SET name = ?, address = ?, contact = ?, latitude = ?, longitude = ?, email = ?, region_id = ?, region = ?, countryId = ? WHERE id = ?',
      [
        clientData['name'],
        clientData['address'],
        clientData['contact'],
        clientData['latitude'],
        clientData['longitude'],
        clientData['email'],
        clientData['regionId'],
        clientData['region'],
        clientData['countryId'],
        operation.entityId,
      ],
    );

    if (result.affectedRows! > 0) {
      print('✅ Client updated successfully: ${clientData['name']}');
    } else {
      print('❌ Failed to update client: ${clientData['name']}');
    }
  }

  /// Process client delete operation
  Future<void> _processDeleteClient(SyncOperation operation) async {
    // Execute database operation
    final result = await _db.query(
      'DELETE FROM Clients WHERE id = ?',
      [operation.entityId],
    );

    if (result.affectedRows! > 0) {
      print('✅ Client deleted successfully: ${operation.entityId}');
    } else {
      print('❌ Failed to delete client: ${operation.entityId}');
    }
  }

  /// Process add journey plan operation
  Future<void> _processAddJourneyPlan(SyncOperation operation) async {
    final planData = operation.data;

    // Execute database operation
    final result = await _db.query(
      'INSERT INTO JourneyPlans (clientId, userId, routeId, date, time, status) VALUES (?, ?, ?, ?, ?, ?)',
      [
        planData['clientId'],
        planData['userId'],
        planData['routeId'],
        planData['date'],
        planData['time'],
        planData['status'],
      ],
    );

    if (result.affectedRows! > 0) {
      print('✅ Journey plan added successfully');
    } else {
      print('❌ Failed to add journey plan');
    }
  }

  /// Process update journey plan operation
  Future<void> _processUpdateJourneyPlan(SyncOperation operation) async {
    final planData = operation.data;

    // Execute database operation
    final result = await _db.query(
      'UPDATE JourneyPlans SET status = ?, checkInTime = ?, checkoutTime = ?, notes = ?, latitude = ?, longitude = ?, checkoutLatitude = ?, checkoutLongitude = ? WHERE id = ?',
      [
        planData['status'],
        planData['checkInTime'],
        planData['checkoutTime'],
        planData['notes'],
        planData['latitude'],
        planData['longitude'],
        planData['checkoutLatitude'],
        planData['checkoutLongitude'],
        operation.entityId,
      ],
    );

    if (result.affectedRows! > 0) {
      print('✅ Journey plan updated successfully');
    } else {
      print('❌ Failed to update journey plan');
    }
  }

  /// Process delete journey plan operation
  Future<void> _processDeleteJourneyPlan(SyncOperation operation) async {
    // Execute database operation
    final result = await _db.query(
      'DELETE FROM JourneyPlans WHERE id = ?',
      [operation.entityId],
    );

    if (result.affectedRows! > 0) {
      print('✅ Journey plan deleted successfully');
    } else {
      print('❌ Failed to delete journey plan');
    }
  }

  /// Process check-in operation
  Future<void> _processCheckInOperation(Map<String, dynamic> data) async {
    try {
      final journeyId = data['journeyPlanId'] as int;
      final clientId = data['clientId'] as int;
      final imageUrl = data['imageUrl'] as String?;
      final latitude = data['latitude'] as double?;
      final longitude = data['longitude'] as double?;
      final checkInTime = DateTime.parse(data['checkInTime'] as String);

      await JourneyPlanService.updateJourneyPlan(
        journeyId: journeyId,
        clientId: clientId,
        status: JourneyPlan.statusInProgress,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        checkInTime: checkInTime,
      );

      await _markOperationAsCompleted(data['operationId'] as String);
      print('✅ Check-in processed successfully');
    } catch (e) {
      print('❌ Failed to process check-in: $e');
      await _markOperationAsFailed(data['operationId'] as String, e.toString());
    }
  }

  /// Process checkout operation
  Future<void> _processCheckoutOperation(Map<String, dynamic> data) async {
    try {
      final journeyId = data['journeyPlanId'] as int;
      final clientId = data['clientId'] as int;
      final checkoutTime = DateTime.parse(data['checkoutTime'] as String);
      final latitude = data['checkoutLatitude'] as double;
      final longitude = data['checkoutLongitude'] as double;

      await JourneyPlanService.updateJourneyPlan(
        journeyId: journeyId,
        clientId: clientId,
        status: JourneyPlan.statusCompleted,
        checkoutTime: checkoutTime,
        checkoutLatitude: latitude,
        checkoutLongitude: longitude,
      );

      await _markOperationAsCompleted(data['operationId'] as String);
      print('✅ Checkout processed successfully');
    } catch (e) {
      print('❌ Failed to process checkout: $e');
      await _markOperationAsFailed(data['operationId'] as String, e.toString());
    }
  }

  /// Process update notes operation
  Future<void> _processUpdateNotesOperation(Map<String, dynamic> data) async {
    try {
      final journeyId = data['journeyPlanId'] as int;
      final clientId = data['clientId'] as int;
      final notes = data['notes'] as String;
      final status = data['status'] as int;

      await JourneyPlanService.updateJourneyPlan(
        journeyId: journeyId,
        clientId: clientId,
        notes: notes,
        status: status,
      );

      await _markOperationAsCompleted(data['operationId'] as String);
      print('✅ Notes update processed successfully');
    } catch (e) {
      print('❌ Failed to process notes update: $e');
      await _markOperationAsFailed(data['operationId'] as String, e.toString());
    }
  }

  /// Execute a specific operation
  Future<bool> _executeOperation(SyncOperation operation) async {
    try {
      switch (operation.type) {
        case 'add_client':
          return await _executeAddClient(operation);
        case 'update_client':
          return await _executeUpdateClient(operation);
        case 'delete_client':
          return await _executeDeleteClient(operation);
        case 'add_journey_plan':
          return await _executeAddJourneyPlan(operation);
        case 'update_journey_plan':
          return await _executeUpdateJourneyPlan(operation);
        case 'delete_journey_plan':
          return await _executeDeleteJourneyPlan(operation);
        default:
          print('⚠️ Unknown operation type: ${operation.type}');
          return false;
      }
    } catch (e) {
      print('❌ Error executing operation ${operation.type}: $e');
      return false;
    }
  }

  /// Execute add client operation
  Future<bool> _executeAddClient(SyncOperation operation) async {
    try {
      final clientData = operation.data;

      // Execute database operation
      final result = await _db.query(
        'INSERT INTO Clients (name, address, contact, latitude, longitude, email, region_id, region, countryId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          clientData['name'],
          clientData['address'],
          clientData['contact'],
          clientData['latitude'],
          clientData['longitude'],
          clientData['email'],
          clientData['regionId'],
          clientData['region'],
          clientData['countryId'],
        ],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('❌ Error adding client: $e');
      return false;
    }
  }

  /// Execute update client operation
  Future<bool> _executeUpdateClient(SyncOperation operation) async {
    try {
      final clientData = operation.data;

      // Execute database operation
      final result = await _db.query(
        'UPDATE Clients SET name = ?, address = ?, contact = ?, latitude = ?, longitude = ?, email = ?, region_id = ?, region = ?, countryId = ? WHERE id = ?',
        [
          clientData['name'],
          clientData['address'],
          clientData['contact'],
          clientData['latitude'],
          clientData['longitude'],
          clientData['email'],
          clientData['regionId'],
          clientData['region'],
          clientData['countryId'],
          operation.entityId,
        ],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('❌ Error updating client: $e');
      return false;
    }
  }

  /// Execute delete client operation
  Future<bool> _executeDeleteClient(SyncOperation operation) async {
    try {
      // Execute database operation
      final result = await _db.query(
        'DELETE FROM Clients WHERE id = ?',
        [operation.entityId],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('❌ Error deleting client: $e');
      return false;
    }
  }

  /// Execute add journey plan operation
  Future<bool> _executeAddJourneyPlan(SyncOperation operation) async {
    try {
      final planData = operation.data;

      // Execute database operation
      final result = await _db.query(
        'INSERT INTO JourneyPlans (clientId, userId, routeId, date, time, status) VALUES (?, ?, ?, ?, ?, ?)',
        [
          planData['clientId'],
          planData['userId'],
          planData['routeId'],
          planData['date'],
          planData['time'],
          planData['status'],
        ],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('❌ Error adding journey plan: $e');
      return false;
    }
  }

  /// Execute update journey plan operation
  Future<bool> _executeUpdateJourneyPlan(SyncOperation operation) async {
    try {
      final planData = operation.data;

      // Execute database operation
      final result = await _db.query(
        'UPDATE JourneyPlans SET status = ?, checkInTime = ?, checkoutTime = ?, notes = ?, latitude = ?, longitude = ?, checkoutLatitude = ?, checkoutLongitude = ? WHERE id = ?',
        [
          planData['status'],
          planData['checkInTime'],
          planData['checkoutTime'],
          planData['notes'],
          planData['latitude'],
          planData['longitude'],
          planData['checkoutLatitude'],
          planData['checkoutLongitude'],
          operation.entityId,
        ],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('❌ Error updating journey plan: $e');
      return false;
    }
  }

  /// Execute delete journey plan operation
  Future<bool> _executeDeleteJourneyPlan(SyncOperation operation) async {
    try {
      // Execute database operation
      final result = await _db.query(
        'DELETE FROM JourneyPlans WHERE id = ?',
        [operation.entityId],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('❌ Error deleting journey plan: $e');
      return false;
    }
  }

  /// Remove operation from storage
  Future<void> _removeOperation(String operationKey) async {
    try {
      final operationBox = await _hiveService.getOperationBox();
      await operationBox.delete(operationKey);
    } catch (e) {
      print('❌ Error removing operation: $e');
    }
  }

  /// Start network monitoring
  void _startNetworkMonitoring() {
    _networkCheckTimer = Timer.periodic(_networkCheckInterval, (timer) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkNetworkConnectivity();

      if (!wasOnline && _isOnline) {
        print('🌐 Network restored - processing pending operations');
        _processPendingOperations();
      } else if (wasOnline && !_isOnline) {
        print('📡 Network lost - operations will be queued');
      }
    });
  }

  /// Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Simple database connectivity test
      await _db.query('SELECT 1').timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'pending_operations': _pendingOperations.length,
      'is_online': _isOnline,
      'is_processing': _isProcessing,
      'retry_counts': Map.from(_retryCounts),
      'last_retry_times': _lastRetryTimes
          .map((key, value) => MapEntry(key, value.toIso8601String())),
    };
  }

  /// Force retry all pending operations
  Future<void> forceRetryAll() async {
    print('🔄 Force retrying all pending operations...');
    _retryCounts.clear();
    _lastRetryTimes.clear();
    _processPendingOperations();
  }

  /// Clear all pending operations
  Future<void> clearAllPending() async {
    print('🧹 Clearing all pending operations...');
    _pendingOperations.clear();
    _retryCounts.clear();
    _lastRetryTimes.clear();

    try {
      final operationBox = await _hiveService.getOperationBox();
      await operationBox.clear();
    } catch (e) {
      print('❌ Error clearing operations: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    _networkCheckTimer?.cancel();
  }

  // Add stubs for _markOperationAsFailed and _markOperationAsCompleted
  Future<void> _markOperationAsFailed(String operationId, String error) async {
    print('❌ Marking operation $operationId as failed: $error');
    // TODO: Update operation status in Hive
  }

  Future<void> _markOperationAsCompleted(String operationId) async {
    print('✅ Marking operation $operationId as completed');
    // TODO: Remove operation from Hive
  }
}

/// Represents a sync operation to be retried
class SyncOperation {
  final String type;
  final int entityId;
  final Map<String, dynamic> data;

  SyncOperation({
    required this.type,
    required this.entityId,
    required this.data,
  });
}
