/// Date range model
class DateRange {
  final String startDate;
  final String endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// Get parsed start date
  DateTime get parsedStartDate => DateTime.parse(startDate);

  /// Get parsed end date
  DateTime get parsedEndDate => DateTime.parse(endDate);

  /// Get duration in days
  int get durationInDays =>
      parsedEndDate.difference(parsedStartDate).inDays + 1;

  /// Get display text for date range
  String get displayText {
    final start = parsedStartDate;
    final end = parsedEndDate;

    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day} ${_getMonthName(start.month)} ${start.year}';
    } else if (start.year == end.year) {
      return '${start.day} ${_getMonthName(start.month)} - ${end.day} ${_getMonthName(end.month)} ${start.year}';
    } else {
      return '${start.day} ${_getMonthName(start.month)} ${start.year} - ${end.day} ${_getMonthName(end.month)} ${end.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  DateRange copyWith({
    String? startDate,
    String? endDate,
  }) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
