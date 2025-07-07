import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/Products_Inventory/price_option_model.dart';
import 'package:woosh/services/core/order_service.dart';
import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/utils/country_currency_labels.dart';
import 'package:woosh/utils/date_utils.dart' as custom_date;
import 'package:get_storage/get_storage.dart';

class UpdateOrderPage extends StatefulWidget {
  final MyOrderModel order;

  const UpdateOrderPage({
    super.key,
    required this.order,
  });

  @override
  State<UpdateOrderPage> createState() => _UpdateOrderPageState();
}

class _UpdateOrderPageState extends State<UpdateOrderPage> {
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  bool _isUpdating = false;

  List<ProductModel> _products = [];
  List<OrderItem> _orderItems = [];
  List<OrderItem> _originalOrderItems = [];

  String _searchQuery = '';
  String _comment = '';

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final currencyFormat = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'Ksh ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.order.comment;
    _comment = widget.order.comment;
    _loadOrderItems();
    _loadProducts();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await OrderService.getOrderItems(widget.order.id);

      if (mounted) {
        setState(() {
          _orderItems = items;
          _originalOrderItems = List.from(items);
          _isLoading = false;
        });

        // Fix any invalid price option IDs after loading products
        if (_products.isNotEmpty) {
          for (final item in _orderItems) {
            final product = _products.firstWhere(
              (p) => p.id == item.productId,
              orElse: () => ProductModel(
                id: 0,
                name: '',
                categoryId: 1,
                category: '',
                unitCost: 0.0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                priceOptions: [],
              ),
            );
            _updateInvalidPriceOptionId(item, product.priceOptions);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Error',
          'Failed to load order items: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);

    try {
      // Get current user's country ID for product filtering
      final box = GetStorage();
      final salesRep = box.read('salesRep');
      final userCountryId = salesRep?['countryId'] ?? 1;

      final products = await ProductService.getProducts(
        page: 1,
        limit: 100, // Load more products for selection
        countryId: userCountryId,
        inStock: true, // Only show in-stock products
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });

        // Fix any invalid price option IDs in order items
        if (_orderItems.isNotEmpty) {
          for (final item in _orderItems) {
            final product = products.firstWhere(
              (p) => p.id == item.productId,
              orElse: () => ProductModel(
                id: 0,
                name: '',
                categoryId: 1,
                category: '',
                unitCost: 0.0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                priceOptions: [],
              ),
            );
            _updateInvalidPriceOptionId(item, product.priceOptions);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        Get.snackbar(
          'Error',
          'Failed to load products: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  List<ProductModel> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;

    return _products.where((product) {
      final name = product.name.toLowerCase();
      final description = product.description?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || description.contains(query);
    }).toList();
  }

  void _addProductToOrder(ProductModel product) {
    // Check if product already exists in order
    final existingIndex = _orderItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      // Increment quantity if product already exists
      setState(() {
        final existingItem = _orderItems[existingIndex];
        _orderItems[existingIndex] = OrderItem(
          id: existingItem.id,
          productId: existingItem.productId,
          quantity: existingItem.quantity + 1,
          product: existingItem.product,
          priceOptionId: existingItem.priceOptionId,
        );
      });
    } else {
      // Add new product with default price option
      final defaultPriceOption =
          product.priceOptions.isNotEmpty ? product.priceOptions.first : null;

      if (defaultPriceOption != null) {
        setState(() {
          _orderItems.add(OrderItem(
            productId: product.id,
            quantity: 1,
            product: product,
            priceOptionId: defaultPriceOption.id,
          ));
        });
      }
    }
  }

  void _updateOrderItemQuantity(OrderItem item, int newQuantity) {
    if (newQuantity <= 0) {
      _removeOrderItem(item);
      return;
    }

    setState(() {
      final index = _orderItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _orderItems[index] = OrderItem(
          id: item.id,
          productId: item.productId,
          quantity: newQuantity,
          product: item.product,
          priceOptionId: item.priceOptionId,
        );
      }
    });
  }

  void _updateOrderItemPriceOption(
      OrderItem item, PriceOptionModel newPriceOption) {
    setState(() {
      final index = _orderItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _orderItems[index] = OrderItem(
          id: item.id,
          productId: item.productId,
          quantity: item.quantity,
          product: item.product,
          priceOptionId: newPriceOption.id,
        );
      }
    });
  }

  /// Update price option ID when the current one is invalid
  void _updateInvalidPriceOptionId(
      OrderItem item, List<PriceOptionModel> priceOptions) {
    if (priceOptions.isEmpty) return;

    final validPriceOptionId =
        _getValidPriceOptionId(item.priceOptionId, priceOptions);
    if (validPriceOptionId != item.priceOptionId) {
      _updateOrderItemPriceOption(
          item, priceOptions.firstWhere((po) => po.id == validPriceOptionId));
    }
  }

  void _removeOrderItem(OrderItem item) {
    setState(() {
      _orderItems.removeWhere((i) => i.id == item.id);
    });
  }

  double get _totalAmount {
    return _orderItems.fold(0.0, (sum, item) {
      final product = item.product;
      if (product == null) return sum;

      final priceOption = product.priceOptions.firstWhere(
        (po) => po.id == item.priceOptionId,
        orElse: () =>
            product.priceOptions.firstOrNull ??
            PriceOptionModel(id: 0, option: '', value: 0, categoryId: 1),
      );

      return sum + (priceOption.value * item.quantity);
    });
  }

  bool get _hasChanges {
    if (_comment != widget.order.comment) return true;
    if (_orderItems.length != _originalOrderItems.length) return true;

    for (int i = 0; i < _orderItems.length; i++) {
      final current = _orderItems[i];
      final original = _originalOrderItems[i];

      if (current.productId != original.productId ||
          current.quantity != original.quantity ||
          current.priceOptionId != original.priceOptionId) {
        return true;
      }
    }

    return false;
  }

  /// Get a valid price option ID, falling back to the first available option if the current one doesn't exist
  int _getValidPriceOptionId(
      int? currentPriceOptionId, List<PriceOptionModel> priceOptions) {
    if (priceOptions.isEmpty) return 0;

    // Check if the current price option ID exists in the available options
    final exists =
        priceOptions.any((option) => option.id == currentPriceOptionId);

    if (exists) {
      return currentPriceOptionId!;
    } else {
      // Fall back to the first available option
      return priceOptions.first.id;
    }
  }

  Future<void> _saveOrder() async {
    if (!_hasChanges) {
      Get.back();
      return;
    }

    if (_orderItems.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add at least one product to the order',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // Convert order items to the format expected by the service
      final orderItemsData = _orderItems
          .map((item) => {
                'productId': item.productId,
                'quantity': item.quantity,
                'priceOptionId': item.priceOptionId,
              })
          .toList();

      final result = await OrderService.updateOrder(
        orderId: widget.order.id,
        orderItems: orderItemsData,
        comment: _comment,
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          'Order updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        Get.back(result: true); // Return true to indicate update
      } else {
        throw Exception(result['message'] ?? 'Failed to update order');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Update Order #${widget.order.id}',
        actions: [
          if (_hasChanges && !_isUpdating)
            TextButton(
              onPressed: _saveOrder,
              child: const Text(
                'Save',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Order Info Card
                _buildOrderInfoCard(),

                // Comment Section
                _buildCommentSection(),

                // Products Section
                Expanded(
                  child: Column(
                    children: [
                      _buildProductsHeader(),
                      Expanded(
                        child: _buildProductsSection(),
                      ),
                    ],
                  ),
                ),

                // Order Items Section
                _buildOrderItemsSection(),
              ],
            ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Order Date',
              custom_date.DateUtils.formatDateTime(widget.order.orderDate)),
          _buildInfoRow('Client ID', widget.order.clientId.toString()),
          _buildInfoRow('Status', 'Pending (Can be updated)'),
          _buildInfoRow(
              'Current Total',
              CountryCurrencyLabels.formatCurrency(
                  widget.order.totalAmount, null)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Comment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Add a comment to this order...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            onChanged: (value) => _comment = value,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Products',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No products available'
                  : 'No products found',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final priceOptions = product.priceOptions;
    final defaultPrice = priceOptions.isNotEmpty ? priceOptions.first.value : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: product.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    product.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.grey,
                    ),
                  ),
                )
              : const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.grey,
                ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.description?.isNotEmpty == true)
              Text(
                product.description!,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              'Price: ${CountryCurrencyLabels.formatCurrency(defaultPrice.toDouble(), null)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          onPressed: () => _addProductToOrder(product),
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Items (${_orderItems.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'Total: ${CountryCurrencyLabels.formatCurrency(_totalAmount, null)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_orderItems.isEmpty)
            _buildEmptyOrderItems()
          else
            ..._orderItems.map((item) => _buildOrderItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildEmptyOrderItems() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 36,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No items in order',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products from the list above',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    final product = item.product;
    if (product == null) return const SizedBox.shrink();

    final priceOptions = product.priceOptions;
    final currentPriceOption = priceOptions.firstWhere(
      (po) => po.id == item.priceOptionId,
      orElse: () =>
          priceOptions.firstOrNull ??
          PriceOptionModel(id: 0, option: '', value: 0, categoryId: 1),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.red),
                onPressed: () => _removeOrderItem(item),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Quantity controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () =>
                        _updateOrderItemQuantity(item, item.quantity - 1),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () =>
                        _updateOrderItemQuantity(item, item.quantity + 1),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Price option dropdown
              if (priceOptions.length > 1)
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: item.priceOptionId,
                    decoration: const InputDecoration(
                      labelText: 'Price Option',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    items: priceOptions.map((option) {
                      return DropdownMenuItem(
                        value: option.id,
                        child: Text(
                          '${option.option} - ${CountryCurrencyLabels.formatCurrency(option.value.toDouble(), null)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final selectedOption =
                            priceOptions.firstWhere((po) => po.id == value);
                        _updateOrderItemPriceOption(item, selectedOption);
                      }
                    },
                  ),
                )
              else
                Expanded(
                  child: Text(
                    'Price: ${CountryCurrencyLabels.formatCurrency(currentPriceOption.value.toDouble(), null)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Subtotal: ${CountryCurrencyLabels.formatCurrency((currentPriceOption.value.toDouble() * item.quantity), null)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
