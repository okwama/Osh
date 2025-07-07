import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/widgets/gradient_widgets.dart';

class OrdersTab extends StatelessWidget {
  final List<OrderModel> userOrders;
  final bool isLoadingOrders;
  final int totalItemsSold;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final bool hasMoreOrders;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;

  const OrdersTab({
    super.key,
    required this.userOrders,
    required this.isLoadingOrders,
    required this.totalItemsSold,
    required this.onRefresh,
    required this.scrollController,
    required this.hasMoreOrders,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingOrders) {
      return const Center(child: GradientCircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: userOrders.length +
            2, // +1 for sales card, +1 for loading indicator
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSalesDataCard(context);
          }

          if (index == userOrders.length + 1) {
            if (isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: GradientCircularProgressIndicator(),
                ),
              );
            }
            if (hasMoreOrders) {
              onLoadMore();
            }
            return const SizedBox.shrink();
          }

          final order = userOrders[index - 1];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 3.0),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Text(
                'Order #${order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${order.items.length} items - ${DateFormat('MMM d, yyyy').format(order.orderDate)}',
              ),
              trailing: Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesDataCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(6.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart,
                    color: Theme.of(context).primaryColor, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Sales Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            isLoadingOrders
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total items sold:',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalItemsSold items',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From ${userOrders.length} orders',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      if (userOrders.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Recent Orders:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...userOrders.map((order) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_bag,
                                    size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${order.items.length} items',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(order.orderDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
