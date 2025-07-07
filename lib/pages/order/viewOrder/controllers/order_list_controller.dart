import 'package:flutter/material.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/services/core/order_service.dart';

/// Controller for managing order list data and operations
class OrderListController {
  bool isLoading = false;
  bool isLoadingMore = false;
  List<MyOrderModel> orders = [];
  int page = 1;
  static const int limit = 10;
  bool hasMore = true;
  static const int prefetchThreshold = 200;
  static const int precachePages = 2;

  // Date filter variables
  String? dateFrom;
  String? dateTo;

  /// Load orders with current filters
  Future<void> loadOrders(Function() onStateChanged) async {
    if (isLoading) return;

    isLoading = true;
    page = 1;
    hasMore = true;
    orders = [];
    onStateChanged();

    try {
      print(
          '🔍 Loading orders with filters: dateFrom=$dateFrom, dateTo=$dateTo');
      final newOrders = await OrderService.getOrders(
        page: 1,
        limit: limit,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      print('📦 Loaded ${newOrders.length} orders');

      orders = newOrders;
      isLoading = false;
      hasMore = newOrders.length >= limit;
      onStateChanged();

      // Precache next pages if available
      if (hasMore) {
        precacheNextPages();
      }
    } catch (e) {
      isLoading = false;
      onStateChanged();
      // Auto-retry after delay
      Future.delayed(const Duration(seconds: 2), () {
        loadOrders(onStateChanged);
      });
    }
  }

  /// Precache next pages for better performance
  Future<void> precacheNextPages() async {
    if (!hasMore) return;

    final nextPage = page + 1;
    final endPage = nextPage + precachePages;

    for (int pageNum = nextPage; pageNum < endPage; pageNum++) {
      try {
        final newOrders = await OrderService.getOrders(
          page: pageNum,
          limit: limit,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );

        if (newOrders.isNotEmpty) {
          // Cache the data for future use with filter-specific key
          final cacheKey = getCacheKey(pageNum);
          OrderService.cacheData(
            cacheKey,
            newOrders,
            validity: const Duration(minutes: 5),
          );
        }
      } catch (e) {
        // Silently fail for precaching
        print('Precaching failed for page $pageNum: $e');
      }
    }
  }

  /// Load more orders for pagination
  Future<void> loadMoreOrders(Function() onStateChanged) async {
    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    onStateChanged();

    try {
      // Try to get cached data first
      final cacheKey = getCacheKey(page + 1);
      final cachedData =
          OrderService.getCachedData<List<MyOrderModel>>(cacheKey);

      if (cachedData != null) {
        orders.addAll(cachedData);
        page++;
        isLoadingMore = false;
        hasMore = page < precachePages + 1;
        onStateChanged();
        return;
      }

      // If no cached data, fetch from API
      final newOrders = await OrderService.getOrders(
        page: page + 1,
        limit: limit,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      orders.addAll(newOrders);
      page++;
      isLoadingMore = false;
      hasMore = newOrders.length >= limit;
      onStateChanged();

      // Precache next pages if available
      if (hasMore) {
        precacheNextPages();
      }
    } catch (e) {
      isLoadingMore = false;
      onStateChanged();
      // Auto-retry after delay
      Future.delayed(const Duration(seconds: 2), () {
        loadMoreOrders(onStateChanged);
      });
    }
  }

  /// Refresh orders
  Future<void> refreshOrders(Function() onStateChanged) async {
    try {
      isLoading = true;
      onStateChanged();

      // Clear existing cache before refresh
      for (int i = 1; i <= precachePages; i++) {
        final cacheKey = getCacheKey(i);
        OrderService.removeFromCache(cacheKey);
      }

      // Reset pagination state but keep existing orders
      page = 1;
      hasMore = true;

      // Load fresh data with current filters
      final newOrders = await OrderService.getOrders(
        page: 1,
        limit: limit,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      orders = newOrders;
      isLoading = false;
      hasMore = newOrders.length >= limit;
      onStateChanged();

      // Precache next pages if available
      if (hasMore) {
        precacheNextPages();
      }
    } catch (e) {
      isLoading = false;
      onStateChanged();
      rethrow;
    }
  }

  /// Refresh only a specific order by its ID
  Future<void> refreshSingleOrder(
      int orderId, Function() onStateChanged) async {
    try {
      // Find the current index of the order to update
      final currentIndex = orders.indexWhere((o) => o.id == orderId);
      if (currentIndex == -1) return; // Order not found in list

      // Store a reference to the current order for comparison later
      final currentOrder = orders[currentIndex];

      // Use the existing getOrders API with a small limit
      // This is more efficient than reloading all orders
      final newOrders = await OrderService.getOrders(
        page: 1,
        limit: 20,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      // Find the updated order in the response
      final updatedOrder = newOrders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => currentOrder, // Keep current if not found
      );

      // Update only this order in the list if it's different
      if (updatedOrder != currentOrder) {
        orders[currentIndex] = updatedOrder;
        onStateChanged();
      }
    } catch (e) {
      // Handle error silently - the old data is still valid
      print('Error refreshing order $orderId: $e');
    }
  }

  /// Update date filters
  void updateDateFilters(
      String? newDateFrom, String? newDateTo, Function() onStateChanged) {
    dateFrom = newDateFrom;
    dateTo = newDateTo;
    loadOrders(onStateChanged);
  }

  /// Get cache key based on current filter
  String getCacheKey(int pageNum) {
    if (dateFrom != null && dateTo != null) {
      return 'orders_page_${pageNum}_${dateFrom}_${dateTo}';
    }
    return 'orders_page_$pageNum';
  }

  /// Retry API call with exponential backoff
  Future<T> retryApiCall<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 15),
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await apiCall().timeout(timeout);
      } catch (e) {
        if (attempts >= maxRetries) {
          rethrow;
        }
        print('Retry attempt $attempts of $maxRetries after error: $e');
        await Future.delayed(retryDelay * attempts); // Exponential backoff
      }
    }
  }
}
