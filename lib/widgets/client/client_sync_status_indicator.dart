import 'package:flutter/material.dart';
import 'package:woosh/services/hive/client_hive_service.dart';

/// Widget to display sync status indicators for optimistic UI updates
class ClientSyncStatusIndicator extends StatelessWidget {
  final int clientId;
  final Widget child;

  const ClientSyncStatusIndicator({
    super.key,
    required this.clientId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 4,
          right: 4,
          child: _buildStatusIndicator(),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final status = ClientHiveService.instance.getSyncStatus(clientId);

    switch (status) {
      case ClientHiveService.STATUS_PENDING:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.schedule,
            size: 8,
            color: Colors.white,
          ),
        );

      case ClientHiveService.STATUS_SYNCING:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );

      case ClientHiveService.STATUS_FAILED:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            size: 8,
            color: Colors.white,
          ),
        );

      case ClientHiveService.STATUS_SUCCESS:
      default:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 8,
            color: Colors.white,
          ),
        );
    }
  }
}
