import 'dart:async';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/database_service.dart';

/// Journey plan service using direct database connections
class JourneyPlanService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get journey plans with pagination and filtering
  static Future<List<JourneyPlan>> getJourneyPlans({
    int page = 1,
    int limit = 20,
    int? status,
    DateTime? date,
    int? userId,
    int? routeId,
    bool excludePast = false,
  }) async {
    try {
      String sql = '''
        SELECT 
          jp.id,
          jp.date,
          jp.time,
          jp.userId as salesRepId,
          jp.clientId,
          jp.status,
          jp.checkInTime,
          jp.latitude,
          jp.longitude,
          jp.imageUrl,
          jp.notes,
          jp.checkoutLatitude,
          jp.checkoutLongitude,
          jp.checkoutTime,
          jp.showUpdateLocation,
          jp.routeId,
          c.id as client_id,
          c.name as client_name,
          c.address as client_address,
          c.contact as client_contact,
          c.email as client_email,
          c.latitude as client_latitude,
          c.longitude as client_longitude,
          c.balance as client_balance,
          c.region_id as client_region_id,
          c.region as client_region,
          c.route_id as client_route_id,
          c.route_name as client_route_name,
          c.status as client_status,
          c.client_type as client_client_type,
          c.outlet_account as client_outlet_account,
          c.countryId as client_countryId,
          c.added_by as client_added_by,
          c.created_at as client_created_at
        FROM JourneyPlan jp
        LEFT JOIN Clients c ON jp.clientId = c.id
        WHERE 1=1
      ''';

      List<dynamic> params = [];

      // Filter by user if provided, otherwise use current user
      final filterUserId = userId ?? _db.getCurrentUserId();
      sql += ' AND jp.userId = ?';
      params.add(filterUserId);

      // Add status filter
      if (status != null) {
        sql += ' AND jp.status = ?';
        params.add(status);
      }

      // Add date filter
      if (date != null) {
        sql += ' AND DATE(jp.date) = DATE(?)';
        params.add(date.toIso8601String());
      }

      // Add route filter
      if (routeId != null) {
        sql += ' AND jp.routeId = ?';
        params.add(routeId);
      }

      // Exclude past journey plans if requested
      if (excludePast) {
        sql += ' AND jp.date >= CURDATE()';
      }

      sql += ' ORDER BY jp.date DESC, jp.time ASC LIMIT ? OFFSET ?';
      params.add(limit);
      params.add((page - 1) * limit);

      final results = await _db.query(sql, params);

      return results.map((row) => _mapToJourneyPlan(row.fields)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get multiple journey plans by IDs in a single query (batch optimization)
  static Future<List<JourneyPlan>> getJourneyPlansByIds(
      List<int> journeyPlanIds) async {
    if (journeyPlanIds.isEmpty) return [];

    try {
      final placeholders = journeyPlanIds.map((_) => '?').join(',');
      final sql = '''
        SELECT 
          jp.id,
          jp.date,
          jp.time,
          jp.userId as salesRepId,
          jp.clientId,
          jp.status,
          jp.checkInTime,
          jp.latitude,
          jp.longitude,
          jp.imageUrl,
          jp.notes,
          jp.checkoutLatitude,
          jp.checkoutLongitude,
          jp.checkoutTime,
          jp.showUpdateLocation,
          jp.routeId,
          c.id as client_id,
          c.name as client_name,
          c.address as client_address,
          c.contact as client_contact,
          c.email as client_email,
          c.latitude as client_latitude,
          c.longitude as client_longitude,
          c.balance as client_balance,
          c.region_id as client_region_id,
          c.region as client_region,
          c.route_id as client_route_id,
          c.route_name as client_route_name,
          c.status as client_status,
          c.client_type as client_client_type,
          c.outlet_account as client_outlet_account,
          c.countryId as client_countryId,
          c.added_by as client_added_by,
          c.created_at as client_created_at
        FROM JourneyPlan jp
        LEFT JOIN Clients c ON jp.clientId = c.id
        WHERE jp.id IN ($placeholders)
        ORDER BY jp.id
      ''';

      final results = await _db.query(sql, journeyPlanIds);
      return results.map((row) => _mapToJourneyPlan(row.fields)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific journey plan by ID
  static Future<JourneyPlan?> getJourneyPlanById(int journeyPlanId) async {
    try {
      // Use the batch method for consistency
      final results = await getJourneyPlansByIds([journeyPlanId]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get minimal journey plan data for completion status (lightweight fetch)
  static Future<JourneyPlan?> getJourneyPlanCompletionStatus(
      int journeyPlanId) async {
    try {
      const sql = '''
        SELECT 
          jp.id,
          jp.status,
          c.id as client_id
        FROM JourneyPlan jp
        LEFT JOIN Clients c ON jp.clientId = c.id
        WHERE jp.id = ?
      ''';

      final results = await _db.query(sql, [journeyPlanId]);

      if (results.isEmpty) return null;

      final row = results.first.fields;

      // Create minimal client object with only ID
      final client = Client(
        id: row['client_id'] ?? 0,
        name: '', // Empty for minimal fetch
        address: '',
        contact: '',
        email: null,
        latitude: null,
        longitude: null,
        balance: null,
        taxPin: '',
        location: '',
        clientType: null,
        regionId: 0,
        region: '',
        countryId: 0,
      );

      // Create minimal journey plan object with only essential fields
      return JourneyPlan(
        id: row['id'],
        date: DateTime.now(), // Placeholder
        time: '', // Placeholder
        salesRepId: null,
        status: row['status'] ?? 0,
        notes: null,
        checkInTime: null,
        latitude: null,
        longitude: null,
        imageUrl: null,
        client: client,
        checkoutTime: null, // Not needed for basic status
        checkoutLatitude: null,
        checkoutLongitude: null,
        showUpdateLocation: false,
        routeId: null,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get ultra-minimal journey plan data (ID, status, client ID only)
  static Future<Map<String, dynamic>?> getJourneyPlanBasicStatus(
      int journeyPlanId) async {
    try {
      const sql = '''
        SELECT 
          jp.id,
          jp.status,
          jp.clientId
        FROM JourneyPlan jp
        WHERE jp.id = ?
      ''';

      final results = await _db.query(sql, [journeyPlanId]);

      if (results.isEmpty) return null;

      final row = results.first.fields;

      return {
        'id': row['id'],
        'status': row['status'] ?? 0,
        'clientId': row['clientId'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new journey plan
  static Future<JourneyPlan> createJourneyPlan({
    required int clientId,
    required DateTime date,
    required String time,
    String? notes,
    int? routeId,
    int? userId,
  }) async {
    try {
      final filterUserId = userId ?? _db.getCurrentUserId();

      const sql = '''
        INSERT INTO JourneyPlan (
          date, time, userId, clientId, status, notes, routeId, showUpdateLocation
        ) VALUES (?, ?, ?, ?, 0, ?, ?, 1)
      ''';

      final params = [
        date.toIso8601String(),
        time,
        filterUserId,
        clientId,
        notes,
        routeId,
      ];

      final result = await _db.query(sql, params);
      final journeyPlanId = result.insertId;

      if (journeyPlanId == null) {
        throw Exception('Failed to create journey plan');
      }

      // Fetch the created journey plan
      final createdPlan = await getJourneyPlanById(journeyPlanId);
      if (createdPlan == null) {
        throw Exception('Failed to fetch created journey plan');
      }
      return createdPlan;
    } catch (e) {
      rethrow;
    }
  }

  /// Update journey plan
  static Future<JourneyPlan> updateJourneyPlan({
    required int journeyId,
    required int clientId,
    int? status,
    DateTime? checkInTime,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? notes,
    DateTime? checkoutTime,
    double? checkoutLatitude,
    double? checkoutLongitude,
  }) async {
    try {
      // Build dynamic update query
      final updates = <String>[];
      final params = <dynamic>[];

      if (status != null) {
        updates.add('status = ?');
        params.add(status);
      }

      if (checkInTime != null) {
        updates.add('checkInTime = ?');
        params.add(checkInTime.toIso8601String());
      }

      if (latitude != null) {
        updates.add('latitude = ?');
        params.add(latitude);
      }

      if (longitude != null) {
        updates.add('longitude = ?');
        params.add(longitude);
      }

      if (imageUrl != null) {
        updates.add('imageUrl = ?');
        params.add(imageUrl);
      }

      if (notes != null) {
        updates.add('notes = ?');
        params.add(notes);
      }

      if (checkoutTime != null) {
        updates.add('checkoutTime = ?');
        params.add(checkoutTime.toIso8601String());
      }

      if (checkoutLatitude != null) {
        updates.add('checkoutLatitude = ?');
        params.add(checkoutLatitude);
      }

      if (checkoutLongitude != null) {
        updates.add('checkoutLongitude = ?');
        params.add(checkoutLongitude);
      }

      if (updates.isEmpty) {
        throw Exception('No fields to update');
      }

      // Simplified WHERE clause - just id = ?
      final sql = 'UPDATE JourneyPlan SET ${updates.join(', ')} WHERE id = ?';
      params.add(journeyId);

      // Retry mechanism with exponential backoff and shorter timeouts
      Exception? lastException;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          // Use a shorter timeout for each attempt
          await _db.query(sql, params).timeout(
            Duration(seconds: 10), // Reduced from 20s to 10s
            onTimeout: () {
              throw TimeoutException('Query timeout after 10 seconds');
            },
          );
          break; // Success - exit retry loop
        } catch (e) {
          lastException = e as Exception;

          if (attempt < 3) {
            // Exponential backoff: 1s, 2s, 4s
            final delay = Duration(seconds: 1 << (attempt - 1));
            await Future.delayed(delay);
          }
        }
      }

      // If all attempts failed, throw the last exception
      if (lastException != null) {
        throw lastException;
      }

      // Fetch the updated journey plan (keeping as requested)
      final updatedPlan = await getJourneyPlanById(journeyId);
      if (updatedPlan == null) {
        throw Exception('Failed to fetch updated journey plan');
      }
      return updatedPlan;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete journey plan (only pending ones)
  static Future<void> deleteJourneyPlan(int journeyId) async {
    try {
      const sql = 'DELETE FROM JourneyPlan WHERE id = ? AND status = 0';
      await _db.query(sql, [journeyId]);
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to map database row to JourneyPlan
  static JourneyPlan _mapToJourneyPlan(Map<String, dynamic> row) {
    // Create client object
    final client = Client(
      id: row['client_id'] ?? row['clientId'],
      name: row['client_name'] ?? '',
      address: row['client_address'] ?? '',
      contact: row['client_contact'] ?? '',
      email: row['client_email'],
      latitude: row['client_latitude']?.toDouble(),
      longitude: row['client_longitude']?.toDouble(),
      balance: row['client_balance']?.toString(),
      taxPin: row['client_tax_pin'] ?? '',
      location: row['client_location'] ?? '',
      clientType: row['client_client_type'],
      regionId: row['client_region_id'] ?? 0,
      region: row['client_region'] ?? '',
      countryId: row['client_countryId'] ?? 0,
    );

    // Create journey plan object
    return JourneyPlan(
      id: row['id'],
      date: row['date'] is String
          ? DateTime.parse(row['date'])
          : row['date'] as DateTime,
      time: row['time'] ?? '',
      salesRepId: row['salesRepId'],
      status: row['status'] ?? 0,
      notes: row['notes'],
      checkInTime: row['checkInTime'] != null
          ? (row['checkInTime'] is String
              ? DateTime.parse(row['checkInTime'])
              : row['checkInTime'] as DateTime)
          : null,
      latitude: row['latitude']?.toDouble(),
      longitude: row['longitude']?.toDouble(),
      imageUrl: row['imageUrl'],
      client: client,
      checkoutTime: row['checkoutTime'] != null
          ? (row['checkoutTime'] is String
              ? DateTime.parse(row['checkoutTime'])
              : row['checkoutTime'] as DateTime)
          : null,
      checkoutLatitude: row['checkoutLatitude']?.toDouble(),
      checkoutLongitude: row['checkoutLongitude']?.toDouble(),
      showUpdateLocation: row['showUpdateLocation'] == 1,
      routeId: row['routeId'],
    );
  }
}