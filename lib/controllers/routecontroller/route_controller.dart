import 'package:get/get.dart';
import 'package:woosh/services/core/route_service.dart';
import 'package:woosh/utils/error_handler.dart';

class RouteController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Route> routes = <Route>[].obs;
  final RxList<RouteOption> routeOptions = <RouteOption>[].obs;
  final Rx<Route?> selectedRoute = Rx<Route?>(null);

  /// Get routes filtered by country ID
  Future<List<Route>> getRoutes({int? countryId}) async {
    try {
      isLoading.value = true;
      final result = await RouteService.getRoutes(countryId: countryId);
      routes.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'RouteController.getRoutes');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get routes for current user's country
  Future<List<Route>> getRoutesForCurrentUser() async {
    try {
      isLoading.value = true;
      final result = await RouteService.getRoutesForCurrentUser();
      routes.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'RouteController.getRoutesForCurrentUser');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get route by ID
  Future<Route?> getRouteById(int routeId) async {
    try {
      isLoading.value = true;
      final result = await RouteService.getRouteById(routeId);
      selectedRoute.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'RouteController.getRouteById');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get routes by region
  Future<List<Route>> getRoutesByRegion(int regionId) async {
    try {
      isLoading.value = true;
      final result = await RouteService.getRoutesByRegion(regionId);
      routes.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'RouteController.getRoutesByRegion');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get routes for current user's region
  Future<List<Route>> getRoutesForCurrentUserRegion() async {
    try {
      isLoading.value = true;
      final result = await RouteService.getRoutesForCurrentUserRegion();
      routes.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'RouteController.getRoutesForCurrentUserRegion');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get cached route options for current user's country
  Future<List<RouteOption>> getCachedRouteOptionsForCurrentUser() async {
    try {
      isLoading.value = true;
      final result = await RouteService.getCachedRouteOptionsForCurrentUser();
      routeOptions.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'RouteController.getCachedRouteOptionsForCurrentUser');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear route cache
  void clearCache() {
    try {
      RouteService.clearCache();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'RouteController.clearCache');
    }
  }

  /// Clear cache for specific country
  void clearCacheForCountry(int countryId) {
    try {
      RouteService.clearCacheForCountry(countryId);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'RouteController.clearCacheForCountry');
    }
  }

  /// Get cache status for debugging
  Map<String, dynamic> getCacheStatus() {
    try {
      return RouteService.getCacheStatus();
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'RouteController.getCacheStatus');
      return {};
    }
  }

  /// Set selected route
  void setSelectedRoute(Route? route) {
    selectedRoute.value = route;
  }

  /// Clear routes list
  void clearRoutes() {
    routes.clear();
  }

  /// Clear route options
  void clearRouteOptions() {
    routeOptions.clear();
  }
}
