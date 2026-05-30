import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/core/models/platform_image.dart';
import 'package:gharsewa/core/services/image_service.dart';
import 'package:gharsewa/features/provider_panel/data/services/provider_upload_service.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'certificate_upload_integration_test.mocks.dart';

/// Verification tests for Task 7.2: Certificate Upload Service Integration
/// 
/// This test suite verifies:
/// - ProviderUploadService correctly handles certificate uploads with PlatformImage
/// - Base64 conversion works correctly for certificates
/// - Error handling when certificate upload fails
/// 
/// Requirements: 9.5, 10.3, 11.1, 11.2
@GenerateMocks([Dio])
void main() {
  group('Task 7.2: Certificate Upload Service Integration Verification', () {
    late MockDio mockDio;
    late ProviderUploadService uploadService;
    late ImageService imageService;

    setUp(() {
      mockDio = MockDio();
      uploadService = ProviderUploadService(mockDio);
      imageService = ImageService();
    });

    group('Requirement 9.5: Certificate Upload with PlatformImage', () {
      test('ProviderUploadService accepts PlatformImage for certificate upload', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final platformImage = WebPlatformImage(testBytes);
        const certName = 'Medical License';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-456',
              'name': certName,
              'document_url': 'https://example.com/medical-license.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-15T10:30:00Z',
              'verified_at': null,
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await uploadService.uploadCertification(
          platformImage,
          certName,
        );

        // Assert - Verify service accepts PlatformImage and returns Certification
        expect(result.id, equals('cert-456'));
        expect(result.name, equals(certName));
        expect(result.documentUrl, contains('medical-license.jpg'));
        expect(result.isVerified, isFalse);
      });

      test('ProviderUploadService handles WebPlatformImage correctly', () async {
        // Arrange - Create a WebPlatformImage (web platform scenario)
        final testBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
        final webImage = WebPlatformImage(testBytes);
        const certName = 'Nursing Certificate';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-789',
              'name': certName,
              'document_url': 'https://example.com/nursing-cert.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-15T11:00:00Z',
              'verified_at': null,
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await uploadService.uploadCertification(
          webImage,
          certName,
        );

        // Assert
        expect(result.id, equals('cert-789'));
        expect(result.name, equals(certName));
      });
    });

    group('Requirement 10.3: Base64 Conversion for Certificates', () {
      test('base64 conversion works correctly for certificate images', () async {
        // Arrange - Create a test certificate image
        final certificateBytes = Uint8List.fromList([
          // Simulate a small certificate image
          255, 216, 255, 224, 0, 16, 74, 70, 73, 70, // JPEG header
          100, 101, 102, 103, 104, 105, 106, 107, 108, 109, // Data
        ]);
        final platformImage = WebPlatformImage(certificateBytes);

        // Act - Convert to base64
        final base64String = await imageService.imageToBase64(platformImage);

        // Assert - Verify base64 conversion
        expect(base64String, isNotEmpty);
        expect(base64String, isA<String>());
        
        // Verify it's valid base64 by decoding it back
        final decodedBytes = base64Decode(base64String);
        expect(decodedBytes, equals(certificateBytes));
      });

      test('ProviderUploadService sends base64-encoded certificate to backend', () async {
        // Arrange
        final certificateBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
        final platformImage = WebPlatformImage(certificateBytes);
        const certName = 'Professional License';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-101',
              'name': certName,
              'document_url': 'https://example.com/license.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-15T12:00:00Z',
              'verified_at': null,
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        await uploadService.uploadCertification(platformImage, certName);

        // Assert - Verify base64 string was sent
        final captured = verify(mockDio.post(
          captureAny,
          data: captureAnyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).captured;

        final formData = captured[1] as FormData;
        final fields = <String, dynamic>{};
        for (final field in formData.fields) {
          fields[field.key] = field.value;
        }

        // Verify the document field contains base64 string
        expect(fields['document'], isA<String>());
        expect(fields['document'], isNotEmpty);
        
        // Verify it's valid base64
        final base64String = fields['document'] as String;
        expect(() => base64Decode(base64String), returnsNormally);
        
        // Verify decoded bytes match original
        final decodedBytes = base64Decode(base64String);
        expect(decodedBytes, equals(certificateBytes));
      });

      test('base64 conversion handles large certificate images', () async {
        // Arrange - Create a larger certificate image (1KB)
        final largeCertBytes = Uint8List.fromList(
          List.generate(1024, (index) => index % 256),
        );
        final platformImage = WebPlatformImage(largeCertBytes);

        // Act
        final base64String = await imageService.imageToBase64(platformImage);

        // Assert
        expect(base64String, isNotEmpty);
        expect(base64String.length, greaterThan(1000)); // Base64 is larger than original
        
        // Verify round-trip conversion
        final decodedBytes = base64Decode(base64String);
        expect(decodedBytes, equals(largeCertBytes));
      });
    });

    group('Requirement 11.1 & 11.2: Error Handling', () {
      test('handles backend validation errors correctly', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final platformImage = WebPlatformImage(testBytes);
        const certName = 'Invalid Certificate';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 422,
          data: {
            'success': false,
            'message': 'Invalid certificate format',
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => uploadService.uploadCertification(platformImage, certName),
          throwsA(
            predicate((e) => 
              e is Exception && 
              e.toString().contains('Invalid certificate format')
            ),
          ),
        );
      });

      test('handles network timeout errors', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final platformImage = WebPlatformImage(testBytes);

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        ));

        // Act & Assert
        expect(
          () => uploadService.uploadCertification(platformImage, 'Test'),
          throwsA(isA<DioException>()),
        );
      });

      test('handles server errors (500) correctly', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final platformImage = WebPlatformImage(testBytes);

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 500,
          data: {
            'success': false,
            'message': 'Internal server error',
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => uploadService.uploadCertification(platformImage, 'Test'),
          throwsA(
            predicate((e) => 
              e is Exception && 
              e.toString().contains('Internal server error')
            ),
          ),
        );
      });

      test('handles malformed backend response', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final platformImage = WebPlatformImage(testBytes);

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            // Missing 'data' field - malformed response
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act & Assert - Should throw when trying to parse missing data
        expect(
          () => uploadService.uploadCertification(platformImage, 'Test'),
          throwsA(isA<TypeError>()),
        );
      });

      test('handles empty certificate name gracefully', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final platformImage = WebPlatformImage(testBytes);
        const emptyCertName = '';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-empty',
              'name': emptyCertName,
              'document_url': 'https://example.com/cert.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-15T12:00:00Z',
              'verified_at': null,
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act - Should not throw, service accepts empty name
        final result = await uploadService.uploadCertification(
          platformImage,
          emptyCertName,
        );

        // Assert
        expect(result.id, equals('cert-empty'));
      });
    });

    group('Integration: Complete Certificate Upload Flow', () {
      test('end-to-end: PlatformImage -> Base64 -> Upload -> Success', () async {
        // Arrange - Simulate complete flow
        final certificateBytes = Uint8List.fromList([
          // Realistic certificate image bytes
          255, 216, 255, 224, 0, 16, 74, 70, 73, 70, // JPEG header
          0, 1, 1, 0, 0, 1, 0, 1, 0, 0, // JFIF data
          255, 219, 0, 67, 0, 8, 6, 6, 7, 6, 5, 8, // Quantization table
        ]);
        final platformImage = WebPlatformImage(certificateBytes);
        const certName = 'Medical Degree';

        // Step 1: Verify base64 conversion
        final base64String = await imageService.imageToBase64(platformImage);
        expect(base64String, isNotEmpty);

        // Step 2: Mock successful upload
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-final',
              'name': certName,
              'document_url': 'https://example.com/medical-degree.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-15T13:00:00Z',
              'verified_at': null,
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Step 3: Upload certificate
        final result = await uploadService.uploadCertification(
          platformImage,
          certName,
        );

        // Assert - Complete flow successful
        expect(result.id, equals('cert-final'));
        expect(result.name, equals(certName));
        expect(result.documentUrl, contains('medical-degree.jpg'));
        expect(result.fileType, equals('JPG'));
        expect(result.isVerified, isFalse);

        // Verify correct data was sent
        final captured = verify(mockDio.post(
          captureAny,
          data: captureAnyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).captured;

        expect(captured[0], equals('/v1/provider/certifications/upload'));

        final formData = captured[1] as FormData;
        final fields = <String, dynamic>{};
        for (final field in formData.fields) {
          fields[field.key] = field.value;
        }

        expect(fields['name'], equals(certName));
        expect(fields['document'], equals(base64String));
      });

      test('progress tracking works during certificate upload', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final platformImage = WebPlatformImage(testBytes);
        const certName = 'Progress Test Certificate';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-progress',
              'name': certName,
              'document_url': 'https://example.com/cert.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-15T14:00:00Z',
              'verified_at': null,
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((invocation) async {
          final onProgress = invocation.namedArguments[#onSendProgress] as void Function(int, int)?;
          if (onProgress != null) {
            onProgress(25, 100);  // 25%
            onProgress(50, 100);  // 50%
            onProgress(75, 100);  // 75%
            onProgress(100, 100); // 100%
          }
          return mockResponse;
        });

        final progressValues = <double>[];

        // Act
        await uploadService.uploadCertification(
          platformImage,
          certName,
          onProgress: (progress) => progressValues.add(progress),
        );

        // Assert - Progress tracking works
        expect(progressValues, isNotEmpty);
        expect(progressValues.length, equals(4));
        expect(progressValues[0], equals(0.25));
        expect(progressValues[1], equals(0.50));
        expect(progressValues[2], equals(0.75));
        expect(progressValues[3], equals(1.0));
      });
    });
  });
}
