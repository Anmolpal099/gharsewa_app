import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for JWT tokens
/// 
/// Stores access tokens, refresh tokens, and user data securely.
/// Uses SharedPreferences for web and FlutterSecureStorage for mobile/desktop.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  static const _userDataKey = 'user_data';

  /// Save JWT tokens securely
  /// 
  /// [accessToken] - JWT access token from backend
  /// [refreshToken] - Refresh token for getting new access tokens
  /// [expiresIn] - Token expiry time in seconds
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiryTime = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .toIso8601String();
    
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_accessTokenKey, accessToken),
        prefs.setString(_refreshTokenKey, refreshToken),
        prefs.setString(_tokenExpiryKey, expiryTime),
      ]);
    } else {
      // Use FlutterSecureStorage for mobile/desktop
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
        _storage.write(key: _tokenExpiryKey, value: expiryTime),
      ]);
    }
  }

  /// Get stored access token
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } else {
      return await _storage.read(key: _accessTokenKey);
    }
  }

  /// Get stored refresh token
  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } else {
      return await _storage.read(key: _refreshTokenKey);
    }
  }

  /// Check if the stored token is expired
  static Future<bool> isTokenExpired() async {
    String? expiryStr;
    
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      expiryStr = prefs.getString(_tokenExpiryKey);
    } else {
      expiryStr = await _storage.read(key: _tokenExpiryKey);
    }
    
    if (expiryStr == null) return true;
    
    try {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true; // If parsing fails, consider expired
    }
  }

  /// Save user data as JSON string
  static Future<void> saveUserData(String userData) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, userData);
    } else {
      await _storage.write(key: _userDataKey, value: userData);
    }
  }

  /// Get stored user data
  static Future<String?> getUserData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userDataKey);
    } else {
      return await _storage.read(key: _userDataKey);
    }
  }

  /// Clear all stored tokens and user data
  /// 
  /// Call this on logout or when tokens are invalid
  static Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
        prefs.remove(_tokenExpiryKey),
        prefs.remove(_userDataKey),
      ]);
    } else {
      await _storage.deleteAll();
    }
  }
}
