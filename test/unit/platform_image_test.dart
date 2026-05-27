import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/core/models/platform_image.dart';

void main() {
  group('WebPlatformImage', () {
    test('toBase64 returns correct base64 string for known byte array', () async {
      // Arrange
      final bytes = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
      final image = WebPlatformImage(bytes);
      final expectedBase64 = base64Encode(bytes);

      // Act
      final result = await image.toBase64();

      // Assert
      expect(result, equals(expectedBase64));
    });

    test('getSizeInBytes returns correct size', () async {
      // Arrange
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final image = WebPlatformImage(bytes);

      // Act
      final size = await image.getSizeInBytes();

      // Assert
      expect(size, equals(5));
    });

    test('equality works correctly for same bytes', () {
      // Arrange
      final bytes = Uint8List.fromList([1, 2, 3]);
      final image1 = WebPlatformImage(bytes);
      final image2 = WebPlatformImage(Uint8List.fromList([1, 2, 3]));

      // Assert
      expect(image1, equals(image2));
      expect(image1.hashCode, equals(image2.hashCode));
    });

    test('equality works correctly for different bytes', () {
      // Arrange
      final image1 = WebPlatformImage(Uint8List.fromList([1, 2, 3]));
      final image2 = WebPlatformImage(Uint8List.fromList([4, 5, 6]));

      // Assert
      expect(image1, isNot(equals(image2)));
    });
  });

  group('DesktopPlatformImage', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      // Create a temporary directory and file for testing
      tempDir = await Directory.systemTemp.createTemp('platform_image_test');
      testFile = File('${tempDir.path}/test_image.txt');
      await testFile.writeAsBytes([72, 101, 108, 108, 111]); // "Hello"
    });

    tearDown(() async {
      // Clean up temporary files
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('toBase64 reads file and returns correct base64 string', () async {
      // Arrange
      final image = DesktopPlatformImage(testFile);
      final expectedBytes = await testFile.readAsBytes();
      final expectedBase64 = base64Encode(expectedBytes);

      // Act
      final result = await image.toBase64();

      // Assert
      expect(result, equals(expectedBase64));
    });

    test('getSizeInBytes returns correct file size', () async {
      // Arrange
      final image = DesktopPlatformImage(testFile);
      final expectedSize = await testFile.length();

      // Act
      final size = await image.getSizeInBytes();

      // Assert
      expect(size, equals(expectedSize));
      expect(size, equals(5)); // "Hello" is 5 bytes
    });

    test('equality works correctly for same file path', () {
      // Arrange
      final image1 = DesktopPlatformImage(testFile);
      final image2 = DesktopPlatformImage(File(testFile.path));

      // Assert
      expect(image1, equals(image2));
      expect(image1.hashCode, equals(image2.hashCode));
    });

    test('equality works correctly for different file paths', () async {
      // Arrange
      final file2 = File('${tempDir.path}/test_image2.txt');
      await file2.writeAsBytes([1, 2, 3]);
      
      final image1 = DesktopPlatformImage(testFile);
      final image2 = DesktopPlatformImage(file2);

      // Assert
      expect(image1, isNot(equals(image2)));
    });
  });

  group('PlatformImage.fromPlatform', () {
    test('throws ArgumentError when bytes is null on web', () {
      // This test would need to mock kIsWeb, which is complex
      // For now, we'll test the desktop path which is easier to test
      expect(
        () => PlatformImage.fromPlatform(bytes: null, file: null),
        throwsArgumentError,
      );
    });

    test('creates DesktopPlatformImage when file is provided on desktop', () {
      // Arrange
      final file = File('test.txt');

      // Act
      final image = PlatformImage.fromPlatform(file: file);

      // Assert
      expect(image, isA<DesktopPlatformImage>());
      expect((image as DesktopPlatformImage).file, equals(file));
    });
  });
}
