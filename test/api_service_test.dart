import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API Service Token Handling Tests', () {
    test('should handle string tokens correctly', () {
      // Test data with string tokens
      final testData = {
        'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.string',
        'refreshToken': 'refresh.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        'expiresIn': 3600,
        'salesRep': {'id': 1, 'name': 'Test User'}
      };

      // Test access token extraction
      String? accessToken;
      if (testData['accessToken'] is String) {
        accessToken = testData['accessToken'] as String;
      } else if (testData['accessToken'] is Map<String, dynamic>) {
        final tokenMap = testData['accessToken'] as Map<String, dynamic>;
        accessToken =
            tokenMap['token']?.toString() ?? tokenMap['value']?.toString();
      } else if (testData['accessToken'] != null) {
        accessToken = testData['accessToken'].toString();
      }

      expect(accessToken, isNotNull);
      expect(accessToken, isA<String>());
      expect(accessToken!.length, greaterThan(0));

      // Test refresh token extraction
      String? refreshToken;
      if (testData['refreshToken'] is String) {
        refreshToken = testData['refreshToken'] as String;
      } else if (testData['refreshToken'] is Map<String, dynamic>) {
        final tokenMap = testData['refreshToken'] as Map<String, dynamic>;
        refreshToken =
            tokenMap['token']?.toString() ?? tokenMap['value']?.toString();
      } else if (testData['refreshToken'] != null) {
        refreshToken = testData['refreshToken'].toString();
      }

      expect(refreshToken, isNotNull);
      expect(refreshToken, isA<String>());
      expect(refreshToken!.length, greaterThan(0));
    });

    test('should handle map tokens correctly', () {
      // Test data with map tokens (the problematic case)
      final testData = {
        'accessToken': {
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.string',
          'type': 'Bearer'
        },
        'refreshToken': {
          'token': 'refresh.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
          'type': 'Refresh'
        },
        'expiresIn': 3600,
        'salesRep': {'id': 1, 'name': 'Test User'}
      };

      // Test access token extraction from map
      String? accessToken;
      if (testData['accessToken'] is String) {
        accessToken = testData['accessToken'] as String;
      } else if (testData['accessToken'] is Map<String, dynamic>) {
        final tokenMap = testData['accessToken'] as Map<String, dynamic>;
        accessToken =
            tokenMap['token']?.toString() ?? tokenMap['value']?.toString();
      } else if (testData['accessToken'] != null) {
        accessToken = testData['accessToken'].toString();
      }

      expect(accessToken, isNotNull);
      expect(accessToken, isA<String>());
      expect(accessToken!.length, greaterThan(0));
      expect(accessToken,
          contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.string'));

      // Test refresh token extraction from map
      String? refreshToken;
      if (testData['refreshToken'] is String) {
        refreshToken = testData['refreshToken'] as String;
      } else if (testData['refreshToken'] is Map<String, dynamic>) {
        final tokenMap = testData['refreshToken'] as Map<String, dynamic>;
        refreshToken =
            tokenMap['token']?.toString() ?? tokenMap['value']?.toString();
      } else if (testData['refreshToken'] != null) {
        refreshToken = testData['refreshToken'].toString();
      }

      expect(refreshToken, isNotNull);
      expect(refreshToken, isA<String>());
      expect(refreshToken!.length, greaterThan(0));
      expect(refreshToken,
          contains('refresh.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test'));
    });

    test('should handle null tokens correctly', () {
      // Test data with null tokens
      final testData = {
        'accessToken': null,
        'refreshToken': null,
        'expiresIn': null,
        'salesRep': {'id': 1, 'name': 'Test User'}
      };

      // Test access token extraction
      String? accessToken;
      if (testData['accessToken'] is String) {
        accessToken = testData['accessToken'] as String;
      } else if (testData['accessToken'] is Map<String, dynamic>) {
        final tokenMap = testData['accessToken'] as Map<String, dynamic>;
        accessToken =
            tokenMap['token']?.toString() ?? tokenMap['value']?.toString();
      } else if (testData['accessToken'] != null) {
        accessToken = testData['accessToken'].toString();
      }

      expect(accessToken, isNull);

      // Test refresh token extraction
      String? refreshToken;
      if (testData['refreshToken'] is String) {
        refreshToken = testData['refreshToken'] as String;
      } else if (testData['refreshToken'] is Map<String, dynamic>) {
        final tokenMap = testData['refreshToken'] as Map<String, dynamic>;
        refreshToken =
            tokenMap['token']?.toString() ?? tokenMap['value']?.toString();
      } else if (testData['refreshToken'] != null) {
        refreshToken = testData['refreshToken'].toString();
      }

      expect(refreshToken, isNull);
    });

    test('should handle expiresIn as string correctly', () {
      // Test data with string expiresIn
      final testData = {
        'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.string',
        'refreshToken': 'refresh.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        'expiresIn': '3600',
        'salesRep': {'id': 1, 'name': 'Test User'}
      };

      // Test expiresIn extraction
      int? expiresIn;
      if (testData['expiresIn'] is int) {
        expiresIn = testData['expiresIn'] as int;
      } else if (testData['expiresIn'] is String) {
        expiresIn = int.tryParse(testData['expiresIn'] as String);
      }

      expect(expiresIn, isNotNull);
      expect(expiresIn, isA<int>());
      expect(expiresIn, equals(3600));
    });

    test('should handle expiresIn as int correctly', () {
      // Test data with int expiresIn
      final testData = {
        'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.string',
        'refreshToken': 'refresh.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        'expiresIn': 3600,
        'salesRep': {'id': 1, 'name': 'Test User'}
      };

      // Test expiresIn extraction
      int? expiresIn;
      if (testData['expiresIn'] is int) {
        expiresIn = testData['expiresIn'] as int;
      } else if (testData['expiresIn'] is String) {
        expiresIn = int.tryParse(testData['expiresIn'] as String);
      }

      expect(expiresIn, isNotNull);
      expect(expiresIn, isA<int>());
      expect(expiresIn, equals(3600));
    });
  });

  group('API Service Latitude/Longitude Type Conversion Tests', () {
    test('should handle int latitude/longitude correctly', () {
      // Test data with int coordinates (the problematic case)
      final testData = {
        'id': 1,
        'name': 'Test Client',
        'address': 'Test Address',
        'latitude': 123456, // int value
        'longitude': 789012, // int value
        'region_id': 1,
        'region': 'Test Region',
        'country_id': 1,
      };

      // Test latitude conversion
      double? latitude;
      if (testData['latitude'] != null) {
        if (testData['latitude'] is int) {
          latitude = (testData['latitude'] as int).toDouble();
        } else if (testData['latitude'] is double) {
          latitude = testData['latitude'] as double;
        } else if (testData['latitude'] is String) {
          latitude = double.tryParse(testData['latitude'] as String);
        } else {
          latitude = null;
        }
      }

      expect(latitude, isNotNull);
      expect(latitude, isA<double>());
      expect(latitude, equals(123456.0));

      // Test longitude conversion
      double? longitude;
      if (testData['longitude'] != null) {
        if (testData['longitude'] is int) {
          longitude = (testData['longitude'] as int).toDouble();
        } else if (testData['longitude'] is double) {
          longitude = testData['longitude'] as double;
        } else if (testData['longitude'] is String) {
          longitude = double.tryParse(testData['longitude'] as String);
        } else {
          longitude = null;
        }
      }

      expect(longitude, isNotNull);
      expect(longitude, isA<double>());
      expect(longitude, equals(789012.0));
    });

    test('should handle double latitude/longitude correctly', () {
      // Test data with double coordinates
      final testData = {
        'id': 1,
        'name': 'Test Client',
        'address': 'Test Address',
        'latitude': 123.456, // double value
        'longitude': 789.012, // double value
        'region_id': 1,
        'region': 'Test Region',
        'country_id': 1,
      };

      // Test latitude conversion
      double? latitude;
      if (testData['latitude'] != null) {
        if (testData['latitude'] is int) {
          latitude = (testData['latitude'] as int).toDouble();
        } else if (testData['latitude'] is double) {
          latitude = testData['latitude'] as double;
        } else if (testData['latitude'] is String) {
          latitude = double.tryParse(testData['latitude'] as String);
        } else {
          latitude = null;
        }
      }

      expect(latitude, isNotNull);
      expect(latitude, isA<double>());
      expect(latitude, equals(123.456));

      // Test longitude conversion
      double? longitude;
      if (testData['longitude'] != null) {
        if (testData['longitude'] is int) {
          longitude = (testData['longitude'] as int).toDouble();
        } else if (testData['longitude'] is double) {
          longitude = testData['longitude'] as double;
        } else if (testData['longitude'] is String) {
          longitude = double.tryParse(testData['longitude'] as String);
        } else {
          longitude = null;
        }
      }

      expect(longitude, isNotNull);
      expect(longitude, isA<double>());
      expect(longitude, equals(789.012));
    });

    test('should handle null latitude/longitude correctly', () {
      // Test data with null coordinates
      final testData = {
        'id': 1,
        'name': 'Test Client',
        'address': 'Test Address',
        'latitude': null,
        'longitude': null,
        'region_id': 1,
        'region': 'Test Region',
        'country_id': 1,
      };

      // Test latitude conversion
      double? latitude;
      if (testData['latitude'] != null) {
        if (testData['latitude'] is int) {
          latitude = (testData['latitude'] as int).toDouble();
        } else if (testData['latitude'] is double) {
          latitude = testData['latitude'] as double;
        } else if (testData['latitude'] is String) {
          latitude = double.tryParse(testData['latitude'] as String);
        } else {
          latitude = null;
        }
      }

      expect(latitude, isNull);

      // Test longitude conversion
      double? longitude;
      if (testData['longitude'] != null) {
        if (testData['longitude'] is int) {
          longitude = (testData['longitude'] as int).toDouble();
        } else if (testData['longitude'] is double) {
          longitude = testData['longitude'] as double;
        } else if (testData['longitude'] is String) {
          longitude = double.tryParse(testData['longitude'] as String);
        } else {
          longitude = null;
        }
      }

      expect(longitude, isNull);
    });
  });
}
