import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:get_storage/get_storage.dart';

class VisitTargetsDetailPage extends StatefulWidget {
  final String period;
  final Map<String, dynamic> initialData;

  const VisitTargetsDetailPage({
    super.key,
    required this.period,
    required this.initialData,
  });

  @override
  State<VisitTargetsDetailPage> createState() => _VisitTargetsDetailPageState();
}

class _VisitTargetsDetailPageState extends State<VisitTargetsDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _dailyVisitTargets = {};
  List<dynamic> _monthlyVisits = [];
  final List<dynamic> _weeklyVisits = [];
  String _selectedView = 'daily'; // daily, weekly, monthly

  @override
  void initState() {
    super.initState();
    _dailyVisitTargets = widget.initialData;
    _loadVisitData();
  }

  Future<void> _loadVisitData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final box = GetStorage();
      final userId = box.read<String>('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Load monthly visits data
      final monthlyVisits =
          await TargetService.getMonthlyVisits(userId: userId);

      if (mounted) {
        setState(() {
          _monthlyVisits = monthlyVisits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load visit data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Visit Targets',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadVisitData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader(height: 200, width: double.infinity),
          SizedBox(height: 16),
          SkeletonLoader(height: 120, width: double.infinity),
          SizedBox(height: 16),
          SkeletonLoader(height: 300, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Failed to load visit data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadVisitData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadVisitData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentDayCard(),
            SizedBox(height: 20),
            _buildViewSelector(),
            SizedBox(height: 16),
            _buildVisitHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDayCard() {
    final visitTarget = _dailyVisitTargets['visitTarget'] ?? 0;
    final completedVisits = _dailyVisitTargets['completedVisits'] ?? 0;
    final remainingVisits = _dailyVisitTargets['remainingVisits'] ?? 0;
    final progress = _dailyVisitTargets['progress'] ?? 0;
    final status = _dailyVisitTargets['status'] ?? 'In Progress';
    final statusColor =
        status == 'Target Achieved' ? Colors.green : Colors.orange;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Visits',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 10,
                  percent: progress / 100,
                  center: Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $completedVisits / $visitTarget visits',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$remainingVisits visits remaining',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      SizedBox(height: 12),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: progress / 100,
                        backgroundColor: Colors.grey[300],
                        progressColor: Colors.blue,
                        barRadius: Radius.circular(4),
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

  Widget _buildViewSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visit History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildViewButton('Daily', 'daily', Icons.calendar_today),
                SizedBox(width: 8),
                _buildViewButton('Weekly', 'weekly', Icons.calendar_view_week),
                SizedBox(width: 8),
                _buildViewButton(
                    'Monthly', 'monthly', Icons.calendar_view_month),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewButton(String label, String value, IconData icon) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitHistory() {
    switch (_selectedView) {
      case 'daily':
        return _buildDailyHistory();
      case 'weekly':
        return _buildWeeklyHistory();
      case 'monthly':
        return _buildMonthlyHistory();
      default:
        return _buildDailyHistory();
    }
  }

  Widget _buildDailyHistory() {
    if (_monthlyVisits.isEmpty) {
      return _buildEmptyState('No daily visit history available');
    }

    // Get last 7 days
    final recentVisits = _monthlyVisits.take(7).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            ...recentVisits.map((visit) => _buildVisitHistoryItem(visit)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            _buildEmptyState('Weekly view coming soon'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyHistory() {
    if (_monthlyVisits.isEmpty) {
      return _buildEmptyState('No monthly visit history available');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            ..._monthlyVisits.map((visit) => _buildVisitHistoryItem(visit)),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitHistoryItem(Map<String, dynamic> visit) {
    final date = visit['date'] is String 
        ? DateTime.parse(visit['date'])
        : visit['date'] as DateTime;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final target = visit['visitTarget'] ?? 0;
    final completed = visit['completedVisits'] ?? 0;
    final progress = visit['progress'] ?? 0;
    final status = completed >= target ? 'Completed' : 'In Progress';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? Colors.blue[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isToday ? Colors.blue : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('EEE, MMM d').format(date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue[800] : null,
                      ),
                    ),
                    if (isToday) ...[
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '$completed / $target visits',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$progress%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progress >= 100 ? Colors.green : Colors.orange,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'Completed'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Completed'
                        ? Colors.green[800]
                        : Colors.orange[800],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
