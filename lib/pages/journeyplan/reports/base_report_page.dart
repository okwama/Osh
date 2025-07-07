import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'package:geolocator/geolocator.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/services/core/journey_plan_service.dart';

mixin BaseReportPageMixin<T extends StatefulWidget> on State<T> {
  TextEditingController get commentController => _commentController;
  bool get isSubmitting => _isSubmitting;
  set isSubmitting(bool value) => _isSubmitting = value;

  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingOut = false;
  Position? _currentPosition;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void resetForm() {
    setState(() {
      _commentController.clear();
      _isSubmitting = false;
    });
  }

  Future<void> submitReport(Report report) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // This method is now handled by individual report services
      // The specific report submission logic is implemented in each report page
      print('Report submission handled by individual services');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget buildOutletInfo() {
    final journeyPlan = (widget as BaseReportPage).journeyPlan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              journeyPlan.client.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Address: ${journeyPlan.client.address}'),
            if (journeyPlan.client.latitude != null &&
                journeyPlan.client.longitude != null)
              Text(
                  'Location: ${journeyPlan.client.latitude}, ${journeyPlan.client.longitude}'),
          ],
        ),
      ),
    );
  }

  Widget buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => onSubmit(),
        child: _isSubmitting
            ? const CircularProgressIndicator()
            : const Text('Submit Report'),
      ),
    );
  }

  Widget buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCheckingOut ? null : _confirmCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isCheckingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Complete Visit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _confirmCheckout() async {
    // Quick confirmation with minimal UI
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Complete Visit?'),
        content: Text(
            'Finish visit at ${(widget as BaseReportPage).journeyPlan.client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processCheckout();
    }
  }

  Future<void> _processCheckout() async {
    if (_isCheckingOut) return;

    setState(() => _isCheckingOut = true);

    try {
      final journeyPlan = (widget as BaseReportPage).journeyPlan;
      final now = DateTime.now();

      // Lightweight GPS with shorter timeout
      double latitude, longitude;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Lower accuracy = faster
          timeLimit: const Duration(seconds: 5), // Shorter timeout
        );
        latitude = position.latitude;
        longitude = position.longitude;
        print('📍 GPS acquired: $latitude, $longitude');
      } catch (e) {
        // Quick fallback to client location
        latitude = journeyPlan.client.latitude ?? 0.0;
        longitude = journeyPlan.client.longitude ?? 0.0;
        print('⚠️ Using client location: $latitude, $longitude');
      }

      // Essential data update only
      final updatedPlan = await JourneyPlanService.updateJourneyPlan(
        journeyId: journeyPlan.id!,
        clientId: journeyPlan.client.id,
        status: JourneyPlan.statusCompleted,
        checkoutTime: now,
        checkoutLatitude: latitude,
        checkoutLongitude: longitude,
      );

      if (mounted) {
        // Minimal success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${journeyPlan.client.name} - Completed'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Essential logging only
        print(
            '✅ Checkout: ${journeyPlan.client.name} at ${DateFormat('HH:mm').format(now)}');

        Get.back(result: updatedPlan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  Future<void> onSubmit() async {
    // To be implemented by subclasses
  }

  Widget buildReportForm() {
    return const SizedBox.shrink(); // To be implemented by subclasses
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${(widget as BaseReportPage).reportType.name} Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildOutletInfo(),
            const SizedBox(height: 16),
            buildReportForm(),
            const SizedBox(height: 16),
            buildSubmitButton(),
            const SizedBox(height: 16),
            buildCheckoutButton(),
          ],
        ),
      ),
    );
  }
}

class BaseReportPage extends StatefulWidget {
  final JourneyPlan journeyPlan;
  final ReportType reportType;

  const BaseReportPage({
    super.key,
    required this.journeyPlan,
    required this.reportType,
  });

  @override
  State<BaseReportPage> createState() => _BaseReportPageState();
}

class _BaseReportPageState extends State<BaseReportPage>
    with BaseReportPageMixin {
  @override
  Future<void> onSubmit() async {
    // Base implementation does nothing
  }
}

