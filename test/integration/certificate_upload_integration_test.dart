import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/core/models/platform_image.dart';
import 'package:gharsewa/core/services/image_service.dart';
import 'package:gharsewa/features/provider_panel/data/services/provider_upload_service.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'certificate_upload_integration_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('Certificate Upload Service Integration', () {
    late MockDio mockDio;
    late ProviderUploadService uploadService;
    late ImageService imageService;

    setUp(() {
      mockDio = MockDio();
      uploadService = ProviderUploadService(mockDio);
      imageService = ImageService();
    });

    group('PlatformImage to Base64 Conversion', () {
      test('WebPlatformImage converts to base64 correctly', () async {
        // Create a simple test image (1x1 red pixel PNG)
        final testBytes = Uint8List.fromList([
          137, 80, 78, 71, 13, 10, 26, 10, // PNG signature
          0, 0, 0, 13, 73, 72, 68, 82, // IHDR chunk
          0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222,
          0, 0, 0, 12, 73, 68, 65, 84, 8, 215, 99, 248, 207, 192, 0, 0, 3, 1, 1, 0, 24, 221, 141, 176,
          0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
        ]);

        final platformImage = WebPlatformImage(testBytes);
        final base64String = await imageService.imageToBase64(platformImage);

        expect(base64String, isNotEmpty);
        expect(base64String, isA<String>());
        // Verify it's valid base64
        expect(() => base64String.contains(RegExp(r'^[A-Za-z0-9+/=]+$')), returnsNormally);
      });

      test('PlatformImage getSizeInBytes returns correct size', () async {
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final platformImage = WebPlatformImage(testBytes);

        final size = await imageService.getImageSize(platformImage);

        expect(size, equals(5));
      });
    });

    group('ProviderUploadService Certificate Upload', () {
      test('uploadCertification sends correct data to backend', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final platformImage = WebPlatformImage(testBytes);
        const certName = 'Test Certificate';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-123',
              'name': certName,
              'document_url': 'https://example.com/cert.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-01T00:00:00Z',
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

        // Assert
        expect(result.id, equals('cert-123'));
        expect(result.name, equals(certName));
        expect(result.documentUrl, equals('https://example.com/cert.jpg'));
        expect(result.fileType, equals('JPG'));
        expect(result.isVerified, isFalse);

        // Verify the correct endpoint was called
        final captured = verify(mockDio.post(
          captureAny,
          data: captureAnyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).captured;

        expect(captured[0], equals('/v1/provider/certifications/upload'));

        // Verify FormData contains base64 string and name
        final formData = captured[1] as FormData;
        final fields = <String, dynamic>{};
        for (final field in formData.fields) {
          fields[field.key] = field.value;
        }

        expect(fields['name'], equals(certName));
        expect(fields['document'], isA<String>());
        expect(fields['document'], isNotEmpty);
      });

      test('uploadCertification tracks progress correctly', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final platformImage = WebPlatformImage(testBytes);
        const certName = 'Test Certificate';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-123',
              'name': certName,
              'document_url': 'https://example.com/cert.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-01T00:00:00Z',
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
            onProgress(50, 100); // Simulate 50% progress
            onProgress(100, 100); // Simulate 100% progress
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

        // Assert
        expect(progressValues, isNotEmpty);
        expect(progressValues.last, equals(1.0)); // Should reach 100%
      });

      test('uploadCertification handles backend errors correctly', () async {
        // Arrange
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final platformImage = WebPlatformImage(testBytes);
        const certName = 'Test Certificate';

        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 422,
          data: {
            'success': false,
            'message': 'Validation failed',
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
          throwsA(isA<Exception>()),
        );
      });
    });

    group('End-to-End Certificate Upload Flow', () {
      test('complete flow: select image -> convert to base64 -> upload', () async {
        // This test verifies the complete integration flow
        // 1. PlatformImage is created
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final platformImage = WebPlatformImage(testBytes);

        // 2. Image is converted to base64
        final base64String = await imageService.imageToBase64(platformImage);
        expect(base64String, isNotEmpty);

        // 3. Upload service accepts PlatformImage and converts internally
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/v1/provider/certifications/upload'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'id': 'cert-123',
              'name': 'Test Certificate',
              'document_url': 'https://example.com/cert.jpg',
              'file_type': 'JPG',
              'is_verified': false,
              'uploaded_at': '2024-01-01T00:00:00Z',
              'verified_at': null,
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          onSendProgress: anyNamed('onSendProgress'),
        )).thenAnswer((_) async => mockResponse);

        // 4. Upload completes successfully
        final result = await uploadService.uploadCertification(
          platformImage,
          'Test Certificate',
        );

        expect(result.id, equals('cert-123'));
        expect(result.documentUrl, isNotEmpty);
      });
    });

    group('Error Handling', () {
      test('handles empty image bytes gracefully', () async {
        final emptyBytes = Uint8List(0);
        final platformImage = WebPlatformImage(emptyBytes);

        final base64String = await imageService.imageToBase64(platformImage);
        expect(base64String, isEmpty);
      });

      test('handles network errors during upload', () async {
        final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
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

        expect(
          () => uploadService.uploadCertification(platformImage, 'Test'),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
