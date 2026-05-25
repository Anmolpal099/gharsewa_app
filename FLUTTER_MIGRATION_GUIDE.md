# Flutter Migration Guide: Firebase to JWT Authentication

## Overview

This guide provides complete instructions to migrate your Flutter app from Firebase authentication to JWT-based authentication with Laravel backend.

**Status:** Backend complete (Tasks 1-7) ✅  
**Remaining:** Flutter refactoring (Tasks 8-9)

---

## Task 8: Refactor Flutter Auth Service

### Step 1: Update pubspec.yaml

Remove Firebase dependencies and add JWT decoder:

```yaml
dependencies:
  # Remove these:
  # firebase_core: ^2.24.0
  # firebase_auth: ^4.16.0
  
  # Keep these:
  flutter_secure_storage: ^9.0.0
  jwt_decoder: ^2.0.1
  dio: ^5.4.0
  flutter_riverpod: ^2.4.0
```

Run: `flutter pub get`

### Step 2: Create JWT Token Storage Service

**File:** `lib/services/auth/token_storage.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  static const _userDataKey = 'user_data';

  // Save tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiryTime = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .toIso8601String();
    
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _tokenExpiryKey, value: expiryTime),
    ]);
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Check if token is expired
  static Future<bool> isTokenExpired() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return true;
    
    final expiry = DateTime.parse(expiryStr);
    return DateTime.now().isAfter(expiry);
  }

  // Save user data
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }

  // Get user data
  static Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  // Clear all tokens
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

### Step 3: Update auth_service.dart

**File:** `lib/services/auth/auth_service.dart`

```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'jwt_tokens.dart';
import 'token_storage.dart';
import '../api/api_client.dart';

// Stream provider for auth state
final authServiceProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authActionsProvider);
  return authService.authStateChanges();
});

// Actions provider
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.read(apiClientProvider));
});

class AuthActions {
  AuthActions(this._apiClient);
  final ApiClient _apiClient;

  // Auth state stream
  Stream<AuthState> authStateChanges() async* {
    // Check if user is logged in
    final accessToken = await TokenStorage.getAccessToken();
    
    if (accessToken == null) {
      yield const AuthState.unauthenticated();
      return;
    }

    // Check if token is expired
    final isExpired = await TokenStorage.isTokenExpired();
    if (isExpired) {
      // Try to refresh token
      try {
        await refreshToken();
      } catch (e) {
        await TokenStorage.clearAll();
        yield const AuthState.unauthenticated();
        return;
      }
    }

    // Get user data
    final userDataStr = await TokenStorage.getUserData();
    if (userDataStr != null) {
      final userData = jsonDecode(userDataStr);
      final user = JwtUser.fromJson(userData);
      final role = AuthState.roleFromString(user.role);
      
      yield AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: role,
      );
    } else {
      yield const AuthState.unauthenticated();
    }
  }

  /// Register new user
  Future<void> register(String email, String password, String name) async {
    final response = await _apiClient.post('/v1/auth/jwt/register', data: {
      'name': name,
      'email': email.trim(),
      'password': password,
      'role': 'customer',
    });

    if (response.data['success'] == true) {
      // Registration successful, OTP sent
      // User will verify email in next step
    }
  }

  /// Verify email with OTP
  Future<void> verifyEmail(String email, String otp) async {
    final response = await _apiClient.post('/v1/auth/otp/verify-email', data: {
      'email': email.trim(),
      'otp': otp,
    });

    if (response.data['success'] == true) {
      final data = response.data['data'];
      
      // Save tokens
      await TokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );
      
      // Save user data
      await TokenStorage.saveUserData(jsonEncode(data['user']));
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    final response = await _apiClient.post('/v1/auth/jwt/login', data: {
      'email': email.trim(),
      'password': password,
    });

    if (response.data['success'] == true) {
      final data = response.data['data'];
      
      // Save tokens
      await TokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );
      
      // Save user data
      await TokenStorage.saveUserData(jsonEncode(data['user']));
    }
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _apiClient.post('/v1/auth/jwt/refresh', data: {
      'refresh_token': refreshToken,
    });

    if (response.data['success'] == true) {
      final data = response.data['data'];
      
      await TokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      await _apiClient.post('/v1/auth/jwt/logout', data: {
        'refresh_token': refreshToken,
      });
    } catch (e) {
      // Ignore errors, clear local storage anyway
    }
    
    await TokenStorage.clearAll();
  }

  /// Send password reset OTP
  Future<void> sendPasswordResetOtp(String email) async {
    await _apiClient.post('/v1/auth/otp/send-password-reset', data: {
      'email': email.trim(),
    });
  }

  /// Reset password with OTP
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _apiClient.post('/v1/auth/otp/reset-password', data: {
      'email': email.trim(),
      'otp': otp,
      'new_password': newPassword,
    });
  }

  /// Get current user
  Future<JwtUser?> getCurrentUser() async {
    final userDataStr = await TokenStorage.getUserData();
    if (userDataStr == null) return null;
    
    final userData = jsonDecode(userDataStr);
    return JwtUser.fromJson(userData);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getAccessToken();
    return token != null;
  }
}
```

### Step 4: Update API Client with Token Interceptor

**File:** `lib/services/api/api_client.dart`

Add token interceptor to automatically add JWT token to requests:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseURL: 'http://localhost:8000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add JWT token to headers
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized - token expired
        if (error.response?.statusCode == 401) {
          try {
            // Try to refresh token
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null) {
              final response = await _dio.post('/v1/auth/jwt/refresh', data: {
                'refresh_token': refreshToken,
              });

              if (response.data['success'] == true) {
                final data = response.data['data'];
                
                // Save new tokens
                await TokenStorage.saveTokens(
                  accessToken: data['access_token'],
                  refreshToken: data['refresh_token'],
                  expiresIn: data['expires_in'],
                );

                // Retry original request with new token
                error.requestOptions.headers['Authorization'] = 
                    'Bearer ${data['access_token']}';
                
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            }
          } catch (e) {
            // Refresh failed, clear tokens
            await TokenStorage.clearAll();
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
```

---

## Task 9: Update Flutter UI Screens

### Step 1: Update login_screen.dart

Remove Firebase-specific code and use new auth service:

**Changes needed:**
1. Remove `_isNavigatingToOtp` flag (no longer needed)
2. Update registration flow to navigate to OTP screen
3. Update login flow to use JWT
4. Remove Firebase auth state listener

**Key changes:**

```dart
// Registration
if (_isRegisterMode) {
  await actions.register(_emailController.text, _passwordController.text, _nameController.text);
  
  // Navigate to OTP verification
  if (mounted) {
    context.push('/otp-input?type=email_verification', extra: _emailController.text);
  }
} else {
  // Login
  await actions.signIn(_emailController.text, _passwordController.text);
  
  // Navigation will be handled by auth state listener
}
```

### Step 2: Update otp_input_screen.dart

Update to call new verify email endpoint:

```dart
Future<void> _verifyOtp() async {
  if (_otpController.text.length != 6) {
    _showError('Please enter 6-digit OTP');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final actions = ref.read(authActionsProvider);
    
    if (widget.type == 'email_verification') {
      await actions.verifyEmail(widget.email, _otpController.text);
      
      // Navigate to dashboard (auth state will update)
      if (mounted) {
        context.go('/customer/dashboard'); // or appropriate role dashboard
      }
    } else {
      // Password reset verification
      if (mounted) {
        context.push('/new-password', extra: {
          'email': widget.email,
          'otp': _otpController.text,
        });
      }
    }
  } catch (e) {
    _showError('Invalid or expired OTP');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Step 3: Update new_password_screen.dart

Update to use new password reset endpoint:

```dart
Future<void> _resetPassword() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final actions = ref.read(authActionsProvider);
    
    await actions.resetPassword(
      widget.email,
      widget.otp,
      _passwordController.text,
    );

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful! Please login.')),
      );
      
      // Navigate to login
      context.go('/login');
    }
  } catch (e) {
    _showError('Failed to reset password');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Step 4: Update forgot_password_screen.dart

Update to use new send OTP endpoint:

```dart
Future<void> _sendOtp() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final actions = ref.read(authActionsProvider);
    await actions.sendPasswordResetOtp(_emailController.text);

    if (mounted) {
      context.push('/otp-input?type=password_reset', extra: _emailController.text);
    }
  } catch (e) {
    _showError('Failed to send OTP');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Step 5: Update app_router.dart

Remove Firebase auth redirect logic:

```dart
// Remove Firebase-specific redirects
// Update to use JWT auth state

redirect: (context, state) {
  final authAsync = ref.read(authServiceProvider);
  
  return authAsync.when(
    data: (auth) {
      final isLoginRoute = state.matchedLocation == '/login';
      
      if (!auth.isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      
      if (auth.isAuthenticated && isLoginRoute) {
        // Redirect to appropriate dashboard based on role
        switch (auth.role) {
          case UserRole.serviceProvider:
            return '/provider/dashboard';
          case UserRole.admin:
            return '/admin/dashboard';
          default:
            return '/customer/dashboard';
        }
      }
      
      return null; // No redirect needed
    },
    loading: () => null,
    error: (_, __) => '/login',
  );
},
```

---

## Testing Checklist

After completing the migration:

### Backend Testing
- [ ] Test registration API
- [ ] Test OTP email delivery
- [ ] Test email verification
- [ ] Test login API
- [ ] Test rate limiting
- [ ] Test password reset flow
- [ ] Test token refresh

### Flutter Testing
- [ ] Test registration flow
- [ ] Test OTP verification
- [ ] Test login flow
- [ ] Test logout
- [ ] Test password reset
- [ ] Test token auto-refresh
- [ ] Test navigation after auth

---

## Common Issues & Solutions

### Issue: "No access token" error
**Solution:** Make sure tokens are saved after login/verification

### Issue: API calls return 401
**Solution:** Check token interceptor is working and tokens are valid

### Issue: Navigation not working after login
**Solution:** Ensure auth state stream is updating correctly

### Issue: OTP not received
**Solution:** Check Laravel logs and Gmail SMTP configuration

---

## Summary

**Completed:**
- ✅ Backend JWT authentication (Tasks 1-7)
- ✅ Gmail SMTP configuration
- ✅ All API endpoints working

**To Complete:**
- ⏳ Task 8: Refactor Flutter auth service (use this guide)
- ⏳ Task 9: Update Flutter UI screens (use this guide)
- ⏳ Task 10: Testing & validation

**Estimated Time:** 4-6 hours for Flutter tasks

---

*This guide provides complete implementation details. Follow step-by-step to migrate your Flutter app from Firebase to JWT authentication.*
