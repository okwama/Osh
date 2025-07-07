import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:get_storage/get_storage.dart';

class AllTargetsDetailPage extends StatefulWidget {
  final String period;

  const AllTargetsDetailPage({
    super.key,
    required this.period,
  });

  @override
  State<AllTargetsDetailPage> createState() => _AllTargetsDetailPageState();
}

class _AllTargetsDetailPageState extends State<AllTargetsDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedPeriod = 'current_month';

  // All target data
  Map<String, dynamic> _dailyVisitTargets = {};
  Map<String, dynamic> _newClientsProgress = {};
  Map<String, dynamic> _productSalesProgress = {};
  List<dynamic> _allTargets = [];

  final List<String> _periods = [
    'current_month',
    'last_month',
    'current_year',
  ];

  final Map<String, String> _periodLabels = {
    'current_month': 'This Month',
    'last_month': 'Last Month',
    'current_year': 'This Year',
  };

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
    _loadAllTargetsData();
  }

  Future<void> _loadAllTargetsData() async {
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

      // Load all target data in parallel
      final results = await Future.wait([
        _loadDailyVisitTargets(userId),
        _loadNewClientsProgress(userId),
        _loadProductSalesProgress(userId),
        _loadAllTargets(userId),
      ]);

      if (mounted) {
        setState(() {
          _dailyVisitTargets = results[0] as Map<String, dynamic>;
          _newClientsProgress = results[1] as Map<String, dynamic>;
          _productSalesProgress = results[2] as Map<String, dynamic>;
          _allTargets = results[3] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load targets data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadDailyVisitTargets(String userId) async {
    try {
      final date = DateTime.now();
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      return await TargetService.getDailyVisitTargets(
        userId: userId,
        date: formattedDate,
      );
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadNewClientsProgress(String userId) async {
    try {
      return await TargetService.getNewClientsProgress(
        int.parse(userId),
        period: _selectedPeriod,
      );
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadProductSalesProgress(String userId) async {
    try {
      return await TargetService.getProductSalesProgress(
        int.parse(userId),
        period: _selectedPeriod,
      );
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>> _loadAllTargets(String userId) async {
    try {
      // For now, return empty list since getTargets method doesn't exist
      return [];
    } catch (e) {
      return [];
    }
  }

  void _changePeriod(String period) {
    if (period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadAllTargetsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'All Targets',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAllTargetsData,
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
            'Failed to load targets data',
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
            onPressed: _loadAllTargetsData,
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
      onRefresh: _loadAllTargetsData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallSummaryCard(),
            SizedBox(height: 20),
            _buildPeriodSelector(),
            SizedBox(height: 16),
            _buildTargetsGrid(),
            SizedBox(height: 16),
            _buildTargetsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummaryCard() {
    // Calculate overall progress from all targets
    final visitProgress = _dailyVisitTargets['progress'] ?? 0;
    final newClientsProgress = _newClientsProgress['progress'] ?? 0;
    final productSalesSummary = _productSalesProgress['summary'] ?? {};
    final vapesProgress = (productSalesSummary['vapes'] ?? {})['progress'] ?? 0;
    final pouchesProgress =
        (productSalesSummary['pouches'] ?? {})['progress'] ?? 0;

    final overallProgress = ((visitProgress +
                newClientsProgress +
                vapesProgress +
                pouchesProgress) /
            4) /
        100;

    final completedTargets =
        _allTargets.where((target) => target['achieved'] == true).length;
    final totalTargets = _allTargets.length;
    final activeTargets =
        _allTargets.where((target) => target['isCurrent'] == true).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.teal.withOpacity(0.1),
              Colors.teal.withOpacity(0.05),
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
                    color: Colors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.list_alt,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Targets Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                      ),
                      Text(
                        _periodLabels[_selectedPeriod] ?? _selectedPeriod,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
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
                  percent: overallProgress,
                  center: Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  progressColor: Colors.teal,
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Performance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Combined performance across all target types',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      SizedBox(height: 12),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: overallProgress,
                        backgroundColor: Colors.grey[300],
                        progressColor: Colors.teal,
                        barRadius: Radius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStatItem(
                    'Active',
                    activeTargets.toString(),
                    Icons.play_circle,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStatItem(
                    'Completed',
                    completedTargets.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStatItem(
                    'Total',
                    totalTargets.toString(),
                    Icons.list,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            Row(
              children: _periods.map((period) {
                final isSelected = period == _selectedPeriod;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _changePeriod(period),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _periodLabels[period] ?? period,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsGrid() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view, color: Colors.teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Target Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildTargetCategoryCard(
                  'Visit Targets',
                  _dailyVisitTargets['progress'] ?? 0,
                  _dailyVisitTargets['status'] ?? 'In Progress',
                  Colors.blue,
                  Icons.location_on,
                ),
                _buildTargetCategoryCard(
                  'New Clients',
                  _newClientsProgress['progress'] ?? 0,
                  _newClientsProgress['status'] ?? 'In Progress',
                  Colors.green,
                  Icons.person_add,
                ),
                _buildTargetCategoryCard(
                  'Vapes Sales',
                  (_productSalesProgress['summary'] ?? {})['vapes']
                          ?['progress'] ??
                      0,
                  (_productSalesProgress['summary'] ?? {})['vapes']
                          ?['status'] ??
                      'In Progress',
                  Colors.purple,
                  Icons.cloud,
                ),
                _buildTargetCategoryCard(
                  'Pouches Sales',
                  (_productSalesProgress['summary'] ?? {})['pouches']
                          ?['progress'] ??
                      0,
                  (_productSalesProgress['summary'] ?? {})['pouches']
                          ?['status'] ??
                      'In Progress',
                  Colors.orange,
                  Icons.inventory_2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCategoryCard(
    String title,
    int progress,
    String status,
    Color color,
    IconData icon,
  ) {
    final statusColor =
        status == 'Target Achieved' ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '$progress%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsList() {
    if (_allTargets.isEmpty) {
      return _buildEmptyState('No targets found');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Colors.teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'All Targets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                Text(
                  '${_allTargets.length} total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._allTargets.map((target) => _buildTargetListItem(target)),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetListItem(Map<String, dynamic> target) {
    final title = target['title'] ?? 'Unknown Target';
    final targetValue = target['targetValue'] ?? 0;
    final achievedValue = target['achievedValue'] ?? 0;
    final progress = target['progress'] ?? 0.0;
    final isAchieved = target['achieved'] ?? false;
    final isCurrent = target['isCurrent'] ?? false;
    final startDate = target['startDate'] != null
        ? DateTime.parse(target['startDate'])
        : null;
    final endDate =
        target['endDate'] != null ? DateTime.parse(target['endDate']) : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.teal[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? Colors.teal[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? Colors.teal[800] : null,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress: $achievedValue / $targetValue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    LinearPercentIndicator(
                      lineHeight: 6,
                      percent: progress / 100,
                      backgroundColor: Colors.grey[300],
                      progressColor: isAchieved ? Colors.green : Colors.teal,
                      barRadius: Radius.circular(3),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAchieved ? Colors.green : Colors.teal,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          isAchieved ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAchieved ? 'Achieved' : 'In Progress',
                      style: TextStyle(
                        color:
                            isAchieved ? Colors.green[800] : Colors.orange[800],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (startDate != null && endDate != null) ...[
            SizedBox(height: 8),
            Text(
              '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
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
              Icons.tablet,
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
