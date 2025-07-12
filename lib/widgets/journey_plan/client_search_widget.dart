import 'package:flutter/material.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/widgets/client/client_list_item.dart';
import 'package:shimmer/shimmer.dart';

class ClientSearchWidget extends StatefulWidget {
  final Function(Client) onClientSelected;
  final List<Client> initialClients;
  final bool showLoadingState;

  const ClientSearchWidget({
    super.key,
    required this.onClientSelected,
    this.initialClients = const [],
    this.showLoadingState = false,
  });

  @override
  State<ClientSearchWidget> createState() => _ClientSearchWidgetState();
}

class _ClientSearchWidgetState extends State<ClientSearchWidget> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];
  String searchQuery = '';
  int _currentPage = 1;
  bool _hasMoreData = true;
  final List<String> _whereParams = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, List<Client>> _searchCache = {};

  // Service instances
  late final DatabaseService _db;
  late final PaginationService _paginationService;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService.instance;
    _paginationService = PaginationService.instance;

    _allClients = widget.initialClients;
    _filteredClients = _allClients;

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Initialize clients if not provided
    if (_allClients.isEmpty) {
      _initializeClients();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreClients();
      }
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
        _updateFilteredClients();
      });
    }
  }

  Future<void> _initializeClients() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user's country ID for filtering
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      print('🔍 Loading clients for country ID: $countryId');

      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: 100,
        filters: {
          'countryId': countryId,
        },
        additionalWhere: 'countryId IS NOT NULL AND countryId > 0',
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: _whereParams,
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

      final clients = result.items
          .map((row) => Client(
                id: row['id'] as int,
                name: row['name'] as String,
                address: row['address'] as String? ?? '',
                contact: row['contact'] as String?,
                latitude: row['latitude'] as double?,
                longitude: row['longitude'] as double?,
                email: row['email'] as String?,
                regionId: row['region_id'] as int? ?? 0,
                region: row['region'] as String? ?? '',
                countryId: row['countryId'] as int? ?? 0,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _allClients = clients;
          _filteredClients = _allClients;
          _currentPage = 1;
          _hasMoreData = result.hasMore;
        });
      }
    } catch (e) {
      print('❌ Error loading clients: $e');
      if (mounted) {
        setState(() {
          _allClients = widget.initialClients;
          _filteredClients = _allClients;
          _currentPage = 1;
          _hasMoreData = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreClients() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      print(
          '📍 Loading more clients for country ID: $countryId - page ${_currentPage + 1}');

      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: _currentPage + 1,
        limit: 100,
        filters: {
          'countryId': countryId,
        },
        additionalWhere: 'countryId IS NOT NULL AND countryId > 0',
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: _whereParams,
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

      final clients = result.items
          .map((row) => Client(
                id: row['id'] as int,
                name: row['name'] as String,
                address: row['address'] as String? ?? '',
                contact: row['contact'] as String?,
                latitude: row['latitude'] as double?,
                longitude: row['longitude'] as double?,
                email: row['email'] as String?,
                regionId: row['region_id'] as int? ?? 0,
                region: row['region'] as String? ?? '',
                countryId: row['countryId'] as int? ?? 0,
              ))
          .toList();

      if (mounted) {
        if (clients.isEmpty) {
          setState(() {
            _hasMoreData = false;
          });
        } else {
          setState(() {
            final existingIds = _allClients.map((c) => c.id).toSet();
            final newClients =
                clients.where((c) => !existingIds.contains(c.id)).toList();
            _allClients.addAll(newClients);
            _currentPage++;
            _hasMoreData = result.hasMore;
            _updateFilteredClients();
          });
        }
      }
    } catch (e) {
      print('❌ Error loading more clients: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _updateFilteredClients() {
    if (searchQuery.isEmpty) {
      _filteredClients = _allClients;
    } else {
      _filteredClients = _allClients.where((client) {
        return client.name.toLowerCase().contains(searchQuery) ||
            client.address.toLowerCase().contains(searchQuery) ||
            (client.contact?.toLowerCase().contains(searchQuery) ?? false) ||
            (client.email?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),

        // Client List
        Expanded(
          child: _buildClientList(),
        ),
      ],
    );
  }

  Widget _buildClientList() {
    if (widget.showLoadingState || _isLoading) {
      return _buildLoadingState();
    }

    if (_filteredClients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _initializeClients,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filteredClients.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredClients.length) {
            return _buildLoadingMoreIndicator();
          }

          final client = _filteredClients[index];
          return ClientListItem(
            client: client,
            onTap: () => widget.onClientSelected(client),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
              ),
              title: Container(
                height: 16,
                color: Colors.grey.shade300,
              ),
              subtitle: Container(
                height: 12,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No clients found'
                : 'No clients match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Try refreshing the list'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
