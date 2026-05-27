import 'dart:io';
import '../../../../../core/services/image_service.dart';
import '../../../../../core/models/platform_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../core/constants/route_constants.dart';
import '../../../../../core/utils/error_logger.dart';
import '../state/ai_consultation_providers.dart';

/// Image Capture Screen
///
/// Allows users to capture or select images for AI consultation.
/// Provides two options:
/// - Take Photo: Opens device camera
/// - Select from Gallery: Opens gallery picker
///
/// Features:
/// - Image validation (all formats supported, no size limit)
/// - Permission handling for camera and gallery
/// - Error messages for validation failures
/// - Navigation to annotation editor on success
class ImageCaptureScreen extends ConsumerStatefulWidget {
  const ImageCaptureScreen({super.key});

  @override
  ConsumerState<ImageCaptureScreen> createState() =>
      _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends ConsumerState<ImageCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final ImageService _imageService = ImageService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Image'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Section ──────────────────────────────
                _buildHeaderSection(theme),
                const SizedBox(height: 40),

                // ── Action Buttons ──────────────────────────────
                _buildActionButtons(theme),
                const SizedBox(height: 32),

                // ── Info Section ────────────────────────────────
                _buildInfoSection(theme),
              ],
            ),
          ),

          // ── Loading Overlay ─────────────────────────────────
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// Builds the header section with icon and description
  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_a_photo,
            size: 64,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose Image Source',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Take a photo or select an existing image to get AI-powered diagnosis',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the action buttons for camera and gallery
  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Take Photo Button
        _buildActionButton(
          theme: theme,
          icon: Icons.camera_alt,
          label: 'Take Photo',
          subtitle: 'Use your camera to capture an image',
          onPressed: () => _handleImageCapture(ImageSource.camera),
          isPrimary: true,
        ),
        const SizedBox(height: 16),

        // Select from Gallery Button
        _buildActionButton(
          theme: theme,
          icon: Icons.photo_library,
          label: 'Select from Gallery',
          subtitle: 'Choose an existing image from your device',
          onPressed: () => _handleImageCapture(ImageSource.gallery),
          isPrimary: false,
        ),
      ],
    );
  }

  /// Builds a single action button
  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: isPrimary
                ? Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the info section with requirements
  Widget _buildInfoSection(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Image Requirements',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              theme,
              'All image formats supported',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              theme,
              'No size limit - any image size accepted',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              theme,
              'Clear, well-lit images work best',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single info item
  Widget _buildInfoItem(ThemeData theme, String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the loading overlay
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Processing image...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handles image capture from camera or gallery
  Future<void> _handleImageCapture(ImageSource source) async {
    // Check and request permissions
    final hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Use ImageService to select image (platform-aware)
      final result = await _imageService.selectImage(source: source);

      if (result.wasCancelled) {
        // User cancelled
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (result.hasError) {
        logWarning('ImageCaptureScreen', 'Image selection failed: ${result.errorMessage}');
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog(result.errorMessage!);
        return;
      }
      // Set image in state (platform-aware)
      ref.read(currentConsultationProvider.notifier).setImage(result.image!);

      setState(() {
        _isProcessing = false;
      });

      // Navigate to annotation editor
      if (mounted) {
        context.push(RouteConstants.customerAIAnnotation);
      }
    } catch (e, stackTrace) {
      logError('ImageCaptureScreen', 'Failed to capture image', e, stackTrace);
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog(
        'Failed to capture image. Please try again.',
      );
    }
  }

  /// Checks and requests permission for camera or gallery
  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    Permission permission;
    String permissionName;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
      permissionName = 'Camera';
    } else {
      // For gallery, use photos permission
      if (Platform.isIOS) {
        permission = Permission.photos;
      } else {
        // Android 13+ uses photos, older versions use storage
        permission = Permission.photos;
      }
      permissionName = 'Gallery';
    }

    // Check current permission status
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      logWarning('ImageCaptureScreen', '$permissionName permission permanently denied');
      _showPermissionDeniedDialog(permissionName);
      return false;
    }

    // Request permission
    final result = await permission.request();

    if (result.isGranted) {
      return true;
    }

    if (result.isPermanentlyDenied) {
      logWarning('ImageCaptureScreen', '$permissionName permission permanently denied after request');
      _showPermissionDeniedDialog(permissionName);
      return false;
    }

    // Permission denied
    logWarning('ImageCaptureScreen', '$permissionName permission denied');
    _showPermissionRequiredDialog(permissionName);
    return false;
  }

 

  /// Shows error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Validation Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows permission required dialog
  void _showPermissionRequiredDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'Please grant $permissionName permission to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry permission request
              _handleImageCapture(
                permissionName == 'Camera'
                    ? ImageSource.camera
                    : ImageSource.gallery,
              );
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Shows permission permanently denied dialog
  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Denied'),
        content: Text(
          '$permissionName permission is required to use this feature.\n\n'
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
