import 'jwt_tokens.dart';

enum UserRole { customer, serviceProvider, admin }

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final JwtUser? user;
  final UserRole? role;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.role,
    this.errorMessage,
  });

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        role = null,
        errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        role = null,
        errorMessage = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  static UserRole roleFromString(String? role) {
    switch (role) {
      case 'serviceProvider': return UserRole.serviceProvider;
      case 'admin':           return UserRole.admin;
      default:                return UserRole.customer;
    }
  }
}
