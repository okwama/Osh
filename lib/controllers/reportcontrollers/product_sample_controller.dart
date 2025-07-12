import 'package:get/get.dart';
import 'package:woosh/services/core/reports/product_sample_service.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/productSample_model.dart';

class ProductSampleController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Report> productSamples = <Report>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 ProductSampleController initialized');
  }

  Future<List<Report>> getProductSamplesByJourneyPlan(int journeyPlanId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting product samples for journey plan: $journeyPlanId');

      final result = await ProductSampleService.getProductSamplesByJourneyPlan(
          journeyPlanId);
      productSamples.value = result;

      print(
          '✅ Product samples loaded for journey plan: ${result.length} items');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to load product samples: $e';
      print('❌ Error loading product samples: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitProductSample({
    required int journeyPlanId,
    required int clientId,
    required List<ProductSample> productSamples,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print(
          '🔍 Submitting product sample for journey plan: $journeyPlanId, client: $clientId');

      final result = await ProductSampleService.submitProductSample(
        journeyPlanId: journeyPlanId,
        clientId: clientId,
        productSamples: productSamples,
        userId: userId,
      );

      print('✅ Product sample submitted successfully: ${result.id}');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to submit product sample: $e';
      print('❌ Error submitting product sample: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
