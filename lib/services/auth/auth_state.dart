import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { customer, serviceProvider, admin }

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? firebaseUser;
  final UserRole? role;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.firebaseUser,
    this.role,
    this.errorMessage,
  });

  const AuthState.loading()
      : status = AuthStatus.loading,
        firebaseUser = null,
        role = null,
        errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        firebaseUser = null,
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
