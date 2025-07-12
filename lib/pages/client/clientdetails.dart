import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as ptr;
import 'package:woosh/models/client/client_payment_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:woosh/utils/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:woosh/utils/country_tax_labels.dart';
import 'package:woosh/controllers/paymentcontroller/payment_controller.dart';
import 'package:woosh/controllers/clientcontroler/client_stock_controller.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/pages/client/payment_dialog.dart';
import 'package:woosh/pages/client/payment_history_card.dart';
import 'package:woosh/pages/client/client_details_widgets.dart';

class ClientDetailsPage extends StatefulWidget {
  final Client client;

  const ClientDetailsPage({super.key, required this.client});

  @override
  State<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  String? _locationDescription;
  List<ClientPayment> _payments = [];
  bool _loadingPayments = false;
  String? _errorMessage;
  final ptr.RefreshController _refreshController = ptr.RefreshController();
  bool _clientStockEnabled = true; // Track if client stock feature is enabled

  @override
  void initState() {
    super.initState();
    _decodeLocation();
    _fetchPayments();
    _checkClientStockFeature();
  }

  Future<void> _decodeLocation() async {
    if (widget.client.latitude != null && widget.client.longitude != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          widget.client.latitude!,
          widget.client.longitude!,
        );
        final placemark = placemarks.first;
        setState(() {
          _locationDescription =
              "${placemark.street}, ${placemark.locality}, ${placemark.country}";
        });
      } catch (e) {
        setState(() {
          _locationDescription = "Location unavailable";
        });
      }
    }
  }

  Future<void> _fetchPayments() async {
    if (_loadingPayments) return;

    setState(() {
      _loadingPayments = true;
      _errorMessage = null;
    });

    try {
      final paymentController = Get.find<PaymentController>();
      final paymentsData =
          await paymentController.getClientPayments(widget.client.id);
      setState(() {
        _payments = paymentsData;
      });
    } catch (e) {
      // Handle server errors silently
      if (e.toString().contains('500') ||
          e.toString().contains('501') ||
          e.toString().contains('502') ||
          e.toString().contains('503')) {
      } else {
        setState(() {
          _errorMessage = 'Failed to load payments. Please try again.';
        });
        _showErrorDialog();
      }
    } finally {
      setState(() => _loadingPayments = false);
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _checkClientStockFeature() async {
    try {
      final clientStockController = Get.find<ClientStockController>();
      final isEnabled = await clientStockController.checkFeatureEnabled();
      setState(() {
        _clientStockEnabled = isEnabled;
      });
    } catch (e) {
      // Default to enabled if we can't check the status or endpoint doesn't exist
      setState(() {
        _clientStockEnabled = true;
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchPayments(),
      _checkClientStockFeature(),
    ]);
  }

  void _showErrorDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load payments. This could be due to:'),
              const SizedBox(height: 8),
              const Text('• No internet connection'),
              const Text('• Server is temporarily unavailable'),
              const Text('• Database connection issues'),
              const SizedBox(height: 16),
              const Text('Would you like to retry?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _fetchPayments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showAddPaymentDialog() async {
    await PaymentDialog.showAddPaymentDialog(
      context,
      widget.client.id,
      _fetchPayments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final outlet = widget.client;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: outlet.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPayments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPayments,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CreamGradientCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  child: Icon(Icons.person, size: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        outlet.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Balance: Ksh ${outlet.balance != null && outlet.balance!.isNotEmpty ? outlet.balance! : '0'}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DetailSection(
                                    icon: Icons.home,
                                    label: 'Address',
                                    value: outlet.address,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DetailSection(
                                    icon: Icons.email,
                                    label: 'Email',
                                    value: outlet.email ?? '-',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: DetailSection(
                                    icon: Icons.phone,
                                    label: 'Phone',
                                    value: outlet.contact ?? '-',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DetailSection(
                                    icon: Icons.badge,
                                    label: CountryTaxLabels.getTaxPinLabel(
                                        widget.client.countryId),
                                    value: outlet.taxPin ?? '-',
                                  ),
                                ),
                              ],
                            ),
                            if (_locationDescription != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: DetailSection(
                                      icon: Icons.place,
                                      label: 'Location',
                                      value: _locationDescription!,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                      child:
                                          SizedBox()), // Empty to keep layout
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Add Payment'),
                                onPressed: _showAddPaymentDialog,
                                style: ElevatedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payments',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _showAddPaymentDialog,
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Add',
                                style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      PaymentHistoryCard(
                        payments: _payments,
                        loading: _loadingPayments,
                        onRefresh: _fetchPayments,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
