import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';
import 'package:woosh/pages/journeyplan/reports/base_report_page.dart';

class FeedbackReportPage extends BaseReportPage {
  const FeedbackReportPage({super.key, required super.journeyPlan})
      : super(
          reportType: ReportType.FEEDBACK,
        );

  @override
  State<FeedbackReportPage> createState() => _FeedbackReportPageState();
}

class _FeedbackReportPageState extends State<FeedbackReportPage>
    with BaseReportPageMixin {
  @override
  void initState() {
    super.initState();
    print(
        'Journey Plan User ID: ${widget.journeyPlan.salesRepId} (${widget.journeyPlan.salesRepId.runtimeType})');

    // Try to get user ID from storage for comparison
    final box = GetStorage();
    final userData = box.read('salesRep');
    if (userData != null) {
      print(
          'User ID from storage: ${userData['id']} (${userData['id'].runtimeType})');

      // Compare user IDs
      final storedUserId = userData['id'];
      final journeyUserId = widget.journeyPlan.salesRepId;
      print(
          'String equality: ${storedUserId.toString() == journeyUserId.toString()}');
    } else {
    }
  }

  @override
  Future<void> onSubmit() async {

    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback')),
      );
      return;
    }

    // Get the currently logged in salesRep from storage
    final box = GetStorage();
    final salesRepData = box.read('salesRep');

    if (salesRepData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication error: User data not found')),
      );
      return;
    }

    // Extract the salesRep ID from the stored data
    final int? salesRepId =
        salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

    if (salesRepId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication error: User ID not found')),
      );
      return;
    }


    final report = Report(
      type: ReportType.FEEDBACK,
      journeyPlanId: widget.journeyPlan.id!,
      salesRepId: salesRepId,
      clientId: widget.journeyPlan.client.id,
      feedbackReport: FeedbackReport(
        reportId: 0,
        comment: commentController.text,
      ),
    );

    // Debug: Validate report object before submission
    print(
        'FEEDBACK REPORT DEBUG: Report journeyPlanId: ${report.journeyPlanId}');

    if (report.feedbackReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Feedback details missing')),
      );
      return;
    }

    print(
        'FEEDBACK REPORT DEBUG: FeedbackReport comment: ${report.feedbackReport!.comment}');

    await submitReport(report);
  }

  @override
  Widget buildReportForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client: ${widget.journeyPlan.client.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Address: ${widget.journeyPlan.client.address}',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}