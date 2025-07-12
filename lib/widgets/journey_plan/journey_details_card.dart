import 'package:flutter/material.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:intl/intl.dart';

class JourneyDetailsCard extends StatelessWidget {
  final JourneyPlan journeyPlan;
  final String? currentAddress;
  final bool isFetchingLocation;
  final bool isWithinGeofence;
  final double distanceToClient;
  final VoidCallback? onUpdateLocation;
  final bool showUpdateLocation;

  const JourneyDetailsCard({
    super.key,
    required this.journeyPlan,
    this.currentAddress,
    this.isFetchingLocation = false,
    this.isWithinGeofence = false,
    this.distanceToClient = 0.0,
    this.onUpdateLocation,
    this.showUpdateLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6.0),
                topRight: Radius.circular(6.0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    journeyPlan.client.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoItem(
                            'Date',
                            dateFormatter.format(journeyPlan.date),
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: 6),
                          _buildInfoItem(
                            'Location',
                            journeyPlan.client.address,
                            Icons.location_on,
                          ),
                          const SizedBox(height: 6),
                          if (showUpdateLocation) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isFetchingLocation
                                        ? null
                                        : onUpdateLocation,
                                    icon: const Icon(Icons.upload_rounded,
                                        size: 14),
                                    label: Text(
                                      isFetchingLocation
                                          ? 'Updating...'
                                          : 'Update Location',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Right column
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoItem(
                            // Show different label based on journey status
                            journeyPlan.isPending
                                ? 'Current Location'
                                : 'Check-in Location',
                            isFetchingLocation
                                ? 'Fetching location...'
                                : currentAddress ?? 'Location not available',
                            Icons.my_location,
                          ),
                          if (currentAddress != null) ...[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isWithinGeofence
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    journeyPlan.status ==
                                            JourneyPlan.statusInProgress
                                        ? Icons.check_circle
                                        : isWithinGeofence
                                            ? Icons.check_circle
                                            : Icons.warning,
                                    size: 12,
                                    color: journeyPlan.status ==
                                            JourneyPlan.statusInProgress
                                        ? Colors.blue
                                        : isWithinGeofence
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      journeyPlan.status ==
                                              JourneyPlan.statusInProgress
                                          ? 'Checked In'
                                          : isWithinGeofence
                                              ? 'Within range'
                                              : 'Outside range',
                                      style: TextStyle(
                                        color: journeyPlan.status ==
                                                JourneyPlan.statusInProgress
                                            ? Colors.blue
                                            : isWithinGeofence
                                                ? Colors.green
                                                : Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Only show distance if not checked in
                            if (!isWithinGeofence &&
                                journeyPlan.status !=
                                    JourneyPlan.statusInProgress)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '${distanceToClient.toStringAsFixed(1)}m away',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
