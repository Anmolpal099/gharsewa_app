import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

class LocalStorageService {
  static const _keyOnboarded = 'onboarded';
  static const _keyTheme = 'theme_mode';

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

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
