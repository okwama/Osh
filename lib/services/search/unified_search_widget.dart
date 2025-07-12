import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/services/search/unified_search_controller.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/widgets/client/client_list_item.dart';

/// Unified search widget that consolidates all search functionality
/// Provides a complete search interface with suggestions, results, and error handling
class UnifiedSearchWidget extends StatefulWidget {
  final Function(Client)? onClientSelected;
  final String? hintText;
  final bool showSuggestions;
  final bool showClearButton;
  final bool showResults;
  final bool showLoadMore;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final bool autoFocus;
  final TextEditingController? controller;

  const UnifiedSearchWidget({
    super.key,
    this.onClientSelected,
    this.hintText,
    this.showSuggestions = true,
    this.showClearButton = true,
    this.showResults = true,
    this.showLoadMore = true,
    this.margin,
    this.borderRadius,
    this.autoFocus = false,
    this.controller,
  });

  @override
  State<UnifiedSearchWidget> createState() => _UnifiedSearchWidgetState();
}

class _UnifiedSearchWidgetState extends State<UnifiedSearchWidget> {
  late final UnifiedSearchController _searchController;
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController = Get.put(UnifiedSearchController());
    _textController = widget.controller ?? TextEditingController();

    // Listen to search controller changes
    ever(_searchController.currentQuery, (query) {
      if (_textController.text != query) {
        _textController.text = query;
      }
    });

    // Load suggestions when query changes
    ever(_searchController.currentQuery, (query) {
      if (widget.showSuggestions && query.length >= 2) {
        _searchController.loadSuggestions(query);
        setState(() => _showSuggestions = true);
      } else {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _textController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchController.updateSearchQuery(query);
  }

  void _onSuggestionSelected(String suggestion) {
    _textController.text = suggestion;
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
    _searchController.updateSearchQuery(suggestion);
  }

  void _onClientSelected(Client client) {
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
    widget.onClientSelected?.call(client);
  }

  void _clearSearch() {
    _textController.clear();
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
    _searchController.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search TextField
        _buildSearchField(),

        // Search Results or Suggestions
        if (_showSuggestions && widget.showSuggestions)
          _buildSuggestionsPanel(),

        // Search Results
        if (widget.showResults) _buildSearchResults(),

        // Loading Indicator
        if (_searchController.isSearching.value) _buildLoadingIndicator(),

        // Error Message
        if (_searchController.hasError) _buildErrorMessage(),

        // Empty State
        if (_searchController.isEmpty) _buildEmptyState(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        autofocus: widget.autoFocus,
        onChanged: _onSearchChanged,
        onTap: () {
          if (widget.showSuggestions && _textController.text.length >= 2) {
            setState(() => _showSuggestions = true);
          }
        },
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search clients...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _buildSuffixIcon(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    return Obx(() {
      if (_searchController.isSearching.value) {
        return const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (widget.showClearButton && _textController.text.isNotEmpty) {
        return IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: _clearSearch,
        );
      }

      return const SizedBox.shrink();
    });
  }

  Widget _buildSuggestionsPanel() {
    return Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_searchController.isLoadingSuggestions.value)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading suggestions...'),
                    ],
                  ),
                )
              else if (_searchController.hasSuggestions)
                ..._searchController.suggestions
                    .map((suggestion) => _buildSuggestionTile(suggestion)),
            ],
          ),
        ));
  }

  Widget _buildSuggestionTile(String suggestion) {
    return ListTile(
      leading: const Icon(Icons.search, color: Colors.grey),
      title: Text(suggestion),
      onTap: () => _onSuggestionSelected(suggestion),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (!_searchController.hasResults) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${_searchController.resultCount} results found',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ..._searchController.searchResults
                .map((client) => _buildClientTile(client)),
            if (widget.showLoadMore && _searchController.hasMoreResults.value)
              _buildLoadMoreButton(),
          ],
        ),
      );
    });
  }

  Widget _buildClientTile(Client client) {
    return ClientListItem(
      client: client,
      onTap: () => _onClientSelected(client),
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _searchController.loadMoreResults,
          child: const Text('Load More Results'),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Searching...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Obx(() => Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _searchController.errorMessage.value,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              TextButton(
                onPressed: _searchController.retrySearch,
                child: const Text('Retry'),
              ),
            ],
          ),
        ));
  }

  Widget _buildEmptyState() {
    return Obx(() {
      if (!_searchController.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(24.0),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Try adjusting your search terms',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
