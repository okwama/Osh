import 'package:get/get.dart';
import 'package:woosh/services/core/reports/visibility_report_service.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';

class VisibilityReportController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 VisibilityReportController initialized');
  }

  Future<bool> submitVisibilityReport({
    required int journeyPlanId,
    required int clientId,
    required String comment,
    String? imageUrl,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print(
          '🔍 Submitting visibility report for journey plan: $journeyPlanId, client: $clientId');

      final result = await VisibilityReportService.submitVisibilityReport(
        journeyPlanId: journeyPlanId,
        clientId: clientId,
        comment: comment,
        imageUrl: imageUrl,
        userId: userId,
      );

      print('✅ Visibility report submitted successfully: ${result.id}');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to submit visibility report: $e';
      print('❌ Error submitting visibility report: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
