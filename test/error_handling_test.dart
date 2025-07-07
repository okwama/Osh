import 'package:flutter_test/flutter_test.dart';
import 'package:woosh/utils/error_handler.dart';

void main() {
  group('Error Handling Tests', () {
    test('Server errors (5xx) should return user-friendly messages', () {
      final testCases = [
        'HTTP 500: Internal Server Error',
        'Error 501: Not Implemented',
        '502 Bad Gateway',
        'Service Unavailable (503)',
        '504 Gateway Timeout',
        'Exception: 500 Internal Server Error with stack trace',
      ];

      for (final error in testCases) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Should NOT contain raw error codes or technical details
        expect(result.contains('500'), false,
            reason: 'Should not contain raw 500 error');
        expect(result.contains('501'), false,
            reason: 'Should not contain raw 501 error');
        expect(result.contains('502'), false,
            reason: 'Should not contain raw 502 error');
        expect(result.contains('503'), false,
            reason: 'Should not contain raw 503 error');
        expect(result.contains('504'), false,
            reason: 'Should not contain raw 504 error');
        expect(result.contains('Internal Server Error'), false,
            reason: 'Should not contain technical terms');
        expect(result.contains('Bad Gateway'), false,
            reason: 'Should not contain technical terms');

        // Should contain user-friendly message
        expect(
            result,
            equals(
                'Our servers are temporarily unavailable. Please try again later.'));
      }
    });

    test('Client errors (4xx) should return appropriate user-friendly messages',
        () {
      final testCases = {
        'HTTP 401: Unauthorized':
            'Your session has expired. Please log in again.',
        '403 Forbidden': 'You don\'t have permission to perform this action.',
        'Error 404: Not Found': 'The requested information could not be found.',
        '429 Too Many Requests':
            'Too many requests. Please wait a moment and try again.',
        '400 Bad Request':
            'There was an issue with your request. Please try again.',
      };

      testCases.forEach((error, expectedMessage) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Should NOT contain raw error codes
        expect(result.contains('401'), false);
        expect(result.contains('403'), false);
        expect(result.contains('404'), false);
        expect(result.contains('429'), false);
        expect(result.contains('400'), false);

        // Should contain expected user-friendly message
        expect(result, equals(expectedMessage));
      });
    });

    test('Network errors should return connection-related messages', () {
      final testCases = [
        'SocketException: Failed to connect',
        'Connection timeout',
        'XMLHttpRequest error',
        'Network error',
        'Connection refused',
        'ClientException: Connection failed',
      ];

      for (final error in testCases) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Should NOT contain technical terms
        expect(result.contains('SocketException'), false);
        expect(result.contains('XMLHttpRequest'), false);
        expect(result.contains('ClientException'), false);

        // Should contain user-friendly message
        expect(result,
            equals('Please check your internet connection and try again.'));
      }
    });

    test('Timeout errors should return timeout-related messages', () {
      final testCases = [
        'TimeoutException: Request timeout',
        'Operation timed out',
        'timeout after 30 seconds',
      ];

      for (final error in testCases) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Should NOT contain technical terms
        expect(result.contains('TimeoutException'), false);

        // Should contain user-friendly message
        expect(result,
            equals('The request is taking too long. Please try again.'));
      }
    });

    test('Validation errors should return input-related messages', () {
      final testCases = [
        'ValidationException: Invalid email',
        'Invalid input provided',
        'Required field missing',
        '422 Unprocessable Entity',
      ];

      for (final error in testCases) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Should NOT contain technical terms
        expect(result.contains('ValidationException'), false);
        expect(result.contains('422'), false);
        expect(result.contains('Unprocessable Entity'), false);

        // Should contain user-friendly message
        expect(result, equals('Please check your input and try again.'));
      }
    });

    test('Generic errors should return fallback message', () {
      final testCases = [
        'Some random error with technical details',
        'NullPointerException at line 123',
        'Unexpected error occurred in method xyz()',
        'Stack trace with technical information',
      ];

      for (final error in testCases) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Should return generic fallback message
        expect(result, equals('Something went wrong. Please try again.'));
      }
    });

    test('No raw technical details should leak through', () {
      final technicalErrors = [
        'HTTP 500: Internal Server Error\nat Object.throw_ [as throw] (http://localhost:8080/dart_sdk.js:5348:11)',
        'SocketException: OS Error: Connection refused, errno = 111',
        'TimeoutException after 0:00:30.000000: Future not completed',
        'ValidationException: The email field is required and must be a valid email address',
        'XMLHttpRequest error: Network request failed with status 0',
      ];

      for (final error in technicalErrors) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Ensure no technical details leak through
        expect(result.contains('Object.throw_'), false);
        expect(result.contains('dart_sdk.js'), false);
        expect(result.contains('errno = 111'), false);
        expect(result.contains('Future not completed'), false);
        expect(result.contains('status 0'), false);
        expect(result.contains('ValidationException'), false);
        expect(result.contains('XMLHttpRequest'), false);

        // Should be user-friendly
        expect(result.length, lessThan(100)); // Reasonable length
        expect(
            result.contains('Please') ||
                result.contains('try again') ||
                result.contains('temporarily'),
            true);
      }
    });

    test('All error messages should be user-friendly', () {
      final testErrors = [
        'HTTP 500: Internal Server Error',
        'HTTP 501: Not Implemented',
        '401 Unauthorized',
        'SocketException: Connection failed',
        'TimeoutException: Request timeout',
        'ValidationException: Invalid input',
        'Some unknown error',
      ];

      for (final error in testErrors) {
        final result =
            GlobalErrorHandler.getUserFriendlyMessage(Exception(error));

        // Should not contain any HTTP status codes
        expect(result.contains('500'), false);
        expect(result.contains('501'), false);
        expect(result.contains('401'), false);
        expect(result.contains('HTTP'), false);

        // Should not contain exception class names
        expect(result.contains('Exception'), false);
        expect(result.contains('SocketException'), false);
        expect(result.contains('TimeoutException'), false);
        expect(result.contains('ValidationException'), false);

        // Should be reasonable length
        expect(result.length, greaterThan(10));
        expect(result.length, lessThan(150));

        // Should be user-friendly (contain helpful words)
        final userFriendlyWords = [
          'please',
          'try',
          'again',
          'check',
          'temporarily',
          'unavailable',
          'connection',
          'internet',
          'session',
          'permission',
          'information',
          'input',
          'something',
          'went',
          'wrong'
        ];

        final lowerResult = result.toLowerCase();
        final containsUserFriendlyWord =
            userFriendlyWords.any((word) => lowerResult.contains(word));
        expect(containsUserFriendlyWord, true,
            reason: 'Result should contain user-friendly language: $result');
      }
    });
  });
}
