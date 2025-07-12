import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';

/// Widget for displaying individual journey plan items
class JourneyPlanItemCard extends StatelessWidget {
  final JourneyPlan journeyPlan;
  final VoidCallback onTap;
  final VoidCallback? onHide;
  final VoidCallback? onDelete;
  final bool hasActiveVisit;
  final JourneyPlan? activeVisit;

  const JourneyPlanItemCard({
    super.key,
    required this.journeyPlan,
    required this.onTap,
    this.onHide,
    this.onDelete,
    required this.hasActiveVisit,
    this.activeVisit,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = journeyPlan.statusText == 'Completed';
    final isPending = journeyPlan.statusText == 'Pending';
    final clientName = journeyPlan.client.name;

    // Only disable if completed
    final shouldDisable = isCompleted;

    return Opacity(
      opacity: isCompleted ? 0.5 : 1.0,
      child: Card(
        key: ValueKey('journey_plan_${journeyPlan.id}'),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: InkWell(
          onTap: shouldDisable ? null : onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                // Left section: Action icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPending && onDelete != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          onPressed: onDelete,
                          tooltip: 'Delete journey plan',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Center section: Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(journeyPlan.date.toLocal()),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right section: Status and arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: journeyPlan.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        journeyPlan.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
