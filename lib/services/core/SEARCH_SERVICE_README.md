# Search Service Documentation

## Overview

The `SearchService` provides efficient server-side search capabilities for the Flutter application, specifically designed for client data. It integrates with the existing database service and pagination system to deliver fast, scalable search results.

## Features

### ✅ **Server-Side Search**
- All filtering happens in the database, not in Flutter
- Returns only relevant results
- Supports large datasets efficiently

### ✅ **Multi-Term Search**
- Splits search queries into individual terms
- Uses AND logic (all terms must match)
- Searches across multiple fields: name, address, contact, email

### ✅ **Pagination Support**
- Integrates with existing pagination service
- Supports both offset and keyset pagination
- Configurable page sizes

### ✅ **Advanced Search Options**
- Field-specific search
- Location-based search (Haversine formula)
- Search suggestions
- Search statistics

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   SearchWidget  │───▶│ SearchController │───▶│  SearchService  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                                               ┌─────────────────┐
                                               │ DatabaseService │
                                               └─────────────────┘
```

## Usage Examples

### 1. Basic Search

```dart
import 'package:woosh/services/core/search_service.dart';

final searchService = SearchService.instance;

// Search clients
final result = await searchService.searchClients(
  query: 'john nairobi',
  page: 1,
  limit: 100,
);

print('Found ${result.items.length} clients');
```

### 2. Using Search Controller

```dart
import 'package:woosh/controllers/search_controller.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late SearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SearchWidget(
        searchController: _searchController,
        onClientSelected: (client) {
          print('Selected: ${client.name}');
        },
      ),
    );
  }
}
```

### 3. Field-Specific Search

```dart
// Search by specific field
final result = await searchService.searchClientsByField(
  field: 'name',
  value: 'john',
  page: 1,
  limit: 50,
);
```

### 4. Location-Based Search

```dart
// Search clients near a location
final result = await searchService.searchClientsNearLocation(
  latitude: -1.2921,
  longitude: 36.8219,
  radiusKm: 10.0,
  page: 1,
  limit: 100,
);
```

### 5. Search Suggestions

```dart
// Get search suggestions
final suggestions = await searchService.getSearchSuggestions(
  partialQuery: 'jo',
  limit: 10,
);
```

## API Reference

### SearchService

#### `searchClients()`
Main search method with multi-term support.

**Parameters:**
- `query` (String, required): Search query
- `page` (int): Page number (default: 1)
- `limit` (int): Results per page (default: 100)
- `orderBy` (String): Sort field (default: 'id')
- `orderDirection` (String): Sort direction (default: 'DESC')
- `addedBy` (int?): Filter by sales rep ID

**Returns:** `PaginatedResult<Client>`

#### `searchClientsByField()`
Search by specific field with exact matching.

**Parameters:**
- `field` (String, required): Field name ('name', 'address', 'contact', 'email')
- `value` (String, required): Search value
- `page` (int): Page number (default: 1)
- `limit` (int): Results per page (default: 100)
- `orderBy` (String): Sort field (default: 'id')
- `orderDirection` (String): Sort direction (default: 'DESC')
- `addedBy` (int?): Filter by sales rep ID

**Returns:** `PaginatedResult<Client>`

#### `searchClientsNearLocation()`
Search clients within a radius of a location.

**Parameters:**
- `latitude` (double, required): Center latitude
- `longitude` (double, required): Center longitude
- `radiusKm` (double): Search radius in kilometers (default: 10.0)
- `page` (int): Page number (default: 1)
- `limit` (int): Results per page (default: 100)
- `addedBy` (int?): Filter by sales rep ID

**Returns:** `PaginatedResult<Client>`

#### `getSearchSuggestions()`
Get search suggestions based on partial input.

**Parameters:**
- `partialQuery` (String, required): Partial search query
- `limit` (int): Number of suggestions (default: 10)
- `addedBy` (int?): Filter by sales rep ID

**Returns:** `List<String>`

#### `getSearchStats()`
Get search statistics for a query.

**Parameters:**
- `query` (String, required): Search query
- `addedBy` (int?): Filter by sales rep ID

**Returns:** `Map<String, dynamic>`

### SearchController

#### Properties
- `currentQuery` (String): Current search query
- `searchResults` (List<Client>): Current search results
- `isSearching` (bool): Whether search is in progress
- `hasMoreResults` (bool): Whether more results are available
- `errorMessage` (String?): Error message if search failed
- `suggestions` (List<String>): Search suggestions
- `isLoadingSuggestions` (bool): Whether suggestions are loading

#### Methods
- `updateSearchQuery(String query)`: Update search with debouncing
- `loadMoreResults()`: Load additional search results
- `searchByField(String field, String value)`: Search by specific field
- `searchNearLocation(double lat, double lng, double radius)`: Location search
- `loadSuggestions(String partialQuery)`: Load search suggestions
- `clearSearch()`: Clear search results
- `retrySearch()`: Retry failed search
- `refreshSearch()`: Refresh current search

## Search Widget

The `SearchWidget` provides a complete search interface with:

- **Debounced search input**
- **Search suggestions**
- **Loading indicators**
- **Error handling**
- **Results display**
- **Load more functionality**

### Usage

```dart
SearchWidget(
  searchController: searchController,
  onClientSelected: (client) {
    // Handle client selection
  },
  hintText: 'Search clients...',
  showSuggestions: true,
  showClearButton: true,
)
```

## Performance Optimizations

### Database Indexes
Ensure these indexes exist on your `Clients` table:

```sql
-- For general search
CREATE INDEX idx_clients_search ON Clients(name, address, contact, email);

-- For location search
CREATE INDEX idx_clients_location ON Clients(latitude, longitude);

-- For sales rep filtering
CREATE INDEX idx_clients_added_by ON Clients(added_by);
```

### Full-Text Search (Optional)
For better performance with large datasets, consider using MySQL full-text search:

```sql
ALTER TABLE Clients ADD FULLTEXT(name, address, contact, email);
```

Then update the search service to use `MATCH ... AGAINST` instead of `LIKE`.

## Error Handling

The search service includes comprehensive error handling:

```dart
try {
  final result = await searchService.searchClients(query: 'test');
  // Handle success
} catch (e) {
  print('Search failed: $e');
  // Handle error
}
```

## Integration with Existing Code

### Update Client Service
The `ClientService` has been updated to use the new search service:

```dart
// Old way (client-side search)
final clients = await clientService.getClients(search: 'john');

// New way (server-side search)
final result = await clientService.searchClients(query: 'john');
final clients = result.items;
```

### Update UI Pages
Replace client-side search logic with the search controller:

```dart
// Old way
List<Client> _filterClients(String query) {
  return _allClients.where((client) => 
    client.name.toLowerCase().contains(query.toLowerCase())
  ).toList();
}

// New way
final searchController = SearchController();
searchController.updateSearchQuery(query);
```

## Best Practices

1. **Use debouncing** to avoid excessive API calls
2. **Implement proper error handling** for network issues
3. **Cache frequent searches** if performance is critical
4. **Use appropriate page sizes** (50-100 items per page)
5. **Provide loading indicators** for better UX
6. **Handle empty states** gracefully
7. **Validate search inputs** before sending to server

## Migration Guide

### From Client-Side Search

1. **Replace filtering logic:**
   ```dart
   // Remove this
   List<Client> filteredClients = allClients.where(...).toList();
   
   // Use this instead
   final result = await searchService.searchClients(query: searchQuery);
   List<Client> filteredClients = result.items;
   ```

2. **Update UI components:**
   ```dart
   // Replace custom search widgets with SearchWidget
   SearchWidget(
     searchController: searchController,
     onClientSelected: handleClientSelection,
   )
   ```

3. **Update controllers:**
   ```dart
   // Replace manual search logic with SearchController
   final searchController = SearchController();
   searchController.updateSearchQuery(query);
   ```

### Benefits of Migration

- **Better Performance**: Server-side filtering is faster
- **Scalability**: Handles large datasets efficiently
- **Consistency**: Unified search behavior across the app
- **Maintainability**: Centralized search logic
- **User Experience**: Faster search results and better feedback 