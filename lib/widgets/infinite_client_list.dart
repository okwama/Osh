import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/client_controller.dart';
import 'package:woosh/models/client/client_model.dart';

import 'package:woosh/widgets/client/client_list_item.dart';

class InfiniteClientList extends StatelessWidget {
  final ClientController controller;
  final Function(Client)? onClientTap;
  final Widget Function(BuildContext, Client)? itemBuilder;

  const InfiniteClientList({
    super.key,
    required this.controller,
    this.onClientTap,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.clients.isEmpty && controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.builder(
          itemCount:
              controller.clients.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.clients.length) {
              // Show loading indicator at the bottom
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              // Load more data when reaching the end
              controller.loadMore();
              return const SizedBox.shrink();
            }

            final client = controller.clients[index];
            if (itemBuilder != null) {
              return itemBuilder!(context, client);
            }
            return ClientListItem(
              client: client,
              onTap: onClientTap != null ? () => onClientTap!(client) : () {},
            );
          },
        ),
      );
    });
  }
}
