import 'package:get/get.dart';
import 'package:woosh/services/core/order_service.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';

class OrderDetailController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<MyOrderModel?> selectedOrder = Rx<MyOrderModel?>(null);
  final RxList<OrderItem> orderItems = <OrderItem>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 OrderDetailController initialized');
  }

  Future<MyOrderModel?> getOrderById(int orderId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting order by ID: $orderId');

      final result = await OrderService.getOrderById(orderId);
      selectedOrder.value = result;

      print('✅ Order retrieved: $orderId');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to get order: $e';
      print('❌ Error getting order: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting order items for order: $orderId');

      final result = await OrderService.getOrderItems(orderId);
      orderItems.value = result;

      print('✅ Order items retrieved for order: $orderId');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to get order items: $e';
      print('❌ Error getting order items: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Deleting order: $orderId');

      final result = await OrderService.deleteOrder(orderId);
      print('✅ Order deleted: $orderId');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to delete order: $e';
      print('❌ Error deleting order: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> requestOrderVoid({
    required int orderId,
    required String reason,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Requesting order void: $orderId');

      final result = await OrderService.requestOrderVoid(
        orderId: orderId,
        reason: reason,
      );
      print('✅ Order void requested: $orderId');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to request order void: $e';
      print('❌ Error requesting order void: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> canUpdateOrder(int orderId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Checking if order can be updated: $orderId');

      final result = await OrderService.canUpdateOrder(orderId);
      print('✅ Order update check completed: $orderId');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to check order update status: $e';
      print('❌ Error checking order update status: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
