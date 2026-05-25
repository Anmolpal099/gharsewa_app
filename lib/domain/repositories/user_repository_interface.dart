import '../entities/user_entity.dart';

abstract class UserRepositoryInterface {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> updateProfile(Map<String, dynamic> data);
}
