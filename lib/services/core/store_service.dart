import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/Products_Inventory/store_model.dart';

/// Service for managing stores using direct database connections
class StoreService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get stores for a specific country
  static Future<List<Store>> getStoresByCountry(int countryId) async {
    try {

      const sql = '''
        SELECT 
          s.id,
          s.name,
          s.regionId,
          s.client_type,
          s.countryId,
          s.region_id,
          s.status,
          r.id as region_id,
          r.name as region_name,
          c.id as country_id,
          c.name as country_name
        FROM Stores s
        LEFT JOIN Regions r ON s.regionId = r.id
        LEFT JOIN Country c ON r.countryId = c.id
        WHERE s.countryId = ?
        AND s.status = 0
        ORDER BY s.name ASC
      ''';

      final results = await _db.query(sql, [countryId]);

      return results.map((row) {
        final data = row.fields;
        return Store(
          id: data['id'],
          name: data['name'],
          countryId: data['countryId'],
          regionId: data['regionId'],
          status: data['status'],
          region: data['region_id'] != null
              ? Region(
                  id: data['region_id'],
                  name: data['region_name'],
                  country: data['country_id'] != null
                      ? Country(
                          id: data['country_id'],
                          name: data['country_name'],
                        )
                      : null,
                )
              : null,
        );
      }).toList();
    } catch (e) {
      print('❌ [StoreService] Error fetching stores: $e');
      return [];
    }
  }

  /// Get store by ID
  static Future<Store?> getStoreById(int storeId) async {
    try {

      const sql = '''
        SELECT 
          s.id,
          s.name,
          s.regionId,
          s.client_type,
          s.countryId,
          s.region_id,
          s.status,
          r.id as region_id,
          r.name as region_name,
          c.id as country_id,
          c.name as country_name
        FROM Stores s
        LEFT JOIN Regions r ON s.regionId = r.id
        LEFT JOIN Country c ON r.countryId = c.id
        WHERE s.id = ?
      ''';

      final results = await _db.query(sql, [storeId]);

      if (results.isEmpty) return null;

      final data = results.first.fields;
      return Store(
        id: data['id'],
        name: data['name'],
        countryId: data['countryId'],
        regionId: data['regionId'],
        status: data['status'],
        region: data['region_id'] != null
            ? Region(
                id: data['region_id'],
                name: data['region_name'],
                country: data['country_id'] != null
                    ? Country(
                        id: data['country_id'],
                        name: data['country_name'],
                      )
                    : null,
              )
            : null,
      );
    } catch (e) {
      print('❌ [StoreService] Error fetching store by ID: $e');
      return null;
    }
  }

  /// Get stores for user's country and region
  static Future<List<Store>> getStoresForUser(
      int countryId, int? regionId) async {
    try {

      String sql = '''
        SELECT 
          s.id,
          s.name,
          s.regionId,
          s.client_type,
          s.countryId,
          s.region_id,
          s.status,
          r.id as region_id,
          r.name as region_name,
          c.id as country_id,
          c.name as country_name
        FROM Stores s
        LEFT JOIN Regions r ON s.regionId = r.id
        LEFT JOIN Country c ON r.countryId = c.id
        WHERE s.countryId = ?
        AND s.status = 0
      ''';

      List<dynamic> params = [countryId];

      if (regionId != null) {
        sql += ' AND s.regionId = ?';
        params.add(regionId);
      }

      sql += ' ORDER BY s.name ASC';

      print('📋 [StoreService] Executing query: $sql');
      print('📋 [StoreService] Values: $params');

      final results = await _db.query(sql, params);

      print('✅ [StoreService] Found ${results.length} stores');

      return results.map((row) {
        final data = row.fields;
        return Store(
          id: data['id'],
          name: data['name'],
          countryId: data['countryId'],
          regionId: data['regionId'],
          status: data['status'],
          region: data['region_id'] != null
              ? Region(
                  id: data['region_id'],
                  name: data['region_name'],
                  country: data['country_id'] != null
                      ? Country(
                          id: data['country_id'],
                          name: data['country_name'],
                        )
                      : null,
                )
              : null,
        );
      }).toList();
    } catch (e) {
      print('❌ [StoreService] Error fetching stores for user: $e');
      return [];
    }
  }
}
