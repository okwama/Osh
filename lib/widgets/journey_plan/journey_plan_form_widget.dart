import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/core/route_service.dart' as RouteServices;
import 'package:woosh/services/database_service.dart';
import 'package:woosh/utils/app_theme.dart';

class JourneyPlanFormWidget extends StatefulWidget {
  final Client selectedClient;
  final Function(JourneyPlan) onSuccess;
  final VoidCallback onCancel;

  const JourneyPlanFormWidget({
    super.key,
    required this.selectedClient,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<JourneyPlanFormWidget> createState() => _JourneyPlanFormWidgetState();
}

class _JourneyPlanFormWidgetState extends State<JourneyPlanFormWidget> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController notesController = TextEditingController();
  int? selectedRouteId;
  List<RouteServices.RouteOption> _routeOptions = [];
  bool _isLoadingRoutes = false;
  bool _isCreating = false;

  late final DatabaseService _db;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService.instance;
    _initializeRoutes();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      final currentUser = await _db.getCurrentUserDetails();
      final userRouteId = currentUser['routeId'];

      final routeOptions = await RouteServices.RouteService
          .getCachedRouteOptionsForCurrentUser();

      print(
          '📍 Fetched ${routeOptions.length} cached route options for current user');

      if (mounted) {
        setState(() {
          _routeOptions = routeOptions;
          if (userRouteId != null) {
            final userRoute = routeOptions.firstWhere(
              (route) => route.id == userRouteId,
              orElse: () => routeOptions.isNotEmpty
                  ? routeOptions.first
                  : routeOptions.first,
            );
            selectedRouteId = userRoute.id;
          } else if (routeOptions.isNotEmpty) {
            selectedRouteId = routeOptions.first.id;
          }
        });
      }
    } catch (e) {
      print('❌ Error loading routes: $e');
      try {
        final currentUser = await _db.getCurrentUserDetails();
        final routeId = currentUser['routeId'];

        if (routeId != null && mounted) {
          setState(() {
            selectedRouteId = routeId;
          });
        }
      } catch (fallbackError) {
        print('❌ Error in fallback route loading: $fallbackError');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _createJourneyPlan() async {
    if (selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a route'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final currentUser = await _db.getCurrentUserDetails();
      final userId = currentUser['id'];
      final routeId = selectedRouteId ?? currentUser['routeId'];

      print(
          '🚀 Creating journey plan for client ${widget.selectedClient.name}');

      final journeyPlan = await JourneyPlanService.createJourneyPlan(
        clientId: widget.selectedClient.id,
        userId: userId,
        routeId: routeId,
        date: selectedDate,
        time: TimeOfDay.now().format(context),
      );

      if (journeyPlan != null) {
        widget.onSuccess(journeyPlan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                      'Journey plan created for ${widget.selectedClient.name}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error creating journey plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create journey plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Journey Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onCancel,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            _buildClientInfoCard(),
            const SizedBox(height: 24),

            // Date Selection
            _buildDateSelection(),
            const SizedBox(height: 24),

            // Route Selection
            _buildRouteSelection(),
            const SizedBox(height: 24),

            // Notes
            _buildNotesField(),
            const SizedBox(height: 32),

            // Create Button
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.store,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedClient.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedClient.address,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.selectedClient.contact?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.selectedClient.contact!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visit Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingRoutes
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : DropdownButtonFormField<int>(
                  value: selectedRouteId,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Select a route',
                  ),
                  items: _routeOptions.map((route) {
                    return DropdownMenuItem(
                      value: route.id,
                      child: Text(route.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRouteId = value;
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about this visit...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createJourneyPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCreating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Creating...'),
                ],
              )
            : const Text(
                'Create Journey Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
