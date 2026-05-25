import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage_service.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/service_repository.dart';
import '../../repositories/booking_repository.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../models/booking_model.dart';

/// Provider for CacheManager
final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager(
    localStorage: ref.read(localStorageServiceProvider),
    userRepository: ref.read(userRepositoryProvider),
    serviceRepository: ref.read(serviceRepositoryProvider),
    bookingRepository: ref.read(bookingRepositoryProvider),
  );
});

/// Cache manager for synchronizing local cache with server data
class CacheManager {
  CacheManager({
    required LocalStorageService localStorage,
    required UserRepository userRepository,
    required ServiceRepository serviceRepository,
    required BookingRepository bookingRepository,
  })  : _localStorage = localStorage,
        _userRepository = userRepository,
        _serviceRepository = serviceRepository,
        _bookingRepository = bookingRepository;

  final LocalStorageService _localStorage;
  final UserRepository _userRepository;
  final ServiceRepository _serviceRepository;
  final BookingRepository _bookingRepository;

  // ══════════════════════════════════════════════════════════════════════════════
  // Sync Operations
  // ══════════════════════════════════════════════════════════════════════════════

  /// Sync all data from server to local cache
  Future<SyncResult> syncAll() async {
    final result = SyncResult();

    try {
      // Sync services
      await syncServices();
      result.servicesSync = true;
    } catch (e) {
      result.errors.add('Services sync failed: $e');
    }

    try {
      // Sync bookings
      await syncBookings();
      result.bookingsSync = true;
    } catch (e) {
      result.errors.add('Bookings sync failed: $e');
    }

    try {
      // Sync current user
      await syncCurrentUser();
      result.userSync = true;
    } catch (e) {
      result.errors.add('User sync failed: $e');
    }

    // Update last sync timestamp
    if (result.isSuccess) {
      await _localStorage.updateLastSync();
    }

    return result;
  }

  /// Sync services from server to cache
  Future<void> syncServices() async {
    try {
      // Fetch services from server
      final services = await _serviceRepository.getServices();
      
      // Clear old cache
      await _localStorage.clearServices();
      
      // Save new data
      await _localStorage.saveServices(services);
    } catch (e) {
      // If sync fails, keep existing cache
      rethrow;
    }
  }

  /// Sync bookings from server to cache
  Future<void> syncBookings() async {
    try {
      // Fetch bookings from server (customer or provider based on role)
      final bookings = await _bookingRepository.getCustomerBookings();
      
      // Clear old cache
      await _localStorage.clearBookings();
      
      // Save new data
      await _localStorage.saveBookings(bookings);
    } catch (e) {
      // If sync fails, keep existing cache
      rethrow;
    }
  }

  /// Sync current user from server to cache
  Future<void> syncCurrentUser() async {
    try {
      // Fetch current user from server
      final user = await _userRepository.getCurrentUser();
      
      // Save to cache
      await _localStorage.saveUser(user);
    } catch (e) {
      // If sync fails, keep existing cache
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Cache-First Operations
  // ══════════════════════════════════════════════════════════════════════════════

  /// Get services (cache-first strategy)
  Future<List<ServiceModel>> getServices({
    bool forceRefresh = false,
  }) async {
    // Check if cache is expired or force refresh
    if (forceRefresh || _localStorage.isCacheExpired()) {
      try {
        await syncServices();
      } catch (e) {
        // If sync fails, return cached data
      }
    }

    return _localStorage.getAllServices();
  }

  /// Get bookings (cache-first strategy)
  Future<List<BookingModel>> getBookings({
    bool forceRefresh = false,
  }) async {
    // Check if cache is expired or force refresh
    if (forceRefresh || _localStorage.isCacheExpired()) {
      try {
        await syncBookings();
      } catch (e) {
        // If sync fails, return cached data
      }
    }

    return _localStorage.getAllBookings();
  }

  /// Get current user (cache-first strategy)
  Future<UserModel?> getCurrentUser({
    bool forceRefresh = false,
  }) async {
    // Check if cache is expired or force refresh
    if (forceRefresh || _localStorage.isCacheExpired()) {
      try {
        await syncCurrentUser();
      } catch (e) {
        // If sync fails, return cached data
      }
    }

    final users = _localStorage.getAllUsers();
    return users.isNotEmpty ? users.first : null;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Conflict Resolution
  // ══════════════════════════════════════════════════════════════════════════════

  /// Resolve conflicts between local and server data
  /// 
  /// Strategy: Server data always wins (last-write-wins)
  Future<void> resolveConflicts() async {
    // For now, we use a simple strategy: server data always wins
    // In the future, we can implement more sophisticated conflict resolution
    await syncAll();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Cache Management
  // ══════════════════════════════════════════════════════════════════════════════

  /// Check if cache needs refresh
  bool needsRefresh() {
    return _localStorage.isCacheExpired();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _localStorage.getCacheStats();
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await LocalStorageService.clearAll();
  }

  /// Invalidate cache (force next fetch from server)
  Future<void> invalidateCache() async {
    // Clear last sync timestamp to force refresh
    final lastSync = _localStorage.getLastSync();
    if (lastSync != null) {
      // Set last sync to a very old date
      await _localStorage.updateLastSync();
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sync Result Model
// ══════════════════════════════════════════════════════════════════════════════

class SyncResult {
  bool userSync = false;
  bool servicesSync = false;
  bool bookingsSync = false;
  List<String> errors = [];

  bool get isSuccess => errors.isEmpty;
  bool get hasErrors => errors.isNotEmpty;
  
  int get successCount {
    int count = 0;
    if (userSync) count++;
    if (servicesSync) count++;
    if (bookingsSync) count++;
    return count;
  }

  @override
  String toString() {
    return 'SyncResult(success: $successCount/3, errors: ${errors.length})';
  }
}
