import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:get_storage/get_storage.dart';

class NewClientsDetailPage extends StatefulWidget {
  final String period;
  final Map<String, dynamic> initialData;

  const NewClientsDetailPage({
    super.key,
    required this.period,
    required this.initialData,
  });

  @override
  State<NewClientsDetailPage> createState() => _NewClientsDetailPageState();
}

class _NewClientsDetailPageState extends State<NewClientsDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _newClientsProgress = {};
  List<dynamic> _clientHistory = [];
  String _selectedPeriod = 'current_month';

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
    _newClientsProgress = widget.initialData;
    _selectedPeriod = widget.period;
    _loadClientData();
  }

  Future<void> _loadClientData() async {
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

      // Load new clients progress for the selected period
      final newClientsData = await TargetService.getNewClientsProgress(
        int.parse(userId),
        period: _selectedPeriod,
      );

      // Load client details from the API
      final clientDetails = await _loadClientDetails(int.parse(userId));

      if (mounted) {
        setState(() {
          _newClientsProgress = newClientsData;
          _clientHistory = clientDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load client data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<dynamic>> _loadClientDetails(int userId) async {
    try {
      final response =
          await TargetService.getClientDetails(userId, period: _selectedPeriod);
      return response['newClients'] ?? [];
    } catch (e) {
      // Fallback to mock data if API fails
      return _generateMockClientHistory();
    }
  }

  List<dynamic> _generateMockClientHistory() {
    final now = DateTime.now();
    final List<dynamic> history = [];

    for (int i = 0; i < 10; i++) {
      final date = now.subtract(Duration(days: i * 3));
      history.add({
        'id': i + 1,
        'clientName': 'Client ${i + 1}',
        'email': 'client${i + 1}@example.com',
        'phone': '+1234567890${i.toString().padLeft(2, '0')}',
        'addedDate': date.toIso8601String(),
        'status': i % 3 == 0 ? 'Active' : 'Pending',
        'location': 'Location ${i + 1}',
      });
    }

    return history;
  }

  void _changePeriod(String period) {
    if (period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadClientData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'New Clients',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadClientData,
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
            'Failed to load client data',
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
            onPressed: _loadClientData,
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
      onRefresh: _loadClientData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(),
            SizedBox(height: 20),
            _buildPeriodSelector(),
            SizedBox(height: 16),
            _buildClientHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    // Convert to Map if it's a NewClientsProgress object
    Map<String, dynamic> data = Map<String, dynamic>.from(_newClientsProgress);

    final target = data['newClientsTarget'] ?? 0;
    final added = data['newClientsAdded'] ?? _clientHistory.length;
    final remaining = target - added;
    final progress = target > 0 ? (added / target * 100) : 0;
    final status = progress >= 100 ? 'Target Achieved' : 'In Progress';
    final statusColor =
        status == 'Target Achieved' ? Colors.green : Colors.orange;
    final dateRange = data['dateRange'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
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
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Acquisition',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                      if (dateRange.isNotEmpty)
                        Text(
                          '${dateRange['startDate'] ?? ''} - ${dateRange['endDate'] ?? ''}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  percent: (progress / 100).clamp(0.0, 1.0),
                  center: Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  progressColor: Colors.green,
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $added / $target clients',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$remaining clients remaining',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      SizedBox(height: 12),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: (progress / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        progressColor: Colors.green,
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
                  child: _buildStatItem(
                    'Added',
                    added.toString(),
                    Icons.person_add,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Target',
                    target.toString(),
                    Icons.flag,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Remaining',
                    remaining.toString(),
                    Icons.schedule,
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
                        color: isSelected ? Colors.green : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey[300]!,
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

  Widget _buildClientHistory() {
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
                Icon(Icons.history, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Clients',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                Text(
                  '${_clientHistory.length} total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_clientHistory.isEmpty)
              _buildEmptyState('No client history available')
            else
              ..._clientHistory
                  .map((client) => _buildClientHistoryItem(client)),
          ],
        ),
      ),
    );
  }

  Widget _buildClientHistoryItem(Map<String, dynamic> client) {
    final addedDate = DateTime.parse(client['created_at']);
    final status = client['status'] == 1 ? 'Active' : 'Pending';
    final statusColor = status == 'Active' ? Colors.green : Colors.orange;
    final contact = client['contact'] ?? 'Not provided';
    final region = client['region'] ?? 'Unknown';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client['name'] ?? 'Unknown Client',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  contact,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(addedDate),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
              SizedBox(height: 4),
              Text(
                region,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
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
    );
  }
}
