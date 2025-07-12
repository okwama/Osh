import 'package:get/get.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/core/client_storage_service.dart';
import 'package:woosh/services/search/index.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/widgets/client/client_filter_panel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ClientViewController extends GetxController {
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isOnline = true.obs;
  final RxList<Client> outlets = <Client>[].obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;
  final RxString searchQuery = ''.obs;

  // Filter observables
  final Rx<SortOption> sortOption = SortOption.nameAsc.obs;
  final RxBool showFilters = false.obs;
  final RxBool showOnlyWithContact = false.obs;
  final RxBool showOnlyWithEmail = false.obs;
  final Rx<DateFilter> dateFilter = DateFilter.all.obs;

  // Service instances
  late final ClientStorageService _clientStorageService;
  late final DatabaseService _db;
  late final UnifiedSearchService _searchService;

  // Private variables
  Timer? _debounce;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static const int _pageSize = 1000;
  static const int _prefetchThreshold = 200;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _initConnectivity();
    loadOutlets();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  void _initializeServices() {
    _clientStorageService = ClientStorageService.instance;
    _db = DatabaseService.instance;
    _searchService = UnifiedSearchService.instance;
  }

  Future<void> _initConnectivity() async {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      isOnline.value = results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);

      if (isOnline.value && outlets.isEmpty) {
        loadOutlets();
      }
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    isOnline.value = connectivityResult != ConnectivityResult.none;
  }

  Future<void> loadOutlets() async {
    if (!isOnline.value) {
      await _loadFromCache();
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    currentPage.value = 1;
    hasMore.value = true;

    try {
      await _clientStorageService.init();
      await _loadFromCache();

      final isSyncNeeded = await _clientStorageService.isSyncNeeded();

      if (isSyncNeeded) {
        print('🔄 Syncing clients with storage service...');

        try {
          final syncedClients = await _clientStorageService.syncClients();
          outlets.value = syncedClients;
          isLoading.value = false;
          hasMore.value = syncedClients.length >= _pageSize;
        } catch (e) {
          print('⚠️ Sync failed, using stored data: $e');
          final storedClients =
              await _clientStorageService.getAllStoredClients();
          outlets.value = storedClients;
          isLoading.value = false;
          hasMore.value = storedClients.length >= _pageSize;
        }
      } else {
        final storedClients = await _clientStorageService.getAllStoredClients();
        outlets.value = storedClients;
        isLoading.value = false;
        hasMore.value = storedClients.length >= _pageSize;
      }

      // Update hasMore based on total count
      final totalCount = await _clientStorageService.getTotalClientCount();
      hasMore.value = outlets.length < totalCount;
    } catch (e) {
      errorMessage.value =
          'Failed to load clients. ${outlets.isEmpty ? 'No stored data available.' : 'Showing stored data.'}';
      isLoading.value = false;
    }
  }

  Future<void> _loadFromCache() async {
    final storedClients = await _clientStorageService.getAllStoredClients();
    if (storedClients.isNotEmpty) {
      outlets.value = storedClients;
    }
  }

  Future<void> loadMoreOutlets() async {
    if (!isOnline.value || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;

    try {
      print('📍 Loading more clients from storage service...');

      final moreClients = await _clientStorageService.loadMoreClients(
        page: currentPage.value + 1,
        limit: _pageSize,
        appendToExisting: true,
      );

      outlets.value = moreClients;
      currentPage.value++;
      isLoadingMore.value = false;
      hasMore.value = moreClients.length >= _pageSize;

      print('✅ Loaded ${moreClients.length} more clients');
    } catch (e) {
      isLoadingMore.value = false;
      Get.snackbar(
        'Error',
        'Failed to load more clients: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    searchQuery.value = query;

    if (query.isNotEmpty) {
      isSearching.value = true;
    } else {
      isSearching.value = false;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        if (query.isNotEmpty) {
          final searchResult = await _searchService.searchClients(
            query: query,
            page: currentPage.value,
            limit: _pageSize,
            useCache: true,
          );

          outlets.value = searchResult.items;
          hasMore.value = searchResult.hasMore;
          await Future.delayed(const Duration(milliseconds: 200));
          isSearching.value = false;
        } else if (query.isEmpty) {
          isLoading.value = true;
          await loadOutlets();
          isLoading.value = false;
        }
      } catch (e) {
        isSearching.value = false;
        Get.snackbar(
          'Search Error',
          'Search failed: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  List<Client> get filteredOutlets {
    final query = searchQuery.value.toLowerCase().trim();

    // Filter outlets based on search query and filters
    List<Client> filtered = outlets.where((client) {
      // Search query filter
      if (query.isNotEmpty) {
        final matchesQuery = client.name.toLowerCase().contains(query) ||
            (client.address?.toLowerCase().contains(query) ?? false) ||
            (client.contact?.toLowerCase().contains(query) ?? false) ||
            (client.email?.toLowerCase().contains(query) ?? false);
        if (!matchesQuery) return false;
      }

      // Contact filter
      if (showOnlyWithContact.value && (client.contact?.isEmpty ?? true))
        return false;

      // Email filter
      if (showOnlyWithEmail.value && (client.email?.isEmpty ?? true))
        return false;

      return true;
    }).toList();

    // Apply date filter
    if (dateFilter.value != DateFilter.all) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      filtered = filtered.where((outlet) {
        final outletDate = outlet.createdAt;
        if (outletDate == null) return false;

        switch (dateFilter.value) {
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
    switch (sortOption.value) {
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

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void updateSortOption(SortOption option) {
    sortOption.value = option;
  }

  void updateDateFilter(DateFilter filter) {
    dateFilter.value = filter;
  }

  void updateContactFilter(bool value) {
    showOnlyWithContact.value = value;
  }

  void updateEmailFilter(bool value) {
    showOnlyWithEmail.value = value;
  }

  void clearSearch() {
    searchQuery.value = '';
    isSearching.value = false;
  }
}
