import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/widgets/client/client_list_item.dart';
import 'package:woosh/widgets/client/client_empty_state.dart';
import 'package:woosh/widgets/client/client_search_indicator.dart';
import 'package:woosh/widgets/skeleton_loader.dart';

class ClientListWidget extends StatelessWidget {
  final List<Client> clients;
  final bool isLoading;
  final bool isSearching;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String searchQuery;
  final ScrollController scrollController;
  final Function(Client) onClientSelected;
  final VoidCallback onRetry;
  final VoidCallback onAddClient;
  final Future<void> Function() onRefresh;

  const ClientListWidget({
    super.key,
    required this.clients,
    required this.isLoading,
    required this.isSearching,
    required this.isLoadingMore,
    required this.hasMore,
    this.errorMessage,
    required this.searchQuery,
    required this.scrollController,
    required this.onClientSelected,
    required this.onRetry,
    required this.onAddClient,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && clients.isEmpty) {
      return const ClientListSkeleton();
    }

    if (isSearching) {
      return ClientSearchIndicator(searchQuery: searchQuery);
    }

    if (errorMessage != null && clients.isEmpty) {
      return _buildErrorState();
    }

    if (clients.isEmpty) {
      return ClientEmptyState(
        searchQuery: searchQuery,
        onAddClient: onAddClient,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: clients.length + 1,
        itemBuilder: (context, index) {
          if (index == clients.length) {
            return _buildListFooter();
          }

          final client = clients[index];
          return ClientListItem(
            client: client,
            onTap: () => onClientSelected(client),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 36,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListFooter() {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!hasMore && clients.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text('End of list')),
      );
    }
    return const SizedBox.shrink();
  }
}
