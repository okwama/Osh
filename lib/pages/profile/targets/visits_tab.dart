import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/cream_gradient_card.dart';

class VisitsTab extends StatelessWidget {
  final Map<String, dynamic> dailyVisitTargets;
  final bool isLoadingDailyVisits;
  final Future<void> Function() onRefresh;

  const VisitsTab({
    super.key,
    required this.dailyVisitTargets,
    required this.isLoadingDailyVisits,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingDailyVisits) {
      return const Center(child: GradientCircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildDailyVisitCard(context),
            const SizedBox(height: 16),
            if (dailyVisitTargets.isNotEmpty) ...[
              const Text(
                'Recent Visits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Add recent visits list here when available
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyVisitCard(BuildContext context) {
    if (isLoadingDailyVisits) {
      return _buildSkeletonSalesCard();
    }

    if (dailyVisitTargets.isEmpty) {
      return const SizedBox.shrink();
    }

    final visitTarget = dailyVisitTargets['visitTarget'] ?? 0;
    final completedVisits = dailyVisitTargets['completedVisits'] ?? 0;
    final remainingVisits = dailyVisitTargets['remainingVisits'] ?? 0;
    final progress = dailyVisitTargets['progress'] ?? 0;
    final status = dailyVisitTargets['status'] ?? 'In Progress';

    return Card(
      margin: const EdgeInsets.all(6.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: Theme.of(context).primaryColor, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Daily Visit Target',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Target Achieved'
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Target Achieved'
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 30.0,
                  lineWidth: 6.0,
                  percent: progress / 100,
                  center: GradientText(
                    "${progress.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                  backgroundColor: Colors.grey[300]!,
                  progressColor: goldMiddle2,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $completedVisits / $visitTarget visits',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remainingVisits visits remaining',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GradientLinearProgressIndicator(
                        value: progress / 100,
                        height: 6.0,
                        borderRadius: 3.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonSalesCard() {
    return Card(
      margin: const EdgeInsets.all(6.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
