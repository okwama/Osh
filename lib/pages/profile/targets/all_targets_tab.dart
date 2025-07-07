import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:woosh/models/order/my_order_model.dart';
import 'package:woosh/models/targets/target_model.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:get_storage/get_storage.dart';

class AllTargetsTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AllTargetsTab({
    super.key,
    required this.onRefresh,
    required bool isLoading,
    required bool isLoadingOrders,
    required Map<String, dynamic> dailyVisitTargets,
    required bool isLoadingDailyVisits,
    required int totalItemsSold,
    required List<Target> targets,
    required List<MyOrderModel> userOrders,
  });

  @override
  State<AllTargetsTab> createState() => _AllTargetsTabState();
}

class _AllTargetsTabState extends State<AllTargetsTab> {
  bool _isLoadingMonthlyVisits = true;
  List<dynamic> _monthlyVisits = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMonthlyVisits();
  }

  Future<void> _loadMonthlyVisits() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMonthlyVisits = true;
      _errorMessage = null;
    });

    try {
      final box = GetStorage();
      final userId = box.read<String>('userId');
      if (userId == null) throw Exception('User ID not found');

      final monthlyVisits =
          await TargetService.getMonthlyVisits(userId: userId);
      if (!mounted) return;

      setState(() {
        _monthlyVisits = monthlyVisits;
        _isLoadingMonthlyVisits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load monthly visits: $e';
        _isLoadingMonthlyVisits = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadMonthlyVisits();
        await widget.onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          _buildMonthlyVisitSummaryCard(context),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Daily Visit History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          if (_isLoadingMonthlyVisits)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) => _buildSkeletonCard(),
            )
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_monthlyVisits.isEmpty)
            _buildEmptyState()
          else
            _buildDailyVisitReports(context),
        ],
      ),
    );
  }

  Widget _buildMonthlyVisitSummaryCard(BuildContext context) {
    if (_isLoadingMonthlyVisits) return _buildSkeletonSummaryCard();
    if (_monthlyVisits.isEmpty) return const SizedBox.shrink();

    int totalTarget = 0, totalCompleted = 0, daysWithProgress = 0;
    for (var visit in _monthlyVisits) {
      totalTarget += (visit['visitTarget'] as num?)?.toInt() ?? 0;
      totalCompleted += (visit['completedVisits'] as num?)?.toInt() ?? 0;
      if (((visit['completedVisits'] as num?)?.toInt() ?? 0) > 0) {
        daysWithProgress++;
      }
    }

    final progress =
        totalTarget > 0 ? (totalCompleted / totalTarget * 100).round() : 0;
    final remainingVisits = totalTarget - totalCompleted;
    final status =
        totalCompleted >= totalTarget ? 'Target Achieved' : 'In Progress';
    final totalDays = _monthlyVisits.length;

    return Card(
      margin: const EdgeInsets.all(4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 6),
                const Text('Monthly Visit Summary',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      fontSize: 11,
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
                  radius: 30,
                  lineWidth: 6,
                  percent: progress / 100,
                  center: GradientText(
                    "$progress%",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[300]!,
                  progressColor: goldMiddle2,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1000,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $totalCompleted / $totalTarget visits',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remainingVisits remaining',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      GradientLinearProgressIndicator(
                        value: progress / 100,
                        height: 6,
                        borderRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Days', '$totalDays',
                      Icons.calendar_month, Colors.blue),
                ),
                Expanded(
                  child: _buildStatItem('Active Days', '$daysWithProgress',
                      Icons.trending_up, Colors.green),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg/Day',
                    totalDays > 0
                        ? (totalCompleted / totalDays).toStringAsFixed(1)
                        : '0',
                    Icons.analytics,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyVisitReports(BuildContext context) {
    final sortedVisits = List<dynamic>.from(_monthlyVisits)
      ..sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedVisits.length,
      itemBuilder: (context, index) {
        final visit = sortedVisits[index];
        final date = DateTime.parse(visit['date']);
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;
        final target = visit['visitTarget'] ?? 0;
        final completed = visit['completedVisits'] ?? 0;
        final progress = visit['progress'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          elevation: isToday ? 3 : 1,
          color: isToday ? Colors.blue[50] : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isToday
                          ? Colors.blue
                          : Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEE, MMM d').format(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue[800] : null,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 20,
                      lineWidth: 4,
                      percent: progress / 100,
                      center: GradientText(
                        "$progress%",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 9),
                      ),
                      backgroundColor: Colors.grey[300]!,
                      progressColor:
                          completed >= target ? Colors.green : goldMiddle2,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Target: $target visits',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: completed >= target
                                      ? Colors.green[100]
                                      : completed > 0
                                          ? Colors.orange[100]
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  completed >= target
                                      ? 'Completed'
                                      : completed > 0
                                          ? 'In Progress'
                                          : 'Not Started',
                                  style: TextStyle(
                                    color: completed >= target
                                        ? Colors.green[800]
                                        : completed > 0
                                            ? Colors.orange[800]
                                            : Colors.grey[600],
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed: $completed visits',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                          ),
                          if (completed < target) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Remaining: ${target - completed} visits',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600]),
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
        );
      },
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GoldGradientButton(
              onPressed: _loadMonthlyVisits,
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No visit history found',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildSkeletonCard() => Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
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

  Widget _buildSkeletonSummaryCard() => Card(
        margin: const EdgeInsets.all(4),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
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
