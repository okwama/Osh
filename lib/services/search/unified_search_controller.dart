import 'dart:async';
import 'package:get/get.dart';
import 'package:woosh/services/search/unified_search_service.dart';
import 'package:woosh/models/client/client_model.dart';

/// Unified search controller using GetX for reactive state management
/// Consolidates all search functionality into a single controller
class UnifiedSearchController extends GetxController {
  // Search service
  final UnifiedSearchService _searchService = UnifiedSearchService.instance;

  // Search state observables
  final RxString currentQuery = ''.obs;
  final RxList<Client> searchResults = <Client>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool hasMoreResults = false.obs;
  final RxInt currentPage = 1.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoadingSuggestions = false.obs;
  final RxList<String> suggestions = <String>[].obs;

  // Search configuration
  final RxInt pageSize = 100.obs;
  final RxString orderBy = 'name'.obs;
  final RxString orderDirection = 'ASC'.obs;
  final RxBool useCache = true.obs;
  final RxBool forceRefresh = false.obs;

  // Performance metrics
  final RxInt lastQueryDuration = 0.obs;
  final RxInt totalResults = 0.obs;
  final RxDouble cacheHitRate = 0.0.obs;

  // Debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  // Search history
  final RxList<String> searchHistory = <String>[].obs;
  static const int _maxSearchHistory = 10;

  @override
  void onInit() {
    super.onInit();
    _loadSearchStats();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// Update search query with debouncing
  void updateSearchQuery(String query) {
    currentQuery.value = query;
    errorMessage.value = '';

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Clear results if query is empty
    if (query.trim().isEmpty) {
      clearSearchResults();
      return;
    }

    // Start new debounce timer
    _debounceTimer = Timer(_debounceDelay, () {
      _performSearch();
    });
  }

  /// Perform search with current query
  Future<void> _performSearch() async {
    if (currentQuery.value.trim().isEmpty) {
      clearSearchResults();
      return;
    }

    isSearching.value = true;
    currentPage.value = 1;

    try {
      final result = await _searchService.searchClients(
        query: currentQuery.value,
        page: currentPage.value,
        limit: pageSize.value,
        orderBy: orderBy.value,
        orderDirection: orderDirection.value,
        useCache: useCache.value,
        forceRefresh: forceRefresh.value,
      );

      searchResults.value = result.items;
      hasMoreResults.value = result.hasMore;
      totalResults.value = result.totalCount ?? 0;
      lastQueryDuration.value = result.queryDuration.inMilliseconds;
      errorMessage.value = '';

      // Add to search history
      _addToSearchHistory(currentQuery.value);

      print(
          '✅ Search completed: "${currentQuery.value}" -> ${result.items.length} results');
    } catch (e) {
      errorMessage.value = 'Search failed: ${e.toString()}';
      searchResults.clear();
      hasMoreResults.value = false;
      totalResults.value = 0;
      print('❌ Search error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Load more search results
  Future<void> loadMoreResults() async {
    if (isSearching.value ||
        !hasMoreResults.value ||
        currentQuery.value.trim().isEmpty) {
      return;
    }

    isSearching.value = true;

    try {
      final result = await _searchService.searchClients(
        query: currentQuery.value,
        page: currentPage.value + 1,
        limit: pageSize.value,
        orderBy: orderBy.value,
        orderDirection: orderDirection.value,
        useCache: useCache.value,
        forceRefresh: forceRefresh.value,
      );

      searchResults.addAll(result.items);
      hasMoreResults.value = result.hasMore;
      currentPage.value++;
      lastQueryDuration.value = result.queryDuration.inMilliseconds;

      print('📄 Loaded ${result.items.length} more results');
    } catch (e) {
      errorMessage.value = 'Failed to load more results: ${e.toString()}';
      print('❌ Load more error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Search by specific field
  Future<void> searchByField({
    required String field,
    required String value,
  }) async {
    isSearching.value = true;
    currentPage.value = 1;

    try {
      final result = await _searchService.searchClientsByField(
        field: field,
        value: value,
        page: currentPage.value,
        limit: pageSize.value,
        orderBy: orderBy.value,
        orderDirection: orderDirection.value,
      );

      searchResults.value = result.items;
      hasMoreResults.value = result.hasMore;
      totalResults.value = result.totalCount ?? 0;
      lastQueryDuration.value = result.queryDuration.inMilliseconds;
      errorMessage.value = '';

      print(
          '✅ Field search completed: $field="$value" -> ${result.items.length} results');
    } catch (e) {
      errorMessage.value = 'Field search failed: ${e.toString()}';
      searchResults.clear();
      hasMoreResults.value = false;
      totalResults.value = 0;
      print('❌ Field search error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Search clients near location
  Future<void> searchNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    isSearching.value = true;
    currentPage.value = 1;

    try {
      final result = await _searchService.searchClientsNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        page: currentPage.value,
        limit: pageSize.value,
      );

      searchResults.value = result.items;
      hasMoreResults.value = result.hasMore;
      totalResults.value = result.totalCount ?? 0;
      lastQueryDuration.value = result.queryDuration.inMilliseconds;
      errorMessage.value = '';

      print(
          '📍 Location search completed: ${result.items.length} results found');
    } catch (e) {
      errorMessage.value = 'Location search failed: ${e.toString()}';
      searchResults.clear();
      hasMoreResults.value = false;
      totalResults.value = 0;
      print('❌ Location search error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Load search suggestions
  Future<void> loadSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) {
      suggestions.clear();
      return;
    }

    isLoadingSuggestions.value = true;

    try {
      final newSuggestions = await _searchService.getSearchSuggestions(
        partialQuery: partialQuery,
        limit: 10,
      );

      suggestions.value = newSuggestions;
      print(
          '💡 Loaded ${newSuggestions.length} suggestions for "$partialQuery"');
    } catch (e) {
      suggestions.clear();
      print('❌ Suggestions error: $e');
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  /// Clear search results
  void clearSearchResults() {
    searchResults.clear();
    hasMoreResults.value = false;
    totalResults.value = 0;
    lastQueryDuration.value = 0;
    errorMessage.value = '';
    currentPage.value = 1;
  }

  /// Clear search query and results
  void clearSearch() {
    currentQuery.value = '';
    clearSearchResults();
    suggestions.clear();
  }

  /// Retry failed search
  Future<void> retrySearch() async {
    if (currentQuery.value.isNotEmpty) {
      await _performSearch();
    }
  }

  /// Refresh current search
  Future<void> refreshSearch() async {
    forceRefresh.value = true;
    await _performSearch();
    forceRefresh.value = false;
  }

  /// Update search configuration
  void updateSearchConfig({
    int? newPageSize,
    String? newOrderBy,
    String? newOrderDirection,
    bool? newUseCache,
  }) {
    if (newPageSize != null) pageSize.value = newPageSize;
    if (newOrderBy != null) orderBy.value = newOrderBy;
    if (newOrderDirection != null) orderDirection.value = newOrderDirection;
    if (newUseCache != null) useCache.value = newUseCache;
  }

  /// Get search statistics
  Future<Map<String, dynamic>> getSearchStats() async {
    try {
      final stats = await _searchService.getSearchStats(
        query: currentQuery.value,
      );

      cacheHitRate.value = stats['cacheHitRate'] ?? 0.0;

      return stats;
    } catch (e) {
      return {
        'error': e.toString(),
        'cacheHitRate': cacheHitRate.value,
      };
    }
  }

  /// Clear search cache
  Future<void> clearSearchCache() async {
    await _searchService.clearSearchCache();
    print('🧹 Search cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _searchService.getCacheStats();
  }

  /// Load search statistics
  Future<void> _loadSearchStats() async {
    try {
      final stats = await _searchService.getSearchStats(query: '');
      cacheHitRate.value = stats['cacheHitRate'] ?? 0.0;
    } catch (e) {
      print('❌ Error loading search stats: $e');
    }
  }

  /// Add query to search history
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    // Remove if already exists
    searchHistory.remove(query);

    // Add to beginning
    searchHistory.insert(0, query);

    // Keep only recent searches
    if (searchHistory.length > _maxSearchHistory) {
      searchHistory.removeRange(_maxSearchHistory, searchHistory.length);
    }
  }

  /// Get search history
  List<String> getSearchHistory() {
    return searchHistory.toList();
  }

  /// Clear search history
  void clearSearchHistory() {
    searchHistory.clear();
  }

  // Computed properties
  bool get hasResults => searchResults.isNotEmpty;
  bool get isEmpty =>
      searchResults.isEmpty &&
      currentQuery.value.isNotEmpty &&
      !isSearching.value;
  int get resultCount => searchResults.length;
  bool get hasError => errorMessage.value.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get isSearchingOrLoading =>
      isSearching.value || isLoadingSuggestions.value;
}
