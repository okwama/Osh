import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/models/outlet_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/services/core/currency_config_service.dart';

import 'package:woosh/pages/order/product/product_detail_page.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/utils/image_utils.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/services/hive/product_hive_service.dart';
import 'package:woosh/models/hive/product_model.dart';
import 'package:woosh/services/core/stock_service.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:get_storage/get_storage.dart';

class ProductsGridPage extends StatefulWidget {
  final Outlet outlet;
  final OrderModel? order;

  const ProductsGridPage({
    super.key,
    required this.outlet,
    this.order,
  });

  @override
  _ProductsGridPageState createState() => _ProductsGridPageState();
}

class _ProductsGridPageState extends State<ProductsGridPage>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  List<ProductModel> _products = [];
  bool _hasMoreData = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  String _currentSearchQuery = '';
  late ProductHiveService _productHiveService;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;

  // Currency configuration
  CurrencyConfig? _userCurrencyConfig;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
    _scrollController.addListener(_onScroll);
    _setupConnectivityListener();
    _loadCurrencyConfig();
  }

  Future<void> _loadCurrencyConfig() async {
    try {
      _userCurrencyConfig =
          await CurrencyConfigService.getCurrentUserCurrencyConfig();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
    }
  }

  // Helper method to ensure Hive adapters are registered
  void ensureProductHiveAdapterRegistered() {
    // This method is called to ensure Hive adapters are registered
    // The actual registration should be done in the app initialization
    // For now, we'll just check if the service is available
  }

  Future<void> _initializeAndLoad() async {
    try {
      ensureProductHiveAdapterRegistered();

      // Try to get the ProductHiveService from Get
      if (Get.isRegistered<ProductHiveService>()) {
        _productHiveService = Get.find<ProductHiveService>();
      } else {
        _productHiveService = ProductHiveService();
        await _productHiveService.init();
        Get.put(_productHiveService);
      }

      // Load data
      await _loadFromCacheAndApi();
    } catch (e) {
      _loadInitialData();
    }
  }

  // Calculate responsive grid parameters
  Map<String, dynamic> _getGridParameters(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (screenWidth < mobileBreakpoint) {
      // Mobile: 2 columns
      crossAxisCount = 2;
      childAspectRatio = 0.75;
      spacing = 8.0;
    } else if (screenWidth < tabletBreakpoint) {
      // Tablet: 3 columns
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      spacing = 12.0;
    } else {
      // Desktop: 4+ columns
      crossAxisCount = (screenWidth / 250).floor().clamp(4, 6);
      childAspectRatio = 0.85;
      spacing = 16.0;
    }

    return {
      'crossAxisCount': crossAxisCount,
      'childAspectRatio': childAspectRatio,
      'spacing': spacing,
    };
  }

  List<ProductModel> _getFilteredProducts() {
    final query = _currentSearchQuery.toLowerCase();
    if (query.isEmpty) return _products;

    // Enhanced search with multiple terms
    final searchTerms = query.split(' ').where((term) => term.isNotEmpty);

    return _products.where((product) {
      final productName = product.name.toLowerCase();
      final productDesc = (product.description ?? '').toLowerCase();

      // Check if all search terms are found in either name or description
      return searchTerms.every(
          (term) => productName.contains(term) || productDesc.contains(term));
    }).toList();
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_currentSearchQuery != query) {
        setState(() {
          _currentSearchQuery = query;
        });

        // For search, we can use cached data if available and search locally
        if (query.isEmpty) {
          // If search is cleared, show all cached products
          setState(() {
            _isLoading = false;
          });
        } else if (query.length >= 2) {
          // For search queries, try to use cached data first
          final filteredProducts = _getFilteredProducts();
          if (filteredProducts.isNotEmpty) {
            // We have matching cached data, no need to fetch
            setState(() {
              _isLoading = false;
            });
          } else {
            // No matching cached data, fetch from API
          _loadInitialData();
          }
        }
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      // Force refresh by clearing cache timestamp and fetching fresh data
      await _productHiveService
          .setLastUpdateTime(DateTime.now().subtract(const Duration(hours: 1)));
      await _loadInitialData();
      await _loadCurrencyConfig(); // Refresh currency config

      // Refresh stock service cache
      await StockService.instance.refreshCache();

    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadFromCacheAndApi() async {
    // Always load from cache first for instant display
    await _loadFromCache();

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isConnected = connectivityResult != ConnectivityResult.none;

    // Check if cache is fresh (less than 5 minutes old)
    final lastUpdate = await _productHiveService.getLastUpdateTime();
    final isCacheFresh = lastUpdate != null &&
        DateTime.now().difference(lastUpdate).inMinutes < 5;

    // Only fetch from API if:
    // 1. We have internet connection AND
    // 2. Cache is not fresh OR we have no cached data
    if (_isConnected && (!isCacheFresh || _products.isEmpty)) {
      await _loadInitialData();
    } else if (_isConnected && isCacheFresh) {
      print(
          '[ProductsGrid] Using fresh cached data (${_products.length} products)');
      setState(() {
        _isLoading = false;
      });
    } else if (!_isConnected && _products.isEmpty) {
      setState(() {
        _error = 'No internet connection and no cached data available.';
        _isLoading = false;
      });
    } else if (!_isConnected) {
      print(
          '[ProductsGrid] Offline mode - using cached data (${_products.length} products)');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromCache() async {
    if (_products.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final cachedProducts = await _productHiveService.getAllProductModels();
      if (cachedProducts.isNotEmpty) {
        print(
            '[ProductsGrid] Loaded ${cachedProducts.length} products from cache');

        if (mounted) {
          setState(() {
            _products = cachedProducts;
            _isLoading = false;
          });
        }
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> _loadInitialData() async {
    if (!_isConnected && _products.isNotEmpty) {
      return; // Don't load if offline and we have cached data
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await ProductService.getProducts(
        page: 1,
        limit: 50, // Increased limit for better caching
        search: _currentSearchQuery,
        clientId: widget.outlet.id,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });

        // Always save to cache when we get fresh data
        await _saveToCache(products);
        print(
            '[ProductsGrid] ✅ Successfully cached ${products.length} products');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _isConnected
              ? 'Failed to load products. Please try again.'
              : 'No internet connection. Showing cached data.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveToCache(List<ProductModel> products) async {
    try {
      if (Get.isRegistered<ProductHiveService>()) {
        await _productHiveService.saveProducts(products);
        await _productHiveService.setLastUpdateTime(DateTime.now());
        print(
            '[ProductsGrid] 💾 Cached ${products.length} products successfully');
      } else {
        print(
            '[ProductsGrid] ⚠️ ProductHiveService not registered, cannot cache');
      }
    } catch (e) {
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _isLoading || !_isConnected) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // For now, we'll just set hasMoreData to false since we're not implementing pagination
        setState(() {
        _hasMoreData = false;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load more products';
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreData();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      setState(() {
        _isConnected = results.isNotEmpty &&
            results.any((result) => result != ConnectivityResult.none);
      });
    });
  }

  Widget _buildProductCard(ProductModel product, int index, double spacing) {
    // Don't show stock status until confirmed - use basic info only
    final hasStockData = product.storeQuantities.isNotEmpty;

    // Format price using dynamic currency configuration
    String formattedPrice = 'Price not available';
    if (product.priceOptions.isNotEmpty) {
      final price = product.priceOptions.first.value.toDouble();
      if (_userCurrencyConfig != null) {
        formattedPrice =
            CurrencyConfigService.formatCurrency(price, _userCurrencyConfig!);
      } else {
        // Fallback to basic formatting
        formattedPrice =
            '${_userCurrencyConfig?.currencySymbol ?? 'KES'} $price';
      }
    }

    return Card(
      key: ValueKey('product_${product.id}_$index'),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Stock data is already pre-loaded, no need to calculate
          Get.to(
            () => ProductDetailPage(
              outlet: widget.outlet,
              product: product,
              order: widget.order,
            ),
            preventDuplicates: true,
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 13,
              child: Stack(
                children: [
                  Hero(
                    tag: 'product_image_${product.id}',
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: product.imageUrl?.isNotEmpty ?? false
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: CachedNetworkImage(
                                imageUrl:
                                    ImageUtils.getGridUrl(product.imageUrl!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[100],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 32,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Image not available',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No image',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  // Stock status badge - only show if stock data is available
                  if (hasStockData)
                  Positioned(
                    top: 8,
                    right: 8,
                      child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                        child: const Text(
                          'Stock Available',
                          style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.priceOptions.isNotEmpty)
                          Expanded(
                            child: Text(
                              formattedPrice,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        if (hasStockData)
                          Text(
                            'Stock Info Available',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(double spacing) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Text(
            'You\'re offline. Showing cached data.',
            style: TextStyle(
              color: Colors.orange[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _currentSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filteredProducts = _getFilteredProducts();
    final bool isInitialLoading = _isLoading && _products.isEmpty;

    // Use FutureBuilder to handle the async lastUpdate
    return FutureBuilder<DateTime?>(
      future: Get.isRegistered<ProductHiveService>()
          ? Get.find<ProductHiveService>().getLastUpdateTime()
          : Future.value(null),
      builder: (context, snapshot) {
        final DateTime? lastUpdate = snapshot.data;

        return Scaffold(
          backgroundColor: appBackground,
          appBar: GradientAppBar(
            title: widget.outlet.name,
            actions: [
              if (_isConnected)
                IconButton(
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isRefreshing ? null : _refreshData,
                  tooltip: 'Refresh',
                ),
              if (lastUpdate != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Tooltip(
                    message:
                        'Last updated: ${lastUpdate.toString().substring(0, 16)}\n${_products.length} products cached',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cached, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_products.length}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          body: isInitialLoading
              ? GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 6, // Show 6 skeleton cards while loading
                  itemBuilder: (context, index) => _buildSkeletonCard(8.0),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _currentSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_currentSearchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              key: const PageStorageKey('products_grid'),
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filteredProducts.length +
                                  (_hasMoreData ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredProducts.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                return _buildProductCard(
                                    filteredProducts[index], index, 8.0);
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentSearchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _currentSearchQuery.isNotEmpty
                ? 'No products found'
                : 'No products available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentSearchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Products will appear here when available',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_currentSearchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }
}