import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';
import 'package:woosh/pages/journeyplan/reports/base_report_page.dart';
import 'package:woosh/services/core/reports/feedback_report_service.dart';

class FeedbackPage extends BaseReportPage {
  const FeedbackPage({
    super.key,
    required super.journeyPlan,
  }) : super(reportType: ReportType.FEEDBACK);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with BaseReportPageMixin {
  @override
  Future<void> onSubmit() async {
    if (commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
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

    // Use the new FeedbackReportService
    try {
      await FeedbackReportService.submitFeedbackReport(
      journeyPlanId: widget.journeyPlan.id!,
      clientId: widget.journeyPlan.client.id,
        comment: commentController.text,
        userId: salesRepId,
    );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Feedback report submitted successfully'),
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
            const Text(
              'Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your Feedback',
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
