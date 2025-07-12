import 'package:get/get.dart';
import 'package:woosh/services/core/leave_balance_service.dart';

class LeaveBalanceController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<dynamic> leaveBalances = <dynamic>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 LeaveBalanceController initialized');
  }

  Future<void> getLeaveBalances({
    int? userId,
    int? year,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Fetching leave balances for user: $userId, year: $year');

        final result = await LeaveBalanceService.getLeaveBalances(
        userId: userId,
        year: year,
      );
      leaveBalances.value = result;

      print('✅ Leave balances loaded: ${leaveBalances.length} items');
    } catch (e) {
      errorMessage.value = 'Failed to load leave balances: $e';
      print('❌ Error loading leave balances: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getLeaveBalanceById(int balanceId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting leave balance by ID: $balanceId');

      final result = await LeaveBalanceService.getLeaveBalanceById(balanceId);

      print('✅ Leave balance retrieved: $balanceId');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to get leave balance: $e';
      print('❌ Error getting leave balance: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateLeaveBalance(
      int balanceId, Map<String, dynamic> balanceData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Updating leave balance: $balanceId');

      final result =
          await LeaveBalanceService.updateLeaveBalance(balanceId, balanceData);

      if (result) {
        print('✅ Leave balance updated successfully: $balanceId');
        // Refresh the balances list
        await getLeaveBalances();
      } else {
        print('⚠️ Leave balance update failed: $balanceId');
      }

      return result;
    } catch (e) {
      errorMessage.value = 'Failed to update leave balance: $e';
      print('❌ Error updating leave balance: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
