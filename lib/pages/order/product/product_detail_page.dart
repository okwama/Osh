import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/outlet_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/models/Products_Inventory/price_option_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/controllers/cart_controller.dart';
import 'package:woosh/pages/order/cart_page.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/utils/image_utils.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/services/core/currency_config_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailPage extends StatefulWidget {
  final Outlet outlet;
  final ProductModel product;
  final OrderModel? order;

  const ProductDetailPage({
    super.key,
    required this.outlet,
    required this.product,
    this.order,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final CartController _cartController = Get.find<CartController>();
  PriceOptionModel? _selectedPriceOption;
  int? _regionId;
  final _storage = GetStorage();

  // Performance optimizations
  int? _cachedAvailableStock;
  bool _isInitialized = false;
  bool _isStockLoading = true;
  bool _isCalculatingStock = false;

  // Memoized values to prevent recalculation
  String? _cachedProductName;
  String? _cachedPackSizeText;
  CurrencyConfig? _userCurrencyConfig;
  bool _hasDescription = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    // Pre-calculate static values once
    _cachedProductName = widget.product.name +
        (widget.product.packSize != null
            ? ' (Sold in packs of ${widget.product.packSize})'
            : '');
    _cachedPackSizeText = widget.product.packSize != null
        ? 'You are ordering in packs. 1 pack = ${widget.product.packSize} pieces.'
        : null;
    _hasDescription = widget.product.description?.isNotEmpty ?? false;

    // Get user data once
    final userData = _storage.read('salesRep');
    await _loadCurrencyConfig();

    if (userData != null) {
      _regionId = userData['region_id'];
      if (_regionId != null) {
        _calculateStockAvailability();
      } else {
        setState(() {
          _isStockLoading = false;
        });
      }
    } else {
      setState(() {
        _isStockLoading = false;
      });
    }

    // Set default price option
    if (widget.product.priceOptions.isNotEmpty) {
      _selectedPriceOption = widget.product.priceOptions.first;
    }

    setState(() {
      _isInitialized = true;
    });
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

  void _calculateStockAvailability() {
    if (_regionId == null) return;

    setState(() {
      _isCalculatingStock = true;
    });

    // Use compute for heavy calculations on a separate isolate
    Future.microtask(() {
      int stock = 0;
      try {
        final storeQuantity = widget.product.storeQuantities
            .firstWhere((sq) => sq.storeId == _regionId);
        stock = storeQuantity.quantity;
      } catch (e) {
        // No store quantity found for this region, use 0
        stock = 0;
      }

      if (mounted) {
        setState(() {
          _cachedAvailableStock = stock;
          _isCalculatingStock = false;
          _isStockLoading = false;
        });
      }
    });
  }

  int get _availableStock {
    if (_regionId == null) return 0;
    return _cachedAvailableStock ?? 0;
  }

  bool get _isOutOfStock => _availableStock <= 0;

  void _adjustQuantity(int delta) {
    if (_regionId == null) {
      Get.snackbar(
        'Error',
        'Cannot adjust quantity: No region assigned to your account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final currentValue = int.tryParse(_quantityController.text) ?? 0;
    final newValue = currentValue + delta;
    final maxStock = _cachedAvailableStock ?? 0;

    if (newValue > 0 && newValue <= maxStock) {
      _quantityController.text = newValue.toString();
    }
  }

  void _addToCart() {
    if (_regionId == null) {
      Get.snackbar(
        'Error',
        'Cannot add to cart: No region assigned to your account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedPriceOption == null) {
      Get.snackbar(
        'Error',
        'Please select a price option',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final quantityText = _quantityController.text;
    final quantity = int.tryParse(quantityText) ?? 0;
    final packSize = widget.product.packSize;

    // Prevent partial packs
    if (packSize != null) {
      if (quantity <= 0 ||
          quantityText.contains('.') ||
          int.tryParse(quantityText) == null) {
        Get.snackbar(
          'Error',
          'Please enter a valid whole number of packs (no decimals, no zero, no negative).',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    } else {
      if (quantity <= 0) {
        Get.snackbar(
          'Error',
          'Please enter a valid quantity',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Check stock availability using cached value
    final availableStock = _cachedAvailableStock ?? 0;
    if (quantity > availableStock) {
      Get.snackbar(
        'Error',
        'Not enough stock available in your region',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _cartController.addItem(
      OrderItem(
        productId: widget.product.id,
        quantity: quantity,
        product: widget.product,
        priceOptionId: _selectedPriceOption?.id,
      ),
    );

    // Show success message
    String successMsg = 'Item added to cart';
    if (widget.product.packSize != null) {
      final totalPieces = quantity * (widget.product.packSize ?? 1);
      successMsg = 'Added $quantity pack(s) ($totalPieces pieces) to cart';
    }
    Get.snackbar(
      'Success',
      successMsg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // Navigate to cart page
    Get.to(
      () => CartPage(
        outlet: widget.outlet,
        order: widget.order,
      ),
      transition: Transition.rightToLeft,
    );
  }

  Widget _buildStockStatus() {
    if (_isStockLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Checking stock...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final availableStock = _cachedAvailableStock ?? 0;
    final isOutOfStock = availableStock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutOfStock ? const Color(0xFFFDEDED) : const Color(0xFFEDF7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _regionId == null
            ? 'No region assigned to your account'
            : isOutOfStock
                ? 'Out of stock'
                : 'In stock',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _regionId == null
              ? const Color(0xFFD93025)
              : isOutOfStock
                  ? const Color(0xFFD93025)
                  : const Color(0xFF1E8E3E),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Get.back(),
          ),
          title: Text(
            widget.product.name,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final availableStock = _cachedAvailableStock ?? 0;
    final isOutOfStock = availableStock <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.product.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _CartIconButton(
            cartController: _cartController,
            outlet: widget.outlet,
            order: widget.order,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProductHeroImage(product: widget.product),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                // Product Name - use cached value
                Text(
                  _cachedProductName!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Stock Status
                _buildStockStatus(),

                const SizedBox(height: 24),

                // Quantity Selector - only show when stock is loaded and available
                if (!_isStockLoading && !isOutOfStock && availableStock > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isCalculatingStock)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading quantity options...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _QuantitySelector(
                        controller: _quantityController,
                        onDecrement: () => _adjustQuantity(-1),
                        onIncrement: () => _adjustQuantity(1),
                        maxQuantity: availableStock,
                      ),
                      if (_cachedPackSizeText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _cachedPackSizeText!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Price Options - memoized dropdown items
                if (widget.product.priceOptions.isNotEmpty) ...[
                  const Text(
                    'Select Price Option',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PriceOptionModel>(
                        value: _selectedPriceOption,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: _buildPriceOptionItems(),
                        onChanged: (PriceOptionModel? value) {
                          setState(() {
                            _selectedPriceOption = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 24),

                // Description - only build if exists
                if (_hasDescription) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 100), // Space for bottom button
              ]),
            ),
          ),
        ],
      ),

      // Add to Cart Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedPriceOption != null)
                Text(
                  'Selected Price: ${_formatPrice(_selectedPriceOption!.value?.toDouble() ?? 0.0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    (_isStockLoading || isOutOfStock) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 0),
                ),
                child: Text(
                  _isStockLoading
                      ? 'Checking Stock...'
                      : isOutOfStock
                          ? 'Out of Stock'
                          : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format price using dynamic currency configuration
  String _formatPrice(double price) {
    if (_userCurrencyConfig != null) {
      return CurrencyConfigService.formatCurrency(price, _userCurrencyConfig!);
    } else {
      // Fallback to basic formatting
      return '${_userCurrencyConfig?.currencySymbol ?? 'KES'} $price';
    }
  }

  // Memoized method to build price option items
  List<DropdownMenuItem<PriceOptionModel>> _buildPriceOptionItems() {
    return widget.product.priceOptions.map((option) {
      return DropdownMenuItem<PriceOptionModel>(
        value: option,
        child: Text(
          '${option.option} - ${_formatPrice(option.value?.toDouble() ?? 0.0)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }
}

// --- Optimized Custom Widgets ---

class _ProductHeroImage extends StatelessWidget {
  final ProductModel product;

  const _ProductHeroImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'product-image-${product.id}',
      child: Container(
        color: const Color(0xFFF8F8F8),
        child: product.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: ImageUtils.getDetailUrl(product.imageUrl!),
                fit: BoxFit.contain,
                placeholder: (context, url) => const _PlaceholderImage(),
                errorWidget: (context, url, error) => const _PlaceholderImage(),
                memCacheWidth: 800, // Optimize memory usage
                memCacheHeight: 600,
              )
            : const _PlaceholderImage(),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 80,
        color: Color(0xFFDDDDDD),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final int? maxQuantity;

  const _QuantitySelector({
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    this.maxQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: onDecrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
              SizedBox(
                width: 40,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  if (maxQuantity == null ||
                      int.parse(controller.text) < maxQuantity!) {
                    onIncrement();
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final CartController cartController;
  final Outlet outlet;
  final OrderModel? order;

  const _CartIconButton({
    required this.cartController,
    required this.outlet,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final itemCount = cartController.items.length;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon:
                const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
            onPressed: () => Get.to(
              () => CartPage(outlet: outlet, order: order),
              transition: Transition.fadeIn,
            ),
          ),
          if (itemCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  itemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }
}