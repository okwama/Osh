import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/hive/client_model.dart';
import 'package:woosh/controllers/clientcontroler/client_view_controller.dart';
import 'package:woosh/pages/order/addorder_page.dart';
import 'package:woosh/pages/client/addclient_page.dart';
import 'package:woosh/pages/client/clientdetails.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';
import 'package:woosh/widgets/client/client_search_indicator.dart';
import 'package:woosh/widgets/client/client_empty_state.dart';
import 'package:woosh/widgets/client/client_filter_panel.dart';
import 'package:woosh/widgets/client/client_list_item.dart';
import 'package:woosh/widgets/client/client_filter_panel.dart';

class ViewClientPage extends StatefulWidget {
  final bool forOrderCreation;
  final bool forUpliftSale;
  final bool forProductReturn;

  const ViewClientPage({
    super.key,
    this.forOrderCreation = false,
    this.forUpliftSale = false,
    this.forProductReturn = false,
  });

  @override
  State<ViewClientPage> createState() => _ViewClientPageState();
}

class _ViewClientPageState extends State<ViewClientPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ClientViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ClientViewController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMoreOutlets();
    }
  }

  void _onSearchChanged(String query) {
    _controller.onSearchChanged(query);
  }

  void _onClientSelected(Client client) async {
    if (widget.forOrderCreation) {
      final result = await Get.to(
        () => AddOrderPage(outlet: client),
        transition: Transition.rightToLeft,
      );
      if (result == true) {
        Get.back(result: true);
      }
    } else if (widget.forUpliftSale) {
      final result = await Get.to(
        () => UpliftSaleCartPage(outlet: client),
        transition: Transition.rightToLeft,
      );
      if (result == true) {
        Get.back(result: true);
      }
    } else if (widget.forProductReturn) {
      final result = await Get.to(
        () => ProductReturnPage(client: client),
        transition: Transition.rightToLeft,
      );
      if (result == true) {
        Get.back(result: true);
      }
    } else {
      await Get.to(
        () => ClientDetailsPage(client: client),
        transition: Transition.rightToLeft,
      );
    }
  }

  List<Client> get _filteredOutlets {
    var outlets = _controller.outlets.toList();

    // Apply filters
    if (_controller.showOnlyWithContact.value) {
      outlets = outlets
          .where((client) => client.contact?.isNotEmpty == true)
          .toList();
    }

    if (_controller.showOnlyWithEmail.value) {
      outlets =
          outlets.where((client) => client.email?.isNotEmpty == true).toList();
    }

    // Apply sorting
    switch (_controller.sortOption.value) {
      case SortOption.nameAsc:
        outlets.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        outlets.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.addressAsc:
        outlets.sort((a, b) => a.address.compareTo(b.address));
        break;
      case SortOption.addressDesc:
        outlets.sort((a, b) => b.address.compareTo(a.address));
        break;
    }

    return outlets;
  }

  int get totalCount => _controller.outlets.length;
  int get filteredCount => _filteredOutlets.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: widget.forOrderCreation
            ? 'Select Client for Order'
            : widget.forUpliftSale
                ? 'Select Outlet for Uplift Sale'
                : widget.forProductReturn
                    ? 'Select Client for Product Return'
                    : 'Clients',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, size: 20),
            onPressed: () => _controller.showFilters.toggle(),
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _controller.loadOutlets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() => Column(
            children: [
              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Stack(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: _controller.isSearching.value
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : const Icon(Icons.search, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _controller.onSearchChanged('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: _onSearchChanged,
                    ),
                  ],
                ),
              ),
              // Filter Panel
              ClientFilterPanel(
                showFilters: _controller.showFilters.value,
                sortOption: _controller.sortOption.value,
                dateFilter: _controller.dateFilter.value,
                showOnlyWithContact: _controller.showOnlyWithContact.value,
                showOnlyWithEmail: _controller.showOnlyWithEmail.value,
                onSortChanged: (value) => _controller.sortOption.value = value,
                onDateFilterChanged: (value) =>
                    _controller.dateFilter.value = value,
                onContactFilterChanged: (value) =>
                    _controller.showOnlyWithContact.value = value,
                onEmailFilterChanged: (value) =>
                    _controller.showOnlyWithEmail.value = value,
              ),
              if (_controller.showFilters.value) const SizedBox(height: 6),
              // Search status and results count
              if (!_controller.isSearching.value &&
                  !_controller.isLoading.value)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Offline',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
              // Outlets List
              Expanded(
                child: _controller.isLoading.value &&
                        _controller.outlets.isEmpty
                    ? const ClientListSkeleton()
                    : _controller.isSearching.value
                        ? ClientSearchIndicator(
                            searchQuery: _searchController.text)
                        : _controller.errorMessage.value.isNotEmpty &&
                                _controller.outlets.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 36,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32),
                                      child: Text(
                                        _controller.errorMessage.value,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _controller.loadOutlets,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Retry',
                                          style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredOutlets.isEmpty
                                ? ClientEmptyState(
                                    searchQuery: _searchController.text,
                                    onAddClient: () async {
                                      final result = await Get.to(
                                          () => const AddClientPage());
                                      if (result == true && mounted) {
                                        _controller.loadOutlets();
                                      }
                                    },
                                  )
                                : RefreshIndicator(
                                    onRefresh: _controller.loadOutlets,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      itemCount: _filteredOutlets.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == _filteredOutlets.length) {
                                          return _buildListFooter();
                                        }

                                        final client = _filteredOutlets[index];
                                        return ClientListItem(
                                          client: client,
                                          onTap: () =>
                                              _onClientSelected(client),
                                        );
                                      },
                                    ),
                                  ),
              ),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const AddClientPage());
          if (result == true && mounted) {
            _controller.loadOutlets();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildListFooter() {
    if (_controller.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_controller.hasMore.value) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'No more clients to load',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
