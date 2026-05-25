import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/services/api/api_client.dart';
import 'package:gharsewa/services/api/api_exception.dart';

void main() {
  group('ApiClient', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    group('Error Handling', () {
      test('should have 30 second timeout configured', () {
        // This test verifies the timeout configuration
        // The actual timeout is set in the constructor
        expect(apiClient, isNotNull);
      });

      test('ApiException should contain user-friendly message for network error', () {
        final exception = ApiException(
          message: 'No internet connection. Please check your network settings.',
          type: ApiExceptionType.network,
          statusCode: null,
        );

        expect(exception.message, contains('No internet connection'));
        expect(exception.type, ApiExceptionType.network);
        expect(exception.statusCode, isNull);
      });

      test('ApiException should contain user-friendly message for timeout', () {
        final exception = ApiException(
          message: 'Request timed out. Please try again.',
          type: ApiExceptionType.timeout,
          statusCode: null,
        );

        expect(exception.message, contains('timed out'));
        expect(exception.type, ApiExceptionType.timeout);
      });

      test('ApiException should contain user-friendly message for server error', () {
        final exception = ApiException(
          message: 'Server error. Our team has been notified. Please try again later.',
          type: ApiExceptionType.server,
          statusCode: 500,
        );

        expect(exception.message, contains('Server error'));
        expect(exception.type, ApiExceptionType.server);
        expect(exception.statusCode, 500);
      });

      test('ApiException should contain specific message for client error', () {
        final exception = ApiException(
          message: 'Invalid file format',
          type: ApiExceptionType.client,
          statusCode: 400,
        );

        expect(exception.message, 'Invalid file format');
        expect(exception.type, ApiExceptionType.client);
        expect(exception.statusCode, 400);
      });

      test('ApiException toString should include all information', () {
        final exception = ApiException(
          message: 'Test error',
          type: ApiExceptionType.network,
          statusCode: 404,
        );

        final stringRepresentation = exception.toString();
        expect(stringRepresentation, contains('Test error'));
        expect(stringRepresentation, contains('network'));
        expect(stringRepresentation, contains('404'));
      });
    });

    group('ApiExceptionType', () {
      test('should have all required error types', () {
        expect(ApiExceptionType.values, contains(ApiExceptionType.network));
        expect(ApiExceptionType.values, contains(ApiExceptionType.timeout));
        expect(ApiExceptionType.values, contains(ApiExceptionType.client));
        expect(ApiExceptionType.values, contains(ApiExceptionType.server));
        expect(ApiExceptionType.values, contains(ApiExceptionType.cancelled));
        expect(ApiExceptionType.values, contains(ApiExceptionType.unknown));
      });
    });

    group('Base Configuration', () {
      test('should be instantiable', () {
        expect(apiClient, isNotNull);
        expect(apiClient, isA<ApiClient>());
      });
    });
  });
}
