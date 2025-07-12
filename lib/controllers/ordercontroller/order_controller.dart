import 'package:get/get.dart';
import 'package:woosh/services/core/order_service.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/utils/error_handler.dart';

class OrderController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<MyOrderModel> orders = <MyOrderModel>[].obs;
  final RxMap<String, dynamic> orderStats = <String, dynamic>{}.obs;

  /// Get orders with pagination and filtering
  Future<List<MyOrderModel>> getOrders({
    int page = 1,
    int limit = 20,
    int? clientId,
    int? status,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      isLoading.value = true;
      final result = await OrderService.getOrders(
        page: page,
        limit: limit,
        clientId: clientId,
        status: status,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      orders.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'OrderController.getOrders');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get order by ID with items
  Future<MyOrderModel?> getOrderById(int orderId) async {
    try {
      isLoading.value = true;
      final result = await OrderService.getOrderById(orderId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'OrderController.getOrderById');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get order items for an order
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      isLoading.value = true;
      final result = await OrderService.getOrderItems(orderId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'OrderController.getOrderItems');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new order with items
  Future<MyOrderModel?> createOrder({
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
      isLoading.value = true;
      final result = await OrderService.createOrder(
        totalAmount: totalAmount,
        totalCost: totalCost,
        amountPaid: amountPaid,
        balance: balance,
        comment: comment,
        customerType: customerType,
        customerId: customerId,
        customerName: customerName,
        clientId: clientId,
        countryId: countryId,
        regionId: regionId,
        orderItems: orderItems,
        riderId: riderId,
        riderName: riderName,
        deliveryLocation: deliveryLocation,
        recepient: recepient,
        storeId: storeId,
        retailManager: retailManager,
        keyChannelManager: keyChannelManager,
        distributionManager: distributionManager,
        imageUrl: imageUrl,
      );
      if (result != null) {
        // Refresh orders list
        await getOrders();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'OrderController.createOrder');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(int orderId, int status,
      {String? notes}) async {
    try {
      isLoading.value = true;
      await OrderService.updateOrderStatus(orderId, status, notes: notes);
      // Refresh orders list
      await getOrders();
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'OrderController.updateOrderStatus');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get order statistics for current user
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      isLoading.value = true;
      final result = await OrderService.getOrderStats(
          0); // Will be filtered by current user in service
      orderStats.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'OrderController.getOrderStats');
      return {};
    } finally {
      isLoading.value = false;
    }
  }

  /// Check void status for an order
  Future<Map<String, dynamic>> checkVoidStatus({required int orderId}) async {
    try {
      isLoading.value = true;
      final result = await OrderService.checkVoidStatus(orderId: orderId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'OrderController.checkVoidStatus');
      return {
        'success': false,
        'message': 'Failed to check void status',
      };
    } finally {
      isLoading.value = false;
    }
  }
}
