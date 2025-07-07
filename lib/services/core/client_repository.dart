import 'package:woosh/models/client_model.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database/query_executor.dart';
import 'package:woosh/services/database/auth_service.dart';

/// Repository pattern implementation for Client data access
/// Abstracts database operations from controllers
class ClientRepository {
  static ClientRepository? _instance;
  static ClientRepository get instance => _instance ??= ClientRepository._();

  ClientRepository._();

  final PaginationService _paginationService = PaginationService.instance;
  final QueryExecutor _queryExecutor = QueryExecutor.instance;

  /// Get paginated clients with proper abstraction
  Future<PaginatedResult<Client>> getClients({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    int? routeId,
    int? countryId,
    String orderBy = 'id',
    String orderDirection = 'DESC',
  }) async {
    try {
      // Get current user's countryId for mandatory security filtering
      final currentUser =
          await DatabaseAuthService.instance.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      // Build filters map for pagination service
      final filters = <String, dynamic>{};

      if (routeId != null) {
        filters['route_id'] = routeId;
      }

      // Always use user's countryId for security, ignore provided countryId parameter
      filters['countryId'] = userCountryId;

      // Use pagination service
      final result = await _paginationService.fetchOffset(
        table: 'Clients',
        page: page,
        limit: limit,
        filters: filters,
        orderBy: orderBy,
        orderDirection: orderDirection,
        columns: [
          'id',
          'name',
          'address',
          'contact',
          'email',
          'latitude',
          'longitude',
          'balance',
          'client_type',
          'countryId',
          'region_id',
          'route_id',
          'created_at',
        ],
      );

      // Convert to Client objects
      final clients =
          result.items.map((row) => Client.fromJson(row.fields)).toList();

      return PaginatedResult<Client>(
        items: clients,
        nextCursor: result.nextCursor,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
        queryDuration: result.queryDuration,
      );
    } catch (e) {
      print('❌ Error fetching clients: $e');
      rethrow;
    }
  }

  /// Get client by ID
  Future<Client?> getClientById(int id) async {
    try {
      // Get current user's countryId for security filtering
      final currentUser =
          await DatabaseAuthService.instance.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      final result = await _queryExecutor.executeSingle(
        'SELECT * FROM Clients WHERE id = ? AND countryId = ?',
        [id, userCountryId],
      );

      if (result == null) return null;
      return Client.fromJson(result.fields);
    } catch (e) {
      print('❌ Error fetching client by ID: $e');
      rethrow;
    }
  }

  /// Create new client
  Future<Client> createClient(
    Client client, {
    int? currentUserId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _queryExecutor.execute(
        '''
        INSERT INTO Clients (name, contact, email, address, client_type, countryId, region_id, added_by, latitude, longitude, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ''',
        [
          client.name,
          client.contact,
          client.email,
          client.address,
          client.clientType ?? 1,
          client.countryId,
          client.regionId,
          currentUserId ?? client.addedBy,
          latitude ?? client.latitude,
          longitude ?? client.longitude,
        ],
      );

      final newId = result.insertId;
      if (newId == null) throw Exception('Failed to create client');

      return await getClientById(newId) ?? client;
    } catch (e) {
      print('❌ Error creating client: $e');
      rethrow;
    }
  }

  /// Update existing client
  Future<Client> updateClient(Client client) async {
    try {
      // Get current user's countryId for security filtering
      final currentUser =
          await DatabaseAuthService.instance.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      await _queryExecutor.execute(
        '''
        UPDATE Clients 
        SET name = ?, contact = ?, email = ?, address = ?, client_type = ?, updatedAt = NOW()
        WHERE id = ? AND countryId = ?
        ''',
        [
          client.name,
          client.contact,
          client.email,
          client.address,
          client.clientType ?? 1,
          client.id,
          userCountryId, // Add countryId verification
        ],
      );

      return await getClientById(client.id) ?? client;
    } catch (e) {
      print('❌ Error updating client: $e');
      rethrow;
    }
  }

  /// Delete client
  Future<bool> deleteClient(int id) async {
    try {
      // Get current user's countryId for security filtering
      final currentUser =
          await DatabaseAuthService.instance.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      final result = await _queryExecutor.execute(
        'DELETE FROM Clients WHERE id = ? AND countryId = ?',
        [id, userCountryId],
      );

      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      print('❌ Error deleting client: $e');
      rethrow;
    }
  }

  /// Get client statistics
  Future<Map<String, dynamic>> getClientStats() async {
    try {
      // Get current user's countryId for security filtering
      final currentUser =
          await DatabaseAuthService.instance.getCurrentUserDetails();
      final userCountryId = currentUser['countryId'];

      if (userCountryId == null) {
        throw Exception('User countryId not found - access denied');
      }

      final result = await _queryExecutor.executeSingle(
        '''
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN status = 1 THEN 1 END) as active,
          COUNT(CASE WHEN status = 0 THEN 1 END) as inactive
        FROM Clients
        WHERE countryId = ?
        ''',
        [userCountryId],
      );

      if (result == null) {
        return {'total': 0, 'active': 0, 'inactive': 0};
      }

      return {
        'total': result.fields['total'],
        'active': result.fields['active'],
        'inactive': result.fields['inactive'],
      };
    } catch (e) {
      print('❌ Error getting client stats: $e');
      rethrow;
    }
  }
}
