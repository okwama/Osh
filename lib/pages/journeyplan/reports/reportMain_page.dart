import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/services/core/journey_plan_service.dart';
import 'package:woosh/services/core/reports/index.dart';
import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';
import 'package:woosh/models/journeyplan/report/product_sample_item_model.dart';
import 'package:woosh/pages/journeyplan/reports/pages/feedback_report_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_report_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_sample.dart';
import 'package:woosh/pages/journeyplan/reports/pages/visibility_report_page.dart';
import 'package:woosh/pages/journeyplan/reports/product_availability_page.dart';
import 'package:woosh/pages/journeyplan/reports/base_report_page.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';

class ReportsOrdersPage extends StatefulWidget {
  final JourneyPlan journeyPlan;
  final VoidCallback? onAllReportsSubmitted;

  const ReportsOrdersPage({
    super.key,
    required this.journeyPlan,
    this.onAllReportsSubmitted,
  });

  @override
  State<ReportsOrdersPage> createState() => _ReportsOrdersPageState();
}

class _ReportsOrdersPageState extends State<ReportsOrdersPage> {
  final _commentController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  ProductModel? _selectedProduct;
  File? _imageFile;
  String? _imageUrl;
  final ReportType _selectedReportType = ReportType.PRODUCT_AVAILABILITY;
  List<ProductModel> _products = [];
  List<Report> _submittedReports = [];
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.getProducts(
        page: 1,
        limit: 100,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  Future<void> _loadExistingReports() async {
    try {
      final reports = await ReportService.getReports(
        journeyPlanId: widget.journeyPlan.id,
        limit: 100,
      );
      setState(() {
        _submittedReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading existing reports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadExistingReports();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reports refreshed')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      // For now, we'll skip image upload in this page since it's handled by individual report pages
      // This method is kept for compatibility but doesn't actually upload
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    // Validate form first
    if (_selectedReportType == ReportType.PRODUCT_AVAILABILITY &&
        _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    if (_selectedReportType == ReportType.VISIBILITY_ACTIVITY &&
        _imageFile == null &&
        _imageUrl == null &&
        _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image or comment')),
      );
      return;
    }

    if (_selectedReportType == ReportType.FEEDBACK &&
        _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = await _uploadImage();

      // Get the currently logged in salesRep from storage
      final box = GetStorage();
      final salesRepData = box.read('salesRep');

      if (salesRepData == null) {
        throw Exception("User not authenticated: No salesRep data found");
      }

      // Extract the salesRep ID from the stored data
      final int? salesRepId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (salesRepId == null) {
        throw Exception(
            "User not authenticated: Could not determine salesRep ID");
      }

      print(
          'Creating report using salesRepId: $salesRepId from stored salesRep data');

      Report report;
      switch (_selectedReportType) {
        case ReportType.PRODUCT_AVAILABILITY:
          // Use the new ProductReportService
          final productReports = [
            ProductReport(
              reportId: 0,
              productName: _selectedProduct?.name ?? '',
              quantity: int.tryParse(_quantityController.text) ?? 0,
              comment: _commentController.text,
            ),
          ];

          report = await ProductReportService.submitProductReport(
            journeyPlanId: widget.journeyPlan.id!,
            clientId: widget.journeyPlan.client.id,
            productReports: productReports,
            userId: salesRepId,
          );
          break;

        case ReportType.VISIBILITY_ACTIVITY:
          // Use the new VisibilityReportService
          report = await VisibilityReportService.submitVisibilityReport(
            journeyPlanId: widget.journeyPlan.id!,
            clientId: widget.journeyPlan.client.id,
            comment: _commentController.text,
            imageUrl: imageUrl,
            userId: salesRepId,
          );
          break;

        case ReportType.FEEDBACK:
          // Use the new FeedbackReportService
          report = await FeedbackReportService.submitFeedbackReport(
            journeyPlanId: widget.journeyPlan.id!,
            clientId: widget.journeyPlan.client.id,
            comment: _commentController.text,
            userId: salesRepId,
          );
          break;

        case ReportType.PRODUCT_RETURN:
          // Use the new ProductReturnService
          final productReturnItems = [
            ProductReturnItem(
              productName: _selectedProduct?.name ?? '',
              quantity: int.tryParse(_quantityController.text) ?? 0,
              reason: _commentController.text,
              imageUrl: imageUrl,
            ),
          ];

          report = await ProductReturnService.submitProductReturnReport(
            clientId: widget.journeyPlan.client.id,
            productReturnItems: productReturnItems,
            userId: salesRepId,
          );
          break;

        case ReportType.PRODUCT_SAMPLE:
          // Use the new ProductSampleService
          final productSampleItems = [
            ProductSampleItem(
              productName: _selectedProduct?.name ?? '',
              quantity: int.tryParse(_quantityController.text) ?? 0,
              reason: _commentController.text,
            ),
          ];

          report = await ProductSampleService.submitProductSampleReport(
            journeyPlanId: widget.journeyPlan.id!,
            clientId: widget.journeyPlan.client.id,
            productSampleItems: productSampleItems,
            userId: salesRepId,
          );
          break;
      }

      setState(() {
        _submittedReports.add(report);
        _resetForm();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );

      // Check if all required reports are submitted
      if (_areAllReportsSubmitted()) {
        widget.onAllReportsSubmitted?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _areAllReportsSubmitted() {
    bool hasProductReport =
        _submittedReports.any((r) => r.type == ReportType.PRODUCT_AVAILABILITY);
    bool hasVisibilityReport =
        _submittedReports.any((r) => r.type == ReportType.VISIBILITY_ACTIVITY);
    bool hasFeedbackReport =
        _submittedReports.any((r) => r.type == ReportType.FEEDBACK);

    return hasProductReport && hasVisibilityReport && hasFeedbackReport;
  }

  void _resetForm() {
    _commentController.clear();
    _quantityController.clear();
    _selectedProduct = null;
    _imageFile = null;
    _imageUrl = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Reports & Sales',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outlet Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.journeyPlan.client.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.journeyPlan.client.address,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Report Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // // Sales Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (context) => SalesPage(
                    //             journeyPlan: widget.journeyPlan,
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Theme.of(context).primaryColor,
                    //       foregroundColor: Colors.white,
                    //       alignment: Alignment.centerLeft,
                    //       padding: const EdgeInsets.symmetric(
                    //           vertical: 8, horizontal: 12),
                    //       minimumSize: const Size.fromHeight(36),
                    //     ),
                    //     icon: const Icon(Icons.shopping_cart, size: 18),
                    //     label: const Text('Post Sales',
                    //         style: TextStyle(fontSize: 13)),
                    //   ),
                    // ),
                    const SizedBox(height: 6),
                    // Product Availability Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(
                            () => ProductReportPage(
                              journeyPlan: widget.journeyPlan,
                              onReportSubmitted: () {
                                setState(() {
                                  _submittedReports.add(Report(
                                    type: ReportType.PRODUCT_AVAILABILITY,
                                    journeyPlanId: widget.journeyPlan.id,
                                    salesRepId:
                                        GetStorage().read('salesRep')['id'],
                                    clientId: widget.journeyPlan.client.id,
                                  ));
                                });
                                if (_areAllReportsSubmitted()) {
                                  widget.onAllReportsSubmitted?.call();
                                }
                              },
                            ),
                            transition: Transition.rightToLeft,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          minimumSize: const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.inventory, size: 18),
                        label: const Text('Product Availability',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Visibility Activity Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(
                            () => VisibilityReportPage(
                              journeyPlan: widget.journeyPlan,
                              onReportSubmitted: () {
                                setState(() {
                                  _submittedReports.add(Report(
                                    type: ReportType.VISIBILITY_ACTIVITY,
                                    journeyPlanId: widget.journeyPlan.id,
                                    salesRepId:
                                        GetStorage().read('salesRep')['id'],
                                    clientId: widget.journeyPlan.client.id,
                                  ));
                                });
                                if (_areAllReportsSubmitted()) {
                                  widget.onAllReportsSubmitted?.call();
                                }
                              },
                            ),
                            transition: Transition.rightToLeft,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          minimumSize: const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.photo_camera, size: 18),
                        label: const Text('Visibility Activity',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Feedback Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(
                            () => FeedbackReportPage(
                              journeyPlan: widget.journeyPlan,
                              onReportSubmitted: () {
                                setState(() {
                                  _submittedReports.add(Report(
                                    type: ReportType.FEEDBACK,
                                    journeyPlanId: widget.journeyPlan.id,
                                    salesRepId:
                                        GetStorage().read('salesRep')['id'],
                                    clientId: widget.journeyPlan.client.id,
                                  ));
                                });
                                if (_areAllReportsSubmitted()) {
                                  widget.onAllReportsSubmitted?.call();
                                }
                              },
                            ),
                            transition: Transition.rightToLeft,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          minimumSize: const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.feedback, size: 18),
                        label: const Text('Feedback',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Product Return Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (context) => ProductReturnPage(
                    //             journeyPlan: widget.journeyPlan,
                    //             onReportSubmitted: () {
                    //               setState(() {
                    //                 _submittedReports.add(Report(
                    //                   type: ReportType.PRODUCT_RETURN,
                    //                   journeyPlanId: widget.journeyPlan.id,
                    //                   salesRepId:
                    //                       GetStorage().read('salesRep')['id'],
                    //                   clientId: widget.journeyPlan.client.id,
                    //                 ));
                    //               });
                    //             },
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.red,
                    //       foregroundColor: Colors.white,
                    //       alignment: Alignment.centerLeft,
                    //       padding: const EdgeInsets.symmetric(
                    //           vertical: 8, horizontal: 12),
                    //       minimumSize: const Size.fromHeight(36),
                    //     ),
                    //     icon: const Icon(Icons.assignment_return, size: 18),
                    //     label: const Text('Product Return',
                    //         style: TextStyle(fontSize: 13)),
                    //   ),
                    // ),
                    const SizedBox(height: 6),
                    // Product Sample Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(
                            () => ProductSamplePage(
                              journeyPlan: widget.journeyPlan,
                              onReportSubmitted: () {
                                setState(() {
                                  _submittedReports.add(Report(
                                    type: ReportType.PRODUCT_SAMPLE,
                                    journeyPlanId: widget.journeyPlan.id,
                                    salesRepId:
                                        GetStorage().read('salesRep')['id'],
                                    clientId: widget.journeyPlan.client.id,
                                  ));
                                });
                              },
                            ),
                            transition: Transition.rightToLeft,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 145, 238, 122),
                          foregroundColor: Colors.white,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          minimumSize: const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.assignment_return, size: 18),
                        label: const Text('Product Sample',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Checkout Button
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Visit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'When you have completed all required tasks, check out to mark this visit as complete.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingOut ? null : _confirmCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: _isCheckingOut
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('CHECK OUT',
                                style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCheckout() async {
    if (_isCheckingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: const Text(
          'Are you sure you want to check out from this location? This will mark your visit as complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('CHECK OUT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processCheckout();
    }
  }

  Future<void> _processCheckout() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Get current position with timeout and fallback
      print('CHECKOUT: Starting checkout process...');
      print('CHECKOUT: Getting current position...');

      Position? position;
      try {
        // Try to get current position with timeout
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Faster than high
          timeLimit: const Duration(seconds: 10), // 10 second timeout
        );
        print(
            'CHECKOUT: GPS position obtained: ${position.latitude}, ${position.longitude}');
        print('CHECKOUT: Accuracy: ${position.accuracy} meters');
      } catch (gpsError) {
        print(
            'CHECKOUT: GPS timeout/error, trying last known position: $gpsError');

        // Fallback to last known position
        try {
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            print(
                'CHECKOUT: Using last known position: ${position.latitude}, ${position.longitude}');
          } else {
            print('CHECKOUT: No last known position, using client coordinates');
            // Use client coordinates as final fallback
            position = Position(
              latitude: widget.journeyPlan.client.latitude ?? 0.0,
              longitude: widget.journeyPlan.client.longitude ?? 0.0,
              timestamp: DateTime.now(),
              accuracy: 1000.0, // Low accuracy indicator
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
          }
        } catch (fallbackError) {
          print(
              'CHECKOUT: Fallback position failed, using client coordinates: $fallbackError');
          // Use client coordinates as final fallback
          position = Position(
            latitude: widget.journeyPlan.client.latitude ?? 0.0,
            longitude: widget.journeyPlan.client.longitude ?? 0.0,
            timestamp: DateTime.now(),
            accuracy: 1000.0, // Low accuracy indicator
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        }
      }

      print(
          'CHECKOUT: Final position: ${position.latitude}, ${position.longitude}');
      print('CHECKOUT: Accuracy: ${position.accuracy} meters');
      print('CHECKOUT: Timestamp: ${DateTime.now().toIso8601String()}');
      print('CHECKOUT: Journey ID: ${widget.journeyPlan.id}');
      print('CHECKOUT: Client ID: ${widget.journeyPlan.client.id}');

      // Update journey plan with checkout information
      print('CHECKOUT: Sending data to API...');
      final response = await JourneyPlanService.updateJourneyPlan(
        journeyId: widget.journeyPlan.id!,
        clientId: widget.journeyPlan.client.id,
        status: JourneyPlan.statusCompleted,
        checkoutTime: DateTime.now(),
        checkoutLatitude: position.latitude,
        checkoutLongitude: position.longitude,
      );

      print('CHECKOUT: API response received:');
      print('CHECKOUT: Updated Journey Plan ID: ${response.id}');
      print('CHECKOUT: New Status: ${response.statusText}');
      print('CHECKOUT: Checkout Time: ${response.checkoutTime}');
      print('CHECKOUT: Checkout Latitude: ${response.checkoutLatitude}');
      print('CHECKOUT: Checkout Longitude: ${response.checkoutLongitude}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout completed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Call the callback if provided
        widget.onAllReportsSubmitted?.call();

        // Navigate back after successful checkout
        Get.back();
      }
    } catch (e) {
      print('CHECKOUT ERROR: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during checkout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }
}
