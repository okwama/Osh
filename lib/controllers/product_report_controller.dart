import 'package:get/get.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/services/core/reports/product_report_service.dart';
import 'package:woosh/services/core/reports/report_service.dart';

enum ProductType {
  RETURN,
  SAMPLE,
}

class ProductReportController extends GetxController {
  final RxList<Report> productReports = <Report>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> loadProductReports({
    ProductType? type, // Filter by type (RETURN or SAMPLE)
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? clientId,
    int? userId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await ReportService.getReports(
        type: ReportType.PRODUCT_AVAILABILITY,
        clientId: clientId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );

      productReports.value = response;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Report?> getProductReportById(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await ReportService.getReportById(id);
      return response;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProductReportStatus(int id, String status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await ReportService.updateReportStatus(id, status);
      if (success) {
        // Update local state
        final index = productReports.indexWhere((report) => report.id == id);
        if (index != -1) {
          final updatedReport = await getProductReportById(id);
          if (updatedReport != null) {
            productReports[index] = updatedReport;
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

  Future<bool> deleteProductReport(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await ReportService.deleteReport(id);
      if (success) {
        productReports.removeWhere((report) => report.id == id);
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
