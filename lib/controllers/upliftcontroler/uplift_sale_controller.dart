import 'package:get/get.dart';
import 'package:woosh/models/uplift_sale_model.dart';
import 'package:woosh/services/core/uplift_sale_service.dart';

class UpliftSaleController extends GetxController {
  final RxList<UpliftSale> sales = <UpliftSale>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> loadSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? clientId,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UpliftSaleService.getUpliftSales(
        status: status,
        startDate: startDate,
        endDate: endDate,
        clientId: clientId,
        userId: userId,
      );

      sales.value = response;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<UpliftSale?> getSaleById(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await UpliftSaleService.getUpliftSaleById(id);
      return response;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success =
          await UpliftSaleService.updateUpliftSaleStatus(id, status);
      if (success) {
        // Update local state
        final index = sales.indexWhere((sale) => sale.id == id);
        if (index != -1) {
          final updatedSale = await getSaleById(id);
          if (updatedSale != null) {
            sales[index] = updatedSale;
          }
        }
      }
      return success;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteSale(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await UpliftSaleService.deleteUpliftSale(id);
      if (success) {
        sales.removeWhere((sale) => sale.id == id);
      }
      return success;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
