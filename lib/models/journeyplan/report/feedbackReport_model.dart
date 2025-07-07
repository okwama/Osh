class FeedbackReport {
  final int reportId;
  final String? comment;
  final DateTime createdAt;

  FeedbackReport({
    required this.reportId,
    this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackReport.fromJson(dynamic jsonData) {

    // Convert dynamic Map to Map<String, dynamic>
    final map = Map<String, dynamic>.from(jsonData);

    return FeedbackReport(
      reportId: map['reportId'],
      comment: map['comment'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}