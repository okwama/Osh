import 'package:flutter/material.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/widgets/journey_plan/client_search_widget.dart';
import 'package:woosh/widgets/journey_plan/journey_plan_form_widget.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:get/get.dart';

class CreateJourneyPlanPage extends StatefulWidget {
  final List<Client> clients;
  final Function(List<JourneyPlan>) onSuccess;

  const CreateJourneyPlanPage({
    super.key,
    required this.clients,
    required this.onSuccess,
  });

  @override
  State<CreateJourneyPlanPage> createState() => _CreateJourneyPlanPageState();
}

class _CreateJourneyPlanPageState extends State<CreateJourneyPlanPage> {
  Client? selectedClient;
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Create Journey Plan',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_showForm && selectedClient != null) {
      return JourneyPlanFormWidget(
        selectedClient: selectedClient!,
        onSuccess: (journeyPlan) {
          widget.onSuccess([journeyPlan]);
          Get.back();
        },
        onCancel: () {
          setState(() {
            _showForm = false;
            selectedClient = null;
          });
        },
      );
    }

    return ClientSearchWidget(
      initialClients: widget.clients,
      showLoadingState: widget.clients.isEmpty,
      onClientSelected: (client) {
        setState(() {
          selectedClient = client;
          _showForm = true;
        });
      },
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Create a Journey Plan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Search and select a client from the list'),
            SizedBox(height: 8),
            Text('2. Choose the visit date'),
            SizedBox(height: 8),
            Text('3. Select the route for the visit'),
            SizedBox(height: 8),
            Text('4. Add optional notes'),
            SizedBox(height: 8),
            Text('5. Click "Create Journey Plan"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
