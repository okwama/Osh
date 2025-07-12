# Unified Search System

## Overview

This folder contains the consolidated search functionality for the Woosh application. All search-related code has been unified into a single, efficient system that eliminates redundancy and improves performance.

## Files

### `unified_search_service.dart`
- **Purpose**: Core search service with caching and performance optimizations
- **Features**: 
  - Server-side search with multi-term support
  - Intelligent caching (5-minute validity)
  - Performance monitoring and metrics
  - Location-based search using Haversine formula
  - Search suggestions
  - Field-specific search

### `unified_search_controller.dart`
- **Purpose**: GetX controller for reactive state management
- **Features**:
  - Debounced search (300ms delay)
  - Search history management
  - Error handling and retry logic
  - Performance metrics tracking
  - Search configuration management

### `unified_search_widget.dart`
- **Purpose**: Complete search UI component
- **Features**:
  - Modern, responsive design
  - Search suggestions with loading states
  - Error handling and empty states
  - Load more functionality
  - Customizable appearance

### `index.dart`
- **Purpose**: Export file for easy imports
- **Usage**: `import 'package:woosh/services/search/index.dart';`

## Migration from Old Search System

### Before (Redundant Files):
- `lib/services/core/search_service.dart` ❌ (Deleted)
- `lib/services/core/client_search_service.dart` ❌ (Deleted)
- `lib/controllers/search_controller.dart` ❌ (Deleted)
- `lib/widgets/search_widget.dart` ❌ (Deleted)
- `lib/widgets/client/client_search_widget.dart` ✅ (Kept for specific use cases)
- `lib/widgets/journey_plan/client_search_widget.dart` ✅ (Kept for specific use cases)

### After (Unified System):
- `lib/services/search/unified_search_service.dart` ✅
- `lib/services/search/unified_search_controller.dart` ✅
- `lib/services/search/unified_search_widget.dart` ✅

## Usage Examples

### Basic Search Implementation

```dart
import 'package:woosh/services/search/index.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final UnifiedSearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = Get.put(UnifiedSearchController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UnifiedSearchWidget(
        onClientSelected: (client) {
          print('Selected: ${client.name}');
        },
        hintText: 'Search clients...',
        showSuggestions: true,
        showResults: true,
      ),
    );
  }
}
```

### Advanced Search with Custom Configuration

```dart
// Configure search settings
_searchController.updateSearchConfig(
  newPageSize: 50,
  newOrderBy: 'name',
  newOrderDirection: 'ASC',
  newUseCache: true,
);

// Perform field-specific search
await _searchController.searchByField(
  field: 'name',
  value: 'john',
);

// Location-based search
await _searchController.searchNearLocation(
  latitude: -1.2921,
  longitude: 36.8219,
  radiusKm: 10.0,
);
```

### Direct Service Usage

```dart
import 'package:woosh/services/search/unified_search_service.dart';

final searchService = UnifiedSearchService.instance;

// Search with caching
final result = await searchService.searchClients(
  query: 'john nairobi',
  page: 1,
  limit: 100,
  useCache: true,
);

// Get search statistics
final stats = await searchService.getSearchStats(query: 'john');
print('Cache hit rate: ${stats['cacheHitRate']}');
```

## Performance Features

### Caching
- **Cache Size**: 100 entries maximum
- **Cache Validity**: 5 minutes
- **Cache Hit Rate**: Monitored and reported

### Performance Monitoring
- **Query Duration**: Tracked for all searches
- **Cache Statistics**: Hit rates and usage patterns
- **Search Metrics**: Historical performance data

### Optimizations
- **Debouncing**: 300ms delay to prevent excessive API calls
- **Server-side Search**: All filtering happens in database
- **Pagination**: Efficient loading of large datasets
- **Country Filtering**: Automatic security isolation

## Error Handling

The unified search system includes comprehensive error handling:

```dart
// Automatic retry on failure
if (_searchController.hasError) {
  await _searchController.retrySearch();
}

// Clear cache if needed
await _searchController.clearSearchCache();

// Get error details
if (_searchController.errorMessage.value.isNotEmpty) {
  print('Search error: ${_searchController.errorMessage.value}');
}
```

## Benefits of Consolidation

1. **Reduced Code Duplication**: Single source of truth for search logic
2. **Improved Performance**: Unified caching and optimization
3. **Better Maintainability**: Centralized search functionality
4. **Consistent UX**: Standardized search interface across the app
5. **Enhanced Security**: Unified country-based filtering
6. **Better Error Handling**: Centralized error management

## Migration Checklist

- [x] Delete redundant search files
- [x] Move unified files to `lib/services/search/`
- [x] Update import paths
- [x] Create index file for easy imports
- [x] Document the unified system
- [ ] Update existing pages to use unified search
- [ ] Test all search functionality
- [ ] Monitor performance improvements

## Performance Metrics

From the logs, we can see:
- ✅ **Smart Sync**: Incremental client sync working
- ✅ **Caching**: Storage service properly initialized
- ⚠️ **Database**: Some slow queries detected (1-2 seconds)
- 🔧 **Recommendation**: Add database indexes for frequently searched fields 