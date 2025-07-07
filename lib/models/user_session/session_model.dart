class Session {
  final int id;
  final int userId;
  final DateTime? sessionStart;
  final DateTime? sessionEnd;
  final DateTime loginAt;
  final DateTime? logoutAt;
  final String timezone;
  final DateTime? shiftStart;
  final DateTime? shiftEnd;
  final bool isLate;
  final bool? isEarly;
  final String? duration;
  final String status;

  Session({
    required this.id,
    required this.userId,
    this.sessionStart,
    this.sessionEnd,
    required this.loginAt,
    this.logoutAt,
    required this.timezone,
    this.shiftStart,
    this.shiftEnd,
    required this.isLate,
    this.isEarly,
    this.duration,
    required this.status,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      userId: json['userId'] as int,
      sessionStart: json['sessionStart'] != null
          ? DateTime.parse(json['sessionStart'] as String)
          : null,
      sessionEnd: json['sessionEnd'] != null
          ? DateTime.parse(json['sessionEnd'] as String)
          : null,
      loginAt: DateTime.parse(json['loginAt'] as String),
      logoutAt: json['logoutAt'] != null
          ? DateTime.parse(json['logoutAt'] as String)
          : null,
      timezone: json['timezone'] as String,
      shiftStart: json['shiftStart'] != null
          ? DateTime.parse(json['shiftStart'] as String)
          : null,
      shiftEnd: json['shiftEnd'] != null
          ? DateTime.parse(json['shiftEnd'] as String)
          : null,
      isLate: json['isLate'] as bool,
      isEarly: json['isEarly'] as bool?,
      duration: json['duration']?.toString(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionStart': sessionStart?.toIso8601String(),
      'sessionEnd': sessionEnd?.toIso8601String(),
      'loginAt': loginAt.toIso8601String(),
      'logoutAt': logoutAt?.toIso8601String(),
      'timezone': timezone,
      'shiftStart': shiftStart?.toIso8601String(),
      'shiftEnd': shiftEnd?.toIso8601String(),
      'isLate': isLate,
      'isEarly': isEarly,
      'duration': duration,
      'status': status,
    };
  }

  String get formattedDuration {
    if (duration == null) return 'N/A';

    // Handle negative durations (like "-2h 36m")
    if (duration!.startsWith('-')) {
      return duration!;
    }

    // Format raw minutes if needed (assuming duration might come as raw number)
    try {
      final minutes = int.tryParse(duration!);
      if (minutes != null) {
        final hours = (minutes / 60).floor();
        final mins = minutes % 60;
        return '${hours}h ${mins}m';
      }
    } catch (_) {}

    // If duration is already in a string format, try to parse it
    try {
      // Handle formats like "8h 30m" or "8:30"
      final parts = duration!.toLowerCase().split(RegExp(r'[h\s:]'));
      if (parts.length >= 2) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        return '${hours}h ${minutes}m';
      }
    } catch (_) {}

    return duration!;
  }

  String get formattedStatus {
    switch (status) {
      case '0':
        return 'Inactive';
      case '1':
        return 'Active';
      case 'LATE':
        return 'Late';
      case 'EARLY':
        return 'Early';
      case 'ON_TIME':
        return 'On Time';
      default:
        return isLate
            ? 'Late'
            : (isEarly ?? false)
                ? 'Early'
                : 'On Time';
    }
  }

  // Helper to get local login time (prefer sessionStart if available)
  String get displayLoginTime {
    if (sessionStart != null) {
      return sessionStart!
          .toLocal()
          .toString()
          .substring(0, 19)
          .replaceFirst('T', ' ');
    }
    return loginAt.toLocal().toString().substring(0, 19).replaceFirst('T', ' ');
  }

  // Helper to get local logout time (prefer sessionEnd if available)
  String? get displayLogoutTime {
    if (sessionEnd != null) {
      return sessionEnd!
          .toLocal()
          .toString()
          .substring(0, 19)
          .replaceFirst('T', ' ');
    }
    return logoutAt
        ?.toLocal()
        .toString()
        .substring(0, 19)
        .replaceFirst('T', ' ');
  }

  /// Check if session is active (status = '1' AND no sessionEnd)
  /// A session is active only if it has status '1' and no end time
  bool get isActive => status == '1' && sessionEnd == null;

  /// Check if session is complete (has both start and end times)
  /// A complete session has both sessionStart and sessionEnd set
  bool get isComplete => sessionStart != null && sessionEnd != null;

  /// Get shift start time formatted for display
  String? get displayShiftStartTime {
    if (shiftStart != null) {
      return shiftStart!.toLocal().toString().substring(11, 16); // HH:MM format
    }
    return null;
  }

  /// Get shift end time formatted for display
  String? get displayShiftEndTime {
    if (shiftEnd != null) {
      return shiftEnd!.toLocal().toString().substring(11, 16); // HH:MM format
    }
    return null;
  }

  /// Get shift hours display string
  String get shiftHoursDisplay {
    final start = displayShiftStartTime ?? '9:00';
    final end = displayShiftEndTime ?? '18:00';
    return '$start - $end';
  }

  /// Get session timing status (Early/On Time/Late)
  String get timingStatus {
    if (isEarly ?? false) return 'Early';
    if (isLate) return 'Late';
    return 'On Time';
  }
}
