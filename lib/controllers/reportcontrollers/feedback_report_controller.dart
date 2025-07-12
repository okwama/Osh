import 'package:get/get.dart';
import 'package:woosh/services/core/reports/feedback_report_service.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';

class FeedbackReportController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Report> feedbackReports = <Report>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 FeedbackReportController initialized');
  }

  Future<bool> submitFeedbackReport({
    required int journeyPlanId,
    required int clientId,
    required String comment,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print(
          '🔍 Submitting feedback report for journey plan: $journeyPlanId, client: $clientId');

      final result = await FeedbackReportService.submitFeedbackReport(
        journeyPlanId: journeyPlanId,
        clientId: clientId,
        comment: comment,
        userId: userId,
      );

      print('✅ Feedback report submitted successfully: ${result.id}');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to submit feedback report: $e';
      print('❌ Error submitting feedback report: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateFeedbackReport({
    required int reportId,
    required String comment,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Updating feedback report: $reportId');

      final result = await FeedbackReportService.updateFeedbackReport(
        reportId: reportId,
        comment: comment,
        userId: userId,
      );

      if (result) {
        print('✅ Feedback report updated successfully: $reportId');
      } else {
        print('⚠️ Feedback report update failed: $reportId');
      }

      return result;
    } catch (e) {
      errorMessage.value = 'Failed to update feedback report: $e';
      print('❌ Error updating feedback report: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
