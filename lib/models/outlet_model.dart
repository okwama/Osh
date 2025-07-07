class Outlet {
  final int id;
  final String name;
  final String address;
  final String? balance;
  final double? latitude;
  final double? longitude;
  final String? email;
  final String? contact;
  final String? taxPin;
  final String? location;
  final int? clientType;
  final int? regionId;
  final String? region;
  final int? countryId;
  final DateTime? createdAt;

  Outlet({
    required this.id,
    required this.name,
    required this.address,
    this.balance,
    this.latitude,
    this.longitude,
    this.email,
    this.contact,
    this.taxPin,
    this.location,
    this.clientType,
    this.regionId,
    this.region,
    this.countryId,
    this.createdAt,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    // Debug logging
    print('Outlet.fromJson - Raw JSON: $json');

    // Safe parsing helper functions
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        try {
          // Handle decimal strings by converting to double first, then to int
          if (value.contains('.')) {
            final doubleValue = double.tryParse(value);
            return doubleValue?.toInt();
          }
          return int.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Outlet(
      id: parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      balance: json['balance']?.toString(),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      email: json['email']?.toString(),
      contact: json['contact']?.toString(),
      taxPin: json['tax_pin']?.toString(),
      location: json['location']?.toString(),
      clientType: parseInt(json['client_type']),
      regionId: parseInt(json['region_id']),
      region: json['region']?.toString(),
      countryId:
          json['country'] != null ? parseInt(json['country']['id']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (balance != null) 'balance': balance,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (email != null) 'email': email,
      if (contact != null) 'contact': contact,
      if (taxPin != null) 'tax_pin': taxPin,
      if (location != null) 'location': location,
      if (clientType != null) 'client_type': clientType,
      if (regionId != null) 'region_id': regionId,
      if (region != null) 'region': region,
      if (countryId != null) 'country': {'id': countryId},
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Outlet copyWith({
    int? id,
    String? name,
    String? address,
    String? balance,
    double? latitude,
    double? longitude,
    String? email,
    String? contact,
    String? taxPin,
    String? location,
    int? clientType,
    int? regionId,
    String? region,
    int? countryId,
    DateTime? createdAt,
  }) {
    return Outlet(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      taxPin: taxPin ?? this.taxPin,
      location: location ?? this.location,
      clientType: clientType ?? this.clientType,
      regionId: regionId ?? this.regionId,
      region: region ?? this.region,
      countryId: countryId ?? this.countryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
