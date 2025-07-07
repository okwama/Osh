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
    print('DRASTIC DEBUG: FEEDBACK REPORT PAGE INITIALIZED');
    print('Journey Plan Details:');
    print('Journey Plan ID: ${widget.journeyPlan.id}');
    print(
        'Journey Plan User ID: ${widget.journeyPlan.salesRepId} (${widget.journeyPlan.salesRepId.runtimeType})');
    print('Journey Plan Client ID: ${widget.journeyPlan.client.id}');

    // Try to get user ID from storage for comparison
    final box = GetStorage();
    final userData = box.read('salesRep');
    if (userData != null) {
      print('User data from storage: $userData');
      print(
          'User ID from storage: ${userData['id']} (${userData['id'].runtimeType})');

      // Compare user IDs
      final storedUserId = userData['id'];
      final journeyUserId = widget.journeyPlan.salesRepId;
      print('User ID comparison:');
      print('Direct equality: ${storedUserId == journeyUserId}');
      print(
          'String equality: ${storedUserId.toString() == journeyUserId.toString()}');
    } else {
      print('WARNING: No user data found in storage');
    }
  }

  @override
  Future<void> onSubmit() async {
    print('DRASTIC DEBUG: FEEDBACK REPORT SUBMISSION STARTED');

    if (commentController.text.trim().isEmpty) {
      print('DRASTIC DEBUG: Empty comment detected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback')),
      );
      return;
    }

    // Get the currently logged in salesRep from storage
    final box = GetStorage();
    final salesRepData = box.read('salesRep');

    if (salesRepData == null) {
      print('DRASTIC DEBUG: No salesRep data found in storage');
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
      print('DRASTIC DEBUG: Could not determine salesRep ID from storage data');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication error: User ID not found')),
      );
      return;
    }

    print('DRASTIC DEBUG: Creating report with:');
    print('Type: ${ReportType.FEEDBACK}');
    print('Journey Plan ID: ${widget.journeyPlan.id}');
    print('SalesRep ID: $salesRepId');
    print('Client ID: ${widget.journeyPlan.client.id}');
    print('Comment: ${commentController.text}');

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
    print('FEEDBACK REPORT DEBUG: Report type: ${report.type}');
    print(
        'FEEDBACK REPORT DEBUG: Report journeyPlanId: ${report.journeyPlanId}');
    print('FEEDBACK REPORT DEBUG: Report salesRepId: ${report.salesRepId}');
    print('FEEDBACK REPORT DEBUG: Report clientId: ${report.clientId}');

    if (report.feedbackReport == null) {
      print('FEEDBACK REPORT DEBUG: ERROR - feedbackReport field is null!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Feedback details missing')),
      );
      return;
    }

    print(
        'FEEDBACK REPORT DEBUG: FeedbackReport comment: ${report.feedbackReport!.comment}');

    print('DRASTIC DEBUG: Report created, submitting...');
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
