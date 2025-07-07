import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/Products_Inventory/price_option_model.dart';
import 'package:woosh/services/database_service.dart';

/// Order service using direct database connections
class OrderService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get orders with pagination and filtering (automatically filters by current user)
  static Future<List<MyOrderModel>> getOrders({
    int page = 1,
    int limit = 20,
    int? clientId,
    int? status,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      // Get current user ID for security
      final currentUserId = _db.getCurrentUserId();

      String sql = '''
        SELECT 
          mo.*,
          c.name as clientName,
          c.contact as clientContact,
          c.address as clientAddress
        FROM MyOrder mo
        LEFT JOIN Clients c ON mo.clientId = c.id
        WHERE mo.userId = ?
      ''';

      final params = <dynamic>[currentUserId];

      // Always filter by current user for security

      if (clientId != null) {
        sql += ' AND mo.clientId = ?';
        params.add(clientId);
      }

      if (status != null) {
        sql += ' AND mo.status = ?';
        params.add(status);
      }

      if (search != null && search.isNotEmpty) {
        sql +=
            ' AND (mo.customerName LIKE ? OR mo.comment LIKE ? OR c.name LIKE ?)';
        final searchTerm = '%$search%';
        params.addAll([searchTerm, searchTerm, searchTerm]);
      }

      if (dateFrom != null) {
        sql += ' AND DATE(mo.orderDate) >= ?';
        params.add(dateFrom);
      }

      if (dateTo != null) {
        sql += ' AND DATE(mo.orderDate) <= ?';
        params.add(dateTo);
      }

      sql += ' ORDER BY mo.orderDate DESC LIMIT ? OFFSET ?';
      params.add(limit);
      params.add((page - 1) * limit);

      final results = await _db.query(sql, params);

      return results.map((row) => MyOrderModel.fromMap(row.fields)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get order by ID with items (only for current user's orders)
  static Future<MyOrderModel?> getOrderById(int orderId) async {
    try {
      // Get current user ID for security
      final currentUserId = _db.getCurrentUserId();

      const sql = '''
        SELECT 
          mo.*,
          c.name as clientName,
          c.contact as clientContact,
          c.address as clientAddress
        FROM MyOrder mo
        LEFT JOIN Clients c ON mo.clientId = c.id
        WHERE mo.id = ? AND mo.userId = ?
      ''';

      final results = await _db.query(sql, [orderId, currentUserId]);

      if (results.isEmpty) return null;

      final order = MyOrderModel.fromMap(results.first.fields);

      // Get order items (not used in current implementation)
      await getOrderItems(orderId);

      // Return order with items (you may need to modify MyOrderModel to include items)
      return order;
    } catch (e) {
      rethrow;
    }
  }

  /// Get order items for an order with complete product data
  static Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      // First, get the basic order items
      const sql = '''
        SELECT 
          oi.id,
          oi.orderId,
          oi.productId,
          oi.quantity,
          oi.priceOptionId
        FROM OrderItem oi
        WHERE oi.orderId = ?
        ORDER BY oi.id ASC
      ''';

      final results = await _db.query(sql, [orderId]);
      final orderItems = <OrderItem>[];

      // For each order item, load the complete product data
      for (final row in results) {
        final fields = row.fields;
        final productId = fields['productId'] as int;
        final priceOptionId = fields['priceOptionId'] as int?;

        // Load complete product data with price options
        final product = await _loadProductWithPriceOptions(productId);

        final orderItem = OrderItem(
          id: fields['id'] as int?,
          productId: productId,
          quantity: fields['quantity'] as int,
          product: product,
          priceOptionId: priceOptionId,
        );

        orderItems.add(orderItem);
      }

      return orderItems;
    } catch (e) {
      rethrow;
    }
  }

  /// Load complete product data with price options
  static Future<ProductModel?> _loadProductWithPriceOptions(
      int productId) async {
    try {
      // Get product data
      const productSql = '''
        SELECT 
          p.*,
          c.name as category
        FROM Product p
        LEFT JOIN Category c ON p.category_id = c.id
        WHERE p.id = ?
      ''';

      final productResults = await _db.query(productSql, [productId]);
      if (productResults.isEmpty) return null;

      final productFields = productResults.first.fields;

      // Get price options for this product
      const priceOptionsSql = '''
        SELECT * FROM PriceOption 
        WHERE categoryId = ? 
        ORDER BY value ASC
      ''';

      final priceOptionResults =
          await _db.query(priceOptionsSql, [productFields['category_id']]);

      final priceOptions = priceOptionResults
          .map((row) => PriceOptionModel.fromMap(row.fields))
          .toList();

      // Create product model with price options
      final productData = Map<String, dynamic>.from(productFields);
      productData['priceOptions'] =
          priceOptions.map((po) => po.toMap()).toList();

      return ProductModel.fromMap(productData);
    } catch (e) {
      return null;
    }
  }

  /// Create a new order with items
  static Future<MyOrderModel?> createOrder({
    required double totalAmount,
    required double totalCost,
    required double amountPaid,
    required double balance,
    required String comment,
    required String customerType,
    required String customerId,
    required String customerName,
    required int clientId,
    required int countryId,
    required int regionId,
    required List<OrderItem> orderItems,
    int? riderId,
    String? riderName,
    String? deliveryLocation,
    String? recepient,
    int? storeId,
    int? retailManager,
    int? keyChannelManager,
    int? distributionManager,
    String? imageUrl,
  }) async {
    try {
      final userId = _db.getCurrentUserId();

      return await _db.transaction((connection) async {
        // Create the main order
        const orderSql = '''
          INSERT INTO MyOrder (
            totalAmount, totalCost, amountPaid, balance, comment,
            customerType, customerId, customerName, orderDate,
            riderId, riderName, status, deliveryLocation, recepient,
            userId, clientId, countryId, regionId, createdAt, updatedAt,
            approved_by, approved_by_name, storeId, retail_manager,
            key_channel_manager, distribution_manager, imageUrl
          ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?, 0, ?, ?, ?, ?, ?, ?, NOW(), NOW(),
            '', '', ?, ?, ?, ?, ?
          )
        ''';

        final orderParams = [
          totalAmount,
          totalCost,
          amountPaid,
          balance,
          comment,
          customerType,
          customerId,
          customerName,
          riderId,
          riderName,
          deliveryLocation,
          recepient,
          userId,
          clientId,
          countryId,
          regionId,
          storeId,
          retailManager,
          keyChannelManager,
          distributionManager,
          imageUrl,
        ];

        final orderResult = await connection.query(orderSql, orderParams);
        final orderId = orderResult.insertId;

        if (orderId == null) {
          throw Exception('Failed to create order');
        }

        // Create order items
        for (final item in orderItems) {
          const itemSql = '''
            INSERT INTO OrderItem (orderId, productId, quantity, priceOptionId)
            VALUES (?, ?, ?, ?)
          ''';

          await connection.query(itemSql, [
            orderId,
            item.productId,
            item.quantity,
            item.priceOptionId,
          ]);

          // Update product stock
          const updateStockSql = '''
            UPDATE Product SET currentStock = currentStock - ?
            WHERE id = ?
          ''';
          await connection
              .query(updateStockSql, [item.quantity, item.productId]);
        }

        // Return the created order
        const getOrderSql = 'SELECT * FROM MyOrder WHERE id = ?';
        final orderResults = await connection.query(getOrderSql, [orderId]);

        if (orderResults.isNotEmpty) {
          return MyOrderModel.fromMap(orderResults.first.fields);
        }

        return null;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status
  static Future<void> updateOrderStatus(int orderId, int status,
      {String? notes}) async {
    try {
      String sql = 'UPDATE MyOrder SET status = ?, updatedAt = ?';
      List<dynamic> params = [status, DateTime.now().toIso8601String()];

      // Add status-specific fields
      switch (status) {
        case 1: // Approved
          sql += ', approvedTime = ?';
          params.add(DateTime.now().toIso8601String());
          break;
        case 2: // Dispatched
          sql += ', dispatchTime = ?';
          params.add(DateTime.now().toIso8601String());
          break;
        case 3: // Delivered
          sql += ', deliveryTime = ?';
          params.add(DateTime.now().toIso8601String());
          break;
        case 4: // Cancelled
          if (notes != null) {
            sql += ', cancel_reason = ?';
            params.add(notes);
          }
          break;
      }

      sql += ' WHERE id = ?';
      params.add(orderId);

      await _db.query(sql, params);
    } catch (e) {
      rethrow;
    }
  }

  /// Get order statistics for a user
  static Future<Map<String, dynamic>> getOrderStats(int userId) async {
    try {
      const sql = '''
        SELECT 
          COUNT(*) as total_orders,
          COUNT(CASE WHEN status = 0 THEN 1 END) as pending_orders,
          COUNT(CASE WHEN status = 1 THEN 1 END) as approved_orders,
          COUNT(CASE WHEN status = 2 THEN 1 END) as dispatched_orders,
          COUNT(CASE WHEN status = 3 THEN 1 END) as delivered_orders,
          COUNT(CASE WHEN status = 4 THEN 1 END) as cancelled_orders,
          SUM(totalAmount) as total_amount,
          SUM(CASE WHEN status = 3 THEN totalAmount ELSE 0 END) as delivered_amount
        FROM MyOrder 
        WHERE userId = ?
      ''';

      final results = await _db.query(sql, [userId]);

      if (results.isNotEmpty) {
        return results.first.fields;
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }

  /// Check void status for an order
  static Future<Map<String, dynamic>> checkVoidStatus(
      {required int orderId}) async {
    try {
      const sql = '''
        SELECT status, cancel_reason
        FROM MyOrder 
        WHERE id = ?
      ''';

      final results = await _db.query(sql, [orderId]);

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Order not found',
        };
      }

      final fields = results.first.fields;
      final status = fields['status'] ?? 0;
      final cancelReason = fields['cancel_reason'];

      return {
        'success': true,
        'orderId': orderId,
        'status': status,
        'statusMessage': _getVoidStatusMessage(status),
        'canRequestVoid': status == 0,
        'reason': cancelReason,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to check void status',
      };
    }
  }

  /// Request order void
  static Future<Map<String, dynamic>> requestOrderVoid({
    required int orderId,
    required String reason,
  }) async {
    try {
      // Check if order exists and is pending
      const checkSql = 'SELECT status FROM MyOrder WHERE id = ?';
      final checkResults = await _db.query(checkSql, [orderId]);

      if (checkResults.isEmpty) {
        return {
          'success': false,
          'message': 'Order not found',
        };
      }

      final status = checkResults.first.fields['status'] ?? 0;
      if (status != 0) {
        return {
          'success': false,
          'message': 'Only pending orders can be voided',
        };
      }

      // Update order status to void requested
      const updateSql = '''
        UPDATE MyOrder 
        SET status = 4, cancel_reason = ?, updatedAt = NOW()
        WHERE id = ?
      ''';

      await _db.query(updateSql, [reason, orderId]);

      return {
        'success': true,
        'message': 'Void request submitted',
        'orderId': orderId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit void request',
      };
    }
  }

  /// Update order with new items - only for pending orders
  static Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required List<Map<String, dynamic>> orderItems,
    String? comment,
  }) async {
    try {
      // First check if order exists and is pending
      const checkSql = '''
        SELECT status, totalAmount, clientId, userId 
        FROM MyOrder 
        WHERE id = ?
      ''';

      final checkResults = await _db.query(checkSql, [orderId]);
      if (checkResults.isEmpty) {
        return {
          'success': false,
          'message': 'Order not found',
        };
      }

      final orderData = checkResults.first.fields;
      final currentStatus = orderData['status'] as int;

      // Only allow updates for pending orders (status = 0)
      if (currentStatus != 0) {
        return {
          'success': false,
          'message': 'Only pending orders can be updated',
        };
      }

      // Get current user for security check
      final currentUserId = _db.getCurrentUserId();
      final orderUserId = orderData['userId'] as int;

      if (currentUserId != orderUserId) {
        return {
          'success': false,
          'message': 'You can only update your own orders',
        };
      }

      return await _db.transaction((connection) async {
        // Calculate new total amount
        double newTotalAmount = 0;

        // Get price option values for total calculation
        for (final item in orderItems) {
          const priceSql = '''
            SELECT po.value 
            FROM PriceOption po 
            WHERE po.id = ?
          ''';
          final priceResults =
              await connection.query(priceSql, [item['priceOptionId']]);
          if (priceResults.isNotEmpty) {
            final priceValue =
                (priceResults.first.fields['value'] ?? 0).toDouble();
            newTotalAmount += priceValue * (item['quantity'] as int);
          }
        }

        // Delete existing order items
        const deleteSql = 'DELETE FROM OrderItem WHERE orderId = ?';
        await connection.query(deleteSql, [orderId]);

        // Insert new order items
        for (final item in orderItems) {
          const insertSql = '''
            INSERT INTO OrderItem (orderId, productId, quantity, priceOptionId)
            VALUES (?, ?, ?, ?)
          ''';

          await connection.query(insertSql, [
            orderId,
            item['productId'],
            item['quantity'],
            item['priceOptionId'],
          ]);
        }

        // Update order with new total and comment
        const updateSql = '''
          UPDATE MyOrder 
          SET totalAmount = ?, 
              balance = ?, 
              comment = ?,
              updatedAt = NOW()
          WHERE id = ?
        ''';

        final newBalance =
            newTotalAmount - (orderData['totalAmount'] ?? 0).toDouble();
        await connection.query(updateSql, [
          newTotalAmount,
          newBalance,
          comment ?? '',
          orderId,
        ]);

        return {
          'success': true,
          'message': 'Order updated successfully',
          'orderId': orderId,
          'newTotalAmount': newTotalAmount,
        };
      });
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update order: $e',
      };
    }
  }

  /// Check if order can be updated (pending status and owned by current user)
  static Future<bool> canUpdateOrder(int orderId) async {
    try {
      const sql = '''
        SELECT status, userId 
        FROM MyOrder 
        WHERE id = ?
      ''';

      final results = await _db.query(sql, [orderId]);
      if (results.isEmpty) return false;

      final orderData = results.first.fields;
      final status = orderData['status'] as int;
      final orderUserId = orderData['userId'] as int;
      final currentUserId = _db.getCurrentUserId();

      // Order must be pending (status = 0) and owned by current user
      return status == 0 && currentUserId == orderUserId;
    } catch (e) {
      return false;
    }
  }

  /// Delete order (only for pending orders owned by current user)
  static Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    try {
      // Check if order exists and is pending
      const checkSql = '''
        SELECT status, userId 
        FROM MyOrder 
        WHERE id = ?
      ''';

      final checkResults = await _db.query(checkSql, [orderId]);
      if (checkResults.isEmpty) {
        return {
          'success': false,
          'message': 'Order not found',
        };
      }

      final orderData = checkResults.first.fields;
      final currentStatus = orderData['status'] as int;

      // Only allow deletion for pending orders (status = 0)
      if (currentStatus != 0) {
        return {
          'success': false,
          'message': 'Only pending orders can be deleted',
        };
      }

      // Get current user for security check
      final currentUserId = _db.getCurrentUserId();
      final orderUserId = orderData['userId'] as int;

      if (currentUserId != orderUserId) {
        return {
          'success': false,
          'message': 'You can only delete your own orders',
        };
      }

      return await _db.transaction((connection) async {
        // Delete order items first
        const deleteItemsSql = 'DELETE FROM OrderItem WHERE orderId = ?';
        await connection.query(deleteItemsSql, [orderId]);

        // Delete the order
        const deleteOrderSql = 'DELETE FROM MyOrder WHERE id = ?';
        final result = await connection.query(deleteOrderSql, [orderId]);

        if (result.affectedRows! > 0) {
          return {
            'success': true,
            'message': 'Order deleted successfully',
            'orderId': orderId,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to delete order',
          };
        }
      });
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete order: $e',
      };
    }
  }

  /// Fetch outlets (clients) for the current user
  static Future<List<Map<String, dynamic>>> fetchOutlets() async {
    try {
      final userId = _db.getCurrentUserId();

      const sql = '''
        SELECT id, name, contact, address, countryId
        FROM Clients 
        WHERE userId = ? OR userId IS NULL
        ORDER BY name ASC
      ''';

      final results = await _db.query(sql, [userId]);

      return results.map((row) => row.fields).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get void status message
  static String _getVoidStatusMessage(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 4:
        return 'Void Requested';
      case 5:
        return 'Voided';
      case 6:
        return 'Void Rejected';
      default:
        return 'Unknown Status';
    }
  }

  // Simple in-memory cache for orders
  static final Map<String, Map<String, dynamic>> _cache = {};

  /// Cache data with expiration
  static void cacheData<T>(String key, T data, {Duration? validity}) {
    final expiry = validity != null
        ? DateTime.now().add(validity).millisecondsSinceEpoch
        : DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;

    _cache[key] = {
      'data': data,
      'expiry': expiry,
    };
  }

  /// Get cached data if not expired
  static T? getCachedData<T>(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    final expiry = cached['expiry'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      _cache.remove(key);
      return null;
    }

    return cached['data'] as T?;
  }

  /// Remove data from cache
  static void removeFromCache(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  static void clearCache() {
    _cache.clear();
  }
}