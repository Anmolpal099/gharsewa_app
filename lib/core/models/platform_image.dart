import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Sealed class representing an image on any platform
///
/// Use pattern matching to handle platform-specific cases:
/// ```dart
/// switch (image) {
///   case WebPlatformImage(:final bytes):
///     // Handle web image
///   case DesktopPlatformImage(:final file):
///     // Handle desktop image
/// }
/// ```
@immutable
sealed class PlatformImage {
  const PlatformImage();

  /// Creates a PlatformImage from the current platform
  factory PlatformImage.fromPlatform({
    Uint8List? bytes,
    File? file,
  }) {
    if (kIsWeb) {
      if (bytes == null) {
        throw ArgumentError('bytes must be provided for web platform');
      }
      return WebPlatformImage(bytes);
    } else {
      if (file == null) {
        throw ArgumentError('file must be provided for desktop platform');
      }
      return DesktopPlatformImage(file);
    }
  }

  /// Converts this image to base64 string for API transmission
  Future<String> toBase64();

  /// Gets the size of the image in bytes
  Future<int> getSizeInBytes();
}

/// Web platform image stored as bytes in memory
@immutable
final class WebPlatformImage extends PlatformImage {
  final Uint8List bytes;

  const WebPlatformImage(this.bytes);

  @override
  Future<String> toBase64() async {
    return base64Encode(bytes);
  }

  @override
  Future<int> getSizeInBytes() async {
    return bytes.length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebPlatformImage &&
          runtimeType == other.runtimeType &&
          listEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);
}

/// Desktop platform image stored as file path
@immutable
final class DesktopPlatformImage extends PlatformImage {
  final File file;

  const DesktopPlatformImage(this.file);

  @override
  Future<String> toBase64() async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  @override
  Future<int> getSizeInBytes() async {
    return await file.length();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesktopPlatformImage &&
          runtimeType == other.runtimeType &&
          file.path == other.file.path;

  @override
  int get hashCode => file.path.hashCode;
}
