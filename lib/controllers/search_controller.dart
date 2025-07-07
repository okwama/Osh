import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:woosh/services/core/search_service.dart';
import 'package:woosh/models/client_model.dart';

/// Controller for managing search functionality with debouncing and state management
class SearchController extends ChangeNotifier {
  final SearchService _searchService = SearchService.instance;

  // Search state
  String _currentQuery = '';
  List<Client> _searchResults = [];
  bool _isSearching = false;
  bool _hasMoreResults = false;
  int _currentPage = 1;
  String? _errorMessage;
  Timer? _debounceTimer;

  // Search suggestions
  List<String> _suggestions = [];
  bool _isLoadingSuggestions = false;

  // Getters
  String get currentQuery => _currentQuery;
  List<Client> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get hasMoreResults => _hasMoreResults;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  List<String> get suggestions => _suggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  /// Initialize search with optional initial query
  void initializeSearch([String? initialQuery]) {
    if (initialQuery != null && initialQuery.isNotEmpty) {
      _currentQuery = initialQuery;
      _performSearch();
    }
  }

  /// Update search query with debouncing
  void updateSearchQuery(String query) {
    _currentQuery = query;
    _errorMessage = null;
    notifyListeners();

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Clear results if query is empty
    if (query.trim().isEmpty) {
      _clearSearchResults();
      return;
    }

    // Start new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  /// Perform search with current query
  Future<void> _performSearch() async {
    if (_currentQuery.trim().isEmpty) {
      _clearSearchResults();
      return;
    }

    _setSearching(true);
    _currentPage = 1;

    try {
      final result = await _searchService.searchClients(
        query: _currentQuery,
        page: _currentPage,
        limit: 100,
        orderBy: 'name',
        orderDirection: 'ASC',
      );

      _searchResults = result.items;
      _hasMoreResults = result.hasMore;
      _errorMessage = null;

      print('🔍 Search completed: ${result.items.length} results found');
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
      _searchResults = [];
      _hasMoreResults = false;
      print('❌ Search error: $e');
    } finally {
      _setSearching(false);
    }
  }

  /// Load more search results
  Future<void> loadMoreResults() async {
    if (_isSearching || !_hasMoreResults || _currentQuery.trim().isEmpty) {
      return;
    }

    _setSearching(true);

    try {
      final result = await _searchService.searchClients(
        query: _currentQuery,
        page: _currentPage + 1,
        limit: 100,
        orderBy: 'name',
        orderDirection: 'ASC',
      );

      _searchResults.addAll(result.items);
      _hasMoreResults = result.hasMore;
      _currentPage++;
      _errorMessage = null;

      print('📄 Loaded more results: ${result.items.length} additional items');
    } catch (e) {
      _errorMessage = 'Failed to load more results: ${e.toString()}';
      print('❌ Load more error: $e');
    } finally {
      _setSearching(false);
    }
  }

  /// Search by specific field
  Future<void> searchByField({
    required String field,
    required String value,
  }) async {
    _setSearching(true);
    _currentPage = 1;

    try {
      final result = await _searchService.searchClientsByField(
        field: field,
        value: value,
        page: _currentPage,
        limit: 100,
        orderBy: 'name',
        orderDirection: 'ASC',
      );

      _searchResults = result.items;
      _hasMoreResults = result.hasMore;
      _errorMessage = null;

      print('🔍 Field search completed: ${result.items.length} results found');
    } catch (e) {
      _errorMessage = 'Field search failed: ${e.toString()}';
      _searchResults = [];
      _hasMoreResults = false;
      print('❌ Field search error: $e');
    } finally {
      _setSearching(false);
    }
  }

  /// Search clients near location
  Future<void> searchNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    _setSearching(true);
    _currentPage = 1;

    try {
      final result = await _searchService.searchClientsNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        page: _currentPage,
        limit: 100,
      );

      _searchResults = result.items;
      _hasMoreResults = result.hasMore;
      _errorMessage = null;

      print(
          '📍 Location search completed: ${result.items.length} results found');
    } catch (e) {
      _errorMessage = 'Location search failed: ${e.toString()}';
      _searchResults = [];
      _hasMoreResults = false;
      print('❌ Location search error: $e');
    } finally {
      _setSearching(false);
    }
  }

  /// Load search suggestions
  Future<void> loadSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      final suggestions = await _searchService.getSearchSuggestions(
        partialQuery: partialQuery,
        limit: 10,
      );

      _suggestions = suggestions;
      print('💡 Loaded ${suggestions.length} search suggestions');
    } catch (e) {
      _suggestions = [];
      print('❌ Failed to load suggestions: $e');
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  /// Get search statistics
  Future<Map<String, dynamic>> getSearchStats() async {
    if (_currentQuery.trim().isEmpty) {
      return {
        'totalResults': 0,
        'searchTerms': [],
        'queryDuration': Duration.zero,
      };
    }

    try {
      return await _searchService.getSearchStats(query: _currentQuery);
    } catch (e) {
      print('❌ Failed to get search stats: $e');
      return {
        'totalResults': 0,
        'searchTerms': [],
        'error': e.toString(),
      };
    }
  }

  /// Clear search results
  void _clearSearchResults() {
    _searchResults = [];
    _hasMoreResults = false;
    _currentPage = 1;
    _errorMessage = null;
    _suggestions = [];
    notifyListeners();
  }

  /// Clear search completely
  void clearSearch() {
    _currentQuery = '';
    _clearSearchResults();
    _debounceTimer?.cancel();
  }

  /// Set searching state
  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  /// Retry last search
  Future<void> retrySearch() async {
    if (_currentQuery.trim().isNotEmpty) {
      await _performSearch();
    }
  }

  /// Refresh search results
  Future<void> refreshSearch() async {
    if (_currentQuery.trim().isNotEmpty) {
      _currentPage = 1;
      await _performSearch();
    }
  }

  /// Check if search has results
  bool get hasResults => _searchResults.isNotEmpty;

  /// Check if search is empty
  bool get isEmpty => _searchResults.isEmpty && !_isSearching;

  /// Get result count
  int get resultCount => _searchResults.length;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
