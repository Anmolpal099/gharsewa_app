import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api/api_client.dart';
import '../../../../core/models/platform_image.dart';
import '../../../../core/services/image_service.dart';
import '../models/certification.dart';

final providerUploadServiceProvider = Provider<ProviderUploadService>((ref) {
  return ProviderUploadService(
    ref.watch(apiClientProvider).dio,
  );
});

class ProviderUploadService {
  ProviderUploadService(this._dio);

  final Dio _dio;
  final ImageService _imageService = ImageService();

  Future<String> uploadProfilePhoto(
    PlatformImage image, {
    void Function(double progress)? onProgress,
  }) async {
    // Convert PlatformImage to base64
    final base64String = await _imageService.imageToBase64(image);

    // Upload with progress tracking
    final response = await _dio.post(
      '/v1/provider/profile/image',
      data: FormData.fromMap({
        'image': base64String,
      }),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      final imageUrl = body['data']['image_url'] ?? body['data']['url'];
      if (imageUrl != null) {
        return imageUrl as String;
      }
    }
    throw Exception(
      body is Map ? (body['message'] ?? 'Upload failed') : 'Upload failed',
    );
  }

  Future<Certification> uploadCertification(
    PlatformImage image,
    String name, {
    void Function(double progress)? onProgress,
  }) async {
    // Convert PlatformImage to base64
    final base64String = await _imageService.imageToBase64(image);

    final response = await _dio.post(
      '/v1/provider/certifications/upload',
      data: FormData.fromMap({
        'name': name,
        'document': base64String,
      }),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) onProgress(sent / total);
      },
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      return Certification.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(
      body is Map ? (body['message'] ?? 'Upload failed') : 'Upload failed',
    );
  }
}
