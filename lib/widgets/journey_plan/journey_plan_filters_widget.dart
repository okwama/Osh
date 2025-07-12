import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woosh/controllers/journeycontroller/journey_plans_controller.dart';

/// Widget for journey plan filtering and sorting controls
class JourneyPlanFiltersWidget extends StatelessWidget {
  final JourneyPlansController controller;
  final VoidCallback onRefresh;

  const JourneyPlanFiltersWidget({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: const Center(
        child: Text(
          'My Journey Plans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Widget for journey plan app bar actions
class JourneyPlanAppBarActions extends StatelessWidget {
  final JourneyPlansController controller;
  final VoidCallback onRefresh;

  const JourneyPlanAppBarActions({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => IconButton(
              icon: Icon(controller.sortAscending.value
                  ? Icons.sort
                  : Icons.sort_by_alpha),
              tooltip: controller.sortAscending.value
                  ? 'Sort Descending'
                  : 'Sort Ascending',
              onPressed: controller.toggleSortOrder,
            )),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

/// Widget for journey plan loading shimmer
class JourneyPlanLoadingShimmer extends StatelessWidget {
  const JourneyPlanLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: const Center(
            child: Text(
              'My Journey Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListView.builder(
              itemCount: 5, // Show 5 shimmer items
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                    height: 70,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 100,
                                height: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
