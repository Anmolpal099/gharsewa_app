class AppConstants {
  AppConstants._();

  static const String appName = 'Gharsewa';
  static const String appVersion = '1.0.0';

  // API
  static const String apiVersion = 'v1';
  static const int apiTimeoutMs = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const int cacheExpiryHours = 24;

  // Booking
  static const int minCancellationHours = 24;
}
