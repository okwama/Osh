import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/targets/sales_rep_dashboard.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<SalesRepDashboard> _dashboardFuture;
  String _selectedPeriod = 'current_month';
  bool _isLoading = false;

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
    _loadDashboard();
  }

  Future<SalesRepDashboard> _loadDashboardData(int userId) async {
    try {
      final dashboardMap = await TargetService.getDashboard(
        userId,
        period: _selectedPeriod,
      );

      // Convert Map to SalesRepDashboard
      return SalesRepDashboard.fromJson({
        'userId': userId,
        'period': dashboardMap['period'] ?? 'current_month',
        'visitTargets': dashboardMap['visitTargets'] ?? {},
        'newClients': dashboardMap['newClients'] ?? {},
        'productSales': dashboardMap['productSales'] ?? {},
        'generatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Return a default dashboard on error
      return SalesRepDashboard(
        userId: userId,
        period: _selectedPeriod,
        visitTargets: VisitTargets(
          userId: userId.toString(),
          date: DateTime.now().toIso8601String().split('T')[0],
          visitTarget: 0,
          completedVisits: 0,
          remainingVisits: 0,
          progress: 0,
          status: 'Error',
        ),
        newClients: NewClientsProgress(
          userId: userId,
          salesRepName: 'Unknown',
          period: _selectedPeriod,
          dateRange: DateRange(startDate: '', endDate: ''),
          newClientsTarget: 0,
          newClientsAdded: 0,
          remainingClients: 0,
          progress: 0,
          status: 'Error',
          generatedAt: DateTime.now(),
        ),
        productSales: ProductSalesProgress(
          userId: userId,
          salesRepName: 'Unknown',
          period: _selectedPeriod,
          dateRange: DateRange(startDate: '', endDate: ''),
          summary: ProductSummary(
            totalOrders: 0,
            totalQuantitySold: 0,
            vapes: ProductMetric(
                target: 0, sold: 0, remaining: 0, progress: 0, status: 'Error'),
            pouches: ProductMetric(
                target: 0, sold: 0, remaining: 0, progress: 0, status: 'Error'),
          ),
          productBreakdown: [],
          generatedAt: DateTime.now(),
        ),
        generatedAt: DateTime.now(),
      );
    }
  }

  void _loadDashboard() {
    final box = GetStorage();
    final userId = box.read<String>('userId');

    if (userId == null) {
      setState(() {
        _dashboardFuture = Future.error('User ID not found');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _dashboardFuture = _loadDashboardData(int.parse(userId));
    });

    _dashboardFuture.whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _changePeriod(String period) {
    if (period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Performance Dashboard',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDashboard,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadDashboard(),
              child: FutureBuilder<SalesRepDashboard>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (!snapshot.hasData) {
                    return _buildEmptyState();
                  }

                  return _buildDashboardContent(snapshot.data!);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return GestureDetector(
            onTap: () => _changePeriod(period),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                _periodLabels[period] ?? period,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader(height: 120, width: double.infinity),
          SizedBox(height: 16),
          SkeletonLoader(height: 120, width: double.infinity),
          SizedBox(height: 16),
          SkeletonLoader(height: 180, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No dashboard data available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for your performance metrics',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(SalesRepDashboard dashboard) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallPerformanceCard(dashboard),
          SizedBox(height: 16),
          _buildVisitTargetsCard(dashboard.visitTargets),
          SizedBox(height: 16),
          _buildNewClientsCard(dashboard.newClients),
          SizedBox(height: 16),
          _buildProductSalesCard(dashboard.productSales),
          SizedBox(height: 16),
          _buildProductBreakdownCard(dashboard.productSales.productBreakdown),
        ],
      ),
    );
  }

  Widget _buildOverallPerformanceCard(SalesRepDashboard dashboard) {
    final score = dashboard.overallPerformanceScore;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              dashboard.performanceColor.withOpacity(0.1),
              dashboard.performanceColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 50,
              lineWidth: 8,
              percent: score / 100,
              center: Text(
                '${score.toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: dashboard.performanceColor,
                ),
              ),
              progressColor: dashboard.performanceColor,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _periodLabels[dashboard.period] ?? dashboard.period,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        dashboard.allTargetsAchieved
                            ? Icons.check_circle
                            : Icons.pending,
                        color: dashboard.performanceColor,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        dashboard.allTargetsAchieved
                            ? 'All targets achieved!'
                            : 'Keep going!',
                        style: TextStyle(
                          color: dashboard.performanceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTargetsCard(VisitTargets visitTargets) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Visits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusChip(visitTargets.status, visitTargets.statusColor),
              ],
            ),
            SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 8,
              percent: visitTargets.completionPercentage,
              backgroundColor: Colors.grey[300],
              progressColor: visitTargets.statusColor,
              barRadius: Radius.circular(4),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn(
                  'Completed',
                  visitTargets.completedVisits.toString(),
                  Colors.green,
                ),
                _buildMetricColumn(
                  'Target',
                  visitTargets.visitTarget.toString(),
                  Colors.blue,
                ),
                _buildMetricColumn(
                  'Remaining',
                  visitTargets.remainingVisits.toString(),
                  Colors.orange,
                ),
                _buildMetricColumn(
                  'Progress',
                  '${visitTargets.progress}%',
                  visitTargets.statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewClientsCard(NewClientsProgress newClients) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Clients',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusChip(newClients.status, newClients.statusColor),
              ],
            ),
            SizedBox(height: 8),
            Text(
              newClients.dateRange.displayText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 8,
              percent: newClients.completionPercentage,
              backgroundColor: Colors.grey[300],
              progressColor: newClients.statusColor,
              barRadius: Radius.circular(4),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn(
                  'Added',
                  newClients.newClientsAdded.toString(),
                  Colors.green,
                ),
                _buildMetricColumn(
                  'Target',
                  newClients.newClientsTarget.toString(),
                  Colors.blue,
                ),
                _buildMetricColumn(
                  'Remaining',
                  newClients.remainingClients.toString(),
                  Colors.orange,
                ),
                _buildMetricColumn(
                  'Progress',
                  '${newClients.progress}%',
                  newClients.statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSalesCard(ProductSalesProgress productSales) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Sales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              productSales.dateRange.displayText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            SizedBox(height: 16),
            _buildProductMetricRow(
                'Vapes', productSales.summary.vapes, Icons.cloud),
            SizedBox(height: 12),
            _buildProductMetricRow(
                'Pouches', productSales.summary.pouches, Icons.inventory_2),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total Orders',
                    productSales.summary.totalOrders.toString(),
                    Icons.shopping_cart,
                  ),
                  _buildSummaryItem(
                    'Total Quantity',
                    productSales.summary.totalQuantitySold.toString(),
                    Icons.inventory,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductMetricRow(
      String title, ProductMetric metric, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Spacer(),
            _buildStatusChip(metric.status, metric.statusColor),
          ],
        ),
        SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 6,
          percent: metric.completionPercentage,
          backgroundColor: Colors.grey[300],
          progressColor: metric.statusColor,
          barRadius: Radius.circular(3),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sold: ${metric.sold}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Target: ${metric.target}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${metric.progress}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: metric.statusColor,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductBreakdownCard(List<ProductBreakdown> breakdown) {
    if (breakdown.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            ...breakdown.take(5).map((product) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(product.categoryIcon,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.productName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.isVape
                              ? Colors.blue[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.productTypeDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: product.isVape
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${product.quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                )),
            if (breakdown.length > 5)
              Text(
                '... and ${breakdown.length - 5} more products',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
