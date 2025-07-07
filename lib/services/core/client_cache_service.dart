import 'package:woosh/models/client_model.dart';
import 'package:woosh/services/core/client_service.dart';
import 'package:woosh/services/database/auth_service.dart';

/// Global client cache service to reduce redundant database calls
/// Provides cached client data with automatic refresh when stale
/// Now supports per-country caching for security
class ClientCacheService {
  static ClientCacheService? _instance;
  static ClientCacheService get instance =>
      _instance ??= ClientCacheService._();

  ClientCacheService._();

  // Per-country cache storage
  final Map<int, List<Client>> _cachedClientsByCountry = {};
  final Map<int, DateTime> _lastCacheTimeByCountry = {};
  final Map<int, bool> _isLoadingByCountry = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Get current user's countryId for security filtering
  Future<int> _getCurrentUserCountryId() async {
    final currentUser =
        await DatabaseAuthService.instance.getCurrentUserDetails();
    final userCountryId = currentUser['countryId'];

    if (userCountryId == null) {
      throw Exception('User countryId not found - access denied');
    }

    return userCountryId;
  }

  /// Get clients with caching - returns cached data if fresh, otherwise fetches new data
  Future<List<Client>> getClients({
    int page = 1,
    int limit = 100,
    bool forceRefresh = false,
    int?
        countryId, // This parameter is ignored for security - user's country is always used
  }) async {
    final userCountryId = await _getCurrentUserCountryId();

    // Return cached data if fresh and not forcing refresh
    if (!forceRefresh && _isCacheValid(userCountryId)) {
      final cachedClients = _cachedClientsByCountry[userCountryId] ?? [];
      print(
          '📦 Returning ${cachedClients.length} clients from cache for country $userCountryId');
      return cachedClients;
    }

    // If already loading for this country, wait for current request to complete
    if (_isLoadingByCountry[userCountryId] == true) {
      print(
          '⏳ Client cache request already in progress for country $userCountryId, waiting...');
      while (_isLoadingByCountry[userCountryId] == true) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedClientsByCountry[userCountryId] ?? [];
    }

    // Fetch fresh data with country filter
    return await _fetchAndCacheClients(
        page: page, limit: limit, countryId: userCountryId);
  }

  /// Check if cached data is still valid
  bool _isCacheValid(int countryId) {
    if (_cachedClientsByCountry[countryId] == null ||
        _lastCacheTimeByCountry[countryId] == null) {
      return false;
    }

    final age = DateTime.now().difference(_lastCacheTimeByCountry[countryId]!);
    final isValid = age < _cacheValidityDuration;

    if (isValid) {
      print(
          '✅ Client cache is valid (age: ${age.inMinutes}m ${age.inSeconds % 60}s) for country $countryId');
    } else {
      print(
          '⏰ Client cache is stale (age: ${age.inMinutes}m ${age.inSeconds % 60}s) for country $countryId');
    }

    return isValid;
  }

  /// Fetch clients from database and update cache
  Future<List<Client>> _fetchAndCacheClients({
    int page = 1,
    int limit = 100,
    int? countryId,
  }) async {
    final userCountryId = await _getCurrentUserCountryId();
    _isLoadingByCountry[userCountryId] = true;

    try {
      print(
          '🔄 Fetching fresh client data (page: $page, limit: $limit, country: $countryId)...');

      final clients = await ClientService.instance.getClients(
        page: page,
        limit: limit,
        countryId: countryId, // Pass country filter to service
      );

      // Filter out any clients with null or 0 countryId (additional safety)
      final filteredClients = clients
          .where((client) => client.countryId != null && client.countryId! > 0)
          .toList();

      // Update cache with filtered clients
      _cachedClientsByCountry[userCountryId] = filteredClients;
      _lastCacheTimeByCountry[userCountryId] = DateTime.now();

      print(
          '✅ Cached ${filteredClients.length} clients for country $countryId (valid for ${_cacheValidityDuration.inMinutes} minutes)');

      return filteredClients;
    } catch (e) {

      // Return cached data if available, even if stale
      if (_cachedClientsByCountry[userCountryId] != null) {
        print(
            '📦 Returning stale cached data as fallback for country $userCountryId');
        return _cachedClientsByCountry[userCountryId]!;
      }

      rethrow;
    } finally {
      _isLoadingByCountry[userCountryId] = false;
    }
  }

  /// Force refresh the cache
  Future<List<Client>> refreshCache({
    int page = 1,
    int limit = 100,
  }) async {
    final userCountryId = await _getCurrentUserCountryId();
    return await _fetchAndCacheClients(
        page: page, limit: limit, countryId: userCountryId);
  }

  /// Clear the cache
  void clearCache() {
    _cachedClientsByCountry.clear();
    _lastCacheTimeByCountry.clear();
    _isLoadingByCountry.clear();
  }

  /// Get cache status  
  Future<Map<String, dynamic>> getCacheStatus() async {
    final userCountryId = await _getCurrentUserCountryId();
    return {
      'hasCachedData': _cachedClientsByCountry[userCountryId] != null,
      'cachedCount': _cachedClientsByCountry[userCountryId]?.length ?? 0,
      'lastCacheTime':
          _lastCacheTimeByCountry[userCountryId]?.toIso8601String(),
      'isValid': _isCacheValid(userCountryId),
      'isLoading': _isLoadingByCountry[userCountryId] ?? false,
    };
  }

  /// Get cached clients without fetching (returns null if no cache)
  Future<List<Client>?> getCachedClients() async {
    final userCountryId = await _getCurrentUserCountryId();
    return _cachedClientsByCountry[userCountryId];
  }

  /// Check if cache is currently loading
  Future<bool> get isLoading async {
    final userCountryId = await _getCurrentUserCountryId();
    return _isLoadingByCountry[userCountryId] ?? false;
  }
}