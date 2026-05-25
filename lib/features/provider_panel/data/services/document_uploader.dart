import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// Document Uploader Service
/// 
/// Handles file uploads with validation, progress tracking, image compression,
/// and retry logic for failed uploads.
/// 
/// Features:
/// - File type validation (PDF, PNG, JPG)
/// - File size validation (configurable limits)
/// - Image compression for photos before upload
/// - Progress tracking with callbacks
/// - Retry logic with exponential backoff
/// - Multipart file upload support
class DocumentUploader {
  final Dio _dio;
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  
  // Compression configuration
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int compressionQuality = 85;

  DocumentUploader(this._dio);

  /// Upload a file to the specified endpoint with progress tracking
  /// 
  /// Parameters:
  /// - [file]: The file to upload
  /// - [endpoint]: The API endpoint to upload to
  /// - [fieldName]: The form field name for the file (default: 'file')
  /// - [additionalData]: Additional form data to send with the file
  /// - [onProgress]: Callback for upload progress (0.0 to 1.0)
  /// 
  /// Returns: The file URL from the server response
  /// 
  /// Throws: [DocumentUploadException] on validation or upload failure
  Future<String> uploadFile(
    File file,
    String endpoint, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    Function(double)? onProgress,
  }) async {
    // Validate file exists
    if (!await file.exists()) {
      throw DocumentUploadException(
        'File does not exist',
        type: DocumentUploadExceptionType.validation,
      );
    }

    int retryCount = 0;
    DioException? lastError;

    while (retryCount <= maxRetries) {
      try {
        // Create multipart file
        final fileName = path.basename(file.path);
        final multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );

        // Build form data
        final formData = FormData.fromMap({
          fieldName: multipartFile,
          ...?additionalData,
        });

        // Upload with progress tracking
        final response = await _dio.post(
          endpoint,
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
          onSendProgress: (sent, total) {
            if (onProgress != null && total > 0) {
              final progress = sent / total;
              onProgress(progress);
            }
          },
        );

        // Extract file URL from response
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          
          // Try common response structures
          final fileUrl = data['url'] ?? 
                         data['file_url'] ?? 
                         data['data']?['url'] ?? 
                         data['data']?['file_url'];
          
          if (fileUrl != null && fileUrl is String) {
            return fileUrl;
          }
        }

        throw DocumentUploadException(
          'Invalid response format: missing file URL',
          type: DocumentUploadExceptionType.server,
        );
      } on DioException catch (e) {
        lastError = e;
        
        // Don't retry on client errors (4xx) except for timeout
        if (e.response?.statusCode != null && 
            e.response!.statusCode! >= 400 && 
            e.response!.statusCode! < 500 &&
            e.type != DioExceptionType.connectionTimeout &&
            e.type != DioExceptionType.sendTimeout &&
            e.type != DioExceptionType.receiveTimeout) {
          throw _handleDioException(e);
        }

        // Retry with exponential backoff
        if (retryCount < maxRetries) {
          final delay = initialRetryDelay * (1 << retryCount);
          await Future.delayed(delay);
          retryCount++;
          continue;
        }

        // Max retries reached
        throw _handleDioException(e);
      } catch (e) {
        throw DocumentUploadException(
          'Upload failed: ${e.toString()}',
          type: DocumentUploadExceptionType.unknown,
        );
      }
    }

    // Should never reach here, but handle it anyway
    throw _handleDioException(lastError!);
  }

  /// Validate file type against allowed types
  /// 
  /// Parameters:
  /// - [file]: The file to validate
  /// - [allowedTypes]: List of allowed file extensions (e.g., ['pdf', 'png', 'jpg'])
  /// 
  /// Returns: true if file type is valid, false otherwise
  bool validateFileType(File file, List<String> allowedTypes) {
    final extension = path.extension(file.path).toLowerCase().replaceFirst('.', '');
    return allowedTypes.map((e) => e.toLowerCase()).contains(extension);
  }

  /// Validate file size against maximum size
  /// 
  /// Parameters:
  /// - [file]: The file to validate
  /// - [maxSizeBytes]: Maximum allowed file size in bytes
  /// 
  /// Returns: true if file size is valid, false otherwise
  Future<bool> validateFileSize(File file, int maxSizeBytes) async {
    final fileSize = await file.length();
    return fileSize <= maxSizeBytes;
  }

  /// Compress an image file before upload
  /// 
  /// Reduces image dimensions and quality to optimize bandwidth usage.
  /// Only compresses if the image exceeds the maximum dimensions.
  /// 
  /// Parameters:
  /// - [imageFile]: The image file to compress
  /// - [maxWidth]: Maximum width (default: 1920)
  /// - [maxHeight]: Maximum height (default: 1920)
  /// - [quality]: JPEG quality 0-100 (default: 85)
  /// 
  /// Returns: Compressed image file, or original if compression not needed
  /// 
  /// Throws: [DocumentUploadException] if image cannot be processed
  Future<File> compressImage(
    File imageFile, {
    int maxWidth = maxImageWidth,
    int maxHeight = maxImageHeight,
    int quality = compressionQuality,
  }) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw DocumentUploadException(
          'Unable to decode image',
          type: DocumentUploadExceptionType.validation,
        );
      }

      // Check if compression is needed
      if (image.width <= maxWidth && image.height <= maxHeight) {
        // Image is already small enough
        return imageFile;
      }

      // Calculate new dimensions maintaining aspect ratio
      double scale = 1.0;
      if (image.width > maxWidth) {
        scale = maxWidth / image.width;
      }
      if (image.height * scale > maxHeight) {
        scale = maxHeight / image.height;
      }

      final newWidth = (image.width * scale).round();
      final newHeight = (image.height * scale).round();

      // Resize image
      final resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with quality setting
      final compressed = img.encodeJpg(resized, quality: quality);

      // Create temporary file for compressed image
      final tempDir = imageFile.parent;
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final compressedFile = File('${tempDir.path}/${fileName}_compressed.jpg');
      
      await compressedFile.writeAsBytes(compressed);

      debugPrint('Image compressed: ${bytes.length} bytes -> ${compressed.length} bytes');
      
      return compressedFile;
    } catch (e) {
      if (e is DocumentUploadException) {
        rethrow;
      }
      throw DocumentUploadException(
        'Image compression failed: ${e.toString()}',
        type: DocumentUploadExceptionType.compression,
      );
    }
  }

  /// Validate and upload a profile photo
  /// 
  /// Validates file type (JPG/PNG), size (<5MB), compresses the image,
  /// and uploads it to the specified endpoint.
  /// 
  /// Parameters:
  /// - [imageFile]: The profile photo to upload
  /// - [endpoint]: The API endpoint to upload to
  /// - [onProgress]: Callback for upload progress (0.0 to 1.0)
  /// 
  /// Returns: The uploaded file URL
  /// 
  /// Throws: [DocumentUploadException] on validation or upload failure
  Future<String> uploadProfilePhoto(
    File imageFile,
    String endpoint, {
    Function(double)? onProgress,
  }) async {
    // Validate file type (JPG or PNG)
    if (!validateFileType(imageFile, ['jpg', 'jpeg', 'png'])) {
      throw DocumentUploadException(
        'File must be JPG or PNG format',
        type: DocumentUploadExceptionType.validation,
      );
    }

    // Validate file size (<5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB in bytes
    if (!await validateFileSize(imageFile, maxSize)) {
      throw DocumentUploadException(
        'File size must be under 5MB',
        type: DocumentUploadExceptionType.validation,
      );
    }

    // Compress image
    final compressedFile = await compressImage(imageFile);

    try {
      // Upload compressed image
      return await uploadFile(
        compressedFile,
        endpoint,
        onProgress: onProgress,
      );
    } finally {
      // Clean up compressed file if it's different from original
      if (compressedFile.path != imageFile.path) {
        try {
          await compressedFile.delete();
        } catch (e) {
          debugPrint('Failed to delete compressed file: $e');
        }
      }
    }
  }

  /// Validate and upload a certification document
  /// 
  /// Validates file type (PDF/PNG/JPG) and size (<10MB), compresses images,
  /// and uploads the document to the specified endpoint.
  /// 
  /// Parameters:
  /// - [documentFile]: The certification document to upload
  /// - [endpoint]: The API endpoint to upload to
  /// - [certificationName]: Name of the certification
  /// - [onProgress]: Callback for upload progress (0.0 to 1.0)
  /// 
  /// Returns: The uploaded file URL
  /// 
  /// Throws: [DocumentUploadException] on validation or upload failure
  Future<String> uploadCertification(
    File documentFile,
    String endpoint, {
    required String certificationName,
    Function(double)? onProgress,
  }) async {
    // Validate file type (PDF, PNG, or JPG)
    if (!validateFileType(documentFile, ['pdf', 'png', 'jpg', 'jpeg'])) {
      throw DocumentUploadException(
        'File must be PDF, PNG, or JPG format',
        type: DocumentUploadExceptionType.validation,
      );
    }

    // Validate file size (<10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes
    if (!await validateFileSize(documentFile, maxSize)) {
      throw DocumentUploadException(
        'File size must be under 10MB',
        type: DocumentUploadExceptionType.validation,
      );
    }

    File fileToUpload = documentFile;

    // Compress if it's an image
    final extension = path.extension(documentFile.path).toLowerCase();
    if (['.png', '.jpg', '.jpeg'].contains(extension)) {
      fileToUpload = await compressImage(documentFile);
    }

    try {
      // Upload document with certification name
      return await uploadFile(
        fileToUpload,
        endpoint,
        additionalData: {
          'name': certificationName,
        },
        onProgress: onProgress,
      );
    } finally {
      // Clean up compressed file if it's different from original
      if (fileToUpload.path != documentFile.path) {
        try {
          await fileToUpload.delete();
        } catch (e) {
          debugPrint('Failed to delete compressed file: $e');
        }
      }
    }
  }

  /// Handle DioException and convert to DocumentUploadException
  DocumentUploadException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DocumentUploadException(
          'Upload timed out. Please try again.',
          type: DocumentUploadExceptionType.timeout,
        );

      case DioExceptionType.connectionError:
        return DocumentUploadException(
          'No internet connection. Please check your network settings.',
          type: DocumentUploadExceptionType.network,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        String message = 'Upload failed. Please try again.';
        
        if (responseData is Map<String, dynamic>) {
          message = responseData['message'] ?? 
                   responseData['error'] ?? 
                   message;
        }

        if (statusCode != null && statusCode >= 500) {
          return DocumentUploadException(
            'Server error. Please try again later.',
            type: DocumentUploadExceptionType.server,
          );
        }

        return DocumentUploadException(
          message,
          type: DocumentUploadExceptionType.client,
        );

      case DioExceptionType.cancel:
        return DocumentUploadException(
          'Upload was cancelled.',
          type: DocumentUploadExceptionType.cancelled,
        );

      default:
        return DocumentUploadException(
          'An unexpected error occurred. Please try again.',
          type: DocumentUploadExceptionType.unknown,
        );
    }
  }
}

/// Exception types for document upload operations
enum DocumentUploadExceptionType {
  validation,
  network,
  timeout,
  server,
  client,
  compression,
  cancelled,
  unknown,
}

/// Custom exception for document upload operations
class DocumentUploadException implements Exception {
  final String message;
  final DocumentUploadExceptionType type;

  DocumentUploadException(this.message, {required this.type});

  @override
  String toString() => message;
}
