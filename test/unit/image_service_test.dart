import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/core/models/platform_image.dart';
import 'package:gharsewa/core/services/image_service.dart';

void main() {
  group('ImageSelectionResult', () {
    test('isSuccess returns true when image is not null', () {
      final image = WebPlatformImage(Uint8List(0));
      final result = ImageSelectionResult(image: image);

      expect(result.isSuccess, isTrue);
      expect(result.hasError, isFalse);
    });

    test('isSuccess returns false when image is null', () {
      const result = ImageSelectionResult(wasCancelled: true);

      expect(result.isSuccess, isFalse);
      expect(result.hasError, isFalse);
    });

    test('hasError returns true when errorMessage is not null', () {
      const result = ImageSelectionResult(errorMessage: 'Test error');

      expect(result.hasError, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('hasError returns false when errorMessage is null', () {
      const result = ImageSelectionResult(wasCancelled: true);

      expect(result.hasError, isFalse);
    });
  });

  group('ImageService', () {
    late ImageService imageService;

    setUp(() {
      imageService = ImageService();
    });

    test('imageToBase64 converts WebPlatformImage correctly', () async {
      // Create a simple test image with known bytes
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final image = WebPlatformImage(bytes);

      final base64 = await imageService.imageToBase64(image);

      // Verify base64 is not empty and is a valid string
      expect(base64, isNotEmpty);
      expect(base64, isA<String>());
    });

    test('getImageSize returns correct size for WebPlatformImage', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final image = WebPlatformImage(bytes);

      final size = await imageService.getImageSize(image);

      expect(size, equals(5));
    });
  });
}
