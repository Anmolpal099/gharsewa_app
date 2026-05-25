import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _sharedCacheManager = CacheManager();

final cacheManagerProvider = Provider<CacheManager>(
  (ref) => _sharedCacheManager,
);

/// Call once at app startup (after [Hive.initFlutter]).
Future<void> initializeProviderPanelCache() =>
    _sharedCacheManager.initializeHive();

/// Cache Manager for provider panel data with in-memory cache and Hive offline storage
/// 
/// Features:
/// - In-memory cache with 5-minute default expiration
/// - Automatic cache invalidation based on TTL
/// - Hive-based offline storage for Safety SOPs
/// - Cache hit/miss tracking for performance monitoring
class CacheManager {
  // ── Box names for Hive offline storage ────────────────────────
  static const String _safetySOPsBox = 'safety_sops';
  static const String _providerProfileBox = 'provider_profile_cache';
  static const String _metricsBox = 'metrics_cache';

  // ── Default cache expiration (5 minutes) ──────────────────────
  static const Duration defaultExpiration = Duration(minutes: 5);

  // ── In-memory cache storage ───────────────────────────────────
  final Map<String, _CacheEntry> _memoryCache = {};

  // ── Cache statistics ──────────────────────────────────────────
  int _hits = 0;
  int _misses = 0;

  // ── Hive initialization status ────────────────────────────────
  bool _isHiveInitialized = false;

  /// Initialize Hive for offline storage
  /// 
  /// This should be called during app startup to enable offline features.
  /// If initialization fails, the cache manager will still work with in-memory cache only.
  Future<void> initializeHive() async {
    if (_isHiveInitialized) return;

    try {
      // Initialize Hive (should be called after Hive.initFlutter() in main.dart)
      // Open boxes for offline storage
      await Hive.openBox(_safetySOPsBox);
      await Hive.openBox(_providerProfileBox);
      await Hive.openBox(_metricsBox);

      _isHiveInitialized = true;
    } catch (e) {
      // Log error but don't throw - app can still work with in-memory cache
      print('CacheManager: Failed to initialize Hive: $e');
      _isHiveInitialized = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // In-Memory Cache Operations
  // ══════════════════════════════════════════════════════════════

  /// Store data in memory cache with optional custom expiration
  /// 
  /// [key] - Unique identifier for the cached data
  /// [data] - Data to cache (must be JSON-serializable)
  /// [expiration] - Time-to-live for the cache entry (default: 5 minutes)
  void set(String key, dynamic data, {Duration? expiration}) {
    final ttl = expiration ?? defaultExpiration;
    final expiresAt = DateTime.now().add(ttl);

    _memoryCache[key] = _CacheEntry(
      data: data,
      expiresAt: expiresAt,
    );
  }

  /// Retrieve data from memory cache
  /// 
  /// Returns null if:
  /// - Key doesn't exist
  /// - Cache entry has expired
  /// 
  /// Automatically removes expired entries on access.
  T? get<T>(String key) {
    final entry = _memoryCache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _memoryCache.remove(key);
      _misses++;
      return null;
    }

    _hits++;
    return entry.data as T?;
  }

  /// Check if a key exists in cache and is not expired
  bool has(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _memoryCache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove a specific key from memory cache
  void remove(String key) {
    _memoryCache.remove(key);
  }

  /// Clear all memory cache entries
  void clearMemoryCache() {
    _memoryCache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Remove all expired entries from memory cache
  /// 
  /// This is useful for periodic cleanup to free memory.
  /// Returns the number of entries removed.
  int removeExpired() {
    final keysToRemove = <String>[];

    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }

    return keysToRemove.length;
  }

  /// Get cache statistics
  CacheStats get stats => CacheStats(
        hits: _hits,
        misses: _misses,
        size: _memoryCache.length,
        hitRate: _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0,
      );

  // ══════════════════════════════════════════════════════════════
  // Hive Offline Storage Operations
  // ══════════════════════════════════════════════════════════════

  /// Save Safety SOP to offline storage
  /// 
  /// Requirements: 19.1 - Store SOPs locally using Hive
  Future<void> saveSafetySOPOffline(String sopId, Map<String, dynamic> sopData) async {
    if (!_isHiveInitialized) {
      throw StateError('Hive not initialized. Call initializeHive() first.');
    }

    try {
      final box = Hive.box(_safetySOPsBox);
      await box.put(sopId, sopData);
    } catch (e) {
      throw Exception('Failed to save SOP offline: $e');
    }
  }

  /// Get Safety SOP from offline storage
  /// 
  /// Requirements: 19.2 - Display saved SOPs from local storage when offline
  Map<String, dynamic>? getSafetySOPOffline(String sopId) {
    if (!_isHiveInitialized) return null;

    try {
      final box = Hive.box(_safetySOPsBox);
      final data = box.get(sopId);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('CacheManager: Failed to get SOP offline: $e');
      return null;
    }
  }

  /// Get all Safety SOPs from offline storage
  /// 
  /// Requirements: 19.2 - Display all saved SOPs when offline
  List<Map<String, dynamic>> getAllSafetySOPsOffline() {
    if (!_isHiveInitialized) return [];

    try {
      final box = Hive.box(_safetySOPsBox);
      return box.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    } catch (e) {
      print('CacheManager: Failed to get all SOPs offline: $e');
      return [];
    }
  }

  /// Delete Safety SOP from offline storage
  /// 
  /// Requirements: 19.5 - Allow providers to delete saved SOPs
  Future<void> deleteSafetySOPOffline(String sopId) async {
    if (!_isHiveInitialized) return;

    try {
      final box = Hive.box(_safetySOPsBox);
      await box.delete(sopId);
    } catch (e) {
      print('CacheManager: Failed to delete SOP offline: $e');
    }
  }

  /// Clear all Safety SOPs from offline storage
  Future<void> clearSafetySOPsOffline() async {
    if (!_isHiveInitialized) return;

    try {
      final box = Hive.box(_safetySOPsBox);
      await box.clear();
    } catch (e) {
      print('CacheManager: Failed to clear SOPs offline: $e');
    }
  }

  /// Save provider profile to offline storage for instant display
  /// 
  /// Requirements: 28.2 - Cache profile data locally to display instantly
  Future<void> saveProfileOffline(String providerId, Map<String, dynamic> profileData) async {
    if (!_isHiveInitialized) return;

    try {
      final box = Hive.box(_providerProfileBox);
      await box.put(providerId, {
        'data': profileData,
        'cachedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('CacheManager: Failed to save profile offline: $e');
    }
  }

  /// Get provider profile from offline storage
  /// 
  /// Requirements: 28.2 - Display cached profile instantly on subsequent loads
  Map<String, dynamic>? getProfileOffline(String providerId) {
    if (!_isHiveInitialized) return null;

    try {
      final box = Hive.box(_providerProfileBox);
      final cached = box.get(providerId);
      if (cached == null) return null;

      final data = Map<String, dynamic>.from(cached as Map);
      return Map<String, dynamic>.from(data['data'] as Map);
    } catch (e) {
      print('CacheManager: Failed to get profile offline: $e');
      return null;
    }
  }

  /// Save performance metrics to offline storage
  /// 
  /// Requirements: 28.2 - Cache metrics for instant display
  Future<void> saveMetricsOffline(String providerId, Map<String, dynamic> metricsData) async {
    if (!_isHiveInitialized) return;

    try {
      final box = Hive.box(_metricsBox);
      await box.put(providerId, {
        'data': metricsData,
        'cachedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('CacheManager: Failed to save metrics offline: $e');
    }
  }

  /// Get performance metrics from offline storage
  Map<String, dynamic>? getMetricsOffline(String providerId) {
    if (!_isHiveInitialized) return null;

    try {
      final box = Hive.box(_metricsBox);
      final cached = box.get(providerId);
      if (cached == null) return null;

      final data = Map<String, dynamic>.from(cached as Map);
      return Map<String, dynamic>.from(data['data'] as Map);
    } catch (e) {
      print('CacheManager: Failed to get metrics offline: $e');
      return null;
    }
  }

  /// Clear all offline storage
  Future<void> clearAllOfflineStorage() async {
    if (!_isHiveInitialized) return;

    try {
      await Hive.box(_safetySOPsBox).clear();
      await Hive.box(_providerProfileBox).clear();
      await Hive.box(_metricsBox).clear();
    } catch (e) {
      print('CacheManager: Failed to clear offline storage: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Utility Methods
  // ══════════════════════════════════════════════════════════════

  /// Check if Hive is initialized and offline storage is available
  bool get isOfflineStorageAvailable => _isHiveInitialized;

  /// Get the number of items in offline storage
  int getOfflineStorageSize() {
    if (!_isHiveInitialized) return 0;

    try {
      final sopsCount = Hive.box(_safetySOPsBox).length;
      final profilesCount = Hive.box(_providerProfileBox).length;
      final metricsCount = Hive.box(_metricsBox).length;
      return sopsCount + profilesCount + metricsCount;
    } catch (e) {
      return 0;
    }
  }

  /// Dispose and close all Hive boxes
  Future<void> dispose() async {
    if (!_isHiveInitialized) return;

    try {
      await Hive.box(_safetySOPsBox).close();
      await Hive.box(_providerProfileBox).close();
      await Hive.box(_metricsBox).close();
      _isHiveInitialized = false;
    } catch (e) {
      print('CacheManager: Failed to dispose: $e');
    }
  }
}

// ══════════════════════════════════════════════════════════════
// Internal Classes
// ══════════════════════════════════════════════════════════════

/// Internal cache entry with expiration tracking
class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache statistics for monitoring performance
class CacheStats {
  final int hits;
  final int misses;
  final int size;
  final double hitRate;

  CacheStats({
    required this.hits,
    required this.misses,
    required this.size,
    required this.hitRate,
  });

  @override
  String toString() {
    return 'CacheStats(hits: $hits, misses: $misses, size: $size, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
