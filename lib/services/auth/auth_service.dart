// DEPRECATED: This file is kept for backward compatibility
// Use jwt_auth_service.dart instead
//
// This file re-exports the new JWT auth service with the old provider names
// to maintain compatibility with existing code.

export 'jwt_auth_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'jwt_auth_service.dart';
import 'jwt_tokens.dart';

// ── Backward compatibility providers ──────────────────────────────────────────

/// DEPRECATED: Use authStateProvider from jwt_auth_service.dart
/// 
/// Stream provider: listens to JWT auth state changes
@Deprecated('Use authStateProvider from jwt_auth_service.dart')
final authServiceProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(jwtAuthServiceProvider);
  return authService.authStateChanges;
});

/// DEPRECATED: Use jwtAuthServiceProvider from jwt_auth_service.dart
/// 
/// Actions provider for backward compatibility
@Deprecated('Use jwtAuthServiceProvider from jwt_auth_service.dart')
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.watch(jwtAuthServiceProvider));
});

/// DEPRECATED: Use JwtAuthService directly
/// 
/// Wrapper class for backward compatibility with existing code
@Deprecated('Use JwtAuthService from jwt_auth_service.dart')
class AuthActions {
  AuthActions(this._authService);
  final JwtAuthService _authService;

  /// Stream of authentication state changes
  Stream<AuthState> authStateChanges() => _authService.authStateChanges;

  /// Register new user
  Future<void> register(String email, String password, String name, {String? role}) async {
    await _authService.register(
      email: email,
      password: password,
      name: name,
      role: role ?? 'customer', // Default to 'customer' if null
    );
  }

  /// Verify email with OTP
  Future<void> verifyEmail(String email, String otp) async {
    await _authService.verifyEmail(email: email, otp: otp);
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    await _authService.login(email: email, password: password);
  }

  /// Refresh access token using refresh token
  Future<void> refreshToken() async {
    await _authService.refreshToken();
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.logout();
  }

  /// Send password reset OTP
  Future<void> sendPasswordResetOtp(String email) async {
    await _authService.sendPasswordResetOtp(email);
  }

  /// Reset password with OTP
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _authService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  /// Get current user
  Future<JwtUser?> getCurrentUser() async {
    return await _authService.getCurrentUser();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  /// Upgrade customer account to service provider
  Future<void> becomeServiceProvider() async {
    await _authService.becomeServiceProvider();
  }
}
