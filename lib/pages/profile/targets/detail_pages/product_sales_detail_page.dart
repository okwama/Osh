import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/skeleton_loader.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:get_storage/get_storage.dart';

class ProductSalesDetailPage extends StatefulWidget {
  final String period;
  final Map<String, dynamic> initialData;

  const ProductSalesDetailPage({
    super.key,
    required this.period,
    required this.initialData,
  });

  @override
  State<ProductSalesDetailPage> createState() => _ProductSalesDetailPageState();
}

class _ProductSalesDetailPageState extends State<ProductSalesDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _productSalesProgress = {};
  String _selectedPeriod = 'current_month';
  String _selectedProductType = 'all'; // all, vapes, pouches

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
    _productSalesProgress = widget.initialData;
    _selectedPeriod = widget.period;
    _loadProductSalesData();
  }

  Future<void> _loadProductSalesData() async {
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

      // Load product sales progress for the selected period and product type
      final productSalesData = await TargetService.getProductSalesProgress(
        int.parse(userId),
        productType: _selectedProductType,
        period: _selectedPeriod,
      );

      if (mounted) {
        setState(() {
          _productSalesProgress = productSalesData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load product sales data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _changePeriod(String period) {
    if (period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadProductSalesData();
    }
  }

  void _changeProductType(String productType) {
    if (productType != _selectedProductType) {
      setState(() {
        _selectedProductType = productType;
      });
      _loadProductSalesData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Product Sales',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadProductSalesData,
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
            'Failed to load product sales data',
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
            onPressed: _loadProductSalesData,
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
      onRefresh: _loadProductSalesData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallProgressCard(),
            SizedBox(height: 20),
            _buildFilters(),
            SizedBox(height: 16),
            _buildProductBreakdown(),
            SizedBox(height: 16),
            _buildSalesSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    final summary = _productSalesProgress['summary'] ?? {};
    final vapes = summary['vapes'] ?? {};
    final pouches = summary['pouches'] ?? {};

    final vapesProgress = vapes['progress'] ?? 0;
    final pouchesProgress = pouches['progress'] ?? 0;
    final overallProgress = ((vapesProgress + pouchesProgress) / 2) / 100;

    final vapesStatus = vapes['status'] ?? 'In Progress';
    final pouchesStatus = pouches['status'] ?? 'In Progress';
    final overallStatus =
        (vapesStatus == 'Target Achieved' && pouchesStatus == 'Target Achieved')
            ? 'Target Achieved'
            : 'In Progress';
    final statusColor =
        overallStatus == 'Target Achieved' ? Colors.green : Colors.orange;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.purple.withOpacity(0.05),
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
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Sales Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    overallStatus,
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
                  percent: overallProgress,
                  center: Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  progressColor: Colors.purple,
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Progress',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Combined vapes and pouches performance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      SizedBox(height: 12),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: overallProgress,
                        backgroundColor: Colors.grey[300],
                        progressColor: Colors.purple,
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

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Period',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: _periods.map((period) {
                          final isSelected = period == _selectedPeriod;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _changePeriod(period),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                padding: EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purple
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _periodLabels[period] ?? period,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 10,
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
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildProductTypeButton(
                              'All', 'all', Icons.all_inclusive),
                          SizedBox(width: 4),
                          _buildProductTypeButton(
                              'Vapes', 'vapes', Icons.cloud),
                          SizedBox(width: 4),
                          _buildProductTypeButton(
                              'Pouches', 'pouches', Icons.inventory_2),
                        ],
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

  Widget _buildProductTypeButton(String label, String value, IconData icon) {
    final isSelected = _selectedProductType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeProductType(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 16,
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductBreakdown() {
    final summary = _productSalesProgress['summary'] ?? {};
    final vapes = summary['vapes'] ?? {};
    final pouches = summary['pouches'] ?? {};

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
                Icon(Icons.analytics, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Product Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildProductMetricRow(
              'Vapes',
              vapes['target'] ?? 0,
              vapes['sold'] ?? 0,
              vapes['progress'] ?? 0,
              vapes['status'] ?? 'In Progress',
              Colors.blue,
              Icons.cloud,
            ),
            SizedBox(height: 16),
            _buildProductMetricRow(
              'Pouches',
              pouches['target'] ?? 0,
              pouches['sold'] ?? 0,
              pouches['progress'] ?? 0,
              pouches['status'] ?? 'In Progress',
              Colors.green,
              Icons.inventory_2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductMetricRow(
    String title,
    int target,
    int sold,
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Spacer(),
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
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CircularPercentIndicator(
                radius: 25,
                lineWidth: 6,
                percent: progress / 100,
                center: Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                progressColor: color,
                backgroundColor: Colors.grey[300]!,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress: $sold / $target units',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${target - sold} units remaining',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearPercentIndicator(
                      lineHeight: 6,
                      percent: progress / 100,
                      backgroundColor: Colors.grey[300],
                      progressColor: color,
                      barRadius: Radius.circular(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesSummary() {
    final summary = _productSalesProgress['summary'] ?? {};
    final totalOrders = summary['totalOrders'] ?? 0;
    final totalQuantitySold = summary['totalQuantitySold'] ?? 0;
    final productBreakdown = _productSalesProgress['productBreakdown'] ?? [];

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
                Icon(Icons.summarize, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sales Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Orders',
                    totalOrders.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Units Sold',
                    totalQuantitySold.toString(),
                    Icons.inventory,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Products',
                    productBreakdown.length.toString(),
                    Icons.category,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (productBreakdown.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Top Products',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              ...productBreakdown
                  .take(5)
                  .map((product) => _buildProductItem(product)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(dynamic product) {
    final productName = product.productName ?? 'Unknown Product';
    final quantity = product.quantity ?? 0;
    final isVape = product.isVape ?? false;
    final category = product.category ?? 'Unknown';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isVape ? Icons.cloud : Icons.inventory_2,
            size: 16,
            color: isVape ? Colors.blue : Colors.green,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isVape ? Colors.blue[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isVape ? 'Vape' : 'Pouch',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isVape ? Colors.blue[700] : Colors.green[700],
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$quantity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
