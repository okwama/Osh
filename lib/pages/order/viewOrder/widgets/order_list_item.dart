import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/pages/order/viewOrder/orderDetail.dart';
import 'package:woosh/utils/date_utils.dart' as custom_date;

/// Order list item widget
class OrderListItem extends StatelessWidget {
  final MyOrderModel order;
  final VoidCallback onOrderUpdated;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // Navigate to order detail and refresh on return if needed
            final future = Get.to(
              () => OrderDetailPage(
                order: order,
              ),
              transition: Transition.rightToLeft,
            );

            // Use null-safe then() to handle the result
            future?.then((result) {
              // Refresh only the specific order if an update was made
              if (result == true) {
                onOrderUpdated();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Order #${order.id}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      custom_date.DateUtils.formatDateTime(order.orderDate),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Client ID: ${order.clientId}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 4, 4, 4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(order.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View details for order items',
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get status color based on order status
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange; // pending
      case 1:
        return Colors.blue; // confirmed
      case 2:
        return Colors.purple; // processing
      case 3:
        return Colors.indigo; // shipped
      case 4:
        return Colors.green; // delivered
      case 5:
      case 6:
        return Colors.red; // cancelled/voided
      default:
        return Colors.grey;
    }
  }

  // Get status text based on order status
  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Confirmed';
      case 2:
        return 'Processing';
      case 3:
        return 'Shipped';
      case 4:
        return 'Delivered';
      case 5:
        return 'Cancelled';
      case 6:
        return 'Voided';
      default:
        return 'Unknown';
    }
  }
}
