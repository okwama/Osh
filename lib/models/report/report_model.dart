enum ReportType {
  productAvailability('PRODUCT_AVAILABILITY'),
  visibilityActivity('VISIBILITY_ACTIVITY'),
  productSample('PRODUCT_SAMPLE'),
  productReturn('PRODUCT_RETURN'),
  feedback('FEEDBACK');

  const ReportType(this.value);
  final String value;

  static ReportType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PRODUCT_AVAILABILITY':
        return ReportType.productAvailability;
      case 'VISIBILITY_ACTIVITY':
        return ReportType.visibilityActivity;
      case 'PRODUCT_SAMPLE':
        return ReportType.productSample;
      case 'PRODUCT_RETURN':
        return ReportType.productReturn;
      case 'FEEDBACK':
        return ReportType.feedback;
      default:
        return ReportType.feedback;
    }
  }
}

class ReportModel {
  final int id;
  final int? orderId;
  final int clientId;
  final DateTime createdAt;
  final int userId;
  final int? journeyPlanId;
  final ReportType type;

  ReportModel({
    required this.id,
    this.orderId,
    required this.clientId,
    required this.createdAt,
    required this.userId,
    this.journeyPlanId,
    required this.type,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? 0,
      orderId: map['orderId'],
      clientId: map['clientId'] ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      userId: map['userId'] ?? 0,
      journeyPlanId: map['journeyPlanId'],
      type: ReportType.fromString(map['type'] ?? 'FEEDBACK'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'clientId': clientId,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'journeyPlanId': journeyPlanId,
      'type': type.value,
    };
  }

  /// Get report type display text
  String get typeText {
    switch (type) {
      case ReportType.productAvailability:
        return 'Product Availability';
      case ReportType.visibilityActivity:
        return 'Visibility Activity';
      case ReportType.productSample:
        return 'Product Sample';
      case ReportType.productReturn:
        return 'Product Return';
      case ReportType.feedback:
        return 'Feedback';
    }
  }

  /// Create a copy with updated fields
  ReportModel copyWith({
    int? id,
    int? orderId,
    int? clientId,
    DateTime? createdAt,
    int? userId,
    int? journeyPlanId,
    ReportType? type,
  }) {
    return ReportModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      journeyPlanId: journeyPlanId ?? this.journeyPlanId,
      type: type ?? this.type,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle both ISO string and MySQL datetime formats
        if (value.contains('T')) {
          return DateTime.parse(value);
        } else {
          // MySQL datetime format: YYYY-MM-DD HH:MM:SS
          return DateTime.parse(value.replaceAll(' ', 'T'));
        }
      } catch (e) {
        print('Error parsing datetime: $value - $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, type: $typeText, clientId: $clientId, userId: $userId)';
  }
}
