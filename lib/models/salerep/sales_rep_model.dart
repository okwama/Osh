class SalesRepModel {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String password;
  final int countryId;
  final String country;
  final int regionId;
  final String region;
  final int routeId;
  final String route;
  final int routeIdUpdate;
  final String routeNameUpdate;
  final int visitsTargets;
  final int newClients;
  final int vapesTargets;
  final int pouchesTargets;
  final String role;
  final int managerType;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retailManager;
  final int keyChannelManager;
  final int distributionManager;
  final String photoUrl;
  final int? managerId;

  SalesRepModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.countryId,
    required this.country,
    required this.regionId,
    required this.region,
    required this.routeId,
    required this.route,
    required this.routeIdUpdate,
    required this.routeNameUpdate,
    required this.visitsTargets,
    required this.newClients,
    required this.vapesTargets,
    required this.pouchesTargets,
    required this.role,
    required this.managerType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.retailManager,
    required this.keyChannelManager,
    required this.distributionManager,
    required this.photoUrl,
    this.managerId,
  });

  factory SalesRepModel.fromMap(Map<String, dynamic> map) {
    return SalesRepModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      countryId: map['countryId']?.toInt() ?? 0,
      country: map['country']?.toString() ?? '',
      regionId: map['region_id']?.toInt() ?? 0,
      region: map['region']?.toString() ?? '',
      routeId: map['route_id']?.toInt() ?? 0,
      route: map['route']?.toString() ?? '',
      routeIdUpdate: map['route_id_update']?.toInt() ?? 0,
      routeNameUpdate: map['route_name_update']?.toString() ?? '',
      visitsTargets: map['visits_targets']?.toInt() ?? 0,
      newClients: map['new_clients']?.toInt() ?? 0,
      vapesTargets: map['vapes_targets']?.toInt() ?? 0,
      pouchesTargets: map['pouches_targets']?.toInt() ?? 0,
      role: map['role']?.toString() ?? 'USER',
      managerType: map['manager_type']?.toInt() ?? 0,
      status: map['status']?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      retailManager: map['retail_manager']?.toInt() ?? 0,
      keyChannelManager: map['key_channel_manager']?.toInt() ?? 0,
      distributionManager: map['distribution_manager']?.toInt() ?? 0,
      photoUrl: map['photoUrl']?.toString() ?? '',
      managerId: map['managerId']?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'countryId': countryId,
      'country': country,
      'region_id': regionId,
      'region': region,
      'route_id': routeId,
      'route': route,
      'route_id_update': routeIdUpdate,
      'route_name_update': routeNameUpdate,
      'visits_targets': visitsTargets,
      'new_clients': newClients,
      'vapes_targets': vapesTargets,
      'pouches_targets': pouchesTargets,
      'role': role,
      'manager_type': managerType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'retail_manager': retailManager,
      'key_channel_manager': keyChannelManager,
      'distribution_manager': distributionManager,
      'photoUrl': photoUrl,
      'managerId': managerId,
    };
  }

  SalesRepModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? password,
    int? countryId,
    String? country,
    int? regionId,
    String? region,
    int? routeId,
    String? route,
    int? routeIdUpdate,
    String? routeNameUpdate,
    int? visitsTargets,
    int? newClients,
    int? vapesTargets,
    int? pouchesTargets,
    String? role,
    int? managerType,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retailManager,
    int? keyChannelManager,
    int? distributionManager,
    String? photoUrl,
    int? managerId,
  }) {
    return SalesRepModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      countryId: countryId ?? this.countryId,
      country: country ?? this.country,
      regionId: regionId ?? this.regionId,
      region: region ?? this.region,
      routeId: routeId ?? this.routeId,
      route: route ?? this.route,
      routeIdUpdate: routeIdUpdate ?? this.routeIdUpdate,
      routeNameUpdate: routeNameUpdate ?? this.routeNameUpdate,
      visitsTargets: visitsTargets ?? this.visitsTargets,
      newClients: newClients ?? this.newClients,
      vapesTargets: vapesTargets ?? this.vapesTargets,
      pouchesTargets: pouchesTargets ?? this.pouchesTargets,
      role: role ?? this.role,
      managerType: managerType ?? this.managerType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retailManager: retailManager ?? this.retailManager,
      keyChannelManager: keyChannelManager ?? this.keyChannelManager,
      distributionManager: distributionManager ?? this.distributionManager,
      photoUrl: photoUrl ?? this.photoUrl,
      managerId: managerId ?? this.managerId,
    );
  }

  @override
  String toString() {
    return 'SalesRepModel(id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, countryId: $countryId, country: $country, regionId: $regionId, region: $region, routeId: $routeId, route: $route, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalesRepModel &&
        other.id == id &&
        other.email == email &&
        other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ phoneNumber.hashCode;
  }

  /// Check if the sales rep is active
  bool get isActive => status == 1;

  /// Check if the sales rep is a manager
  bool get isManager => role == 'MANAGER' || managerType > 0;

  /// Check if the sales rep is an admin
  bool get isAdmin => role == 'ADMIN';

  /// Get full name
  String get fullName => name;

  /// Get display name (first name only)
  String get displayName {
    final nameParts = name.split(' ');
    return nameParts.isNotEmpty ? nameParts.first : name;
  }

  /// Get initials for avatar
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Check if sales rep has photo
  bool get hasPhoto => photoUrl.isNotEmpty;

  /// Get manager type description
  String get managerTypeDescription {
    switch (managerType) {
      case 1:
        return 'Retail Manager';
      case 2:
        return 'Key Channel Manager';
      case 3:
        return 'Distribution Manager';
      default:
        return 'Sales Representative';
    }
  }

  /// Get status description
  String get statusDescription {
    switch (status) {
      case 0:
        return 'Inactive';
      case 1:
        return 'Active';
      case 2:
        return 'Suspended';
      default:
        return 'Unknown';
    }
  }

  /// Get role description
  String get roleDescription {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrator';
      case 'MANAGER':
        return 'Manager';
      case 'SUPERVISOR':
        return 'Supervisor';
      default:
        return 'Sales Representative';
    }
  }
}
