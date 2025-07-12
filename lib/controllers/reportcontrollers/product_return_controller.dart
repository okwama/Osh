import 'package:get/get.dart';
import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';
import 'package:woosh/services/core/reports/product_return_service.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/productReturn_model.dart';

class ProductReturnController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Report> productReturns = <Report>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 ProductReturnController initialized');
  }

  Future<List<Report>> getProductReturnsByJourneyPlan(int journeyPlanId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting product returns for journey plan: $journeyPlanId');

      final result = await ProductReturnService.getProductReturnsByJourneyPlan(
          journeyPlanId);
      productReturns.value = result;

      print(
          '✅ Product returns loaded for journey plan: ${result.length} items');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to load product returns: $e';
      print('❌ Error loading product returns: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitProductReturn({
    required int journeyPlanId,
    required int clientId,
    required List<ProductReturnItem> productReturnItems,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print(
          '🔍 Submitting product return for journey plan: $journeyPlanId, client: $clientId');

      final result = await ProductReturnService.submitProductReturn(
        journeyPlanId: journeyPlanId,
        clientId: clientId,
        productReturnItems: productReturnItems,
        userId: userId,
      );

      print('✅ Product return submitted successfully: ${result.id}');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to submit product return: $e';
      print('❌ Error submitting product return: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
