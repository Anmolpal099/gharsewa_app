import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/platform_image.dart';

/// Result of image selection operation
@immutable
class ImageSelectionResult {
  final PlatformImage? image;
  final bool wasCancelled;
  final String? errorMessage;

  const ImageSelectionResult({
    this.image,
    this.wasCancelled = false,
    this.errorMessage,
  });

  bool get isSuccess => image != null;
  bool get hasError => errorMessage != null;
}

/// Service for platform-agnostic image operations
class ImageService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Selects an image from the device
  ///
  /// On web: Uses image_picker with bytes
  /// On desktop: Uses file_picker with file paths
  ///
  /// Returns [ImageSelectionResult] with the selected image or error
  Future<ImageSelectionResult> selectImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      if (kIsWeb) {
        return await _selectImageWeb(source);
      } else {
        return await _selectImageDesktop(source);
      }
    } catch (e) {
      return const ImageSelectionResult(
        errorMessage: 'Failed to select image. Please try again.',
      );
    }
  }

  /// Web-specific image selection
  Future<ImageSelectionResult> _selectImageWeb(ImageSource source) async {
    final XFile? xFile = await _imagePicker.pickImage(source: source);

    if (xFile == null) {
      return const ImageSelectionResult(wasCancelled: true);
    }

    // Read bytes for web platform
    final Uint8List bytes = await xFile.readAsBytes();
    final image = WebPlatformImage(bytes);

    return ImageSelectionResult(image: image);
  }

  /// Desktop-specific image selection
  Future<ImageSelectionResult> _selectImageDesktop(ImageSource source) async {
    if (source == ImageSource.camera) {
      // Use image_picker for camera on desktop
      final XFile? xFile = await _imagePicker.pickImage(source: source);

      if (xFile == null) {
        return const ImageSelectionResult(wasCancelled: true);
      }

      final file = File(xFile.path);
      final image = DesktopPlatformImage(file);

      return ImageSelectionResult(image: image);
    } else {
      // Use file_picker for gallery on desktop (better UX)
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const ImageSelectionResult(wasCancelled: true);
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return const ImageSelectionResult(
          errorMessage: 'Failed to get file path',
        );
      }

      final file = File(filePath);
      final image = DesktopPlatformImage(file);

      return ImageSelectionResult(image: image);
    }
  }

  /// Converts an image to base64 for API transmission
  Future<String> imageToBase64(PlatformImage image) async {
    return await image.toBase64();
  }

  /// Gets the size of an image in bytes
  Future<int> getImageSize(PlatformImage image) async {
    return await image.getSizeInBytes();
  }
}
