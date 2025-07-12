import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/controllers/cart_controller.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';
import 'package:woosh/pages/order/product/products_grid_page.dart';
import 'package:woosh/utils/image_utils.dart';
import 'package:woosh/models/Products_Inventory/store_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:woosh/services/core/currency_config_service.dart';
import 'package:woosh/services/core/order_service.dart';
import 'package:woosh/services/core/store_service.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';

class CartPage extends StatefulWidget {
  final Client outlet;
  final OrderModel? order;

  const CartPage({
    super.key,
    required this.outlet,
    this.order,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with WidgetsBindingObserver {
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Store?> selectedStore = Rx<Store?>(null);
  final RxList<Store> availableStores = <Store>[].obs;
  final Rx<dynamic> selectedImage =
      Rx<dynamic>(null); // For storing selected image
  final RxString comment = ''.obs; // Add comment field
  final TextEditingController commentController =
      TextEditingController(); // Add controller
  final ImagePicker _picker = ImagePicker();

  // Currency configuration
  CurrencyConfig? _userCurrencyConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStores();
    _loadCurrencyConfig();
  }

  Future<void> _loadCurrencyConfig() async {
    try {
      _userCurrencyConfig =
          await CurrencyConfigService.getCurrentUserCurrencyConfig();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    commentController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    ImageCache().clear();
    ImageCache().clearLiveImages();
  }

  Future<void> _loadStores() async {
    try {
      isLoading.value = true;

      // Get user's region and country from GetStorage
      final box = GetStorage();
      final salesRep = box.read('salesRep');
      final userRegionId = salesRep?['region_id'];
      final userCountryId = salesRep?['countryId'];

      print(
          'User context - Region ID: $userRegionId, Country ID: $userCountryId');

      // Use the country ID from user data, fallback to outlet country
      final countryId = userCountryId ?? widget.outlet.countryId;

      if (countryId == null) {
        Get.snackbar(
          'Error',
          'Unable to determine your country. Please contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (userRegionId != null) {}

      // Fetch stores from database
      var stores = await StoreService.getStoresForUser(countryId, userRegionId);

      print(
          '✅ [CartPage] Total stores received from database: ${stores.length}');
      if (stores.isNotEmpty) {
        print(
            '📋 [CartPage] Available stores: ${stores.map((s) => '${s.name} (${s.region?.name ?? 'No Region'})').join(', ')}');
      } else {
        // If no stores found for specific region, try to get all stores in the country
        if (userRegionId != null) {
          print(
              '📋 [CartPage] Trying to get all stores in country without region filter...');
          stores = await StoreService.getStoresForUser(countryId, null);
          print(
              '✅ [CartPage] Found ${stores.length} stores in country (no region filter)');
          if (stores.isNotEmpty) {
            print(
                '📋 [CartPage] Available stores: ${stores.map((s) => '${s.name} (${s.region?.name ?? 'No Region'})').join(', ')}');
          }
        }
      }

      availableStores.value = stores;

      if (stores.isNotEmpty) {
        selectedStore.value = stores.first;
        if (selectedStore.value?.region != null) {
          print(
              '📋 [CartPage] Store region: ${selectedStore.value!.region!.name}');
          if (selectedStore.value!.region!.country != null) {
            print(
                '📋 [CartPage] Store country: ${selectedStore.value!.region!.country!.name}');
          }
        }
      } else {
        // Show a message if no stores are available for the country
        Get.snackbar(
          'No Stores Available',
          'There are no stores available in your country (ID: $countryId). Please contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load stores. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showOrderSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Order Successful'),
          ],
        ),
        content: const Text('Your order has been placed successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offNamed('/orders'); // Go to orders page
            },
            child: const Text('View Orders'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              // Navigate to products grid to add more items
              Get.offNamed('/products');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add More'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image
      );

      if (image != null) {
        selectedImage.value = image;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> placeOrder() async {
    try {
      isLoading.value = true;

      if (selectedStore.value == null) {
        Get.snackbar(
          'Error',
          'Please select a store',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final outletId = widget.outlet.id;

      if (cartController.items.isEmpty) {
        Get.snackbar(
          'Error',
          'Cart is empty',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Show comment dialog before proceeding
      final shouldProceed = await _showCommentDialog();
      if (!shouldProceed) {
        isLoading.value = false;
        return;
      }

      // Prepare order items with store information
      final orderItems = cartController.items.map((item) {
        if (item.product == null) {
          throw Exception('Invalid product in cart');
        }
        if (item.quantity <= 0) {
          throw Exception('Invalid quantity for ${item.product!.name}');
        }

        // Check stock availability for the selected store
        final availableStock =
            item.product!.getQuantityForStore(selectedStore.value!.id);
        if (availableStock < item.quantity) {
          throw Exception(
              'Insufficient stock for ${item.product!.name} in ${selectedStore.value!.name}. Available: $availableStock, Requested: ${item.quantity}');
        }

        return {
          'productId': item.product!.id,
          'quantity': item.quantity,
          'priceOptionId': item.priceOptionId,
          'storeId': selectedStore.value!.id,
          'unitPrice': cartController.getItemPrice(item),
          'totalPrice': cartController.getItemTotal(item),
        };
      }).toList();

      // TODO: Implement order creation with proper service
      // For now, just show success message
      Get.snackbar(
        'Order Created',
        'Order has been created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _processOrderSuccess();
    } catch (e) {
      handleOrderError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _processOrderSuccess() {
    cartController.clear();
    selectedImage.value = null;
    comment.value = ''; // Clear comment
    commentController.clear(); // Clear comment controller
    // Navigate back to home first, then show success dialog
    Get.offNamed('/home');
    // Show success dialog with options after navigation
    _showOrderSuccessDialog();
  }

  Future<bool> _showCommentDialog() async {
    commentController.clear(); // Clear any existing comment
    comment.value = ''; // Reset comment value

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delivery Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add any delivery information (e.g., tax PIN, delivery instructions)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Enter delivery information...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (value) => comment.value = value,
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Get.back(result: true);
                },
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back(result: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Add & Proceed'),
              ),
            ],
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void handleOrderError(dynamic error) async {
    String errorMessage = error.toString();

    // If the response was a success but the returned data was incomplete,
    // ApiService.createOrder will now show a success dialog and return null.
    // So, here, we only need to handle actual errors (like stock issues).
    if (errorMessage.contains('Insufficient stock')) {
      final RegExp regex = RegExp(r'Insufficient stock for product (.+)');
      final match = regex.firstMatch(errorMessage);
      final productName = match?.group(1) ?? 'Unknown Product';

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Out of Stock'),
            content: Text('Insufficient stock for $productName'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else if (errorMessage.contains('Order cancelled by user')) {
      // User cancelled the order due to balance warning
      Get.snackbar(
        'Order Cancelled',
        'The order was cancelled due to balance warning',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      // Handle other errors
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.off(() => ProductsGridPage(
                  outlet: widget.outlet,
                  order: widget.order,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index, OrderItem item) {
    final packSize = item.product?.packSize;
    final totalPieces = (packSize != null) ? item.quantity * packSize : null;

    // Get price using cart controller method
    final itemPrice = cartController.getItemPrice(item);
    final itemTotal = cartController.getItemTotal(item);

    // Format price using dynamic currency configuration
    String formattedPrice = 'Price not available';
    if (_userCurrencyConfig != null) {
      formattedPrice =
          CurrencyConfigService.formatCurrency(itemTotal, _userCurrencyConfig!);
    } else {
      // Fallback to basic formatting
      formattedPrice =
          '${_userCurrencyConfig?.currencySymbol ?? 'KES'} $itemTotal';
    }

    return Card(
      key: ValueKey('cart_item_${index}_${item.productId}'),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.product?.imageUrl != null
                  ? Image.network(
                      ImageUtils.getGridUrl(item.product!.imageUrl!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.name ?? 'Unknown Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.priceOptionId != null)
                    Text(
                      'Price Option: ${item.product?.priceOptions.firstWhereOrNull((po) => po.id == item.priceOptionId)?.option ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    'Quantity: ${item.quantity}${packSize != null ? ' pack(s) ($totalPieces pcs)' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Price: ${_userCurrencyConfig != null ? CurrencyConfigService.formatCurrency(itemPrice, _userCurrencyConfig!) : 'KES $itemPrice'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        final newQuantity = item.quantity - 1;
                        if (newQuantity > 0) {
                          cartController.updateItemQuantity(item, newQuantity);
                        } else {
                          cartController.removeItem(item);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        final newQuantity = item.quantity + 1;
                        // Check stock availability for the selected store
                        if (selectedStore.value != null) {
                          final availableStock = item.product
                                  ?.getQuantityForStore(
                                      selectedStore.value!.id) ??
                              0;
                          if (newQuantity <= availableStock) {
                            cartController.updateItemQuantity(
                                item, newQuantity);
                          } else {
                            Get.snackbar(
                              'Error',
                              'Cannot exceed available stock',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.red[400],
                              colorText: Colors.white,
                            );
                          }
                        } else {
                          cartController.updateItemQuantity(item, newQuantity);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
                Text(
                  formattedPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        final totalItems =
            cartController.items.fold(0, (sum, item) => sum + item.quantity);
        final totalAmount = cartController.totalAmount;
        final totalPieces = cartController.items.fold(
            0,
            (sum, item) =>
                sum +
                ((item.product?.packSize != null)
                    ? item.quantity * item.product!.packSize!
                    : 0));

        // Format total amount using dynamic currency configuration
        String formattedTotalAmount = 'Price not available';
        if (_userCurrencyConfig != null) {
          formattedTotalAmount = CurrencyConfigService.formatCurrency(
              totalAmount, _userCurrencyConfig!);
        } else {
          // Fallback to basic formatting
          formattedTotalAmount =
              '${_userCurrencyConfig?.currencySymbol ?? 'KES'} $totalAmount';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$totalItems',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            if (totalPieces > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pieces',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$totalPieces',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  formattedTotalAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            // Add breakdown of items
            if (cartController.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...cartController.items.map((item) {
                final itemTotal = cartController.getItemTotal(item);
                final formattedItemTotal = _userCurrencyConfig != null
                    ? CurrencyConfigService.formatCurrency(
                        itemTotal, _userCurrencyConfig!)
                    : 'KES $itemTotal';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product?.name ?? 'Unknown'} (${item.quantity})',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedItemTotal,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() {
        final loading = isLoading.value;
        final hasItems = cartController.items.isNotEmpty;

        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: !loading
                    ? () => Get.off(() => ProductsGridPage(
                          outlet: widget.outlet,
                          order: widget.order,
                        ))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add More',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: (!loading && hasItems) ? placeOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Processing...',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      )
                    : Text(
                        widget.order == null ? 'Place Order' : 'Update Order',
                        style: const TextStyle(fontSize: 14),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Cart' : 'Edit Order'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Add image attachment button to app bar
          Obx(() {
            if (selectedImage.value != null) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                    tooltip: 'Change Image',
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                onPressed: _pickImage,
                tooltip: 'Attach Image',
              );
            }
          }),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Store Selection Dropdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Store',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (isLoading.value) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Loading stores...'),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<Store>(
                      value: selectedStore.value,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'Select a store',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(Icons.store, color: Colors.grey),
                      dropdownColor: Colors.white,
                      elevation: 3,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      items: availableStores.map((store) {
                        return DropdownMenuItem(
                          value: store,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 50),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  store.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (store.region != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${store.region!.name}${store.region!.country != null ? ', ${store.region!.country!.name}' : ''}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ] else ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'No region Assigned',
                                    style: TextStyle(
                                      fontSize: 6,
                                      color: Colors.grey[400],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Store? newValue) {
                        if (newValue != null) {
                          selectedStore.value = newValue;
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a store';
                        }
                        return null;
                      },
                    );
                  }),

                  // Selected store info
                  Obx(() {
                    if (selectedStore.value != null) {
                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected: ${selectedStore.value!.name}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (selectedStore.value!.region != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${selectedStore.value!.region!.name}${selectedStore.value!.region!.country != null ? ', ${selectedStore.value!.region!.country!.name}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  cartController.items.isEmpty
                      ? _buildEmptyCart()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: cartController.items.length,
                          itemBuilder: (context, index) {
                            return _buildCartItem(
                                index, cartController.items[index]);
                          },
                        ),
                  // Show image preview if an image is selected
                  if (selectedImage.value != null)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                        future:
                                            selectedImage.value.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            );
                                          } else {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                        },
                                      )
                                    : Image.file(
                                        File(selectedImage.value.path),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => selectedImage.value = null,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildTotalSection(),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
