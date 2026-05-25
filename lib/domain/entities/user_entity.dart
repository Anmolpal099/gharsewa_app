import '../../services/auth/auth_state.dart';

class UserEntity {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
  });
}
