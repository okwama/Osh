import 'package:get/get.dart';
import 'package:woosh/services/core/client_service.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/utils/error_handler.dart';

class ClientServiceController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Client> clients = <Client>[].obs;
  final RxMap<String, dynamic> clientStats = <String, dynamic>{}.obs;

  /// Fetch clients using keyset pagination
  Future<PaginatedResult<Client>> fetchClientsKeyset({
    dynamic lastClientId,
    int limit = 100,
    Map<String, dynamic> filters = const {},
    String? orderDirection,
    int? addedBy,
    String? searchQuery,
  }) async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.fetchClientsKeyset(
        lastClientId: lastClientId,
        limit: limit,
        filters: filters,
        orderDirection: orderDirection,
        addedBy: addedBy,
        searchQuery: searchQuery,
      );
      clients.value = result.items;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientServiceController.fetchClientsKeyset');
      return PaginatedResult<Client>(
        items: [],
        hasMore: false,
        queryDuration: Duration.zero,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch clients using offset pagination
  Future<PaginatedResult<Client>> fetchClientsOffset({
    int page = 1,
    int limit = 50,
    Map<String, dynamic> filters = const {},
    String? orderBy,
    String? orderDirection,
    int? addedBy,
    String? searchQuery,
  }) async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.fetchClientsOffset(
        page: page,
        limit: limit,
        filters: filters,
        orderBy: orderBy,
        orderDirection: orderDirection,
        addedBy: addedBy,
        searchQuery: searchQuery,
      );
      clients.value = result.items;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientServiceController.fetchClientsOffset');
      return PaginatedResult<Client>(
        items: [],
        hasMore: false,
        queryDuration: Duration.zero,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Search clients
  Future<PaginatedResult<Client>> searchClients({
    required String query,
    int page = 1,
    int limit = 100,
    String? orderBy,
    String? orderDirection,
    int? addedBy,
  }) async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.searchClients(
        query: query,
        page: page,
        limit: limit,
        orderBy: orderBy,
        orderDirection: orderDirection,
        addedBy: addedBy,
      );
      clients.value = result.items;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientServiceController.searchClients');
      return PaginatedResult<Client>(
        items: [],
        hasMore: false,
        queryDuration: Duration.zero,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get client by ID
  Future<Client?> getClientById(int clientId) async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.getClientById(clientId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientServiceController.getClientById');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new client
  Future<Client?> createClient(Client client) async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.createClient(client);
      if (result != null) {
        // Refresh clients list
        await fetchClientsOffset();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'ClientServiceController.createClient');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing client
  Future<Client?> updateClient(Client client) async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.updateClient(client);
      if (result != null) {
        // Refresh clients list
        await fetchClientsOffset();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'ClientServiceController.updateClient');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a client
  Future<bool> deleteClient(int clientId) async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.deleteClient(clientId);
      if (result) {
        // Refresh clients list
        await fetchClientsOffset();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'ClientServiceController.deleteClient');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get client statistics
  Future<Map<String, dynamic>> getClientStats() async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.getClientStats();
      clientStats.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientServiceController.getClientStats');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      isLoading.value = true;
      final result = await ClientService.instance.getPerformanceMetrics();
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'ClientServiceController.getPerformanceMetrics');
      return {};
    } finally {
      isLoading.value = false;
    }
  }
}
