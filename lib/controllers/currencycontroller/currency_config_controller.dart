import 'package:get/get.dart';
import 'package:woosh/services/core/currency_config_service.dart';
import 'package:woosh/utils/error_handler.dart';

class CurrencyConfigController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<CurrencyConfig?> currentUserCurrencyConfig =
      Rx<CurrencyConfig?>(null);
  final RxMap<int, CurrencyConfig> allCurrencyConfigs =
      <int, CurrencyConfig>{}.obs;

  /// Get currency configuration for current user's country
  Future<CurrencyConfig?> getCurrentUserCurrencyConfig() async {
    try {
      isLoading.value = true;
      final result = await CurrencyConfigService.getCurrentUserCurrencyConfig();
      currentUserCurrencyConfig.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'CurrencyConfigController.getCurrentUserCurrencyConfig');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get currency configuration for a specific country
  Future<CurrencyConfig?> getCurrencyConfig(int countryId) async {
    try {
      isLoading.value = true;
      final result = await CurrencyConfigService.getCurrencyConfig(countryId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'CurrencyConfigController.getCurrencyConfig');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get all currency configurations from database
  Future<Map<int, CurrencyConfig>> getAllCurrencyConfigs(
      {bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      final result = await CurrencyConfigService.getAllCurrencyConfigs(
          forceRefresh: forceRefresh);
      allCurrencyConfigs.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'CurrencyConfigController.getAllCurrencyConfigs');
      return {};
    } finally {
      isLoading.value = false;
    }
  }

  /// Get currency value based on country configuration
  double getCurrencyValue(
      Map<String, dynamic> item, CurrencyConfig config, String type) {
    try {
      return CurrencyConfigService.getCurrencyValue(item, config, type);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'CurrencyConfigController.getCurrencyValue');
      return 0.0;
    }
  }

  /// Format currency value based on configuration
  String formatCurrency(double value, CurrencyConfig config) {
    try {
      return CurrencyConfigService.formatCurrency(value, config);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'CurrencyConfigController.formatCurrency');
      return value.toString();
    }
  }
}
