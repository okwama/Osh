import 'package:get/get.dart';
import 'package:woosh/services/core/reports/product_report_service.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';

class ProductReportController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Report> productReports = <Report>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 ProductReportController initialized');
  }

  Future<List<Report>> getProductReportsByJourneyPlan(int journeyPlanId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting product reports for journey plan: $journeyPlanId');

      final result = await ProductReportService.getProductReportsByJourneyPlan(
          journeyPlanId);
      productReports.value = result;

      print(
          '✅ Product reports loaded for journey plan: ${result.length} items');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to load product reports: $e';
      print('❌ Error loading product reports: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Report>> getProductReportsByClient(int clientId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting product reports for client: $clientId');

      final result =
          await ProductReportService.getProductReportsByClient(clientId);
      productReports.value = result;

      print('✅ Product reports loaded for client: ${result.length} items');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to load product reports: $e';
      print('❌ Error loading product reports: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitProductReport({
    required int journeyPlanId,
    required int clientId,
    required List<ProductReport> productReports,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print(
          '🔍 Submitting product report for journey plan: $journeyPlanId, client: $clientId');

      final result = await ProductReportService.submitProductReport(
        journeyPlanId: journeyPlanId,
        clientId: clientId,
        productReports: productReports,
        userId: userId,
      );

      print('✅ Product report submitted successfully: ${result.id}');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to submit product report: $e';
      print('❌ Error submitting product report: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
