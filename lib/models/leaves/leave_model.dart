import 'package:woosh/models/salerep/sales_rep_model.dart';

enum LeaveStatus { PENDING, APPROVED, REJECTED }

enum EmployeeType { STAFF, SALES_REP }

class LeaveType {
  final int id;
  final String name;
  final double? maxDaysPerYear;
  final bool accrues;
  final double monthlyAccrual;
  final bool requiresAttachment;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveType({
    required this.id,
    required this.name,
    this.maxDaysPerYear,
    required this.accrues,
    required this.monthlyAccrual,
    required this.requiresAttachment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveType.fromMap(Map<String, dynamic> map) {
    return LeaveType(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      maxDaysPerYear: map['max_days_per_year']?.toDouble(),
      accrues: map['accrues'] == 1,
      monthlyAccrual: (map['monthly_accrual'] ?? 0).toDouble(),
      requiresAttachment: map['requires_attachment'] == 1,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'max_days_per_year': maxDaysPerYear,
      'accrues': accrues ? 1 : 0,
      'monthly_accrual': monthlyAccrual,
      'requires_attachment': requiresAttachment ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

class LeaveRequest {
  final int? id;
  final EmployeeType employeeType;
  final int employeeId;
  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHalfDay;
  final String? reason;
  final LeaveStatus status;
  final int? approvedBy;
  final String? attachmentUrl;
  final DateTime appliedAt;
  final DateTime updatedAt;
  final LeaveType? leaveType;
  final SalesRepModel? employee;

  LeaveRequest({
    this.id,
    required this.employeeType,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.isHalfDay = false,
    this.reason,
    this.status = LeaveStatus.PENDING,
    this.approvedBy,
    this.attachmentUrl,
    required this.appliedAt,
    required this.updatedAt,
    this.leaveType,
    this.employee,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'],
      employeeType: _parseEmployeeType(map['employee_type_id']),
      employeeId: map['employee_id'] ?? 0,
      leaveTypeId: map['leave_type_id'] ?? 0,
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
      isHalfDay: map['is_half_day'] == 1,
      reason: map['reason'],
      status: _parseStatus(map['status']),
      approvedBy: map['approved_by'],
      attachmentUrl: map['attachment_url'],
      appliedAt: _parseDateTime(map['applied_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      leaveType: map['leaveType'] != null 
          ? LeaveType.fromMap(map['leaveType']) 
          : null,
      employee: map['employee'] != null 
          ? SalesRepModel.fromMap(map['employee']) 
          : null,

    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employee_type_id': _employeeTypeToId(employeeType),
      'employee_id': employeeId,
      'leave_type_id': leaveTypeId,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'is_half_day': isHalfDay ? 1 : 0,
      if (reason != null) 'reason': reason,
      'status': _statusToString(status),
      if (approvedBy != null) 'approved_by': approvedBy,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      'applied_at': appliedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get the duration of leave in days
  double get durationInDays {
    final days = endDate.difference(startDate).inDays + 1;
    return isHalfDay ? days * 0.5 : days.toDouble();
  }

  // Check if leave dates overlap with another leave
  bool overlaps(LeaveRequest other) {
    return (startDate.isBefore(other.endDate) ||
            startDate.isAtSameMomentAs(other.endDate)) &&
        (endDate.isAfter(other.startDate) ||
            endDate.isAtSameMomentAs(other.startDate));
  }

  // Check if leave is pending approval
  bool get isPending => status == LeaveStatus.PENDING;

  // Check if leave is approved
  bool get isApproved => status == LeaveStatus.APPROVED;

  // Check if leave is rejected
  bool get isRejected => status == LeaveStatus.REJECTED;

  // Create a copy of the leave with some fields updated
  LeaveRequest copyWith({
    int? id,
    EmployeeType? employeeType,
    int? employeeId,
    int? leaveTypeId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isHalfDay,
    String? reason,
    LeaveStatus? status,
    int? approvedBy,
    String? attachmentUrl,
    DateTime? appliedAt,
    DateTime? updatedAt,
    LeaveType? leaveType,
    SalesRepModel? employee,
 
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeType: employeeType ?? this.employeeType,
      employeeId: employeeId ?? this.employeeId,
      leaveTypeId: leaveTypeId ?? this.leaveTypeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isHalfDay: isHalfDay ?? this.isHalfDay,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      leaveType: leaveType ?? this.leaveType,
      employee: employee ?? this.employee,
    );
  }

  static EmployeeType _parseEmployeeType(dynamic value) {
    if (value == 1) return EmployeeType.STAFF;
    if (value == 2) return EmployeeType.SALES_REP;
    return EmployeeType.STAFF; // default
  }

  static int _employeeTypeToId(EmployeeType type) {
    switch (type) {
      case EmployeeType.STAFF:
        return 1;
      case EmployeeType.SALES_REP:
        return 2;
    }
  }

  static LeaveStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return LeaveStatus.APPROVED;
      case 'REJECTED':
        return LeaveStatus.REJECTED;
      case 'PENDING':
      default:
        return LeaveStatus.PENDING;
    }
  }

  static String _statusToString(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.APPROVED:
        return 'approved';
      case LeaveStatus.REJECTED:
        return 'rejected';
      case LeaveStatus.PENDING:
        return 'pending';
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'LeaveRequest{id: $id, leaveTypeId: $leaveTypeId, status: $status, startDate: $startDate, endDate: $endDate}';
  }
}

class LeaveBalance {
  final int? id;
  final EmployeeType employeeType;
  final int employeeId;
  final int leaveTypeId;
  final int year;
  final double accrued;
  final double used;
  final double carriedForward;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LeaveType? leaveType;

  LeaveBalance({
    this.id,
    required this.employeeType,
    required this.employeeId,
    required this.leaveTypeId,
    required this.year,
    required this.accrued,
    required this.used,
    required this.carriedForward,
    required this.createdAt,
    required this.updatedAt,
    this.leaveType,
  });

  factory LeaveBalance.fromMap(Map<String, dynamic> map) {
    return LeaveBalance(
      id: map['id'],
      employeeType: LeaveRequest._parseEmployeeType(map['employee_type_id']),
      employeeId: map['employee_id'] ?? 0,
      leaveTypeId: map['leave_type_id'] ?? 0,
      year: map['year'] ?? DateTime.now().year,
      accrued: (map['accrued'] ?? 0).toDouble(),
      used: (map['used'] ?? 0).toDouble(),
      carriedForward: (map['carried_forward'] ?? 0).toDouble(),
      createdAt: LeaveRequest._parseDateTime(map['createdAt']),
      updatedAt: LeaveRequest._parseDateTime(map['updatedAt']),
      leaveType: map['leaveType'] != null 
          ? LeaveType.fromMap(map['leaveType']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employee_type_id': LeaveRequest._employeeTypeToId(employeeType),
      'employee_id': employeeId,
      'leave_type_id': leaveTypeId,
      'year': year,
      'accrued': accrued,
      'used': used,
      'carried_forward': carriedForward,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Get available leave balance
  double get available => accrued + carriedForward - used;

  // Check if there's sufficient balance for a given duration
  bool hasSufficientBalance(double duration) {
    return available >= duration;
  }

  // Get balance percentage used
  double get usagePercentage {
    final total = accrued + carriedForward;
    return total > 0 ? (used / total) * 100 : 0;
  }

  @override
  String toString() {
    return 'LeaveBalance{employeeId: $employeeId, leaveTypeId: $leaveTypeId, year: $year, available: $available}';
  }
}

// Legacy class for backward compatibility
class Leave extends LeaveRequest {
  Leave({
    int? id,
    required int userId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachment,
    LeaveStatus status = LeaveStatus.PENDING,
    required DateTime createdAt,
    required DateTime updatedAt,
    SalesRepModel? user,
  }) : super(
          id: id,
          employeeType: EmployeeType.SALES_REP,
          employeeId: userId,
          leaveTypeId: 1, // Default leave type
          startDate: startDate,
          endDate: endDate,
          reason: reason,
          attachmentUrl: attachment,
          status: status,
          appliedAt: createdAt,
          updatedAt: updatedAt,
          employee: user,
        );

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'],
      userId: json['userId'],
      leaveType: json['leaveType'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reason: json['reason'],
      attachment: json['attachment'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      user: json['user'] != null ? SalesRepModel.fromMap(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': employeeId,
      'leaveType': leaveType?.name ?? 'General',
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason ?? '',
      if (attachmentUrl != null) 'attachment': attachmentUrl,
      'status': status.toString().split('.').last,
      'createdAt': appliedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static LeaveStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return LeaveStatus.APPROVED;
      case 'REJECTED':
        return LeaveStatus.REJECTED;
      case 'PENDING':
      default:
        return LeaveStatus.PENDING;
    }
  }
}
