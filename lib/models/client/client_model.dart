class Client {
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
  final int regionId;
  final String region;
  final int countryId;
  final DateTime? createdAt;
  final int? addedBy;

  Client({
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
    required this.regionId,
    required this.region,
    required this.countryId,
    this.createdAt,
    this.addedBy,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    // Debug logging

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

    // Debug logging for each field
    final id = parseInt(json['id']) ?? 0;
    final latitude = parseDouble(json['latitude']);
    final longitude = parseDouble(json['longitude']);
    final clientType = parseInt(json['client_type']);
    final regionId = parseInt(json['region_id']) ?? 0;
    final countryId = parseInt(json['countryId']);
    final addedBy = parseInt(json['added_by']);

    print(
        'Client parsing - client_type: ${json['client_type']} -> $clientType');

    return Client(
      id: id,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      balance: json['balance']?.toString(),
      latitude: latitude,
      longitude: longitude,
      email: json['email']?.toString(),
      contact: json['contact']?.toString(),
      taxPin: json['tax_pin']?.toString(),
      location: json['location']?.toString(),
      clientType: clientType,
      regionId: regionId,
      region: json['region']?.toString() ?? '',
      countryId: countryId ?? 0,
      addedBy: addedBy,
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
      'region_id': regionId,
      'region': region,
      'countryId': countryId,
      if (addedBy != null) 'added_by': addedBy,
    };
  }

  Client copyWith({
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
    int? addedBy,
  }) {
    return Client(
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
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
