import 'package:flutter/material.dart';

enum SortOption { nameAsc, nameDesc, addressAsc, addressDesc }

enum DateFilter { all, today, thisWeek, thisMonth }

class ClientFilterPanel extends StatelessWidget {
  final bool showFilters;
  final SortOption sortOption;
  final DateFilter dateFilter;
  final bool showOnlyWithContact;
  final bool showOnlyWithEmail;
  final ValueChanged<SortOption> onSortChanged;
  final ValueChanged<DateFilter> onDateFilterChanged;
  final ValueChanged<bool> onContactFilterChanged;
  final ValueChanged<bool> onEmailFilterChanged;

  const ClientFilterPanel({
    super.key,
    required this.showFilters,
    required this.sortOption,
    required this.dateFilter,
    required this.showOnlyWithContact,
    required this.showOnlyWithEmail,
    required this.onSortChanged,
    required this.onDateFilterChanged,
    required this.onContactFilterChanged,
    required this.onEmailFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!showFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sort by:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    DropdownButton<SortOption>(
                      value: sortOption,
                      isExpanded: true,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                      items: const [
                        DropdownMenuItem(
                            value: SortOption.nameAsc,
                            child: Text('Name (A-Z)')),
                        DropdownMenuItem(
                            value: SortOption.nameDesc,
                            child: Text('Name (Z-A)')),
                        DropdownMenuItem(
                            value: SortOption.addressAsc,
                            child: Text('Address (A-Z)')),
                        DropdownMenuItem(
                            value: SortOption.addressDesc,
                            child: Text('Address (Z-A)')),
                      ],
                      onChanged: (value) {
                        if (value != null) onSortChanged(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date Range:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    DropdownButton<DateFilter>(
                      value: dateFilter,
                      isExpanded: true,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                      items: const [
                        DropdownMenuItem(
                            value: DateFilter.all, child: Text('All Time')),
                        DropdownMenuItem(
                            value: DateFilter.today, child: Text('Today')),
                        DropdownMenuItem(
                            value: DateFilter.thisWeek,
                            child: Text('This Week')),
                        DropdownMenuItem(
                            value: DateFilter.thisMonth,
                            child: Text('This Month')),
                      ],
                      onChanged: (value) {
                        if (value != null) onDateFilterChanged(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            children: [
              FilterChip(
                label:
                    const Text('Has Contact', style: TextStyle(fontSize: 11)),
                selected: showOnlyWithContact,
                onSelected: onContactFilterChanged,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Has Email', style: TextStyle(fontSize: 11)),
                selected: showOnlyWithEmail,
                onSelected: onEmailFilterChanged,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
