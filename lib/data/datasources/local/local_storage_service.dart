import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../models/booking_model.dart';

/// Provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Local storage service using Hive for offline data caching
class LocalStorageService {
  // Box names
  static const String _usersBox = 'users';
  static const String _servicesBox = 'services';
  static const String _bookingsBox = 'bookings';
  static const String _metadataBox = 'metadata';

  // Metadata keys
  static const String _lastSyncKey = 'last_sync';
  static const String _cacheExpiryKey = 'cache_expiry';

  // Cache expiry duration (24 hours)
  static const Duration _cacheExpiry = Duration(hours: 24);

  // ══════════════════════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════════════════════

  /// Initialize Hive and open all boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox<UserModel>(_usersBox);
    await Hive.openBox<ServiceModel>(_servicesBox);
    await Hive.openBox<BookingModel>(_bookingsBox);
    await Hive.openBox(_metadataBox);
  }

  /// Close all boxes
  static Future<void> close() async {
    await Hive.box<UserModel>(_usersBox).close();
    await Hive.box<ServiceModel>(_servicesBox).close();
    await Hive.box<BookingModel>(_bookingsBox).close();
    await Hive.box(_metadataBox).close();
  }

  /// Clear all cached data
  static Future<void> clearAll() async {
    await Hive.box<UserModel>(_usersBox).clear();
    await Hive.box<ServiceModel>(_servicesBox).clear();
    await Hive.box<BookingModel>(_bookingsBox).clear();
    await Hive.box(_metadataBox).clear();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // User Operations
  // ══════════════════════════════════════════════════════════════════════════════

  /// Save user to cache
  Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(_usersBox);
    await box.put(user.id, user);
  }

  /// Get user from cache
  UserModel? getUser(String userId) {
    final box = Hive.box<UserModel>(_usersBox);
    return box.get(userId);
  }

  /// Get all cached users
  List<UserModel> getAllUsers() {
    final box = Hive.box<UserModel>(_usersBox);
    return box.values.toList();
  }

  /// Delete user from cache
  Future<void> deleteUser(String userId) async {
    final box = Hive.box<UserModel>(_usersBox);
    await box.delete(userId);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Service Operations
  // ══════════════════════════════════════════════════════════════════════════════

  /// Save service to cache
  Future<void> saveService(ServiceModel service) async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    await box.put(service.id, service);
  }

  /// Save multiple services to cache
  Future<void> saveServices(List<ServiceModel> services) async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    final map = {for (var service in services) service.id: service};
    await box.putAll(map);
  }

  /// Get service from cache
  ServiceModel? getService(String serviceId) {
    final box = Hive.box<ServiceModel>(_servicesBox);
    return box.get(serviceId);
  }

  /// Get all cached services
  List<ServiceModel> getAllServices() {
    final box = Hive.box<ServiceModel>(_servicesBox);
    return box.values.toList();
  }

  /// Get services by category
  List<ServiceModel> getServicesByCategory(String category) {
    final box = Hive.box<ServiceModel>(_servicesBox);
    return box.values.where((s) => s.category == category).toList();
  }

  /// Search services by query
  List<ServiceModel> searchServices(String query) {
    final box = Hive.box<ServiceModel>(_servicesBox);
    final lowerQuery = query.toLowerCase();
    return box.values.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          s.description.toLowerCase().contains(lowerQuery) ||
          s.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Delete service from cache
  Future<void> deleteService(String serviceId) async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    await box.delete(serviceId);
  }

  /// Clear all services
  Future<void> clearServices() async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    await box.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Booking Operations
  // ══════════════════════════════════════════════════════════════════════════════

  /// Save booking to cache
  Future<void> saveBooking(BookingModel booking) async {
    final box = Hive.box<BookingModel>(_bookingsBox);
    await box.put(booking.id, booking);
  }

  /// Save multiple bookings to cache
  Future<void> saveBookings(List<BookingModel> bookings) async {
    final box = Hive.box<BookingModel>(_bookingsBox);
    final map = {for (var booking in bookings) booking.id: booking};
    await box.putAll(map);
  }

  /// Get booking from cache
  BookingModel? getBooking(String bookingId) {
    final box = Hive.box<BookingModel>(_bookingsBox);
    return box.get(bookingId);
  }

  /// Get all cached bookings
  List<BookingModel> getAllBookings() {
    final box = Hive.box<BookingModel>(_bookingsBox);
    return box.values.toList();
  }

  /// Get bookings by customer ID
  List<BookingModel> getCustomerBookings(String customerId) {
    final box = Hive.box<BookingModel>(_bookingsBox);
    return box.values.where((b) => b.customerId == customerId).toList();
  }

  /// Get bookings by provider ID
  List<BookingModel> getProviderBookings(String providerId) {
    final box = Hive.box<BookingModel>(_bookingsBox);
    return box.values.where((b) => b.providerId == providerId).toList();
  }

  /// Get bookings by status
  List<BookingModel> getBookingsByStatus(BookingStatus status) {
    final box = Hive.box<BookingModel>(_bookingsBox);
    return box.values.where((b) => b.status == status).toList();
  }

  /// Delete booking from cache
  Future<void> deleteBooking(String bookingId) async {
    final box = Hive.box<BookingModel>(_bookingsBox);
    await box.delete(bookingId);
  }

  /// Clear all bookings
  Future<void> clearBookings() async {
    final box = Hive.box<BookingModel>(_bookingsBox);
    await box.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Cache Metadata Operations
  // ══════════════════════════════════════════════════════════════════════════════

  /// Update last sync timestamp
  Future<void> updateLastSync() async {
    final box = Hive.box(_metadataBox);
    await box.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync timestamp
  DateTime? getLastSync() {
    final box = Hive.box(_metadataBox);
    final lastSyncStr = box.get(_lastSyncKey) as String?;
    return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
  }

  /// Check if cache is expired
  bool isCacheExpired() {
    final lastSync = getLastSync();
    if (lastSync == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference > _cacheExpiry;
  }

  /// Set custom cache expiry
  Future<void> setCacheExpiry(Duration duration) async {
    final box = Hive.box(_metadataBox);
    await box.put(_cacheExpiryKey, duration.inMilliseconds);
  }

  /// Get cache expiry duration
  Duration getCacheExpiry() {
    final box = Hive.box(_metadataBox);
    final expiryMs = box.get(_cacheExpiryKey) as int?;
    return expiryMs != null 
        ? Duration(milliseconds: expiryMs) 
        : _cacheExpiry;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Cache Statistics
  // ══════════════════════════════════════════════════════════════════════════════

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'users_count': Hive.box<UserModel>(_usersBox).length,
      'services_count': Hive.box<ServiceModel>(_servicesBox).length,
      'bookings_count': Hive.box<BookingModel>(_bookingsBox).length,
      'last_sync': getLastSync()?.toIso8601String(),
      'is_expired': isCacheExpired(),
      'cache_expiry_hours': getCacheExpiry().inHours,
    };
  }
}
