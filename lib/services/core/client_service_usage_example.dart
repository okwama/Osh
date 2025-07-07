import 'package:woosh/services/core/client_service.dart';
import 'package:woosh/models/client_model.dart';

/// Example usage of the ClientService
/// This file demonstrates how to use the new client service with direct database connections
class ClientServiceUsageExample {
  /// Example: Get all clients with pagination
  static Future<void> getClientsExample() async {
    try {
      final clientService = ClientService.instance;

      // Get first page of clients (20 per page)
      final clients = await clientService.getClients(
        page: 1,
        limit: 20,
      );

      print('Found ${clients.length} clients');
      for (final client in clients) {
        print('Client: ${client.name} - ${client.address}');
      }
    } catch (e) {
      print('Error fetching clients: $e');
    }
  }

  /// Example: Get clients optimized for journey plan creation
  static Future<void> getClientsForJourneyPlanExample() async {
    try {
      final clientService = ClientService.instance;

      // Get lightweight client data for journey plan creation
      final clients = await clientService.getClientsForJourneyPlan(
        page: 1,
        limit: 50,
        search: 'Nairobi',
      );

      print('Found ${clients.length} clients for journey planning');
      for (final client in clients) {
        print('JP Client: ${client.name} - ${client.address}');
        // Only essential fields are loaded: id, name, address, contact, email
      }
    } catch (e) {
      print('Error fetching clients for journey plan: $e');
    }
  }

  /// Example: Search clients by name, address, or contact
  static Future<void> searchClientsExample() async {
    try {
      final clientService = ClientService.instance;
      final searchResults = await clientService.searchClients(query: 'Nairobi');
      print('Found ${searchResults.items.length} clients matching "Nairobi"');
    } catch (e) {
      print('Error searching clients: $e');
    }
  }

  /// Example: Get clients by region
  static Future<void> getClientsByRegionExample() async {
    try {
      final clientService = ClientService.instance;
      final regionClients = await clientService.getClientsByRegion(1);
      print('Found ${regionClients.length} clients in region 1');
    } catch (e) {
      print('Error fetching clients by region: $e');
    }
  }

  /// Example: Create a new client
  static Future<void> createClientExample() async {
    try {
      final clientService = ClientService.instance;

      final newClient = Client(
        id: 0, // Will be set by database
        name: 'New Client Store',
        address: '123 Main Street, Nairobi',
        regionId: 1,
        region: 'Nairobi',
        countryId: 1,
        contact: '+254700000000',
        email: 'contact@newclient.com',
        latitude: -1.2921,
        longitude: 36.8219,
        clientType: 1,
      );

      final createdClient = await clientService.createClient(newClient);
      print(
          'Created client: ${createdClient.name} with ID: ${createdClient.id}');
    } catch (e) {
      print('Error creating client: $e');
    }
  }

  /// Example: Update client location
  static Future<void> updateClientLocationExample() async {
    try {
      final clientService = ClientService.instance;
      final updatedClient = await clientService.updateClientLocation(
        clientId: 1,
        latitude: -1.2921,
        longitude: 36.8219,
      );

      print('Updated client location: ${updatedClient.name}');
      print(
          'New coordinates: ${updatedClient.latitude}, ${updatedClient.longitude}');
    } catch (e) {
      print('Error updating client location: $e');
    }
  }

  /// Example: Get clients near a specific location
  static Future<void> getClientsNearLocationExample() async {
    try {
      final clientService = ClientService.instance;
      final nearbyClients = await clientService.getClientsNearLocation(
        latitude: -1.2921,
        longitude: 36.8219,
        radiusKm: 10.0,
        limit: 20,
      );

      print('Found ${nearbyClients.length} clients within 10km');
      for (final client in nearbyClients) {
        print('Nearby client: ${client.name}');
      }
    } catch (e) {
      print('Error fetching nearby clients: $e');
    }
  }

  /// Example: Get client statistics
  static Future<void> getClientStatsExample() async {
    try {
      final clientService = ClientService.instance;
      final stats = await clientService.getClientStats();

      print('Client Statistics:');
      print('Total clients: ${stats['total']}');
      print('Active clients: ${stats['active']}');
      print('Inactive clients: ${stats['inactive']}');
    } catch (e) {
      print('Error fetching client stats: $e');
    }
  }

  /// Example: Update client information
  static Future<void> updateClientExample() async {
    try {
      final clientService = ClientService.instance;

      // First get the existing client
      final existingClient = await clientService.getClientById(1);
      if (existingClient == null) {
        print('Client not found');
        return;
      }

      // Create updated client with new values
      final updatedClient = Client(
        id: existingClient.id,
        name: 'Updated Client Name',
        address: 'Updated Address',
        regionId: existingClient.regionId ?? 1,
        region: existingClient.region ?? '',
        countryId: existingClient.countryId ?? 1,
        contact: '+254700000001',
        email: 'updated@client.com',
        latitude: existingClient.latitude,
        longitude: existingClient.longitude,
        clientType: existingClient.clientType,
      );

      final result = await clientService.updateClient(updatedClient);
      print('Updated client: ${result.name}');
    } catch (e) {
      print('Error updating client: $e');
    }
  }

  /// Example: Delete client
  static Future<void> deleteClientExample() async {
    try {
      final clientService = ClientService.instance;
      final success = await clientService.deleteClient(1);

      if (success) {
        print('Client deleted successfully');
      } else {
        print('Client not found or could not be deleted');
      }
    } catch (e) {
      print('Error deleting client: $e');
    }
  }

  /// Example: Advanced pagination with keyset
  static Future<void> advancedPaginationExample() async {
    try {
      final clientService = ClientService.instance;

      // First page
      final firstPage = await clientService.fetchClientsKeyset(
        limit: 10,
        orderDirection: 'DESC',
      );

      print('First page: ${firstPage.items.length} clients');
      print('Has more: ${firstPage.hasMore}');
      print('Next cursor: ${firstPage.nextCursor}');
      print('Query duration: ${firstPage.queryDuration.inMilliseconds}ms');

      // Second page using cursor
      if (firstPage.hasMore && firstPage.nextCursor != null) {
        final secondPage = await clientService.fetchClientsKeyset(
          lastClientId: firstPage.nextCursor,
          limit: 10,
          orderDirection: 'DESC',
        );

        print('Second page: ${secondPage.items.length} clients');
        print('Has more: ${secondPage.hasMore}');
      }
    } catch (e) {
      print('Error with advanced pagination: $e');
    }
  }

  /// Example: Search with pagination
  static Future<void> searchWithPaginationExample() async {
    try {
      final clientService = ClientService.instance;

      final searchResults = await clientService.searchClients(
        query: 'Nairobi',
        limit: 15,
        orderDirection: 'ASC',
      );

      print('Search results: ${searchResults.items.length} clients');
      print('Has more: ${searchResults.hasMore}');

      for (final client in searchResults.items) {
        print('Found: ${client.name} - ${client.address}');
      }
    } catch (e) {
      print('Error searching with pagination: $e');
    }
  }

  /// Example: Get performance metrics
  static Future<void> performanceMetricsExample() async {
    try {
      final clientService = ClientService.instance;
      final metrics = await clientService.getPerformanceMetrics();

      print('Database Performance Metrics:');
      print('Pool size: ${metrics['pool_size']}');
      print('Active connections: ${metrics['active_connections']}');
      print('Total queries: ${metrics['total_queries_executed']}');
      print('Query timeouts: ${metrics['total_query_timeouts']}');
      print('Success rate: ${metrics['success_rate']}%');
      print('Is healthy: ${metrics['is_healthy']}');
    } catch (e) {
      print('Error getting performance metrics: $e');
    }
  }
}
