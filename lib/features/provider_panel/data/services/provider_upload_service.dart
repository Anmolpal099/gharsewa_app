import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api/api_client.dart';
import '../models/certification.dart';
import 'document_uploader.dart';

final providerUploadServiceProvider = Provider<ProviderUploadService>((ref) {
  return ProviderUploadService(
    DocumentUploader(ref.watch(apiClientProvider).dio),
    ref.watch(apiClientProvider).dio,
  );
});

class ProviderUploadService {
  ProviderUploadService(this._uploader, this._dio);

  final DocumentUploader _uploader;
  final Dio _dio;

  Future<String> uploadProfilePhoto(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    if (!_uploader.validateFileType(file, ['png', 'jpg', 'jpeg'])) {
      throw DocumentUploadException(
        'Profile photo must be PNG or JPG',
        type: DocumentUploadExceptionType.validation,
      );
    }
    if (!await _uploader.validateFileSize(file, 2 * 1024 * 1024)) {
      throw DocumentUploadException(
        'Image must be under 2MB',
        type: DocumentUploadExceptionType.validation,
      );
    }

    var uploadFile = file;
    try {
      uploadFile = await _uploader.compressImage(file);
    } catch (_) {}

    return _uploader.uploadFile(
      uploadFile,
      '/v1/profile/image',
      fieldName: 'image',
      onProgress: onProgress,
    );
  }

  Future<Certification> uploadCertification(
    File file,
    String name, {
    void Function(double progress)? onProgress,
  }) async {
    if (!_uploader.validateFileType(file, ['pdf', 'png', 'jpg', 'jpeg'])) {
      throw DocumentUploadException(
        'Allowed formats: PDF, PNG, JPG',
        type: DocumentUploadExceptionType.validation,
      );
    }
    if (!await _uploader.validateFileSize(file, 10 * 1024 * 1024)) {
      throw DocumentUploadException(
        'File must be under 10MB',
        type: DocumentUploadExceptionType.validation,
      );
    }

    var uploadFile = file;
    final ext = file.path.split('.').last.toLowerCase();
    if (['png', 'jpg', 'jpeg'].contains(ext)) {
      try {
        uploadFile = await _uploader.compressImage(file);
      } catch (_) {}
    }

    final multipart = await MultipartFile.fromFile(
      uploadFile.path,
      filename: uploadFile.path.split(Platform.pathSeparator).last,
    );

    final response = await _dio.post(
      '/v1/provider/certifications/upload',
      data: FormData.fromMap({'name': name, 'document': multipart}),
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
