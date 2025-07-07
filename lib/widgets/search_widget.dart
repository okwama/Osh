import 'package:flutter/material.dart' hide SearchController;
import 'package:woosh/controllers/search_controller.dart';
import 'package:woosh/models/client_model.dart';

/// Reusable search widget with modern UI and search functionality
class SearchWidget extends StatefulWidget {
  final SearchController searchController;
  final Function(Client)? onClientSelected;
  final String? hintText;
  final bool showSuggestions;
  final bool showClearButton;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;

  const SearchWidget({
    Key? key,
    required this.searchController,
    this.onClientSelected,
    this.hintText,
    this.showSuggestions = true,
    this.showClearButton = true,
    this.margin,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.searchController.currentQuery;
    widget.searchController.addListener(_onSearchControllerChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    widget.searchController.removeListener(_onSearchControllerChanged);
    super.dispose();
  }

  void _onSearchControllerChanged() {
    if (_textController.text != widget.searchController.currentQuery) {
      _textController.text = widget.searchController.currentQuery;
    }
  }

  void _onSearchChanged(String query) {
    widget.searchController.updateSearchQuery(query);

    if (widget.showSuggestions && query.length >= 2) {
      widget.searchController.loadSuggestions(query);
      setState(() => _showSuggestions = true);
    } else {
      setState(() => _showSuggestions = false);
    }
  }

  void _onSuggestionSelected(String suggestion) {
    _textController.text = suggestion;
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
    widget.searchController.updateSearchQuery(suggestion);
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
    widget.searchController.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search TextField
        Container(
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
                borderRadius:
                    BorderRadius.circular(widget.borderRadius ?? 12.0),
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
        ),

        // Search Results or Suggestions
        if (_showSuggestions && widget.showSuggestions)
          _buildSuggestionsPanel(),

        // Search Results
        if (widget.searchController.hasResults) _buildSearchResults(),

        // Loading Indicator
        if (widget.searchController.isSearching) _buildLoadingIndicator(),

        // Error Message
        if (widget.searchController.errorMessage != null) _buildErrorMessage(),

        // Empty State
        if (widget.searchController.isEmpty &&
            widget.searchController.currentQuery.isNotEmpty &&
            !widget.searchController.isSearching)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildSuffixIcon() {
    if (widget.searchController.isSearching) {
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
  }

  Widget _buildSuggestionsPanel() {
    return AnimatedContainer(
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
          if (widget.searchController.isLoadingSuggestions)
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
          else if (widget.searchController.suggestions.isNotEmpty)
            ...widget.searchController.suggestions
                .map((suggestion) => _buildSuggestionTile(suggestion)),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(String suggestion) {
    return ListTile(
      leading: const Icon(Icons.search, color: Colors.grey),
      title: Text(suggestion),
      onTap: () => _onSuggestionSelected(suggestion),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '${widget.searchController.resultCount} results found',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...widget.searchController.searchResults
              .map((client) => _buildClientTile(client)),
          if (widget.searchController.hasMoreResults) _buildLoadMoreButton(),
        ],
      ),
    );
  }

  Widget _buildClientTile(Client client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.address?.isNotEmpty == true)
              Text(client.address!, style: const TextStyle(fontSize: 12)),
            if (client.contact?.isNotEmpty == true)
              Text(client.contact!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        onTap: () => _onClientSelected(client),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: widget.searchController.loadMoreResults,
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
    return Container(
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
              widget.searchController.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          TextButton(
            onPressed: widget.searchController.retrySearch,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
  }
}
 