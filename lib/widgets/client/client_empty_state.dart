import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/pages/client/addclient_page.dart';

class ClientEmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onAddClient;

  const ClientEmptyState({
    super.key,
    required this.searchQuery,
    this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No clients found' : 'No matching clients',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'No Clients Assigned to this user'
                : 'Try a different search term',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          if (searchQuery.isEmpty && onAddClient != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddClient,
              icon: const Icon(Icons.add),
              label: const Text('Add Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
