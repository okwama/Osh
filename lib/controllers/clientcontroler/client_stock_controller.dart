import 'package:get/get.dart';
import 'package:woosh/services/core/client_stock_service.dart';
import 'package:woosh/utils/error_handler.dart';

class ClientStockController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isFeatureEnabled = true.obs;
  final RxList<Map<String, dynamic>> clientStock = <Map<String, dynamic>>[].obs;

  /// Check if client stock feature is enabled
  Future<bool> checkFeatureEnabled() async {
    try {
      isLoading.value = true;
      final result = await ClientStockService.isFeatureEnabled();
      isFeatureEnabled.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientStockController.checkFeatureEnabled');
      return true; // Default to enabled
    } finally {
      isLoading.value = false;
    }
  }

  /// Get client stock for a specific client
  Future<List<Map<String, dynamic>>> getClientStock(int clientId) async {
    try {
      isLoading.value = true;
      final result = await ClientStockService.getClientStock(clientId);
      clientStock.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientStockController.getClientStock');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Update client stock
  Future<void> updateStock({
    required int clientId,
    required int productId,
    required int quantity,
  }) async {
    try {
      isLoading.value = true;
      await ClientStockService.updateStock(
        clientId: clientId,
        productId: productId,
        quantity: quantity,
      );
      // Refresh client stock after update
      await getClientStock(clientId);
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'ClientStockController.updateStock');
    } finally {
      isLoading.value = false;
    }
  }
}
