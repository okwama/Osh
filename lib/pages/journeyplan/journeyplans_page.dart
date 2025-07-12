import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/pages/journeyplan/createJourneyplan_modular.dart';
import 'package:woosh/pages/journeyplan/journeyview_modular.dart';
import 'package:woosh/controllers/journeycontroller/journey_plans_controller.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/journey_plan/journey_plan_list_widget.dart';
import 'package:woosh/widgets/journey_plan/journey_plan_filters_widget.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/database_service.dart';
import 'package:get/get.dart';
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
  late final JourneyPlansController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _isShowingNotification = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(JourneyPlansController());
    WidgetsBinding.instance.addObserver(this);

    // Use preloaded data if available
    if (widget.preloadedClients != null) {
      _controller.clients.value = widget.preloadedClients!;
    }
    if (widget.preloadedPlans != null) {
      _controller.journeyPlans.value = widget.preloadedPlans!;
      _controller.isLoading.value = false;
    } else {
      // Show UI immediately, load data in background
      _controller.isLoading.value = true;
      // Start loading data immediately after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.loadDataFast();
      });
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when page becomes visible (e.g., returning from other screens)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.refreshJourneyPlans();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _controller.refreshJourneyPlans();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_controller.isLoadingMore.value && _controller.hasMoreData.value) {
        _controller.loadMoreData();
      }
    }
  }

  Future<void> _navigateToCreateJourneyPlan() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (_controller.clients.isEmpty) {
        await _controller.loadDataFast();
      }

      if (mounted) Get.back();

      if (mounted) {
        Get.to(
          () => CreateJourneyPlanPage(
            clients: _controller.clients,
            onSuccess: (newJourneyPlans) {
              if (newJourneyPlans.isNotEmpty) {
                _controller.journeyPlans.insert(0, newJourneyPlans[0]);
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
    final hasInProgressToday = _controller.journeyPlans.any((plan) {
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
                action: _controller.activeVisit.value != null &&
                        _controller.activeVisit.value!.id != journeyPlan.id &&
                        !isInProgress &&
                        !isCheckedIn
                    ? SnackBarAction(
                        label: 'Go to Active',
                        onPressed: () {
                          Get.to(
                            () => JourneyViewModular(
                              journeyPlan: _controller.activeVisit.value!,
                              onCheckInSuccess: (updatedPlan) {
                                _controller.updateJourneyPlanStatus(
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
      () => JourneyViewModular(
        journeyPlan: journeyPlan,
        onCheckInSuccess: (updatedPlan) {
          _controller.updateJourneyPlanStatus(
              updatedPlan.id!, updatedPlan.status);
        },
      ),
      transition: Transition.rightToLeft,
    )?.then((result) {
      // Handle result from journey view (could be updated plan from checkout)
      if (result is JourneyPlan && mounted) {
        _controller.refreshJourneyPlanStatus(result.id!);
      } else if (mounted) {
        // Fallback refresh if no result returned
        _controller.refreshJourneyPlanStatus(journeyPlan.id!);
      }
    });
  }

  void _hideJourneyPlan(int journeyPlanId) {
    _controller.hideJourneyPlan(journeyPlanId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Journey plan hidden'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _controller.showJourneyPlan(journeyPlanId);
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

    await _controller.deleteJourneyPlan(journeyPlan);
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
          JourneyPlanAppBarActions(
            controller: _controller,
            onRefresh: _controller.loadDataFast,
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.journeyPlans.isEmpty) {
          return const JourneyPlanLoadingShimmer();
        }

        return Column(
              children: [
            JourneyPlanFiltersWidget(
              controller: _controller,
              onRefresh: _controller.loadDataFast,
                ),
                Expanded(
              child: JourneyPlanListWidget(
                controller: _controller,
                onJourneyPlanTap: _navigateToJourneyView,
                onHideJourneyPlan: _hideJourneyPlan,
                onDeleteJourneyPlan: _deleteJourneyPlan,
                scrollController: _scrollController,
                  ),
                ),
              ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateJourneyPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
