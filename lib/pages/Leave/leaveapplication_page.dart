import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:woosh/services/core/leave_service.dart';
import 'package:woosh/models/leaves/leave_model.dart';
import 'package:woosh/pages/Leave/leave_requests_page.dart';
import 'package:woosh/pages/Leave/leave_dashboard_page.dart';
import 'package:woosh/services/core/upload_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_storage/get_storage.dart';
import 'package:woosh/services/core/leave_balance_service.dart';

class LeaveApplicationPage extends StatefulWidget {
  const LeaveApplicationPage({super.key});

  @override
  _LeaveApplicationPageState createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  LeaveType? _selectedLeaveType;
  List<LeaveType> _leaveTypes = [];
  File? _attachedFile;
  bool _isLoading = false;
  bool _isLoadingTypes = true;
  String? _error;
  bool _isFileUploadSupported = !kIsWeb;
  bool _isHalfDay = false;
  Map<int, LeaveBalance> _leaveBalances = {};

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
    _loadLeaveBalances();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveTypes() async {
    try {
      setState(() {
        _isLoadingTypes = true;
        _error = null;
      });

      final leaveTypes = await LeaveService.getLeaveTypes();
      setState(() {
        _leaveTypes = leaveTypes;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leave types: $e';
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _loadLeaveBalances() async {
    try {
      final box = GetStorage();
      final userId = box.read('userId');
      int? staffId;

      if (userId != null) {
        staffId = userId is int ? userId : int.tryParse(userId.toString());
      } else {
        final userData = box.read('salesRep');
        if (userData is Map<String, dynamic> && userData['id'] != null) {
          staffId = userData['id'] is int
              ? userData['id']
              : int.tryParse(userData['id'].toString());
        }
      }

      if (staffId == null || staffId == 0) {
        print('⚠️ No valid user ID found for leave balances');
        return;
      }

      final balances = await LeaveBalanceService.getStaffLeaveBalances(
          staffId, DateTime.now().year);

      setState(() {
        _leaveBalances = {
          for (var balance in balances) balance.leaveTypeId: balance
        };
      });
    } catch (e) {
      print('Failed to load leave balances: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isStartDate) {
          _startDateController.text = formattedDate;
        } else {
          _endDateController.text = formattedDate;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    if (!_isFileUploadSupported) {
      setState(() {
        _error = 'File upload is not supported in this environment.';
      });
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: $e';
      });
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a leave type'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_selectedLeaveType!.requiresAttachment && _attachedFile == null) {
      if (!_isFileUploadSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Note: File attachment not available in this environment'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please attach a document for ${_selectedLeaveType!.name}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final box = GetStorage();
      final userId = box.read('userId');
      int? staffId;

      if (userId != null) {
        staffId = userId is int ? userId : int.tryParse(userId.toString());
      } else {
        final userData = box.read('salesRep');
        if (userData is Map<String, dynamic> && userData['id'] != null) {
          staffId = userData['id'] is int
              ? userData['id']
              : int.tryParse(userData['id'].toString());
        }
      }

      if (staffId == null || staffId == 0) {
        throw Exception('User not authenticated. Please login again.');
      }

      String? cloudinaryUrl;
      if (_attachedFile != null && !kIsWeb) {
        try {
          print('📤 Uploading document to Cloudinary...');
          final uploadResult = await UploadService.uploadImage(_attachedFile!);
          cloudinaryUrl = uploadResult['url'];
          print('✅ Document uploaded successfully: $cloudinaryUrl');
        } catch (e) {
          print('❌ Failed to upload document: $e');
        }
      }

      final leave = LeaveRequest(
        employeeType: EmployeeType.SALES_REP,
        employeeId: staffId,
        leaveTypeId: _selectedLeaveType!.id,
        startDate: DateTime.parse(_startDateController.text),
        endDate: DateTime.parse(_endDateController.text),
        isHalfDay: _isHalfDay,
        reason: _reasonController.text,
        status: LeaveStatus.PENDING,
        attachmentUrl: cloudinaryUrl ?? _attachedFile?.path,
        appliedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        leaveType: _selectedLeaveType,
      );

      final success = await LeaveService.createLeaveApplication(leave);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Leave application submitted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Get.back(result: true);
      } else {
        throw Exception('Failed to submit leave application');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to submit leave application: $e';
        _isLoading = false;
      });
    }
  }

  IconData _getLeaveTypeIcon(String leaveTypeName) {
    switch (leaveTypeName.toLowerCase()) {
      case 'annual':
      case 'vacation':
        return Icons.beach_access;
      case 'sick':
      case 'medical':
        return Icons.local_hospital;
      case 'maternity':
      case 'paternity':
        return Icons.child_care;
      case 'emergency':
        return Icons.emergency;
      case 'compassionate':
        return Icons.favorite;
      default:
        return Icons.event_note;
    }
  }

  Color _getLeaveTypeColor(String leaveTypeName) {
    switch (leaveTypeName.toLowerCase()) {
      case 'annual':
      case 'vacation':
        return Colors.blue;
      case 'sick':
      case 'medical':
        return Colors.red;
      case 'maternity':
      case 'paternity':
        return Colors.pink;
      case 'emergency':
        return Colors.orange;
      case 'compassionate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCompactLeaveBalanceCard() {
    if (_selectedLeaveType == null) return const SizedBox.shrink();

    final balance = _leaveBalances[_selectedLeaveType!.id];
    if (balance == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No balance information available',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    // Use the actual accrued balance from database instead of maxDaysPerYear
    final totalEntitlement = balance.accrued + balance.carriedForward;
    final availableDays = totalEntitlement - balance.used;
    final usagePercentage =
        totalEntitlement > 0 ? balance.used / totalEntitlement : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            availableDays > 0 ? Colors.green.shade50 : Colors.red.shade50,
            availableDays > 0 ? Colors.green.shade100 : Colors.red.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              availableDays > 0 ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: availableDays > 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Available Days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: availableDays > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: availableDays > 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${availableDays.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(
                  'Total', totalEntitlement.toString(), Colors.blue),
              _buildBalanceItem('Used', balance.used.toString(), Colors.orange),
              if (balance.carriedForward > 0)
                _buildBalanceItem(
                    'Carried', balance.carriedForward.toString(), Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usagePercentage.toDouble(),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercentage > 0.8 ? Colors.red : Colors.green,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 11,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Leave Type Selection
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<LeaveType>(
            value: _selectedLeaveType,
            decoration: const InputDecoration(
              labelText: 'Leave Type',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _leaveTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getLeaveTypeColor(type.name).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _getLeaveTypeIcon(type.name),
                        size: 16,
                        color: _getLeaveTypeColor(type.name),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(type.name,
                            style: const TextStyle(fontSize: 14))),
                    if (type.requiresAttachment) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(Icons.attach_file,
                            size: 12, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Please select a leave type' : null,
            onChanged: (value) {
              setState(() {
                _selectedLeaveType = value;
              });
            },
          ),
        ),

        // Leave Balance Display
        _buildCompactLeaveBalanceCard(),

        // Date Selection Row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, true),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, false),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Half Day Option
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: _isHalfDay,
                    onChanged: (value) {
                      setState(() {
                        _isHalfDay = value ?? false;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Half Day Leave',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        // Reason Field
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: 'Reason for Leave',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 2,
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter a reason' : null,
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 12),

        // File Attachment Section
        if (_selectedLeaveType?.requiresAttachment == true) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    const Text(
                      'Document Required',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_attachedFile != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _attachedFile!.path.split('/').last,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.green),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Select File',
                          style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Leave Application',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const LeaveDashboardPage()),
              );
            },
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: _isLoading || _isLoadingTypes
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Warning banner for web
                if (!_isFileUploadSupported)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.amber.shade100,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'File upload not supported on web platform',
                            style:
                                TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error message
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Form(
                      key: _formKey,
                      child: _buildCompactForm(),
                    ),
                  ),
                ),

                // Bottom action buttons
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LeaveRequestsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.list_alt, size: 18),
                            label: const Text('View Requests'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _submitLeaveApplication,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send, size: 18),
                            label: Text(_isLoading
                                ? 'Submitting...'
                                : 'Submit Application'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

