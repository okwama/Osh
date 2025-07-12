import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database_service.dart';
import 'dart:async';

class JourneyPlansController extends GetxController
    with WidgetsBindingObserver {
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxList<Client> clients = <Client>[].obs;
  final RxList<JourneyPlan> journeyPlans = <JourneyPlan>[].obs;
  final RxSet<int> hiddenJourneyPlans = <int>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;
  final Rx<JourneyPlan?> activeVisit = Rx<JourneyPlan?>(null);
  final RxBool isShowingNotification = false.obs;
  final RxBool sortAscending = true.obs;

  // Service instances
  late final DatabaseService _db;
  late final PaginationService _paginationService;

  // Private variables
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void _initializeServices() {
    _db = DatabaseService.instance;
    _paginationService = PaginationService.instance;
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (journeyPlans.isNotEmpty) {
        _refreshJourneyPlanStatuses();
      }
    });
  }

  Future<void> loadDataFast() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Load journey plans and clients in parallel
      final results = await Future.wait([
        JourneyPlanService.getJourneyPlans(
          page: 1,
          excludePast: true,
        ),
        _fetchClients(),
      ]);

      journeyPlans.value = results[0] as List<JourneyPlan>;
      clients.value = results[1] as List<Client>;

      // Check for active visit
      _checkActiveVisit();
    } catch (e) {
      errorMessage.value = 'Failed to load journey plans: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Client>> _fetchClients() async {
    try {
      // Get current user's country ID for filtering
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

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
        whereParams: [],
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
    } catch (e) {
      print('❌ Error in JourneyPlansController [_fetchClients]: $e');
      return [];
    }
  }

  void _checkActiveVisit() {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final activePlans = journeyPlans.where((plan) {
        final planDate = plan.date.toLocal();
        final planDateOnly =
            DateTime(planDate.year, planDate.month, planDate.day);
        return planDateOnly == today &&
            (plan.status == JourneyPlan.statusInProgress ||
                plan.status == JourneyPlan.statusCheckedIn);
      }).toList();

      if (activePlans.isNotEmpty) {
        activeVisit.value = activePlans.first;
      }
    } catch (e) {
      print('❌ Error in JourneyPlansController [_checkActiveVisit]: $e');
    }
  }

  Future<void> refreshJourneyPlans() async {
    try {
      final plans = await JourneyPlanService.getJourneyPlans(
        page: 1,
        excludePast: true,
      );
      journeyPlans.value = plans;
      _checkActiveVisit();
    } catch (e) {
      print('❌ Error in JourneyPlansController [refreshJourneyPlans]: $e');
    }
  }

  Future<void> _refreshJourneyPlanStatuses() async {
    try {
      final planIds = journeyPlans.map((p) => p.id!).toList();
      if (planIds.isEmpty) return;

      final updatedPlans =
          await JourneyPlanService.getJourneyPlansByIds(planIds);

      if (updatedPlans.isNotEmpty) {
        // Update journey plans in the list
        for (final updatedPlan in updatedPlans) {
          final index = journeyPlans.indexWhere((p) => p.id == updatedPlan.id);
          if (index != -1) {
            journeyPlans[index] = updatedPlan;
          }

          // Update active visit if this was the active one
          if (activeVisit.value?.id == updatedPlan.id) {
            activeVisit.value = updatedPlan;
          }
        }
      }
    } catch (e) {
      print(
          '❌ Error in JourneyPlansController [_refreshJourneyPlanStatuses]: $e');
    }
  }

  Future<void> refreshJourneyPlanStatus(int journeyPlanId) async {
    try {
      final basicStatus =
          await JourneyPlanService.getJourneyPlanBasicStatus(journeyPlanId);

      if (basicStatus != null) {
        // Update journey plan in the list
        final index = journeyPlans.indexWhere((p) => p.id == basicStatus['id']);
        if (index != -1) {
          // Preserve existing data, only update status
          final existingPlan = journeyPlans[index];
          journeyPlans[index] = JourneyPlan(
            id: existingPlan.id,
            date: existingPlan.date,
            time: existingPlan.time,
            salesRepId: existingPlan.salesRepId,
            status: basicStatus['status'],
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

        // Update active visit if this was the active one
        if (activeVisit.value?.id == basicStatus['id']) {
          activeVisit.value = journeyPlans[index];
        }
      }
    } catch (e) {
      print('❌ Error in JourneyPlansController [refreshJourneyPlanStatus]: $e');
    }
  }

  void hideJourneyPlan(int journeyPlanId) {
    hiddenJourneyPlans.add(journeyPlanId);
  }

  void showJourneyPlan(int journeyPlanId) {
    hiddenJourneyPlans.remove(journeyPlanId);
  }

  Future<void> deleteJourneyPlan(JourneyPlan journeyPlan) async {
    try {
      await JourneyPlanService.deleteJourneyPlan(journeyPlan.id!);
      journeyPlans.removeWhere((plan) => plan.id == journeyPlan.id);

      Get.snackbar(
        'Success',
        'Journey plan deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error in JourneyPlansController [deleteJourneyPlan]: $e');
      Get.snackbar(
        'Error',
        'Failed to delete journey plan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void updateJourneyPlanStatus(int journeyId, int newStatus) {
    final index = journeyPlans.indexWhere((plan) => plan.id == journeyId);
    if (index != -1) {
      final existingPlan = journeyPlans[index];
      journeyPlans[index] = JourneyPlan(
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
  }

  List<JourneyPlan> get visibleJourneyPlans {
    return journeyPlans
        .where((plan) => !hiddenJourneyPlans.contains(plan.id))
        .toList();
  }

  List<JourneyPlan> getFilteredPlans() {
    var filteredPlans = visibleJourneyPlans;

    // Sort by creation date (newest first when ascending, oldest first when descending)
    filteredPlans.sort((a, b) {
      if (sortAscending.value) {
        // Newest first (descending by date)
        return b.date.compareTo(a.date);
      } else {
        // Oldest first (ascending by date)
        return a.date.compareTo(b.date);
      }
    });

    return filteredPlans;
  }

  Future<void> loadMoreData() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    isLoadingMore.value = true;

    try {
      final newPlans = await JourneyPlanService.getJourneyPlans(
        page: currentPage.value + 1,
        excludePast: true,
      );

      if (newPlans.isEmpty) {
        hasMoreData.value = false;
      } else {
        journeyPlans.addAll(newPlans);
        currentPage.value++;
      }
    } catch (e) {
      print('❌ Error in JourneyPlansController [loadMoreData]: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void toggleSortOrder() {
    sortAscending.value = !sortAscending.value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      refreshJourneyPlans();
    }
  }
}
