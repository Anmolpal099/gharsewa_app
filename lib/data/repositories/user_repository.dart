import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../services/api/api_client.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.read(apiClientProvider)),
);

class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;

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
  Future<String> uploadProfileImage(String filePath) async {
    // TODO: Implement multipart file upload
    // For now, return placeholder
    throw UnimplementedError('Profile image upload not yet implemented');
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
