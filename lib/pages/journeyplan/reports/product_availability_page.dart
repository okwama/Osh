import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/pages/journeyplan/reports/base_report_page.dart';
import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/services/core/reports/product_report_service.dart';
import 'package:woosh/services/hive/product_hive_service.dart';

class ProductAvailabilityPage extends BaseReportPage {
  const ProductAvailabilityPage({
    super.key,
    required super.journeyPlan,
  }) : super(reportType: ReportType.PRODUCT_AVAILABILITY);

  @override
  State<ProductAvailabilityPage> createState() =>
      _ProductAvailabilityPageState();
}

class _ProductAvailabilityPageState extends State<ProductAvailabilityPage>
    with BaseReportPageMixin {
  final List<ProductModel> _products = [];
  final Map<int, TextEditingController> _quantityControllers = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  final ProductHiveService _hiveService = ProductHiveService();
  static const _cacheExpirationDuration = Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _initHiveAndLoadProducts();
  }

  Future<void> _initHiveAndLoadProducts() async {
    try {
      await _hiveService.init();
      await _loadProducts(forceRefresh: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing storage: $e')));
      }
    }
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    try {
      // Always load from Hive first - instant display
      final cachedProducts = await _hiveService.getAllProductModels();
      if (cachedProducts.isNotEmpty) {
        _updateProductsList(cachedProducts);
        setState(() => _isLoading = false);
      }

      // Only fetch from direct database on manual refresh
      if (forceRefresh) {
        setState(() => _isRefreshing = true);

        try {
          final dbProducts = await ProductService.getProducts(
            page: 1,
            limit: 1000,
          );
          final validDbProducts = dbProducts
              .where((product) =>
                  product.category.isNotEmpty && product.name.isNotEmpty)
              .toList();

          // Update local storage with new data
          await _hiveService.saveProducts(validDbProducts);

          // Update UI with new data
          if (mounted) {
            _updateProductsList(validDbProducts);
          }
        } catch (e) {
          // If database fails, keep showing local data
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text('Failed to refresh products. Using local data.')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading local products: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _updateProductsList(List<ProductModel> products) {
    // Sort products alphabetically
    products.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _products.clear();
      _products.addAll(products);

      // Initialize quantity controllers for all products
      for (var product in _products) {
        _quantityControllers.putIfAbsent(
          product.id,
          () => TextEditingController(),
        );
      }
    });
  }

  @override
  void dispose() {
    // Dispose all quantity controllers
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void resetForm() {
    setState(() {
      for (var controller in _quantityControllers.values) {
        controller.clear();
      }
      commentController.clear();
      isSubmitting = false;
    });
  }

  @override
  Future<void> onSubmit() async {
    // Find all products with entered quantities
    final productReports = <ProductReport>[];

    for (var product in _products) {
      final quantityText = _quantityControllers[product.id]?.text ?? '';
      if (quantityText.isNotEmpty) {
        final quantity = int.tryParse(quantityText);
        if (quantity == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter valid quantities')),
          );
          return;
        }

        productReports.add(ProductReport(
          reportId: 0, // Will be set by backend
          productName: product.name,
          quantity: quantity,
          comment: commentController.text,
        ));
      }
    }

    if (productReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter quantities for at least one product')),
      );
      return;
    }

    final box = GetStorage();
    final salesRepData = box.read('salesRep');
    final int? salesRepId =
        salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

    if (salesRepId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Use new ProductReportService to submit report
    try {
      await ProductReportService.submitProductReport(
        journeyPlanId: widget.journeyPlan.id!,
        clientId: widget.journeyPlan.client.id,
        productReports: productReports,
        userId: salesRepId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Product availability report submitted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error submitting report: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onSubmit,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget buildReportForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Product Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isRefreshing
                      ? null
                      : () => _loadProducts(forceRefresh: true),
                  tooltip: 'Refresh Products',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildProductsTable(),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Comments',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Quantity')),
        ],
        rows: _products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text(product.name)),
              DataCell(Text(product.category)),
              DataCell(
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _quantityControllers[product.id],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Qty',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
