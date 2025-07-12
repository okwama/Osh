import 'package:flutter/material.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';

class JourneyStatusCard extends StatelessWidget {
  final JourneyPlan journeyPlan;

  const JourneyStatusCard({
    super.key,
    required this.journeyPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: journeyPlan.statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: journeyPlan.statusColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Journey Status:',
              style: TextStyle(
                color: journeyPlan.statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: journeyPlan.statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                journeyPlan.statusText.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
