import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';

import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/core/route_service.dart' as RouteServices;
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

class CreateJourneyPlanPage extends StatefulWidget {
  final List<Client> clients;
  final Function(List<JourneyPlan>) onSuccess;

  const CreateJourneyPlanPage({
    super.key,
    required this.clients,
    required this.onSuccess,
  });

  @override
  State<CreateJourneyPlanPage> createState() => _CreateJourneyPlanPageState();
}

class _CreateJourneyPlanPageState extends State<CreateJourneyPlanPage> {
  bool _isLoading = false;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _isCreating = false;
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];
  String searchQuery = '';
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final Map<String, List<Client>> _searchCache = {};

  // New design fields
  DateTime selectedDate = DateTime.now();
  final TextEditingController notesController = TextEditingController();
  int? selectedRouteId;
  List<RouteServices.RouteOption> _routeOptions = [];
  bool _isLoadingRoutes = false;

  // Service instances
  late final DatabaseService _db;
  late final PaginationService _paginationService;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService.instance;
    _paginationService = PaginationService.instance;

    _allClients = widget.clients;
    _filteredClients = _allClients;

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Clear route cache to ensure updated filtering (country_id OR country_id = 0) is applied
    RouteServices.RouteService.clearCacheForFilterUpdate();

    // Initialize routes and clients
    _initializeRoutes();

    // Initialize clients if not provided
    if (_allClients.isEmpty) {
      _initializeClients();
    } else {
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    notesController.dispose();
    _debounce?.cancel();
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          searchQuery = _searchController.text.toLowerCase();
          _updateFilteredClients();
          // Reset scroll position to top when search query changes
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  Future<void> _initializeRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      // Get current user's route info
      final currentUser = await _db.getCurrentUserDetails();
      final userRouteId = currentUser['routeId'];

      // Fetch cached route options for current user's country (lightweight id + name only)
      final routeOptions = await RouteServices.RouteService
          .getCachedRouteOptionsForCurrentUser();

      print(
          '📍 Fetched ${routeOptions.length} cached route options for current user');

      if (mounted) {
        setState(() {
          _routeOptions = routeOptions;
          // Set selected route to user's current route if it exists in the list
          if (userRouteId != null) {
            final userRoute = routeOptions.firstWhere(
              (route) => route.id == userRouteId,
              orElse: () => routeOptions.isNotEmpty
                  ? routeOptions.first
                  : routeOptions.first,
            );
            selectedRouteId = userRoute.id;
          } else if (routeOptions.isNotEmpty) {
            // If user has no route assigned, default to first available route
            selectedRouteId = routeOptions.first.id;
          }
        });
      }
    } catch (e) {
      // Fallback: Try to get user's current route info
      try {
        final currentUser = await _db.getCurrentUserDetails();
        final routeId = currentUser['routeId'];

        if (routeId != null && mounted) {
          setState(() {
            selectedRouteId = routeId;
          });
        }
      } catch (fallbackError) {}
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
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

      // Use the SAME working method as viewclient_page.dart
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: 10000, // Increased from 100 to 10000 for better data loading
        filters: {
          'countryId': countryId, // Direct database filtering
        },
        additionalWhere:
            'countryId IS NOT NULL AND countryId > 0', // Exclude null/0 countryId
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: [], // Add empty whereParams array
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

      // Convert to Client objects
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
      // Fallback to passed clients if database fetch fails
      if (mounted) {
        setState(() {
          _allClients = widget.clients;
          _filteredClients = _allClients;
          _currentPage = 1;
          _hasMoreData = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  bool _isConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('connection timeout') ||
        errorString.contains('network error') ||
        errorString.contains('connection refused') ||
        errorString.contains('no internet') ||
        errorString.contains('xmlhttprequest error') ||
        errorString.contains('failed to connect') ||
        errorString.contains('timeout');
  }

  Future<void> _loadMoreClients() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Get current user's country ID for filtering
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      print(
          '📍 Loading more clients for country ID: $countryId - page ${_currentPage + 1}');

      // Use the SAME working method as viewclient_page.dart
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: _currentPage + 1,
        limit: 10000, // Increased from 100 to 10000 for better data loading
        filters: {
          'countryId': countryId, // Direct database filtering
        },
        additionalWhere:
            'countryId IS NOT NULL AND countryId > 0', // Exclude null/0 countryId
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: [], // Add empty whereParams array
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

      // Convert to Client objects
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

      print(
          '📍 Fetched ${clients.length} more clients for country ID: $countryId');

      if (mounted) {
        if (clients.isEmpty) {
          setState(() {
            _hasMoreData = false;
          });
        } else {
          setState(() {
            // Use a Set to prevent duplicates
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshClients() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
      _searchCache.clear();
    });

    try {
      // Get current user's country ID for filtering
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      print(
          '🔄 Refreshing clients using working method for country $countryId');

      // Use the SAME working method as viewclient_page.dart
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: 10000, // Increased from 100 to 10000 for better data loading
        filters: {
          'countryId': countryId, // Direct database filtering
        },
        additionalWhere:
            'countryId IS NOT NULL AND countryId > 0', // Exclude null/0 countryId
        orderBy: 'id',
        orderDirection: 'DESC',
        whereParams: [], // Add empty whereParams array
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

      // Convert to Client objects
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

      setState(() {
        _allClients = clients;
        _hasMoreData = result.hasMore;
        _updateFilteredClients();
      });
    } catch (e) {
      // Silent fail for all refresh errors
    }
  }

  void _updateFilteredClients() {
    if (searchQuery.isEmpty) {
      _filteredClients = _allClients;
    } else {
      // Check cache first
      if (_searchCache.containsKey(searchQuery)) {
        _filteredClients = _searchCache[searchQuery]!;
      } else {
        // Perform search
        final results = _performSearch(searchQuery);
        _searchCache[searchQuery] = results;
        _filteredClients = results;
      }
    }
  }

  List<Client> _performSearch(String query) {
    final searchTerms = query.toLowerCase().split(' ');

    return _allClients.where((client) {
      final name = client.name.toLowerCase();
      final address = client.address.toLowerCase();
      final contact = client.contact?.toLowerCase() ?? '';
      final email = client.email?.toLowerCase() ?? '';

      return searchTerms.every((term) =>
          name.contains(term) ||
          address.contains(term) ||
          contact.contains(term) ||
          email.contains(term));
    }).toList();
  }

  // Background search function for complex searches
  static Map<String, dynamic> _matchAndScoreClientsInBackground(
      Map<String, dynamic> params) {
    final List<Client> clients = params['clients'];
    final String query = params['query'];

    final searchTerms = query.toLowerCase().split(' ');
    final results = <Client>[];

    for (final client in clients) {
      int score = 0;
      final name = client.name.toLowerCase();
      final address = client.address.toLowerCase();
      final contact = client.contact?.toLowerCase() ?? '';
      final email = client.email?.toLowerCase() ?? '';

      // Score based on matches
      for (final term in searchTerms) {
        if (name.contains(term)) score += 10;
        if (address.contains(term)) score += 5;
        if (contact.contains(term)) score += 3;
        if (email.contains(term)) score += 2;
      }

      if (score > 0) {
        results.add(client);
      }
    }

    // Sort by score (highest first)
    results.sort((a, b) {
      final scoreA = _calculateScore(a, searchTerms);
      final scoreB = _calculateScore(b, searchTerms);
      return scoreB.compareTo(scoreA);
    });

    return {'results': results, 'query': query};
  }

  static int _calculateScore(Client client, List<String> searchTerms) {
    int score = 0;
    final name = client.name.toLowerCase();
    final address = client.address.toLowerCase();
    final contact = client.contact?.toLowerCase() ?? '';
    final email = client.email?.toLowerCase() ?? '';

    for (final term in searchTerms) {
      if (name.contains(term)) score += 10;
      if (address.contains(term)) score += 5;
      if (contact.contains(term)) score += 3;
      if (email.contains(term)) score += 2;
    }

    return score;
  }

  Future<void> _createJourneyPlan(Client client) async {
    if (_isCreating) return;

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_task, color: Colors.blue),
            SizedBox(width: 8),
            Text('Create Journey Plan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to create a journey plan for:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          client.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          client.address,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (selectedRouteId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.route,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _routeOptions
                                .firstWhere(
                                  (route) => route.id == selectedRouteId,
                                  orElse: () => RouteServices.RouteOption(
                                      id: 0, name: 'Unknown'),
                                )
                                .name,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    // If user cancels, return early
    if (confirmed != true) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Get current user details
      final currentUser = await _db.getCurrentUserDetails();
      final userId = currentUser['id'];
      final routeId = selectedRouteId ?? currentUser['routeId'];

      // Create journey plan
      final journeyPlan = await JourneyPlanService.createJourneyPlan(
        clientId: client.id,
        userId: userId,
        routeId: routeId,
        date: selectedDate,
        time: TimeOfDay.now().format(context),
      );

      if (journeyPlan != null) {
        // Call success callback
        widget.onSuccess([journeyPlan]);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Journey plan created for ${client.name}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back
          Get.back();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create journey plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Widget _buildClientCard(Client client) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _createJourneyPlan(client),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client.address,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
              if (client.contact?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      client.contact!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              if (client.email?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        client.email!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewClientCard(Client client) {
    return InkWell(
      onTap: () => _createJourneyPlan(client),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    client.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Create Journey Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshClients,
            tooltip: 'Refresh Clients',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Route Selection Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Date Picker
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16),
                                    SizedBox(width: 4),
                                    Text('Date',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final DateTime? pickedDate =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        selectedDate = pickedDate;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            DateFormat('MMM dd, yyyy')
                                                .format(selectedDate),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Route Dropdown
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.route, size: 16),
                                    SizedBox(width: 4),
                                    Text('Route',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: selectedRouteId,
                                      isExpanded: true,
                                      icon: const Icon(Icons.expand_more,
                                          size: 20),
                                      iconSize: 20,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                      hint: _isLoadingRoutes
                                          ? const Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Loading routes...',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              'Select route',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 14),
                                            ),
                                      items: _isLoadingRoutes
                                          ? []
                                          : _routeOptions.map((route) {
                                              return DropdownMenuItem<int>(
                                                value: route.id,
                                                child: Tooltip(
                                                  message: route.name,
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 4,
                                                        horizontal: 0),
                                                    child: Text(
                                                      route.name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedRouteId = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search clients...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Client List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 18),
                      const SizedBox(width: 8),
                      const Text('Select Client',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${_filteredClients.length} clients',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Client List
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _isInitialLoad
                        ? _buildLoadingShimmer()
                        : _filteredClients.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.store_mall_directory_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'No clients available'
                                          : 'No matching clients found',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'No clients assigned to your route'
                                          : 'Try a different search term',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _refreshClients,
                                child: ListView.separated(
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: _filteredClients.length +
                                      (_hasMoreData ? 1 : 0),
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    if (index == _filteredClients.length) {
                                      return _isLoadingMore
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : const SizedBox.shrink();
                                    }

                                    final client = _filteredClients[index];
                                    return _buildNewClientCard(client);
                                  },
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
          // Loading Overlay
          if (_isCreating)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Creating Journey Plan...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
