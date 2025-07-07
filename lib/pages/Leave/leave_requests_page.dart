import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/leaves/leave_model.dart';
import 'package:woosh/services/core/leave_service.dart';
import 'package:woosh/pages/Leave/leave_dashboard_page.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

class LeaveRequestsPage extends StatefulWidget {
  const LeaveRequestsPage({super.key});

  @override
  _LeaveRequestsPageState createState() => _LeaveRequestsPageState();
}

class _LeaveRequestsPageState extends State<LeaveRequestsPage> {
  List<LeaveRequest> _leaves = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user ID using the same method as other pages
      final box = GetStorage();

      // Try to get user ID directly first
      final userId = box.read('userId');
      int? staffId;

      if (userId != null) {
        staffId = userId is int ? userId : int.tryParse(userId.toString());
      } else {
        // Fallback: try to get from salesRep data
        final userData = box.read('salesRep');
        if (userData is Map<String, dynamic> && userData['id'] != null) {
          staffId = userData['id'] is int
              ? userData['id']
              : int.tryParse(userData['id'].toString());
        }
      }

      if (staffId == null || staffId == 0) {
        setState(() {
          _error = 'User not authenticated. Please login again.';
          _isLoading = false;
        });
        return;
      }

      if (staffId == 0) {
        setState(() {
          _error = 'Invalid user ID. Please login again.';
          _isLoading = false;
        });
        return;
      }


      final leaves = await LeaveService.getStaffLeaves(staffId);
      if (mounted) {
        setState(() {
          _leaves = leaves;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load leave requests: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLeaveItem(LeaveRequest leave, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(leave.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(leave.status),
            color: _getStatusColor(leave.status),
            size: 20,
          ),
        ),
        title: Text(
          leave.leaveType?.name ?? 'Unknown Type',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1810),
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(leave.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStatusText(leave.status),
                style: TextStyle(
                  color: _getStatusColor(leave.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM dd').format(leave.startDate)} - ${DateFormat('MMM dd, yyyy').format(leave.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (leave.isHalfDay) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'HALF DAY',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Applied: ${DateFormat('MMM dd, yyyy HH:mm').format(leave.appliedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (leave.status == LeaveStatus.APPROVED ||
                leave.status == LeaveStatus.REJECTED) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.update,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(leave.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (leave.attachmentUrl != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Attachment: ${leave.attachmentUrl!.split('/').last}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  IconData _getStatusIcon(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.PENDING:
        return Icons.schedule;
      case LeaveStatus.APPROVED:
        return Icons.check_circle;
      case LeaveStatus.REJECTED:
        return Icons.cancel;
    }
  }

  String _getStatusText(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.PENDING:
        return 'PENDING';
      case LeaveStatus.APPROVED:
        return 'APPROVED';
      case LeaveStatus.REJECTED:
        return 'REJECTED';
    }
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.PENDING:
        return Colors.orange;
      case LeaveStatus.APPROVED:
        return Colors.green;
      case LeaveStatus.REJECTED:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveDashboardPage(),
                ),
              );
            },
            tooltip: 'Leave Dashboard',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaves,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _leaves.isEmpty
                  ? const Center(
                      child: Text('No leave requests found'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeaves,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leaves.length,
                        itemBuilder: (context, index) {
                          final leave = _leaves[index];
                          return _buildLeaveItem(leave, index);
                        },
                      ),
                    ),
    );
  }
}
