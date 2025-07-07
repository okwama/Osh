import 'dart:async';
import 'package:woosh/models/outlet_model.dart';
import 'package:woosh/services/database/pagination_service.dart';
import 'package:woosh/services/database_service.dart';

class ClientSearchService {
  static final ClientSearchService _instance = ClientSearchService._internal();
  factory ClientSearchService() => _instance;
  ClientSearchService._internal();

  final PaginationService _paginationService = PaginationService.instance;
  final DatabaseService _db = DatabaseService.instance;

  /// Search clients with improved loading state management
  Future<List<Outlet>> searchClients({
    required String query,
    required int currentPage,
    required int pageSize,
    required List<Outlet> existingOutlets,
    required bool hasMore,
  }) async {
    try {
      print('🔍 Starting search for: "$query"');

      // Get current user's country ID for filtering
      final currentUser = await _db.getCurrentUserDetails();
      final countryId = currentUser['countryId'];

      print('📍 Searching clients for country ID: $countryId');

      // Always search through existing outlets first
      final searchTerms = query.toLowerCase().split(' ');
      bool foundMatch = _hasMatch(existingOutlets, searchTerms);
      
      print('🔍 Checking existing ${existingOutlets.length} outlets for match...');
      if (foundMatch) {
        print('✅ Found match in existing outlets');
        return existingOutlets;
      }

      // If no match found in existing outlets and there are more pages, load more
      if (query.isNotEmpty && hasMore) {
        print('📄 No match in existing outlets, loading more pages...');
        return await _loadMoreUntilFound(
          query: query,
          currentPage: currentPage,
          pageSize: pageSize,
          existingOutlets: existingOutlets,
          countryId: countryId,
        );
      }

      // If no more pages and no match found, return existing outlets
      print('⚠️ No match found in existing outlets and no more pages available');
      return existingOutlets;
    } catch (e) {
      print('❌ Error in searchClients: $e');
      rethrow;
    }
  }

  /// Load more clients until search term is found or end reached
  Future<List<Outlet>> _loadMoreUntilFound({
    required String query,
    required int currentPage,
    required int pageSize,
    required List<Outlet> existingOutlets,
    required int countryId,
  }) async {
    final searchTerms = query.toLowerCase().split(' ');
    List<Outlet> allOutlets = List.from(existingOutlets);
    int page = currentPage;
    bool hasMore = true;

    // Check if we already have a match in existing outlets
    bool foundMatch = _hasMatch(allOutlets, searchTerms);

    print('🔍 Checking existing ${allOutlets.length} outlets for match...');
    if (foundMatch) {
      print('✅ Found match in existing outlets');
      return allOutlets;
    }

    // Load more pages until we find a match or reach the end
    while (!foundMatch && hasMore) {
      print('📄 Loading page ${page + 1} to search for: "$query"');

      try {
        final result = await _paginationService.fetchOffset(
          table: 'Clients',
          page: page + 1,
          limit: pageSize,
          filters: {
            'countryId': countryId,
          },
          additionalWhere: 'countryId IS NOT NULL AND countryId > 0',
          orderBy: 'id',
          orderDirection: 'DESC',
          columns: [
            'id',
            'name',
            'address',
            'contact',
            'latitude',
            'longitude',
            'email',
            'region_id',
            'region',
            'countryId',
          ],
        );

        final newOutlets = result.items
            .map((row) => Outlet(
                  id: row['id'] as int,
                  name: row['name'] as String,
                  address: row['address'] as String? ?? '',
                  latitude: row['latitude'] as double?,
                  longitude: row['longitude'] as double?,
                  email: row['email'] as String? ?? '',
                  contact: row['contact'] as String? ?? '',
                  regionId: row['region_id'] as int?,
                  region: row['region'] as String? ?? '',
                  countryId: row['countryId'] as int?,
                ))
            .toList();

        allOutlets.addAll(newOutlets);
        page++;
        hasMore = result.hasMore;

        print(
            '📄 Loaded ${newOutlets.length} more clients, total: ${allOutlets.length}');

        // Check for match in new outlets
        foundMatch = _hasMatch(newOutlets, searchTerms);

        if (foundMatch) {
          print('✅ Found match in newly loaded outlets');
        }

        // Limit the search to prevent infinite loading
        if (page > 10) {
          print('⚠️ Reached maximum search pages (10), stopping search');
          break;
        }
      } catch (e) {
        print('❌ Error loading more clients for search: $e');
        break;
      }
    }

    print(
        '🔍 Search completed. Total outlets: ${allOutlets.length}, Found match: $foundMatch');
    return allOutlets;
  }

  /// Check if any outlet matches the search terms
  bool _hasMatch(List<Outlet> outlets, List<String> searchTerms) {
    return outlets.any((outlet) {
      final name = outlet.name.toLowerCase();
      final address = outlet.address.toLowerCase();
      final contact = outlet.contact?.toLowerCase() ?? '';
      final email = outlet.email?.toLowerCase() ?? '';

      return searchTerms.every((term) =>
          name.contains(term) ||
          address.contains(term) ||
          contact.contains(term) ||
          email.contains(term));
    });
  }

  /// Filter outlets based on search query and filters
  List<Outlet> filterOutlets({
    required List<Outlet> outlets,
    required String query,
    required bool showOnlyWithContact,
    required bool showOnlyWithEmail,
  }) {
    List<Outlet> filtered = outlets;

    // Apply text search filter
    if (query.isNotEmpty) {
      final searchTerms = query.toLowerCase().split(' ');
      filtered = filtered.where((outlet) {
        final name = outlet.name.toLowerCase();
        final address = outlet.address.toLowerCase();
        final contact = outlet.contact?.toLowerCase() ?? '';
        final email = outlet.email?.toLowerCase() ?? '';

        return searchTerms.every((term) =>
            name.contains(term) ||
            address.contains(term) ||
            contact.contains(term) ||
            email.contains(term));
      }).toList();
    }

    // Apply contact filter
    if (showOnlyWithContact) {
      filtered = filtered
          .where((outlet) => outlet.contact?.isNotEmpty == true)
          .toList();
    }

    // Apply email filter
    if (showOnlyWithEmail) {
      filtered =
          filtered.where((outlet) => outlet.email?.isNotEmpty == true).toList();
    }

    return filtered;
  }
}
