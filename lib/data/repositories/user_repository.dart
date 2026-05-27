import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../services/api/api_client.dart';
import '../../core/models/platform_image.dart';
import '../../core/services/image_service.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.read(apiClientProvider)),
);

class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;
  final ImageService _imageService = ImageService();

  /// Get current user profile
  Future<UserModel> getCurrentUser() async {
    final res = await _api.get('/v1/auth/me');
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Get user by ID (admin only)
  Future<UserModel> getUserById(String id) async {
    final res = await _api.get('/v1/admin/users/$id');
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Update current user profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.put('/v1/auth/profile', data: data);
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Upload profile image
  Future<String> uploadProfileImage(
    PlatformImage image, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Convert PlatformImage to base64 for API transmission
      final base64String = await _imageService.imageToBase64(image);

      // Create form data with base64 image
      final formData = FormData.fromMap({
        'image': base64String,
      });

      // Upload with progress tracking
      final res = await _api.dio.post(
        '/v1/profile/image',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      // Extract image URL from response
      final data = res.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final imageUrl = data['data']['image_url'] ?? data['data']['url'];
        if (imageUrl != null) {
          return imageUrl as String;
        }
      }

      throw Exception('Failed to upload profile image');
    } on DioException catch (e) {
      // Handle Dio-specific errors
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Failed to upload profile image';
        throw Exception('Failed to upload profile image: $errorMessage');
      }
      throw Exception('Failed to upload profile image: ${e.message}');
    } catch (e) {
      // Handle image conversion errors and other exceptions
      if (e.toString().contains('Failed to convert image')) {
        throw Exception('Failed to process image: ${e.toString()}');
      }
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers({
    String? role,
    String? query,
    int? page,
    int? perPage,
  }) async {
    final res = await _api.get('/v1/admin/users', params: {
      if (role != null) 'role': role,
      if (query != null) 'q': query,
      if (page != null) 'page': page,
      if (perPage != null) 'per_page': perPage,
    });
    final data = res.data['data'] as List;
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Update user status (admin only)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _api.put('/v1/admin/users/$userId/status', data: {
      'is_active': isActive,
    });
  }

  /// Delete user (admin only)
  Future<void> deleteUser(String userId) async {
    await _api.delete('/v1/admin/users/$userId');
  }

  /// Reset user password (admin only)
  Future<void> resetUserPassword(String userId, String newPassword) async {
    await _api.post('/v1/admin/users/$userId/reset-password', data: {
      'new_password': newPassword,
    });
  }
}
