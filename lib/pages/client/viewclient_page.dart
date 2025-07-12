import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/hive/client_model.dart';
import 'package:woosh/services/core/client_storage_service.dart';
import 'package:woosh/services/search/index.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/pages/order/addorder_page.dart';
import 'package:woosh/pages/client/addclient_page.dart';
import 'package:woosh/pages/client/clientdetails.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';
import 'package:woosh/widgets/client/client_search_indicator.dart';
import 'package:woosh/widgets/client/client_empty_state.dart';
import 'package:woosh/widgets/client/client_filter_panel.dart';
import 'package:woosh/widgets/client/client_list_item.dart';

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
  List<Client> _outlets = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageSize =
      10000; // Increased to 10,000 for better performance
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
  late final ClientStorageService _clientStorageService;
  late final PaginationService _paginationService;
  late final DatabaseService _db;
  late final UnifiedSearchService _searchService;

  @override
  void initState() {
    super.initState();
    _clientStorageService = ClientStorageService.instance;
    _paginationService = PaginationService.instance;
    _db = DatabaseService.instance;
    _searchService = UnifiedSearchService.instance;
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
            // Always perform search regardless of hasMore status
            final searchResult = await _searchService.searchClients(
              query: query,
              page: _currentPage,
              limit: _pageSize,
              useCache: true,
            );

            if (mounted) {
              setState(() {
                _outlets = searchResult.items;
                _hasMore = searchResult.hasMore;
              });

              // Add a small delay to prevent flickering
              await Future.delayed(const Duration(milliseconds: 200));

              if (mounted) {
                setState(() {
                  _isSearching = false; // Only clear after search completes
                });
              }
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
      await _loadFromCache();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      // Initialize storage service if needed
      await _clientStorageService.init();

      // First load from storage for quick display
      await _loadFromCache();

      // Check if sync is needed
      final isSyncNeeded = await _clientStorageService.isSyncNeeded();

      if (isSyncNeeded) {
        print('🔄 Syncing clients with storage service...');

        try {
          // Perform smart sync (incremental or full based on data)
          final syncedClients = await _clientStorageService.syncClients();

          if (mounted) {
            setState(() {
              _outlets = syncedClients;
              _isLoading = false;
              _hasMore = syncedClients.length >= _pageSize;
            });
          }
        } catch (e) {
          print('⚠️ Sync failed, using stored data: $e');

          // Use stored data as fallback
          final storedClients =
              await _clientStorageService.getAllStoredClients();

          if (mounted) {
            setState(() {
              _outlets = storedClients;
              _isLoading = false;
              _hasMore = storedClients.length >= _pageSize;
            });
          }
        }
      } else {
        // Use stored data if sync not needed
        final storedClients = await _clientStorageService.getAllStoredClients();

        if (mounted) {
          setState(() {
            _outlets = storedClients;
            _isLoading = false;
            _hasMore = storedClients.length >= _pageSize;
          });
        }
      }

      // Debug: Print storage stats
      if (kDebugMode) {
        final stats = await _clientStorageService.getStorageStats();
        final totalCount = await _clientStorageService.getTotalClientCount();
        print('📊 Storage stats: $stats');
        print('📊 Total clients available: $totalCount');

        // Update hasMore based on total count
        if (mounted) {
          setState(() {
            _hasMore = _outlets.length < totalCount;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load clients. ${_outlets.isEmpty ? 'No stored data available.' : 'Showing stored data.'}';
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
    // Try to get stored clients first
    final storedClients = await _clientStorageService.getAllStoredClients();
    if (storedClients.isNotEmpty) {
      setState(() {
        _outlets = storedClients;
      });
    }
  }

  Future<void> _loadMoreOutlets() async {
    if (!_isOnline || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      print('📍 Loading more clients from storage service...');

      // Load more clients using the storage service
      final moreClients = await _clientStorageService.loadMoreClients(
        page: _currentPage + 1,
        limit: _pageSize,
        appendToExisting: true,
      );

      if (mounted) {
        setState(() {
          _outlets = moreClients;
          _currentPage++;
          _isLoadingMore = false;
          _hasMore = moreClients.length >= _pageSize; // Check if more available
        });
      }

      print('✅ Loaded ${moreClients.length} more clients');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more clients: ${e.toString()}'),
            duration: const Duration(seconds: 2),
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

  List<Client> get _filteredOutlets {
    final query = _searchController.text.toLowerCase().trim();

    // Filter outlets based on search query and filters
    List<Client> filtered = _outlets.where((client) {
      // Fuzzy search query filter
      if (query.isNotEmpty) {
        final searchTerms =
            query.split(' ').where((term) => term.isNotEmpty).toList();

        // Check if all search terms match any field (fuzzy search)
        bool matchesQuery = searchTerms.every((term) {
          return client.name.toLowerCase().contains(term) ||
              (client.address?.toLowerCase().contains(term) ?? false) ||
              (client.contact?.toLowerCase().contains(term) ?? false) ||
              (client.email?.toLowerCase().contains(term) ?? false) ||
              (client.region?.toLowerCase().contains(term) ?? false);
        });

        if (!matchesQuery) return false;
      }

      // Contact filter
      if (_showOnlyWithContact && (client.contact?.isEmpty ?? true))
        return false;

      // Email filter
      if (_showOnlyWithEmail && (client.email?.isEmpty ?? true)) return false;

      return true;
    }).toList();

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

  void _onClientSelected(Client client) {
    if (widget.forOrderCreation) {
      Get.to(
        () => AddOrderPage(outlet: client),
        transition: Transition.rightToLeft,
      );
    } else if (widget.forUpliftSale) {
      Get.off(
        () => UpliftSaleCartPage(outlet: client),
        transition: Transition.rightToLeft,
      );
    } else if (widget.forProductReturn) {
      Get.to(
        () => ProductReturnPage(client: client),
        transition: Transition.rightToLeft,
      );
    } else {
      Get.to(
        () => ClientDetailsPage(client: client),
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

                                    final client = _filteredOutlets[index];
                                    return ClientListItem(
                                      client: client,
                                      onTap: () => _onClientSelected(client),
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
