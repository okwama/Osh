import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/hive/client_model.dart';
import 'package:woosh/models/outlet_model.dart';
import 'package:woosh/services/core/client_cache_service.dart';
import 'package:woosh/services/core/client_search_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/pages/order/addorder_page.dart';
import 'package:woosh/pages/client/addclient_page.dart';
import 'package:woosh/pages/client/clientdetails.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/models/client_model.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';
import 'package:woosh/widgets/client_search_indicator.dart';
import 'package:woosh/widgets/client_empty_state.dart';
import 'package:woosh/widgets/client_filter_panel.dart';
import 'package:woosh/widgets/client_list_item.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class ViewClientPage extends StatefulWidget {
  final bool forOrderCreation;
  final bool forUpliftSale;
  final bool forProductReturn;

  const ViewClientPage({
    super.key,
    this.forOrderCreation = false,
    this.forUpliftSale = false,
    this.forProductReturn = false,
  });

  @override
  State<ViewClientPage> createState() => _ViewClientPageState();
}

class _ViewClientPageState extends State<ViewClientPage> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _isOnline = true;
  List<Outlet> _outlets = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageSize = 100;
  static const int _prefetchThreshold = 200;
  Timer? _debounce;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Filter options
  SortOption _sortOption = SortOption.nameAsc;
  bool _showFilters = false;
  bool _showOnlyWithContact = false;
  bool _showOnlyWithEmail = false;
  DateFilter _dateFilter = DateFilter.all;

  // Service instances
  late final ClientCacheService _clientCacheService;
  late final PaginationService _paginationService;
  late final DatabaseService _db;
  late final ClientSearchService _searchService;

  @override
  void initState() {
    super.initState();
    _clientCacheService = ClientCacheService.instance;
    _paginationService = PaginationService.instance;
    _db = DatabaseService.instance;
    _searchService = ClientSearchService();
    _initConnectivity();
    _loadOutlets();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      setState(() {
        _isOnline = results.isNotEmpty &&
            results.any((result) => result != ConnectivityResult.none);
      });
      if (_isOnline && _outlets.isEmpty) {
        _loadOutlets();
      }
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - _prefetchThreshold &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreOutlets();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Set loading state immediately for any search query
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
    } else {
      // Only clear loading state if query is completely empty
      setState(() {
        _isSearching = false;
      });
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (mounted) {
        try {
          if (query.isNotEmpty) {
            print('🔍 Performing search for: "$query"');

            // Always perform search regardless of hasMore status
            final updatedOutlets = await _searchService.searchClients(
              query: query,
              currentPage: _currentPage,
              pageSize: _pageSize,
              existingOutlets: _outlets,
              hasMore: _hasMore,
            );

            if (mounted) {
              setState(() {
                _outlets = updatedOutlets;
              });

              // Add a small delay to prevent flickering
              await Future.delayed(const Duration(milliseconds: 200));

              if (mounted) {
                setState(() {
                  _isSearching = false; // Only clear after search completes
                });
              }
              print('✅ Search completed. Found ${_outlets.length} clients');
            }
          } else if (query.isEmpty) {
            // If query is empty, reload original data with loading state
            setState(() {
              _isLoading = true;
            });
            await _loadOutlets();
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        } catch (e) {
          print('❌ Error during search: $e');
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Search failed: ${e.toString()}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    });
  }

  Future<void> _loadOutlets() async {
    if (!_isOnline) {
      _loadFromCache();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      // Get current user's country ID for filtering
      final currentUser = await _db.getCurrentUserDetails();
      print('DEBUG: currentUser = $currentUser');
      final countryId = currentUser['countryId'];
      print('DEBUG: countryId = $countryId');

      print('📍 Loading clients for country ID: $countryId');

      // First load from cache for quick display
      await _loadFromCache();
      print('?? Loaded ${_outlets.length} clients from cache');

      // Then fetch from pagination service with country filter
      print('?? Fetching page 1 with limit $_pageSize for country $countryId');

      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: _pageSize,
        filters: {
          'countryId': countryId, // Filter by country at database level
        },
        additionalWhere:
            'countryId IS NOT NULL AND countryId > 0', // Exclude null/0 countryId
        orderBy: 'id',
        orderDirection: 'DESC',
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
        ],
      );

      final outlets = result.items
          .map((row) => Outlet(
                id: row['id'] as int,
                name: row['name'] as String,
                address: row['address'] as String? ?? '',
                latitude: row['latitude'] as double?,
                longitude: row['longitude'] as double?,
                email: row['email'] as String? ?? '',
                contact: row['contact'] as String? ?? '',
                regionId: row['region_id'] as int?,
                region: row['region'] as String? ?? '',
                countryId: row['countryId'] as int?,
              ))
          .toList();

      // Debug: Print all countryIds fetched
      if (kDebugMode) {
        print(
            '🔎 [DEBUG] Fetched client countryIds: ${outlets.map((o) => o.countryId.toString()).join(', ')}');
      }

      print('? Fetched ${outlets.length} clients for country $countryId');

      if (mounted) {
        setState(() {
          _outlets = outlets;
          _isLoading = false;
          _hasMore = result.hasMore;
        });
        print('?? Total clients loaded: ${_outlets.length}');
        print('?? Has more clients: $_hasMore');
      }
    } catch (e) {
      print('? Error loading clients: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load clients. ${_outlets.isEmpty ? 'No cached data available.' : 'Showing cached data.'}';
          _isLoading = false;
        });

        if (_outlets.isEmpty) {
          _showErrorDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadFromCache() async {
    // Try to get cached clients first
    final cachedClients = await _clientCacheService.getCachedClients();
    if (cachedClients != null) {
      final outlets = cachedClients
          .map((client) => Outlet(
                id: client.id,
                name: client.name,
                address: client.address,
                latitude: client.latitude,
                longitude: client.longitude,
                email: client.email ?? '',
                contact: client.contact,
                regionId: client.regionId,
                region: client.region,
                countryId: client.countryId,
              ))
          .toList();

      setState(() {
        _outlets = outlets;
      });
      print('?? Loaded ${outlets.length} clients from cache');
    } else {
      print('?? No cached clients available');
    }
  }

  Future<void> _loadMoreOutlets() async {
    if (!_isOnline || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Get current user's country ID for filtering
      final currentUser = await _db.getCurrentUserDetails();
      print('DEBUG: currentUser = $currentUser');
      final countryId = currentUser['countryId'];
      print('DEBUG: countryId = $countryId');

      print(
          '📍 Loading more clients for country ID: $countryId - page ${_currentPage + 1}');

      // Use pagination service for additional pages with country filter
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: _currentPage + 1,
        limit: _pageSize,
        filters: {
          'countryId': countryId, // Filter by country at database level
        },
        additionalWhere:
            'countryId IS NOT NULL AND countryId > 0', // Exclude null/0 countryId
        orderBy: 'id',
        orderDirection: 'DESC',
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
        ],
      );

      final newOutlets = result.items
          .map((row) => Outlet(
                id: row['id'] as int,
                name: row['name'] as String,
                address: row['address'] as String? ?? '',
                latitude: row['latitude'] as double?,
                longitude: row['longitude'] as double?,
                email: row['email'] as String? ?? '',
                contact: row['contact'] as String? ?? '',
                regionId: row['region_id'] as int?,
                region: row['region'] as String? ?? '',
                countryId: row['countryId'] as int?,
              ))
          .toList();

      // Debug: Print all countryIds fetched in load more
      print(
          '🔎 [DEBUG] (Load More) Fetched client countryIds: ${newOutlets.map((o) => o.countryId.toString()).join(', ')}');

      print(
          '? Fetched ${newOutlets.length} more clients for country $countryId');

      if (mounted) {
        setState(() {
          _outlets.addAll(newOutlets);
          _currentPage++;
          _isLoadingMore = false;
          _hasMore = result.hasMore;
        });
        print('?? Total clients after loading more: ${_outlets.length}');
        print('?? Has more clients: $_hasMore');
      }
    } catch (e) {
      print('? Error loading more clients: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load more clients'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: const Text(
            'Could not connect to the server. Please check your internet connection.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
          if (_outlets.isEmpty)
            TextButton(
              onPressed: () {
                Get.back();
                _loadOutlets();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  List<Outlet> get _filteredOutlets {
    final query = _searchController.text.toLowerCase().trim();

    // Use the search service to filter outlets
    List<Outlet> filtered = _searchService.filterOutlets(
      outlets: _outlets,
      query: query,
      showOnlyWithContact: _showOnlyWithContact,
      showOnlyWithEmail: _showOnlyWithEmail,
    );

    // Apply date filter
    if (_dateFilter != DateFilter.all) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      filtered = filtered.where((outlet) {
        final outletDate = outlet.createdAt;
        if (outletDate == null) return false;

        switch (_dateFilter) {
          case DateFilter.today:
            return outletDate.isAfter(today);
          case DateFilter.thisWeek:
            return outletDate.isAfter(startOfWeek);
          case DateFilter.thisMonth:
            return outletDate.isAfter(startOfMonth);
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.addressAsc:
        filtered.sort((a, b) => a.address.compareTo(b.address));
        break;
      case SortOption.addressDesc:
        filtered.sort((a, b) => b.address.compareTo(a.address));
        break;
    }

    return filtered;
  }

  void _onClientSelected(Outlet outlet) {
    if (widget.forOrderCreation) {
      Get.to(
        () => AddOrderPage(outlet: outlet),
        transition: Transition.rightToLeft,
      );
    } else if (widget.forUpliftSale) {
      Get.off(
        () => UpliftSaleCartPage(outlet: outlet),
        transition: Transition.rightToLeft,
      );
    } else if (widget.forProductReturn) {
      Get.to(
        () => ProductReturnPage(outlet: outlet),
        transition: Transition.rightToLeft,
      );
    } else {
      Get.to(
        () => ClientDetailsPage(outlet: outlet),
        transition: Transition.rightToLeft,
      );
    }
  }

  Widget _buildListFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!_hasMore && _filteredOutlets.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text('End of list')),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCount = _filteredOutlets.length;
    final totalCount = _outlets.length;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Clients ($totalCount)',
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadOutlets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Stack(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search clients...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: _isSearching
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                        : const Icon(Icons.search, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          // Filter Panel
          ClientFilterPanel(
            showFilters: _showFilters,
            sortOption: _sortOption,
            dateFilter: _dateFilter,
            showOnlyWithContact: _showOnlyWithContact,
            showOnlyWithEmail: _showOnlyWithEmail,
            onSortChanged: (value) => setState(() => _sortOption = value),
            onDateFilterChanged: (value) => setState(() => _dateFilter = value),
            onContactFilterChanged: (value) =>
                setState(() => _showOnlyWithContact = value),
            onEmailFilterChanged: (value) =>
                setState(() => _showOnlyWithEmail = value),
          ),
          if (_showFilters) const SizedBox(height: 6),
          // Search status and results count (only show when not loading)
          if (!_isSearching && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  if (filteredCount != totalCount)
                    Text(
                      'Showing $filteredCount of $totalCount clients',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const Spacer(),
                  if (!_isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Offline',
                        style: TextStyle(color: Colors.orange, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          // Outlets List
          Expanded(
            child: _isLoading && _outlets.isEmpty
                ? const ClientListSkeleton()
                : _isSearching
                    ? ClientSearchIndicator(searchQuery: _searchController.text)
                    : _errorMessage != null && _outlets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 36,
                                  color: Colors.red.shade300,
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _loadOutlets,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry',
                                      style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _filteredOutlets.isEmpty
                            ? ClientEmptyState(
                                searchQuery: _searchController.text,
                                onAddClient: () async {
                                  final result =
                                      await Get.to(() => const AddClientPage());
                                  if (result == true && mounted) {
                                    await _loadOutlets();
                                  }
                                },
                              )
                            : RefreshIndicator(
                                onRefresh: _loadOutlets,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  itemCount: _filteredOutlets.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == _filteredOutlets.length) {
                                      return _buildListFooter();
                                    }

                                    final outlet = _filteredOutlets[index];
                                    return ClientListItem(
                                      outlet: outlet,
                                      onTap: () => _onClientSelected(outlet),
                                    );
                                  },
                                ),
                              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const AddClientPage());
          // Only refresh if client was successfully added
          if (result == true && mounted) {
            print('?? Client added successfully, refreshing list');
            // Use the same working method as initial load
            await _loadOutlets();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

