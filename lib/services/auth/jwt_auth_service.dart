import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'jwt_tokens.dart';
import 'token_storage.dart';
import '../api/api_client.dart';

/// JWT Authentication Service
/// 
/// Handles all authentication operations using JWT tokens:
/// - User registration and email verification
/// - Login with email/password
/// - Token refresh and automatic token management
/// - Logout and session cleanup
/// - Password reset flow
class JwtAuthService {
  JwtAuthService(this._apiClient);
  
  final ApiClient _apiClient;
  
  // Stream controller for auth state changes
  final _authStateController = StreamController<AuthState>.broadcast();

  /// Stream of authentication state changes
  /// 
  /// Emits new state when:
  /// - User logs in
  /// - User logs out
  /// - Token is refreshed
  /// - Initial auth check completes
  Stream<AuthState> get authStateChanges async* {
    // Check initial auth state
    yield await _getCurrentAuthState();
    
    // Listen to future state changes
    yield* _authStateController.stream;
  }

  /// Get current authentication state
  /// 
  /// Checks stored tokens and validates expiry.
  /// Attempts token refresh if expired.
  Future<AuthState> _getCurrentAuthState() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      
      if (accessToken == null) {
        return const AuthState.unauthenticated();
      }

      // Check if token is expired
      final isExpired = await TokenStorage.isTokenExpired();
      if (isExpired) {
        // Try to refresh token
        try {
          await refreshToken();
        } catch (e) {
          await TokenStorage.clearAll();
          return const AuthState.unauthenticated();
        }
      }

      // Get user data
      final userDataStr = await TokenStorage.getUserData();
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        final user = JwtUser.fromJson(userData);
        final role = AuthState.roleFromString(user.role);
        
        return AuthState(
          status: AuthStatus.authenticated,
          user: user,
          role: role,
        );
      } else {
        return const AuthState.unauthenticated();
      }
    } catch (e) {
      return const AuthState.unauthenticated();
    }
  }

  /// Notify listeners of auth state change
  Future<void> _notifyAuthStateChanged() async {
    final state = await _getCurrentAuthState();
    _authStateController.add(state);
  }

  /// Register new user
  /// 
  /// Creates a new user account and sends OTP to email for verification.
  /// User must verify email before they can log in.
  /// 
  /// [email] - User's email address
  /// [password] - User's password (min 8 characters)
  /// [name] - User's full name
  /// [role] - User role (defaults to 'customer')
  /// 
  /// Throws [Exception] if registration fails
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String role = 'customer',
  }) async {
    try {
      final response = await _apiClient.post('/v1/auth/jwt/register', data: {
        'name': name,
        'email': email.trim(),
        'password': password,
        'role': role,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
      
      // Registration successful, OTP sent to email
      // User will verify email in next step
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Registration failed';
        throw Exception(message);
      }
      rethrow;
    }
  }

  /// Verify email with OTP
  /// 
  /// After successful verification, user is automatically logged in
  /// and JWT tokens are stored.
  /// 
  /// [email] - User's email address
  /// [otp] - 6-digit OTP code sent to email
  /// 
  /// Throws [Exception] if verification fails
  Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post('/v1/auth/otp/verify-email', data: {
        'email': email.trim(),
        'otp': otp,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Verification failed');
      }

      final data = response.data['data'];
      
      // Save tokens
      await TokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );
      
      // Save user data
      await TokenStorage.saveUserData(jsonEncode(data['user']));
      
      // Notify auth state changed
      await _notifyAuthStateChanged();
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Verification failed';
        throw Exception(message);
      }
      rethrow;
    }
  }

  /// Login with email and password
  /// 
  /// Authenticates user and stores JWT tokens.
  /// Access token expires in 1 hour, refresh token in 30 days.
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Throws [Exception] if login fails
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post('/v1/auth/jwt/login', data: {
        'email': email.trim(),
        'password': password,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Login failed');
      }

      final data = response.data['data'];
      
      // Save tokens
      await TokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );
      
      // Save user data
      await TokenStorage.saveUserData(jsonEncode(data['user']));
      
      // Notify auth state changed
      await _notifyAuthStateChanged();
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Login failed';
        throw Exception(message);
      }
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  /// 
  /// Called automatically by TokenInterceptor when access token expires.
  /// Can also be called manually to proactively refresh token.
  /// 
  /// Throws [Exception] if refresh fails (user must log in again)
  Future<void> refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _apiClient.post('/v1/auth/jwt/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.data['success'] != true) {
        throw Exception('Token refresh failed');
      }

      final data = response.data['data'];
      
      // Save new tokens
      await TokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );
      
      // Notify auth state changed (token refreshed)
      await _notifyAuthStateChanged();
    } catch (e) {
      // Clear tokens on refresh failure
      await TokenStorage.clearAll();
      await _notifyAuthStateChanged();
      
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Token refresh failed';
        throw Exception(message);
      }
      rethrow;
    }
  }

  /// Logout current user
  /// 
  /// Invalidates refresh token on backend and clears all local storage.
  /// Always succeeds locally even if backend call fails.
  Future<void> logout() async {
    try {
      // Try to call logout endpoint to invalidate refresh token
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          await _apiClient.post('/v1/auth/jwt/logout', data: {
            'refresh_token': refreshToken,
          });
        } catch (e) {
          // Ignore API errors during logout (token might be expired)
          // We'll clear local storage anyway
        }
      }
    } catch (e) {
      // Ignore all errors during logout
    } finally {
      // Always clear local storage, even if API call fails
      await TokenStorage.clearAll();
      
      // Notify auth state changed
      await _notifyAuthStateChanged();
    }
  }

  /// Send password reset OTP to email
  /// 
  /// [email] - User's email address
  /// 
  /// Throws [Exception] if email not found or send fails
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      final response = await _apiClient.post('/v1/auth/otp/send-password-reset', data: {
        'email': email.trim(),
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Failed to send OTP';
        throw Exception(message);
      }
      rethrow;
    }
  }

  /// Reset password with OTP
  /// 
  /// Verifies OTP and updates password.
  /// All existing refresh tokens are invalidated.
  /// 
  /// [email] - User's email address
  /// [otp] - 6-digit OTP code sent to email
  /// [newPassword] - New password (min 8 characters)
  /// 
  /// Throws [Exception] if OTP invalid or reset fails
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post('/v1/auth/otp/reset-password', data: {
        'email': email.trim(),
        'otp': otp,
        'new_password': newPassword,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Password reset failed';
        throw Exception(message);
      }
      rethrow;
    }
  }

  /// Get current authenticated user
  /// 
  /// Returns null if not authenticated
  Future<JwtUser?> getCurrentUser() async {
    final userDataStr = await TokenStorage.getUserData();
    if (userDataStr == null) return null;
    
    try {
      final userData = jsonDecode(userDataStr);
      return JwtUser.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is currently logged in
  /// 
  /// Returns true if valid access token exists
  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return false;
    
    // Check if token is expired
    final isExpired = await TokenStorage.isTokenExpired();
    return !isExpired;
  }

  /// Upgrade customer account to service provider
  /// 
  /// Allows existing customers to become service providers.
  /// User will have both 'customer' and 'serviceProvider' roles.
  /// 
  /// Throws [Exception] if upgrade fails or user is already a provider
  Future<void> becomeServiceProvider() async {
    try {
      final response = await _apiClient.post('/v1/auth/jwt/become-service-provider');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to become service provider');
      }

      final userData = response.data['data'];
      
      // Update stored user data with new roles
      await TokenStorage.saveUserData(jsonEncode(userData));
      
      // Notify auth state changed
      await _notifyAuthStateChanged();
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Failed to become service provider';
        throw Exception(message);
      }
      rethrow;
    }
  }

  /// Dispose stream controller
  /// 
  /// Call this when service is no longer needed
  void dispose() {
    _authStateController.close();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

/// Provider for JWT Auth Service instance
final jwtAuthServiceProvider = Provider<JwtAuthService>((ref) {
  final service = JwtAuthService(ref.read(apiClientProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for authentication state
/// 
/// Listen to this provider to react to auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(jwtAuthServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current authenticated user
/// 
/// Returns null if not authenticated
final currentUserProvider = FutureProvider<JwtUser?>((ref) async {
  final authService = ref.watch(jwtAuthServiceProvider);
  return authService.getCurrentUser();
});
