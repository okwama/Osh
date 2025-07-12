import 'package:get/get.dart';
import 'package:woosh/services/core/journeyplan/journey_checkin_service.dart';

class JourneyCheckinController extends GetxController {
  final JourneyCheckInService _checkinService = JourneyCheckInService();

  final RxBool isLoading = false.obs;
  final RxBool isCheckinSuccessful = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 JourneyCheckinController initialized');
  }

  Future<bool> checkIn(int journeyPlanId, double latitude, double longitude,
      String address) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      isCheckinSuccessful.value = false;
      print('🔍 Performing check-in for journey plan: $journeyPlanId');

      final result = await _checkinService.checkIn(
          journeyPlanId, latitude, longitude, address);
      isCheckinSuccessful.value = result;

      if (result) {
        print('✅ Check-in successful for journey plan: $journeyPlanId');
      } else {
        print('⚠️ Check-in failed for journey plan: $journeyPlanId');
      }

      return result;
    } catch (e) {
      errorMessage.value = 'Failed to check-in: $e';
      print('❌ Error during check-in: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> checkOut(int journeyPlanId, double latitude, double longitude,
      String address) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      isCheckinSuccessful.value = false;
      print('🔍 Performing check-out for journey plan: $journeyPlanId');

      final result = await _checkinService.checkOut(
          journeyPlanId, latitude, longitude, address);
      isCheckinSuccessful.value = result;

      if (result) {
        print('✅ Check-out successful for journey plan: $journeyPlanId');
      } else {
        print('⚠️ Check-out failed for journey plan: $journeyPlanId');
      }

      return result;
    } catch (e) {
      errorMessage.value = 'Failed to check-out: $e';
      print('❌ Error during check-out: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getCheckinStatus(int journeyPlanId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting check-in status for journey plan: $journeyPlanId');

      final result = await _checkinService.getCheckinStatus(journeyPlanId);

      print('✅ Check-in status retrieved for journey plan: $journeyPlanId');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to get check-in status: $e';
      print('❌ Error getting check-in status: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
