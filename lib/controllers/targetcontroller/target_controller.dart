import 'package:get/get.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:woosh/utils/error_handler.dart';

class TargetController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> dailyVisitTargets = <String, dynamic>{}.obs;
  final RxList<dynamic> monthlyVisits = <dynamic>[].obs;
  final RxMap<String, dynamic> newClientsProgress = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> productSalesProgress = <String, dynamic>{}.obs;

  /// Get daily visit targets for a user
  Future<Map<String, dynamic>> getDailyVisitTargets({
    required String userId,
    String? date,
  }) async {
    try {
      isLoading.value = true;
      final result = await TargetService.getDailyVisitTargets(
        userId: userId,
        date: date,
      );
      dailyVisitTargets.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'TargetController.getDailyVisitTargets');
      return {
        'visitTarget': 0,
        'completedVisits': 0,
        'remainingVisits': 0,
        'progress': 0,
        'status': 'Error',
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Get monthly visits for a user
  Future<List<dynamic>> getMonthlyVisits({required String userId}) async {
    try {
      isLoading.value = true;
      final result = await TargetService.getMonthlyVisits(userId: userId);
      monthlyVisits.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'TargetController.getMonthlyVisits');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get new clients progress for a user
  Future<Map<String, dynamic>> getNewClientsProgress(
    int userId, {
    String period = 'current_month',
  }) async {
    try {
      isLoading.value = true;
      final result = await TargetService.getNewClientsProgress(
        userId,
        period: period,
      );
      newClientsProgress.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'TargetController.getNewClientsProgress');
      return {
        'newClientsTarget': 0,
        'newClientsAdded': 0,
        'remainingClients': 0,
        'progress': 0,
        'status': 'Error',
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Get product sales progress for a user
  Future<Map<String, dynamic>> getProductSalesProgress(
    int userId, {
    String productType = 'all',
    String period = 'current_month',
  }) async {
    try {
      isLoading.value = true;
      final result = await TargetService.getProductSalesProgress(
        userId,
        productType: productType,
        period: period,
      );
      productSalesProgress.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'TargetController.getProductSalesProgress');
      return {
        'summary': {
          'vapes': {'target': 0, 'sold': 0, 'progress': 0, 'status': 'Error'},
          'pouches': {'target': 0, 'sold': 0, 'progress': 0, 'status': 'Error'},
          'totalOrders': 0,
          'totalQuantitySold': 0,
        },
        'productBreakdown': [],
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Get all targets summary for a user
  Future<Map<String, dynamic>> getAllTargetsSummary(int userId) async {
    try {
      isLoading.value = true;

      final results = await Future.wait([
        getDailyVisitTargets(userId: userId.toString()),
        getNewClientsProgress(userId),
        getProductSalesProgress(userId),
      ]);

      return {
        'dailyVisits': results[0],
        'newClients': results[1],
        'productSales': results[2],
      };
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'TargetController.getAllTargetsSummary');
      return {
        'dailyVisits': {'status': 'Error'},
        'newClients': {'status': 'Error'},
        'productSales': {
          'summary': {
            'vapes': {'status': 'Error'},
            'pouches': {'status': 'Error'}
          }
        },
      };
    } finally {
      isLoading.value = false;
    }
  }
}
