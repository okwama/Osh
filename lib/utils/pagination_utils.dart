import 'package:flutter/material.dart';

class PaginationHelper {
  static bool shouldLoadMore(ScrollController scrollController) {
    return scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.8;
  }

  static Widget buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Widget buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class PaginatedData<T> {
  final List<T> items;
  final bool hasMore;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? error;

  PaginatedData({
    required this.items,
    required this.hasMore,
    required this.currentPage,
    required this.totalPages,
    this.isLoading = false,
    this.error,
  });

  PaginatedData<T> copyWith({
    List<T>? items,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    String? error,
  }) {
    return PaginatedData<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
