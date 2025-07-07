class VisibilityReport {
  final int reportId;
  final String? comment;
  final String? imageUrl;
  final DateTime createdAt;

  VisibilityReport({
    required this.reportId,
    this.comment,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'comment': comment,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VisibilityReport.fromJson(dynamic jsonData) {
    print(
        'VisibilityReport.fromJson input: $jsonData (${jsonData.runtimeType})');

    // Convert dynamic Map to Map<String, dynamic>
    final map = Map<String, dynamic>.from(jsonData);

    return VisibilityReport(
      reportId: map['reportId'],
      comment: map['comment'],
      imageUrl: map['imageUrl'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}
