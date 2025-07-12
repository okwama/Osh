import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/controllers/cartcontroller/cart_controller.dart';
import 'package:woosh/models/Products_Inventory/store_model.dart';
import 'package:woosh/utils/image_utils.dart';
// Remove direct service import - use controller instead

/// Widget for displaying cart items with quantity controls
class CartItemsWidget extends StatelessWidget {
  final CartController cartController;
  final Store? selectedStore;
  final String? currencySymbol;
  final VoidCallback? onEmptyCart;

  const CartItemsWidget({
    super.key,
    required this.cartController,
    this.selectedStore,
    this.currencySymbol,
    this.onEmptyCart,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (cartController.items.isEmpty) {
        return _buildEmptyCart(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: cartController.items.length,
        itemBuilder: (context, index) {
          return _buildCartItem(context, index, cartController.items[index]);
        },
      );
    });
  }

  Widget _buildEmptyCart(BuildContext context) {
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
            onPressed: onEmptyCart,
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

  Widget _buildCartItem(BuildContext context, int index, OrderItem item) {
    final packSize = item.product?.packSize;
    final totalPieces = (packSize != null) ? item.quantity * packSize : null;

    // Get price using cart controller method
    final itemPrice = cartController.getItemPrice(item);
    final itemTotal = cartController.getItemTotal(item);

    // Format price using currency symbol
    String formattedPrice =
        '${currencySymbol ?? 'KES'} ${itemTotal.toStringAsFixed(2)}';

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
                    'Price: ${currencySymbol ?? 'KES'} ${itemPrice.toStringAsFixed(2)}',
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
                        if (selectedStore != null) {
                          final availableStock = item.product
                                  ?.getQuantityForStore(selectedStore!.id) ??
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
}
