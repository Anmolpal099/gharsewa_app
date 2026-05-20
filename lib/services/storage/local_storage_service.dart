import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

/// Local storage service using Hive for caching and SharedPreferences for settings
class LocalStorageService {
  // ── Box names ─────────────────────────────────────────────────
  static const _servicesBox  = 'services_cache';
  static const _bookingsBox  = 'bookings_cache';
  static const _settingsBox  = 'settings';

  // ── Settings keys ─────────────────────────────────────────────
  static const _keyOnboarded  = 'onboarded';
  static const _keyTheme      = 'theme_mode';
  static const _keyLastSync   = 'last_sync';

  // ── Hive boxes ────────────────────────────────────────────────
  Box get _services  => Hive.box(_servicesBox);
  Box get _bookings  => Hive.box(_bookingsBox);
  Box get _settings  => Hive.box(_settingsBox);

  // ── Services Cache ────────────────────────────────────────────

  Future<void> cacheServices(List<Map<String, dynamic>> services) async {
    await _services.clear();
    for (final service in services) {
      await _services.put(service['id'], jsonEncode(service));
    }
    await _updateLastSync('services');
  }

  List<Map<String, dynamic>> getCachedServices() {
    return _services.values
        .map((v) => jsonDecode(v as String) as Map<String, dynamic>)
        .toList();
  }

  // ── Bookings Cache ────────────────────────────────────────────

  Future<void> cacheBookings(List<Map<String, dynamic>> bookings) async {
    await _bookings.clear();
    for (final booking in bookings) {
      await _bookings.put(booking['id'], jsonEncode(booking));
    }
    await _updateLastSync('bookings');
  }

  List<Map<String, dynamic>> getCachedBookings() {
    return _bookings.values
        .map((v) => jsonDecode(v as String) as Map<String, dynamic>)
        .toList();
  }

  // ── Cache Sync Logic ──────────────────────────────────────────

  Future<void> _updateLastSync(String key) async {
    await _settings.put('${_keyLastSync}_$key', DateTime.now().toIso8601String());
  }

  DateTime? getLastSync(String key) {
    final value = _settings.get('${_keyLastSync}_$key') as String?;
    return value != null ? DateTime.tryParse(value) : null;
  }

  /// Returns true if cache is stale (older than [maxAgeHours])
  bool isCacheStale(String key, {int maxAgeHours = 1}) {
    final lastSync = getLastSync(key);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inHours >= maxAgeHours;
  }

  Future<void> clearCache() async {
    await _services.clear();
    await _bookings.clear();
  }

  // ── Settings (SharedPreferences) ─────────────────────────────

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isOnboarded() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  Future<void> setOnboarded() async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboarded, true);
  }

  Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyTheme) ?? 'light';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyTheme, mode);
  }

  Future<void> clearAll() async {
    await clearCache();
    final prefs = await _prefs;
    await prefs.clear();
  }
}
