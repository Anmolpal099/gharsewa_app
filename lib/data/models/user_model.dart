import '../../services/auth/auth_state.dart';

class UserModel {
  final String id;
  /// Legacy Firebase UID or JWT subject — use [externalId].
  final String externalId;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.externalId,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        externalId: json['external_id'] as String? ??
            json['firebase_uid'] as String? ??
            json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: AuthState.roleFromString(json['role'] as String?),
        phoneNumber: json['phone_number'] as String?,
        profileImageUrl: json['profile_image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.parse(json['last_login_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'external_id': externalId,
        'email': email,
        'name': name,
        'role': role.name,
        'phone_number': phoneNumber,
        'profile_image_url': profileImageUrl,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
      };
}
