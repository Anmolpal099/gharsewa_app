import '../../services/auth/auth_state.dart';

/// Serializable auth snapshot for caching (Task 5.1.4).
class AuthenticationStateModel {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? name;
  final UserRole role;
  final List<UserRole> roles;
  final DateTime? lastLoginAt;

  const AuthenticationStateModel({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.name,
    this.role = UserRole.customer,
    this.roles = const [UserRole.customer],
    this.lastLoginAt,
  });

  factory AuthenticationStateModel.fromAuthState(AuthState state) {
    return AuthenticationStateModel(
      isAuthenticated: state.isAuthenticated,
      userId: state.user?.id,
      email: state.user?.email,
      name: state.user?.name,
      role: state.role,
      roles: state.user?.roles ?? [state.role],
      lastLoginAt: state.user?.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_authenticated': isAuthenticated,
        'user_id': userId,
        'email': email,
        'name': name,
        'role': role.name,
        'roles': roles.map((r) => r.name).toList(),
        'last_login_at': lastLoginAt?.toIso8601String(),
      };

  factory AuthenticationStateModel.fromJson(Map<String, dynamic> json) {
    return AuthenticationStateModel(
      isAuthenticated: json['is_authenticated'] as bool? ?? false,
      userId: json['user_id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      role: AuthState.roleFromString(json['role'] as String?),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => AuthState.roleFromString(e as String))
              .toList() ??
          [UserRole.customer],
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }
}
