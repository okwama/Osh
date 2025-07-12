import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/controllers/client_view_controller.dart';
import 'package:woosh/pages/order/addorder_page.dart';
import 'package:woosh/pages/client/addclient_page.dart';
import 'package:woosh/pages/client/clientdetails.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/client/client_search_widget.dart';
import 'package:woosh/widgets/client/client_list_widget.dart';
import 'package:woosh/widgets/client/client_filter_panel.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';

class ViewClientPageModular extends StatefulWidget {
  final bool forOrderCreation;
  final bool forUpliftSale;
  final bool forProductReturn;

  const ViewClientPageModular({
    super.key,
    this.forOrderCreation = false,
    this.forUpliftSale = false,
    this.forProductReturn = false,
  });

  @override
  State<ViewClientPageModular> createState() => _ViewClientPageModularState();
}

class _ViewClientPageModularState extends State<ViewClientPageModular> {
  late final ClientViewController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ClientViewController());
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_controller.isLoadingMore.value &&
        _controller.hasMore.value) {
      _controller.loadMoreOutlets();
    }
  }

  void _onSearchChanged() {
    _controller.onSearchChanged(_searchController.text);
  }

  void _onClientSelected(Client client) {
    if (widget.forOrderCreation) {
      Get.to(
        () => AddOrderPage(outlet: client),
        transition: Transition.rightToLeft,
      );
    } else if (widget.forUpliftSale) {
      Get.off(
        () => UpliftSaleCartPage(outlet: client),
        transition: Transition.rightToLeft,
      );
    } else if (widget.forProductReturn) {
      Get.to(
        () => ProductReturnPage(client: client),
        transition: Transition.rightToLeft,
      );
    } else {
      Get.to(
        () => ClientDetailsPage(client: client),
        transition: Transition.rightToLeft,
      );
    }
  }

  Future<void> _onAddClient() async {
    final result = await Get.to(() => const AddClientPage());
    if (result == true && mounted) {
      await _controller.loadOutlets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Clients (${_controller.outlets.length})',
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  _controller.showFilters.value
                      ? Icons.filter_list
                      : Icons.filter_list_outlined,
                  size: 20,
                ),
                onPressed: _controller.toggleFilters,
                tooltip: 'Filters',
              )),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _controller.loadOutlets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Widget
          Obx(() => ClientSearchWidget(
                controller: _searchController,
                isSearching: _controller.isSearching.value,
                onSearchChanged: _controller.onSearchChanged,
                onClear: _controller.clearSearch,
              )),

          // Filter Panel
          Obx(() => ClientFilterPanel(
                showFilters: _controller.showFilters.value,
                sortOption: _controller.sortOption.value,
                dateFilter: _controller.dateFilter.value,
                showOnlyWithContact: _controller.showOnlyWithContact.value,
                showOnlyWithEmail: _controller.showOnlyWithEmail.value,
                onSortChanged: _controller.updateSortOption,
                onDateFilterChanged: _controller.updateDateFilter,
                onContactFilterChanged: _controller.updateContactFilter,
                onEmailFilterChanged: _controller.updateEmailFilter,
              )),

          Obx(() => _controller.showFilters.value 
              ? const SizedBox(height: 6) 
              : const SizedBox.shrink()),

          // Status Bar
          _buildStatusBar(),

          // Client List
          Expanded(
            child: Obx(() => ClientListWidget(
                  clients: _controller.filteredOutlets,
                  isLoading: _controller.isLoading.value,
                  isSearching: _controller.isSearching.value,
                  isLoadingMore: _controller.isLoadingMore.value,
                  hasMore: _controller.hasMore.value,
                  errorMessage: _controller.errorMessage.value.isEmpty
                      ? null
                      : _controller.errorMessage.value,
                  searchQuery: _controller.searchQuery.value,
                  scrollController: _scrollController,
                  onClientSelected: _onClientSelected,
                  onRetry: _controller.loadOutlets,
                  onAddClient: _onAddClient,
                  onRefresh: _controller.loadOutlets,
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddClient,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Obx(() {
      if (_controller.isSearching.value || _controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      final filteredCount = _controller.filteredOutlets.length;
      final totalCount = _controller.outlets.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            if (filteredCount != totalCount)
              Text(
                'Showing $filteredCount of $totalCount clients',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const Spacer(),
            if (!_controller.isOnline.value)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(color: Colors.orange, fontSize: 10),
                ),
              ),
          ],
        ),
      );
    });
  }
}
