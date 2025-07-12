import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/controllers/cartcontroller/cart_controller.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';
import 'package:woosh/pages/order/product/products_grid_page.dart';
import 'package:woosh/models/Products_Inventory/store_model.dart';
import 'package:woosh/controllers/currencycontroller/currency_config_controller.dart';
import 'package:woosh/controllers/cartcontroller/cart_placement_controller.dart';
import 'package:woosh/services/core/currency_config_service.dart';
import 'package:woosh/utils/error_handler.dart';
import 'package:woosh/widgets/cart/store_selector_widget.dart';
import 'package:woosh/widgets/cart/cart_items_widget.dart';
import 'package:woosh/widgets/cart/order_summary_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

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
  final Rx<Store?> selectedStore = Rx<Store?>(null);
  final Rx<dynamic> selectedImage = Rx<dynamic>(null);
  final RxString comment = ''.obs;
  final ImagePicker _picker = ImagePicker();

  // Currency configuration
  CurrencyConfig? _userCurrencyConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrencyConfig();
  }

  Future<void> _loadCurrencyConfig() async {
    try {
      final currencyController = Get.find<CurrencyConfigController>();
      _userCurrencyConfig =
          await currencyController.getCurrentUserCurrencyConfig();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Use centralized error handling
      ErrorHandler.handleSilentError(e,
          context: 'CartPage._loadCurrencyConfig');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    ImageCache().clear();
    ImageCache().clearLiveImages();
  }

  Future<void> _pickImage() async {
    final cartPlacementController = Get.find<CartPlacementController>();
    final image = await cartPlacementController.pickImage();
    if (image != null) {
      selectedImage.value = image;
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

      // Show comment dialog before proceeding
      final cartPlacementController = Get.find<CartPlacementController>();
      final commentResult = await cartPlacementController.showCommentDialog();
      if (commentResult == null) {
        isLoading.value = false;
        return;
      }

      comment.value = commentResult;

      // Place order using service
      final success = await cartPlacementController.placeOrder(
        outlet: widget.outlet,
        selectedStore: selectedStore.value!,
        comment: comment.value,
        selectedImage: selectedImage.value,
        existingOrder: widget.order,
      );

      if (success) {
        selectedImage.value = null;
        comment.value = '';
      }
    } catch (e) {
      // Use centralized error handling
      ErrorHandler.handleGeneralError(e, context: 'CartPage.placeOrder');
    } finally {
      isLoading.value = false;
    }
  }

  void _onStoreSelected(Store store) {
    selectedStore.value = store;
  }

  void _onEmptyCart() {
    Get.off(() => ProductsGridPage(
          outlet: widget.outlet,
          order: widget.order,
        ));
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
            // Store Selection Widget
            StoreSelectorWidget(
              outlet: widget.outlet,
              onStoreSelected: _onStoreSelected,
              initialStore: selectedStore.value,
            ),
            Expanded(
              child: Stack(
                children: [
                  // Cart Items Widget
                  CartItemsWidget(
                    cartController: cartController,
                    selectedStore: selectedStore.value,
                    currencySymbol: _userCurrencyConfig?.currencySymbol,
                    onEmptyCart: _onEmptyCart,
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
            // Order Summary Widget
            OrderSummaryWidget(
              cartController: cartController,
              currencySymbol: _userCurrencyConfig?.currencySymbol,
            ),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
                onPressed: !loading ? _onEmptyCart : null,
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
}
