import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/services/core/reports/product_report_service.dart';
import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';

class ProductReportPage extends StatefulWidget {
  final JourneyPlan journeyPlan;
  final VoidCallback? onReportSubmitted;
  final List<ProductModel>? preloadedProducts;

  const ProductReportPage({
    super.key,
    required this.journeyPlan,
    this.onReportSubmitted,
    this.preloadedProducts,
  });

  static Future<List<ProductModel>> preloadProducts() async {
    try {
      final products = await ProductService.getProducts(
        page: 1,
        limit: 20,
      );
      return products;
    } catch (e) {
      return [];
    }
  }

  @override
  State<ProductReportPage> createState() => _ProductReportPageState();
}

class _ProductReportPageState extends State<ProductReportPage> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<ProductModel> _products = [];
  Map<int, int> _productQuantities = {}; // Map of productId to quantity
  Map<int, TextEditingController> _quantityControllers =
      {}; // Controllers for quantity fields
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _hasMoreProducts = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    // Dispose all quantity controllers
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreProducts) {
      _loadMoreProducts();
    }
  }

  Future<void> _initializeProducts() async {
    try {
      setState(() => _isLoading = true);

      // Use preloaded products if available
      if (widget.preloadedProducts != null &&
          widget.preloadedProducts!.isNotEmpty) {
        _setupProductsState(widget.preloadedProducts!);
        return;
      }

      // Load from new ProductService
      final products = await ProductService.getProducts(
        page: 1,
        limit: _pageSize,
      );
      _setupProductsState(products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Error loading products: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _initializeProducts,
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupProductsState(List<ProductModel> products) {
    if (mounted) {
      setState(() {
        _products = products;
        _productQuantities = {for (var product in products) product.id: 0};
        _quantityControllers = {
          for (var product in products)
            product.id: TextEditingController(text: '0')
        };
        _isLoading = false;
        _hasMoreProducts = products.length == _pageSize;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final moreProducts = await ProductService.getProducts(
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _products.addAll(moreProducts);
        _productQuantities
            .addAll({for (var product in moreProducts) product.id: 0});
        _quantityControllers.addAll({
          for (var product in moreProducts)
            product.id: TextEditingController(text: '0')
        });
        _currentPage = nextPage;
        _hasMoreProducts = moreProducts.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingMore = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading more products: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadMoreProducts,
          ),
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    // Check if at least one product has a quantity > 0
    bool hasQuantities = _productQuantities.values.any((qty) => qty > 0);
    if (!hasQuantities) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantities for at least one product'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final salesRepId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] as int : 0;

      if (salesRepId == 0) {
        throw Exception(
            "User not authenticated: Could not determine salesRep ID");
      }

      // Create a list of product reports for products with quantities > 0
      final productReports = _products
          .where((product) => _productQuantities[product.id]! > 0)
          .map((product) => ProductReport(
                reportId: 0,
                productName: product.name,
                productId: product.id,
                quantity: _productQuantities[product.id]!,
                comment: _commentController.text,
              ))
          .toList();

      // Use new ProductReportService
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
        widget.onReportSubmitted?.call();
        Get.back();
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
              onPressed: _submitReport,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Product Availability Report',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeProducts,
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outlet Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store,
                            size: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.journeyPlan.client.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.journeyPlan.client.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
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
            ),
            const SizedBox(height: 16),

            // Product Report Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Product Availability',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_products.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _initializeProducts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Products Table
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Product',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Quantity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  _products.length + (_hasMoreProducts ? 1 : 0),
                              separatorBuilder: (context, index) => Divider(
                                  height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                if (index == _products.length) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Center(
                                      child: _isLoadingMore
                                          ? const CircularProgressIndicator()
                                          : const SizedBox.shrink(),
                                    ),
                                  );
                                }

                                final product = _products[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: TextField(
                                            controller: _quantityControllers[
                                                product.id],
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                _productQuantities[product.id] =
                                                    int.tryParse(value) ?? 0;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Additional Comments',
                          hintText: 'Enter any additional comments...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Submitting...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Product Report',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
