import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:woosh/models/client_model.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/pages/journeyplan/createJourneyplan.dart';
import 'package:woosh/pages/journeyplan/journeyview.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/core/journey_plan_service.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class JourneyPlansLoadingScreen extends StatefulWidget {
  const JourneyPlansLoadingScreen({super.key});

  @override
  State<JourneyPlansLoadingScreen> createState() =>
      _JourneyPlansLoadingScreenState();
}

class _JourneyPlansLoadingScreenState extends State<JourneyPlansLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      // Load journey plans and clients from new services
      final journeyPlans = await JourneyPlanService.getJourneyPlans(
        page: 1,
        excludePast: true,
      );

      // Use the SAME working method as viewclient_page.dart
      final db = DatabaseService.instance;
      final paginationService = PaginationService.instance;

      // Get current user's country ID for filtering
      final currentUser = await db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      final result = await paginationService.fetchOffset(
        table: 'Clients',
        page: 1,
        limit: 100,
        filters: {
          'countryId': countryId, // Direct database filtering
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

      // Navigate to main page with preloaded data
      if (mounted) {
        Get.off(
          () => JourneyPlansPage(
            preloadedClients: clients,
            preloadedPlans: journeyPlans,
          ),
          transition: Transition.rightToLeft,
        );
      }
    } catch (e) {
      // If there's an error, still navigate but with empty data
      if (mounted) {
        Get.off(
          () => const JourneyPlansPage(),
          transition: Transition.rightToLeft,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Loading Journey Plans...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JourneyPlansPage extends StatefulWidget {
  final List<Client>? preloadedClients;
  final List<JourneyPlan>? preloadedPlans;

  const JourneyPlansPage({
    super.key,
    this.preloadedClients,
    this.preloadedPlans,
  });

  @override
  State<JourneyPlansPage> createState() => _JourneyPlansPageState();
}

class _JourneyPlansPageState extends State<JourneyPlansPage>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Client> _clients = [];
  List<JourneyPlan> _journeyPlans = [];
  final Set<int> _hiddenJourneyPlans = {};
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  JourneyPlan? _activeVisit;
  bool _isShowingNotification = false;
  Timer? _refreshTimer;
  bool _sortAscending = true;

  // Service instances
  late final DatabaseService _db;
  late final PaginationService _paginationService;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService.instance;
    _paginationService = PaginationService.instance;
    WidgetsBinding.instance.addObserver(this);

    // Use preloaded data if available
    if (widget.preloadedClients != null) {
      _clients = widget.preloadedClients!;
    }
    if (widget.preloadedPlans != null) {
      _journeyPlans = widget.preloadedPlans!;
      _isLoading = false;
    } else {
      _loadData();
    }

    _scrollController.addListener(_onScroll);
    _checkActiveVisit();

    // Start periodic refresh every 5 minutes instead of 60 seconds
    _startPeriodicRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when page becomes visible (e.g., returning from other screens)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshData();
    }
  }

  void _startPeriodicRefresh() {
    // Changed from 60 seconds to 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  /// Helper method to fetch clients using the same working method as viewclient_page.dart
  Future<List<Client>> _fetchClients({int page = 1, int limit = 100}) async {
    // Get current user's country ID for filtering
    final currentUser = await _db.getCurrentUserDetails();
    final countryId = currentUser['countryId'];

    final result = await _paginationService.fetchOffset(
      table: 'Clients',
      page: page,
      limit: limit,
      filters: {
        'countryId': countryId, // Direct database filtering
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

    // Convert to Client objects
    return result.items
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
  }

  Future<void> _refreshData() async {
    try {
      // Quick refresh without showing loading state
      final journeyPlansFuture = JourneyPlanService.getJourneyPlans(
        page: 1,
        excludePast: true,
      );

      // Use the working method as viewclient_page.dart
      final clientsFuture = _fetchClients(
        page: 1,
        limit: 100,
      );

      final journeyPlans = await journeyPlansFuture;
      final clients = await clientsFuture;

      // Build a map for efficient client lookup
      final Map<int, Client> clientMap = {for (var c in clients) c.id: c};

      // Create new JourneyPlan objects with full client data
      final List<JourneyPlan> updatedJourneyPlans = journeyPlans.map((plan) {
        final Client client = clientMap[plan.client.id] ?? plan.client;
        return JourneyPlan(
          id: plan.id,
          date: plan.date,
          time: plan.time,
          salesRepId: plan.salesRepId,
          status: plan.status,
          routeId: plan.routeId,
          client: client,
          showUpdateLocation: plan.showUpdateLocation,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _journeyPlans = updatedJourneyPlans;
          _clients = clients;
        });
      }
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newPlans = await JourneyPlanService.getJourneyPlans(
        page: _currentPage + 1,
        excludePast: true,
      );

      if (newPlans.isEmpty) {
        setState(() {
          _hasMoreData = false;
        });
      } else {
        setState(() {
          _journeyPlans.addAll(newPlans);
          _currentPage++;
        });
      }
    } catch (e) {
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // 1. Fetch journey plans and clients in parallel
      final journeyPlansFuture = JourneyPlanService.getJourneyPlans(
        page: 1,
        excludePast: true,
      );

      // Use the working method as viewclient_page.dart
      final clientsFuture = _fetchClients(
        page: 1,
        limit: 100,
      );

      // Await both futures
      final journeyPlans = await journeyPlansFuture;
      final clients = await clientsFuture;

      // Build a map for efficient client lookup
      final Map<int, Client> clientMap = {for (var c in clients) c.id: c};

      // Create new JourneyPlan objects with full client data
      final List<JourneyPlan> updatedJourneyPlans = journeyPlans.map((plan) {
        final Client client = clientMap[plan.client.id] ?? plan.client;
        return JourneyPlan(
          id: plan.id,
          date: plan.date,
          time: plan.time,
          salesRepId: plan.salesRepId,
          status: plan.status,
          routeId: plan.routeId,
          client: client,
          showUpdateLocation: plan.showUpdateLocation,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _journeyPlans = updatedJourneyPlans;
          _clients = clients;
          _currentPage = 1;
          _hasMoreData = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showGenericErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<JourneyPlan> _getFilteredPlans() {
    // Remove date filtering - show all plans
    var filteredPlans = _journeyPlans.where((plan) {
      return !_hiddenJourneyPlans.contains(plan.id);
    }).toList();

    // Sort by creation date (newest first when ascending, oldest first when descending)
    filteredPlans.sort((a, b) {
      if (_sortAscending) {
        // Newest first (descending by date)
        return b.date.compareTo(a.date);
      } else {
        // Oldest first (ascending by date)
        return a.date.compareTo(b.date);
      }
    });

    return filteredPlans;
  }

  void _showGenericErrorDialog() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Could not refresh plans. Please check your connection.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
  }

  Future<void> _checkActiveVisit() async {
    try {
      // For now, we'll check for active visits by looking for in-progress journey plans
      final activePlans = _journeyPlans
          .where((plan) =>
              plan.status == JourneyPlan.statusInProgress ||
              plan.status == JourneyPlan.statusCheckedIn)
          .toList();

      if (activePlans.isNotEmpty) {
        setState(() {
          _activeVisit = activePlans.first;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _navigateToCreateJourneyPlan() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (_clients.isEmpty) {
        // Use the working method as viewclient_page.dart
        final clients = await _fetchClients(
          page: 1,
          limit: 100,
        );
        setState(() {
          _clients = clients;
        });
      }

      if (mounted) Get.back();

      if (mounted) {
        Get.to(
          () => CreateJourneyPlanPage(
            clients: _clients,
            onSuccess: (newJourneyPlans) {
              if (newJourneyPlans.isNotEmpty) {
                setState(() {
                  _journeyPlans.insert(0, newJourneyPlans[0]);
                });
              }
            },
          ),
          transition: Transition.rightToLeft,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.back();
      }
    }
  }

  void _navigateToJourneyView(JourneyPlan journeyPlan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planDate = journeyPlan.date.toLocal();
    final isToday =
        DateTime(planDate.year, planDate.month, planDate.day) == today;
    final isInProgress = journeyPlan.statusText == 'In progress';
    final isCheckedIn = journeyPlan.statusText == 'Checked In';
    final isPending = journeyPlan.statusText == 'Pending';

    // Check if there are any in-progress journey plans for today
    final hasInProgressToday = _journeyPlans.any((plan) {
      final planDate = plan.date.toLocal();
      final planDateOnly =
          DateTime(planDate.year, planDate.month, planDate.day);
      return planDateOnly == today &&
          (plan.statusText == 'In progress' || plan.statusText == 'Checked In');
    });

    // Allow navigation if journey is in progress/checked in OR if it's pending with no in-progress JPs
    final canNavigate =
        isInProgress || isCheckedIn || (isPending && !hasInProgressToday);

    if (!isToday || !canNavigate) {
      HapticFeedback.vibrate();

      // Only show notification if one isn't already showing and it's a critical navigation restriction
      if (!_isShowingNotification && (!isToday || hasInProgressToday)) {
        _isShowingNotification = true;
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content:
                    const Text('Please complete the active journey plan first'),
                action: _activeVisit != null &&
                        _activeVisit!.id != journeyPlan.id &&
                        !isInProgress &&
                        !isCheckedIn
                    ? SnackBarAction(
                        label: 'Go to Active',
                        onPressed: () {
                          Get.to(
                            () => JourneyView(
                              journeyPlan: _activeVisit!,
                              onCheckInSuccess: (updatedPlan) {
                                setState(() {
                                  final index = _journeyPlans.indexWhere(
                                      (p) => p.id == updatedPlan.id);
                                  if (index != -1) {
                                    _journeyPlans[index] = updatedPlan;
                                  }
                                  _activeVisit = updatedPlan;
                                });
                                // Immediate UI update
                                _updateJourneyPlanStatus(
                                    updatedPlan.id!, updatedPlan.status);
                              },
                            ),
                            transition: Transition.rightToLeft,
                          );
                        },
                      )
                    : null,
              ),
            )
            .closed
            .then((_) {
          _isShowingNotification = false;
        });
      }
      return;
    }

    Get.to(
      () => JourneyView(
        journeyPlan: journeyPlan,
        onCheckInSuccess: (updatedPlan) {
          setState(() {
            final index =
                _journeyPlans.indexWhere((p) => p.id == updatedPlan.id);
            if (index != -1) _journeyPlans[index] = updatedPlan;
            _activeVisit = updatedPlan;
          });
          // Immediate UI update
          _updateJourneyPlanStatus(updatedPlan.id!, updatedPlan.status);
        },
      ),
      transition: Transition.rightToLeft,
    )?.then((result) {
      // Handle result from journey view (could be updated plan from checkout)
      if (result is JourneyPlan && mounted) {
        setState(() {
          final index = _journeyPlans.indexWhere((p) => p.id == result.id);
          if (index != -1) {
            _journeyPlans[index] = result;
          }
          // Update active visit if this was the active one
          if (_activeVisit?.id == result.id) {
            _activeVisit = result;
          }
        });
      } else if (mounted) {
        // Fallback refresh if no result returned
        _refreshJourneyPlanStatus(journeyPlan.id!);
      }
    });
  }

  // Add method to refresh specific journey plan status
  Future<void> _refreshJourneyPlanStatus(int journeyPlanId) async {
    try {
      // Use ultra-minimal method for fastest status update
      final basicStatus =
          await JourneyPlanService.getJourneyPlanBasicStatus(journeyPlanId);

      if (basicStatus != null && mounted) {
        setState(() {
          // Update journey plan in the list
          final index =
              _journeyPlans.indexWhere((p) => p.id == basicStatus['id']);
          if (index != -1) {
            // Preserve existing data, only update status
            final existingPlan = _journeyPlans[index];
            _journeyPlans[index] = JourneyPlan(
              id: existingPlan.id,
              date: existingPlan.date,
              time: existingPlan.time,
              salesRepId: existingPlan.salesRepId,
              status: basicStatus['status'], // Update status only
              notes: existingPlan.notes,
              checkInTime: existingPlan.checkInTime,
              latitude: existingPlan.latitude,
              longitude: existingPlan.longitude,
              imageUrl: existingPlan.imageUrl,
              client: existingPlan.client, // Keep existing client data
              checkoutTime: existingPlan.checkoutTime,
              checkoutLatitude: existingPlan.checkoutLatitude,
              checkoutLongitude: existingPlan.checkoutLongitude,
              showUpdateLocation: existingPlan.showUpdateLocation,
              routeId: existingPlan.routeId,
            );
          }

          // Update active visit if this was the active one
          if (_activeVisit?.id == basicStatus['id']) {
            _activeVisit = _journeyPlans[index];
          }
        });
      }
    } catch (e) {
      // Fallback to lightweight method if ultra-minimal fails
      try {
        final updatedPlan =
            await JourneyPlanService.getJourneyPlanCompletionStatus(
                journeyPlanId);
        if (updatedPlan != null && mounted) {
          setState(() {
            final index =
                _journeyPlans.indexWhere((p) => p.id == updatedPlan.id);
            if (index != -1) {
              final existingPlan = _journeyPlans[index];
              _journeyPlans[index] = JourneyPlan(
                id: existingPlan.id,
                date: existingPlan.date,
                time: existingPlan.time,
                salesRepId: existingPlan.salesRepId,
                status: updatedPlan.status,
                notes: existingPlan.notes,
                checkInTime: existingPlan.checkInTime,
                latitude: existingPlan.latitude,
                longitude: existingPlan.longitude,
                imageUrl: existingPlan.imageUrl,
                client: existingPlan.client,
                checkoutTime: existingPlan.checkoutTime,
                checkoutLatitude: existingPlan.checkoutLatitude,
                checkoutLongitude: updatedPlan.checkoutLongitude,
                showUpdateLocation: existingPlan.showUpdateLocation,
                routeId: existingPlan.routeId,
              );
            }
            if (_activeVisit?.id == updatedPlan.id) {
              _activeVisit = _journeyPlans[index];
            }
          });
        }
      } catch (e2) {
        // Final fallback to batch refresh
        await _batchRefreshJourneyPlanStatus([journeyPlanId]);
      }
    }
  }

  /// Batch refresh multiple journey plans in a single query (N+1 optimization)
  Future<void> _batchRefreshJourneyPlanStatus(List<int> journeyPlanIds) async {
    if (journeyPlanIds.isEmpty) return;

    try {
      // Get updated journey plans in a single batch query
      final updatedPlans =
          await JourneyPlanService.getJourneyPlansByIds(journeyPlanIds);

      if (updatedPlans.isNotEmpty && mounted) {
        setState(() {
          // Update journey plans in the list
          for (final updatedPlan in updatedPlans) {
            final index =
                _journeyPlans.indexWhere((p) => p.id == updatedPlan.id);
            if (index != -1) {
              _journeyPlans[index] = updatedPlan;
            }

            // Update active visit if this was the active one
            if (_activeVisit?.id == updatedPlan.id) {
              _activeVisit = updatedPlan;
            }
          }
        });
      }
    } catch (e) {
    }
  }

  void _hideJourneyPlan(int journeyPlanId) {
    setState(() {
      _hiddenJourneyPlans.add(journeyPlanId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Journey plan hidden'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _hiddenJourneyPlans.remove(journeyPlanId);
            });
          },
        ),
      ),
    );
  }

  Future<void> _deleteJourneyPlan(JourneyPlan journeyPlan) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journey Plan'),
        content: Text(
          'Are you sure you want to delete the journey plan for ${journeyPlan.client.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Call new service to delete journey plan
      await JourneyPlanService.deleteJourneyPlan(journeyPlan.id!);

      // Remove from local list
      setState(() {
        _journeyPlans.removeWhere((plan) => plan.id == journeyPlan.id);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Journey plan deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete journey plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Immediate UI update method for instant feedback
  void _updateJourneyPlanStatus(int journeyId, int newStatus) {
    setState(() {
      final index = _journeyPlans.indexWhere((plan) => plan.id == journeyId);
      if (index != -1) {
        final existingPlan = _journeyPlans[index];
        _journeyPlans[index] = JourneyPlan(
          id: existingPlan.id,
          date: existingPlan.date,
          time: existingPlan.time,
          salesRepId: existingPlan.salesRepId,
          status: newStatus,
          notes: existingPlan.notes,
          checkInTime: existingPlan.checkInTime,
          latitude: existingPlan.latitude,
          longitude: existingPlan.longitude,
          imageUrl: existingPlan.imageUrl,
          client: existingPlan.client,
          checkoutTime: existingPlan.checkoutTime,
          checkoutLatitude: existingPlan.checkoutLatitude,
          checkoutLongitude: existingPlan.checkoutLongitude,
          showUpdateLocation: existingPlan.showUpdateLocation,
          routeId: existingPlan.routeId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Journey Plans',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(_sortAscending ? Icons.sort : Icons.sort_by_alpha),
            tooltip: _sortAscending ? 'Sort Descending' : 'Sort Ascending',
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading && _journeyPlans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: const Center(
                    child: Text(
                      'My Journey Plans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _getFilteredPlans().isEmpty
                        ? const Center(child: Text('No journey plans found'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _getFilteredPlans().length +
                                (_hasMoreData ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _getFilteredPlans().length) {
                                return _isLoadingMore
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }

                              final journeyPlan = _getFilteredPlans()[index];
                              return JourneyPlanItem(
                                journeyPlan: journeyPlan,
                                onTap: () =>
                                    _navigateToJourneyView(journeyPlan),
                                onHide: journeyPlan.statusText == 'Completed' &&
                                        journeyPlan.id != null
                                    ? () => _hideJourneyPlan(journeyPlan.id!)
                                    : null,
                                onDelete: journeyPlan.statusText == 'Pending' &&
                                        journeyPlan.id != null
                                    ? () => _deleteJourneyPlan(journeyPlan)
                                    : null,
                                hasActiveVisit: _activeVisit != null &&
                                    _activeVisit!.id != journeyPlan.id,
                                activeVisit: _activeVisit,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateJourneyPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class JourneyPlanItem extends StatelessWidget {
  final JourneyPlan journeyPlan;
  final VoidCallback onTap;
  final VoidCallback? onHide;
  final VoidCallback? onDelete;
  final bool hasActiveVisit;
  final JourneyPlan? activeVisit;

  const JourneyPlanItem({
    super.key,
    required this.journeyPlan,
    required this.onTap,
    this.onHide,
    this.onDelete,
    required this.hasActiveVisit,
    this.activeVisit,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = journeyPlan.statusText == 'Completed';
    final isPending = journeyPlan.statusText == 'Pending';
    final clientName = journeyPlan.client.name;

    // Only disable if completed
    final shouldDisable = isCompleted;

    return Opacity(
      opacity: isCompleted ? 0.5 : 1.0,
      child: Card(
        key: ValueKey('journey_plan_${journeyPlan.id}'),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: InkWell(
          onTap: shouldDisable ? null : onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                // Left section: Action icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPending && onDelete != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          onPressed: onDelete,
                          tooltip: 'Delete journey plan',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Center section: Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(journeyPlan.date.toLocal()),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right section: Status and arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: journeyPlan.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        journeyPlan.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
