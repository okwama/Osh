import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

/// Date filter functionality for orders
class OrderDateFilter {
  String? dateFrom;
  String? dateTo;
  String selectedFilter = 'all'; // 'all', 'today', 'thisMonth', 'custom'

  /// Apply date filter
  Future<void> applyDateFilter(
      String filterType, Function() onFilterChanged) async {
    selectedFilter = filterType;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filterType) {
      case 'all':
        dateFrom = null;
        dateTo = null;
        break;
      case 'today':
        dateFrom = DateFormat('yyyy-MM-dd').format(today);
        dateTo = DateFormat('yyyy-MM-dd').format(today);
        break;
      case 'thisMonth':
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        dateFrom = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
        dateTo = DateFormat('yyyy-MM-dd').format(now);
        break;
      case 'custom':
        await showCustomDateRangeDialog(onFilterChanged);
        return; // Don't reload here, will reload after date selection
    }

    print(
        '🎯 Applied filter: $selectedFilter (dateFrom=$dateFrom, dateTo=$dateTo)');
    onFilterChanged();
  }

  /// Show custom date range picker dialog
  Future<void> showCustomDateRangeDialog(Function() onFilterChanged) async {
    final context = Get.context!;

    DateTimeRange? selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: dateFrom != null && dateTo != null
          ? DateTimeRange(
              start: DateFormat('yyyy-MM-dd').parse(dateFrom!),
              end: DateFormat('yyyy-MM-dd').parse(dateTo!),
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange != null) {
      dateFrom = DateFormat('yyyy-MM-dd').format(selectedRange.start);
      dateTo = DateFormat('yyyy-MM-dd').format(selectedRange.end);
      selectedFilter = 'custom';

      print(
          '🎯 Applied filter: $selectedFilter (dateFrom=$dateFrom, dateTo=$dateTo)');
      onFilterChanged();
    }
  }

  /// Clear all filters
  void clearFilters(Function() onFilterChanged) {
    selectedFilter = 'all';
    dateFrom = null;
    dateTo = null;
    onFilterChanged();
  }

  /// Get filter display text
  String getFilterDisplayText() {
    switch (selectedFilter) {
      case 'all':
        return 'All Orders';
      case 'today':
        return 'Today';
      case 'thisMonth':
        return 'This Month';
      case 'custom':
        if (dateFrom != null && dateTo != null) {
          final fromDate = DateFormat('MMM dd')
              .format(DateFormat('yyyy-MM-dd').parse(dateFrom!));
          final toDate = DateFormat('MMM dd')
              .format(DateFormat('yyyy-MM-dd').parse(dateTo!));
          return '$fromDate - $toDate';
        }
        return 'Custom Range';
      default:
        return 'All Orders';
    }
  }

  /// Show filter dialog
  void showFilterDialog(
      Function(String) onFilterSelected, Function() onClearFilters) {
    final context = Get.context!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.filter_list,
                color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            const Text('Filter Orders', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a date filter:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(context, 'all', 'All Orders',
                Icons.all_inclusive, onFilterSelected),
            _buildFilterOption(
                context, 'today', 'Today', Icons.today, onFilterSelected),
            _buildFilterOption(context, 'thisMonth', 'This Month',
                Icons.calendar_month, onFilterSelected),
            _buildFilterOption(context, 'custom', 'Custom Range',
                Icons.date_range, onFilterSelected),
            if (selectedFilter != 'all') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Get.back();
                  onClearFilters();
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear All Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Build filter option widget
  Widget _buildFilterOption(BuildContext context, String value, String label,
      IconData icon, Function(String) onFilterSelected) {
    final isSelected = selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Get.back();
          onFilterSelected(value);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

