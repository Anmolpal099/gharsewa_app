class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  // Auth
  static const String login = '/v1/auth/login';
  static const String register = '/v1/auth/register';
  static const String logout = '/v1/auth/logout';
  static const String me = '/v1/auth/me';

  // Customer
  static const String customerDashboard = '/v1/customer/dashboard';
  static const String customerServices = '/v1/customer/services';
  static const String customerBookings = '/v1/customer/bookings';
  static const String customerRecommendations = '/v1/customer/recommendations';

  // Provider
  static const String providerDashboard = '/v1/provider/dashboard';
  static const String providerBookings = '/v1/provider/bookings';
  static const String providerServices = '/v1/provider/services';
  static const String providerAnalytics = '/v1/provider/analytics';

  // Admin
  static const String adminDashboard = '/v1/admin/dashboard';
  static const String adminUsers = '/v1/admin/users';
  static const String adminBookings = '/v1/admin/bookings';
  static const String adminReports = '/v1/admin/reports';
}
