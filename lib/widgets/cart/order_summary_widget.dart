import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/cartcontroller/cart_controller.dart';
// Remove direct service import - use controller instead

/// Widget for displaying order summary and totals
class OrderSummaryWidget extends StatelessWidget {
  final CartController cartController;
  final String? currencySymbol;

  const OrderSummaryWidget({
    super.key,
    required this.cartController,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
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

        // Format total amount using currency symbol
        String formattedTotalAmount =
            '${currencySymbol ?? 'KES'} ${totalAmount.toStringAsFixed(2)}';

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
                final formattedItemTotal =
                    '${currencySymbol ?? 'KES'} ${itemTotal.toStringAsFixed(2)}';

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
              }),
            ],
          ],
        );
      }),
    );
  }
}
