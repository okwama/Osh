import 'package:woosh/services/database_service.dart';

/// Lightweight route option for dropdowns (only id and name)
class RouteOption {
  final int id;
  final String name;

  RouteOption({
    required this.id,
    required this.name,
  });

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    return RouteOption(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  factory RouteOption.fromRoute(Route route) {
    return RouteOption(
      id: route.id,
      name: route.name,
    );
  }
}

/// Route model
class Route {
  final int id;
  final String name;
  final int region;
  final String regionName;
  final int countryId;
  final String countryName;
  final int leaderId;
  final String leaderName;
  final int status;

  Route({
    required this.id,
    required this.name,
    required this.region,
    required this.regionName,
    required this.countryId,
    required this.countryName,
    required this.leaderId,
    required this.leaderName,
    required this.status,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'],
      name: json['name'] ?? '',
      region: json['region'] ?? 0,
      regionName: json['region_name'] ?? '',
      countryId: json['country_id'] ?? 0,
      countryName: json['country_name'] ?? '',
      leaderId: json['leader_id'] ?? 0,
      leaderName: json['leader_name'] ?? '',
      status: json['status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'region_name': regionName,
      'country_id': countryId,
      'country_name': countryName,
      'leader_id': leaderId,
      'leader_name': leaderName,
      'status': status,
    };
  }
}

/// Service for managing routes using direct database connections
class RouteService {
  static final DatabaseService _db = DatabaseService.instance;

  // Cache for route options (lightweight id + name only)
  static final Map<int, List<RouteOption>> _routeOptionsCache = {};
  static final Map<int, DateTime> _cacheTimestamp = {};
  static const Duration _cacheValidityDuration =
      Duration(hours: 2); // Routes don't change often

  /// Get routes filtered by country ID
  static Future<List<Route>> getRoutes({int? countryId}) async {
    try {
      String sql = '''
        SELECT 
          id,
          name,
          region,
          region_name,
          country_id,
          country_name,
          leader_id,
          leader_name,
          status
        FROM routes
      ''';

      List<dynamic> params = [];

      // Filter by country if provided (include country_id = 0 for global routes)
      if (countryId != null) {
        sql += ' WHERE country_id = ? OR country_id = 0';
        params.add(countryId);
      }

      sql += ' ORDER BY name ASC';

      final results = await _db.query(sql, params);

      return results.map((row) => Route.fromJson(row.fields)).toList();
    } catch (e) {
      print('❌ Error fetching routes: $e');
      rethrow;
    }
  }

  /// Get routes for current user's country
  static Future<List<Route>> getRoutesForCurrentUser() async {
    try {
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      print('📍 Current user country ID: $countryId');

      final routes = await getRoutes(countryId: countryId);

      print('📍 Found ${routes.length} routes for country ID: $countryId');

      return routes;
    } catch (e) {
      print('❌ Error fetching routes for current user: $e');
      // Return empty list if there's an error
      return [];
    }
  }

  /// Get route by ID
  static Future<Route?> getRouteById(int routeId) async {
    try {
      const sql = '''
        SELECT 
          id,
          name,
          region,
          region_name,
          country_id,
          country_name,
          leader_id,
          leader_name,
          status
        FROM routes
        WHERE id = ?
      ''';

      final results = await _db.query(sql, [routeId]);

      if (results.isNotEmpty) {
        return Route.fromJson(results.first.fields);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching route by ID: $e');
      rethrow;
    }
  }

  /// Get routes by region
  static Future<List<Route>> getRoutesByRegion(int regionId) async {
    try {
      const sql = '''
        SELECT 
          id,
          name,
          region,
          region_name,
          country_id,
          country_name,
          leader_id,
          leader_name,
          status
        FROM routes
        WHERE region = ?
        ORDER BY name ASC
      ''';

      final results = await _db.query(sql, [regionId]);

      return results.map((row) => Route.fromJson(row.fields)).toList();
    } catch (e) {
      print('❌ Error fetching routes by region: $e');
      rethrow;
    }
  }

  /// Get routes for current user's region
  static Future<List<Route>> getRoutesForCurrentUserRegion() async {
    try {
      final currentUser = await _db.getCurrentUserDetails();
      final regionId = currentUser['region_id'];

      print('📍 Current user region ID: $regionId');

      final routes = await getRoutesByRegion(regionId);

      print('📍 Found ${routes.length} routes for region ID: $regionId');

      return routes;
    } catch (e) {
      print('❌ Error fetching routes for current user region: $e');
      // Return empty list if there's an error
      return [];
    }
  }

  /// Get cached route options (lightweight id + name only) for current user's country
  static Future<List<RouteOption>> getCachedRouteOptionsForCurrentUser() async {
    try {
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      if (countryId == null) {
        print('❌ User countryId is null');
        return [];
      }

      // Check if we have valid cached data
      if (_isCacheValid(countryId)) {
        final cachedOptions = _routeOptionsCache[countryId] ?? [];
        print(
            '📦 Returning ${cachedOptions.length} cached route options for country $countryId');
        return cachedOptions;
      }

      // Fetch fresh data with minimal columns for efficiency
      print(
          '🔄 Fetching fresh route options for country $countryId (including global routes)');

      const sql = '''
        SELECT id, name
        FROM routes
        WHERE country_id = ? OR country_id = 0
        ORDER BY name ASC
      ''';

      final results = await _db.query(sql, [countryId]);

      final routeOptions =
          results.map((row) => RouteOption.fromJson(row.fields)).toList();

      // Cache the results
      _routeOptionsCache[countryId] = routeOptions;
      _cacheTimestamp[countryId] = DateTime.now();

      print(
          '✅ Cached ${routeOptions.length} route options for country $countryId (including global routes)');
      return routeOptions;
    } catch (e) {
      print('❌ Error fetching cached route options: $e');
      return [];
    }
  }

  /// Check if cached data is still valid
  static bool _isCacheValid(int countryId) {
    if (!_routeOptionsCache.containsKey(countryId) ||
        !_cacheTimestamp.containsKey(countryId)) {
      return false;
    }

    final cacheAge = DateTime.now().difference(_cacheTimestamp[countryId]!);
    final isValid = cacheAge < _cacheValidityDuration;

    if (isValid) {
      print(
          '✅ Route cache is valid (age: ${cacheAge.inMinutes}m) for country $countryId');
    } else {
      print(
          '⏰ Route cache is stale (age: ${cacheAge.inMinutes}m) for country $countryId');
    }

    return isValid;
  }

  /// Clear route cache (call this when routes are modified)
  static void clearCache() {
    _routeOptionsCache.clear();
    _cacheTimestamp.clear();
    print('🗑️ Route cache cleared');
  }

  /// Clear cache immediately to apply new filtering logic
  static void clearCacheForFilterUpdate() {
    clearCache();
    print(
        '🔄 Route cache cleared for filter update - next fetch will include global routes');
  }

  /// Clear cache for specific country
  static void clearCacheForCountry(int countryId) {
    _routeOptionsCache.remove(countryId);
    _cacheTimestamp.remove(countryId);
    print('🗑️ Route cache cleared for country $countryId');
  }

  /// Get cache status for debugging
  static Map<String, dynamic> getCacheStatus() {
    return {
      'cachedCountries': _routeOptionsCache.keys.toList(),
      'cacheCount': _routeOptionsCache.length,
      'timestamps': _cacheTimestamp
          .map((k, v) => MapEntry(k.toString(), v.toIso8601String())),
    };
  }
}
