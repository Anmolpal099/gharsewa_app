import 'package:flutter/material.dart';
import '../models/platform_image.dart';

/// Platform-aware widget for displaying images
///
/// Automatically uses:
/// - Image.memory() for web platform
/// - Image.file() for desktop platform
class ImageDisplayWidget extends StatelessWidget {
  final PlatformImage image;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const ImageDisplayWidget({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return switch (image) {
      WebPlatformImage(:final bytes) => Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _defaultErrorWidget(context),
        ),
      DesktopPlatformImage(:final file) => Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _defaultErrorWidget(context),
        ),
    };
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
