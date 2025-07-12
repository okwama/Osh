import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/journeycontroller/journey_plans_controller.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/widgets/journey_plan/journey_plan_item_card.dart';

/// Widget for displaying the list of journey plans
class JourneyPlanListWidget extends StatelessWidget {
  final JourneyPlansController controller;
  final Function(JourneyPlan) onJourneyPlanTap;
  final Function(int)? onHideJourneyPlan;
  final Function(JourneyPlan)? onDeleteJourneyPlan;
  final ScrollController scrollController;

  const JourneyPlanListWidget({
    super.key,
    required this.controller,
    required this.onJourneyPlanTap,
    this.onHideJourneyPlan,
    this.onDeleteJourneyPlan,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filteredPlans = controller.getFilteredPlans();

      if (filteredPlans.isEmpty) {
        return const Center(child: Text('No journey plans found'));
      }

      return RefreshIndicator(
        onRefresh: controller.refreshJourneyPlans,
        child: ListView.builder(
          controller: scrollController,
          itemCount:
              filteredPlans.length + (controller.hasMoreData.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredPlans.length) {
              return controller.isLoadingMore.value
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const SizedBox.shrink();
            }

            final journeyPlan = filteredPlans[index];
            return JourneyPlanItemCard(
              journeyPlan: journeyPlan,
              onTap: () => onJourneyPlanTap(journeyPlan),
              onHide: journeyPlan.statusText == 'Completed' &&
                      journeyPlan.id != null
                  ? () => onHideJourneyPlan?.call(journeyPlan.id!)
                  : null,
              onDelete:
                  journeyPlan.statusText == 'Pending' && journeyPlan.id != null
                      ? () => onDeleteJourneyPlan?.call(journeyPlan)
                      : null,
              hasActiveVisit: controller.activeVisit.value != null &&
                  controller.activeVisit.value!.id != journeyPlan.id,
              activeVisit: controller.activeVisit.value,
            );
          },
        ),
      );
    });
  }
}

/// Widget for journey plan empty state
class JourneyPlanEmptyState extends StatelessWidget {
  const JourneyPlanEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Journey Plans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first journey plan to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget for journey plan loading state
class JourneyPlanLoadingState extends StatelessWidget {
  const JourneyPlanLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading Journey Plans...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
