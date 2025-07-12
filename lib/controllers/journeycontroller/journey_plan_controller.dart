import 'package:get/get.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/utils/error_handler.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/core/route_service.dart';

class JourneyPlanController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<JourneyPlan> journeyPlans = <JourneyPlan>[].obs;
  final Rx<JourneyPlan?> selectedJourneyPlan = Rx<JourneyPlan?>(null);
  final RxList<Client> searchResults = <Client>[].obs;
  final RxString errorMessage = ''.obs;
  final RxList<RouteOption> routeOptions = <RouteOption>[].obs;
  final RxInt selectedRouteId = 0.obs;

  // Client management
  final RxList<Client> filteredClients = <Client>[].obs;
  final RxBool isInitialLoad = true.obs;
  final RxBool isLoadingMoreClients = false.obs;
  final RxBool hasMoreDataToLoad = true.obs;
  final RxString searchQuery = ''.obs;

  // Date and notes
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString notes = ''.obs;

  // Journey plan creation
  final RxBool isCreatingJourneyPlans = false.obs;

  // Route loading
  final RxBool isLoadingRoutesData = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 JourneyPlanController initialized');
    loadRouteOptions();
  }

  /// Initialize clients with provided data or load from database
  Future<void> initializeClients({List<Client>? initialClients}) async {
    try {
      isInitialLoad.value = true;
      if (initialClients != null) {
        filteredClients.value = initialClients;
      } else {
        await loadClients();
      }
    } catch (e) {
      errorMessage.value = 'Failed to initialize clients: $e';
      print('❌ Error initializing clients: $e');
    } finally {
      isInitialLoad.value = false;
    }
  }

  /// Load clients from database
  Future<void> loadClients() async {
    try {
      isLoading.value = true;
      final clients = await JourneyPlanService.getClientsForJourneyPlan();
      filteredClients.value = clients;
    } catch (e) {
      errorMessage.value = 'Failed to load clients: $e';
      print('❌ Error loading clients: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more clients for pagination
  Future<void> loadMoreClients() async {
    if (isLoadingMoreClients.value || !hasMoreDataToLoad.value) return;

    try {
      isLoadingMoreClients.value = true;
      // TODO: Implement pagination logic
      // For now, just set hasMoreDataToLoad to false
      hasMoreDataToLoad.value = false;
    } catch (e) {
      errorMessage.value = 'Failed to load more clients: $e';
      print('❌ Error loading more clients: $e');
    } finally {
      isLoadingMoreClients.value = false;
    }
  }

  /// Update search query and filter clients
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _filterClients();
  }

  /// Filter clients based on search query
  void _filterClients() {
    if (searchQuery.value.isEmpty) {
      // Show all clients if no search query
      return;
    }

    final query = searchQuery.value.toLowerCase();
    final filtered = filteredClients
        .where((client) =>
            client.name.toLowerCase().contains(query) ||
            client.address.toLowerCase().contains(query))
        .toList();

    filteredClients.value = filtered;
  }

  /// Refresh clients list
  Future<void> refreshClients() async {
    await loadClients();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  /// Set notes
  void setNotes(String notesText) {
    notes.value = notesText;
  }

  /// Create journey plans for multiple clients
  Future<bool> createJourneyPlans(List<Client> clients) async {
    if (isCreatingJourneyPlans.value) return false;

    try {
      isCreatingJourneyPlans.value = true;

      for (final client in clients) {
        final success = await createJourneyPlan({
          'clientId': client.id,
          'date': selectedDate.value,
          'time': '09:00', // Default time
          'notes': notes.value,
          'routeId': selectedRouteId.value,
          'userId': null, // Will be set by service
        });

        if (!success) {
          return false;
        }
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create journey plans: $e';
      print('❌ Error creating journey plans: $e');
      return false;
    } finally {
      isCreatingJourneyPlans.value = false;
    }
  }

  /// Load route options
  Future<void> loadRouteOptions() async {
    try {
      isLoadingRoutesData.value = true;
      final options = await RouteService.getCachedRouteOptionsForCurrentUser();
      routeOptions.value = options;
    } catch (e) {
      errorMessage.value = 'Failed to load route options: $e';
      print('❌ Error loading route options: $e');
    } finally {
      isLoadingRoutesData.value = false;
    }
  }

  /// Get current user details
  Future<Map<String, dynamic>?> getCurrentUserDetails() async {
    try {
      print('🔍 Getting current user details');
      final result = await JourneyPlanService.getCurrentUserDetails();
      print('✅ Current user details retrieved');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to get user details: $e';
      print('❌ Error getting current user details: $e');
      return null;
    }
  }

  /// Search clients - using getClientsForJourneyPlan as fallback
  Future<List<Client>> searchClients(String query) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Searching clients with query: $query');

      // Use getClientsForJourneyPlan as the service doesn't have searchClients
      final result = await JourneyPlanService.getClientsForJourneyPlan();
      final filteredResults = result
          .where((client) =>
              client.name.toLowerCase().contains(query.toLowerCase()) ||
              client.address.toLowerCase().contains(query.toLowerCase()))
          .toList();

      searchResults.value = filteredResults;

      print('✅ Client search completed: ${filteredResults.length} results');
      return filteredResults;
    } catch (e) {
      errorMessage.value = 'Failed to search clients: $e';
      print('❌ Error searching clients: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new journey plan
  Future<bool> createJourneyPlan(Map<String, dynamic> journeyPlanData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Creating new journey plan');

      final result = await JourneyPlanService.createJourneyPlan(
        clientId: journeyPlanData['clientId'],
        date: journeyPlanData['date'],
        time: journeyPlanData['time'],
        notes: journeyPlanData['notes'],
        routeId: journeyPlanData['routeId'],
        userId: journeyPlanData['userId'],
      );

      print('✅ Journey plan created successfully: ${result.id}');
      // Refresh the journey plans list
      await getJourneyPlans();
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create journey plan: $e';
      print('❌ Error creating journey plan: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get journey plans with pagination and filtering
  Future<List<JourneyPlan>> getJourneyPlans({
    int page = 1,
    int limit = 20,
    int? status,
    DateTime? date,
    int? userId,
    int? routeId,
    bool excludePast = false,
  }) async {
    try {
      isLoading.value = true;
      final result = await JourneyPlanService.getJourneyPlans(
        page: page,
        limit: limit,
        status: status,
        date: date,
        userId: userId,
        routeId: routeId,
        excludePast: excludePast,
      );
      journeyPlans.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'JourneyPlanController.getJourneyPlans');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get multiple journey plans by IDs
  Future<List<JourneyPlan>> getJourneyPlansByIds(
      List<int> journeyPlanIds) async {
    try {
      isLoading.value = true;
      final result =
          await JourneyPlanService.getJourneyPlansByIds(journeyPlanIds);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'JourneyPlanController.getJourneyPlansByIds');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get a specific journey plan by ID
  Future<JourneyPlan?> getJourneyPlanById(int journeyPlanId) async {
    try {
      isLoading.value = true;
      final result = await JourneyPlanService.getJourneyPlanById(journeyPlanId);
      selectedJourneyPlan.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'JourneyPlanController.getJourneyPlanById');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get minimal journey plan data for completion status
  Future<JourneyPlan?> getJourneyPlanCompletionStatus(int journeyPlanId) async {
    try {
      isLoading.value = true;
      final result = await JourneyPlanService.getJourneyPlanCompletionStatus(
          journeyPlanId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'JourneyPlanController.getJourneyPlanCompletionStatus');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear journey plans list
  void clearJourneyPlans() {
    journeyPlans.clear();
  }

  /// Set selected journey plan
  void setSelectedJourneyPlan(JourneyPlan? plan) {
    selectedJourneyPlan.value = plan;
  }

  /// Clear search results
  void clearSearchResults() {
    searchResults.clear();
  }

  void setSelectedRoute(int routeId) {
    selectedRouteId.value = routeId;
  }
}
