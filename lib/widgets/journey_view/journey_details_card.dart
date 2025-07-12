import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';

class JourneyDetailsCard extends StatelessWidget {
  final JourneyPlan journeyPlan;
  final String? currentAddress;
  final bool isFetchingLocation;
  final bool isWithinGeofence;
  final double distanceToClient;
  final VoidCallback? onUpdateLocation;
  final VoidCallback? onEditNotes;
  final VoidCallback? onCheckIn;
  final VoidCallback? onViewReports;

  const JourneyDetailsCard({
    super.key,
    required this.journeyPlan,
    this.currentAddress,
    this.isFetchingLocation = false,
    this.isWithinGeofence = false,
    this.distanceToClient = 0.0,
    this.onUpdateLocation,
    this.onEditNotes,
    this.onCheckIn,
    this.onViewReports,
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
                          if (journeyPlan.showUpdateLocation) ...[
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
                          _buildLocationInfo(),
                          _buildGeofenceStatus(),
                        ],
                      ),
                    ),
                  ],
                ),

                // Notes section
                const SizedBox(height: 12),
                _buildNotesSection(),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 10.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (journeyPlan.isCheckedIn ||
                    journeyPlan.isInTransit ||
                    journeyPlan.isCompleted)
                  ElevatedButton.icon(
                    onPressed: onViewReports,
                    icon: const Icon(Icons.assessment, size: 14),
                    label: const Text('View Reports'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                else if (journeyPlan.isPending)
                  ElevatedButton.icon(
                    onPressed: onCheckIn,
                    icon: const Icon(Icons.camera_alt, size: 14),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    // Don't show location info if already checked in
    if (label == 'Current Location' &&
        (journeyPlan.status == JourneyPlan.statusInProgress ||
            journeyPlan.status == JourneyPlan.statusCompleted)) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return _buildInfoItem(
      journeyPlan.isPending ? 'Current Location' : 'Check-in Location',
      isFetchingLocation
          ? 'Fetching location...'
          : currentAddress ?? 'Location not available',
      Icons.my_location,
    );
  }

  Widget _buildGeofenceStatus() {
    if (currentAddress == null) return const SizedBox.shrink();

    return Column(
      children: [
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
                journeyPlan.status == JourneyPlan.statusInProgress
                    ? Icons.check_circle
                    : isWithinGeofence
                        ? Icons.check_circle
                        : Icons.warning,
                size: 12,
                color: journeyPlan.status == JourneyPlan.statusInProgress
                    ? Colors.blue
                    : isWithinGeofence
                        ? Colors.green
                        : Colors.red,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  journeyPlan.status == JourneyPlan.statusInProgress
                      ? 'Checked In'
                      : isWithinGeofence
                          ? 'In range'
                          : 'Out of range',
                  style: TextStyle(
                    color: journeyPlan.status == JourneyPlan.statusInProgress
                        ? Colors.blue
                        : isWithinGeofence
                            ? Colors.green
                            : Colors.red,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        // Distance info
        if (!isWithinGeofence &&
            journeyPlan.status != JourneyPlan.statusInProgress)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${distanceToClient.toStringAsFixed(0)}m away',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notes, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              'Notes',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit, size: 14),
              onPressed: onEditNotes,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: journeyPlan.notes?.isNotEmpty == true
              ? Text(
                  journeyPlan.notes!,
                  style: const TextStyle(fontSize: 12),
                )
              : Text(
                  'No notes added',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
        ),
      ],
    );
  }
}
