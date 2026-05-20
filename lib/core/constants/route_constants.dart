class RouteConstants {
  RouteConstants._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Customer
  static const String customerHome = '/customer/home';
  static const String customerServices = '/customer/services';
  static const String customerServiceDetail = '/customer/services/:id';
  static const String customerBooking = '/customer/booking/:serviceId';
  static const String customerBookings = '/customer/bookings';
  static const String customerProfile = '/customer/profile';

  // Provider
  static const String providerDashboard = '/provider/dashboard';
  static const String providerBookings = '/provider/bookings';
  static const String providerServices = '/provider/services';
  static const String providerAnalytics = '/provider/analytics';
  static const String providerProfile = '/provider/profile';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminBookings = '/admin/bookings';
  static const String adminReports = '/admin/reports';
}
