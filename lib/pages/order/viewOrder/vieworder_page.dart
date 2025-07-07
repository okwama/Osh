import 'package:flutter/material.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:get/get.dart';

// Import modular components
import 'widgets/order_date_filter.dart';
import 'widgets/filter_indicator.dart';
import 'widgets/order_list_item.dart';
import 'controllers/order_list_controller.dart';

class ViewOrdersPage extends StatefulWidget {
  const ViewOrdersPage({super.key});

  @override
  _ViewOrdersPageState createState() => _ViewOrdersPageState();
}

class _ViewOrdersPageState extends State<ViewOrdersPage> {
  // Controller for data management
  final OrderListController _controller = OrderListController();

  // Date filter
  final OrderDateFilter _dateFilter = OrderDateFilter();

  // UI state
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.loadOrders(_onStateChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            OrderListController.prefetchThreshold) {
      if (!_controller.isLoadingMore && _controller.hasMore) {
        _controller.loadMoreOrders(_onStateChanged);
      }
    }
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFilterSelected(String filterType) {
    _dateFilter.applyDateFilter(filterType, () {
      _controller.updateDateFilters(
          _dateFilter.dateFrom, _dateFilter.dateTo, _onStateChanged);
    });
  }

  void _onClearFilters() {
    _dateFilter.clearFilters(() {
      _controller.updateDateFilters(
          _dateFilter.dateFrom, _dateFilter.dateTo, _onStateChanged);
    });
  }

  Future<void> _refreshOrders() async {
    try {
      await _controller.refreshOrders(_onStateChanged);

      if (mounted) {
        Get.snackbar(
          'Success',
          'Orders refreshed successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to refresh orders',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'My Orders',
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _dateFilter.showFilterDialog(
                _onFilterSelected, _onClearFilters),
            tooltip: 'Filter Orders',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: _controller.isLoading && _controller.orders.isEmpty
          ? const OrdersListSkeleton()
          : RefreshIndicator(
              onRefresh: _refreshOrders,
              color: Theme.of(context).primaryColor,
              backgroundColor: Colors.white,
              strokeWidth: 2.0,
              displacement: 40.0,
              edgeOffset: 0.0,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Filter indicator
                  if (_dateFilter.selectedFilter != 'all')
                    SliverToBoxAdapter(
                      child: FilterIndicator(
                        filterText: _dateFilter.getFilterDisplayText(),
                        onClear: _onClearFilters,
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: _controller.orders.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const Text('No orders found'),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == _controller.orders.length) {
                                  return _controller.isLoadingMore
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }

                                final order = _controller.orders[index];

                                return OrderListItem(
                                  order: order,
                                  onOrderUpdated: () =>
                                      _controller.refreshSingleOrder(
                                          order.id, _onStateChanged),
                                );
                              },
                              childCount: _controller.orders.length +
                                  (_controller.hasMore ? 1 : 0),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
