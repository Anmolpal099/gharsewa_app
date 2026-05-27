class RouteConstants {
  RouteConstants._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Customer
  static const String customerHome = '/customer/home';
  static const String customerServices = '/customer/services';
  static const String customerServiceList = '/customer/services-list';
  static const String customerServiceDetail = '/customer/services/:id';
  static const String customerBooking = '/customer/booking/:serviceId';
  static const String customerBookings = '/customer/bookings';
  static const String customerProfile = '/customer/profile';
  static const String customerAIAssistant = '/customer/ai-assistant';
  static const String customerAIImageCapture = '/customer/ai-assistant/capture';
  static const String customerAIAnnotation = '/customer/ai-assistant/annotate';
  static const String customerAIResults = '/customer/ai-assistant/results';
  static const String customerAIHistory = '/customer/ai-assistant/history';
  static const String customerAIConsultationDetail = '/customer/ai-assistant/consultations/:id';

  // Provider
  static const String providerDashboard = '/provider/dashboard';
  static const String providerBookings = '/provider/bookings';
  static const String providerServices = '/provider/services';
  static const String providerAnalytics = '/provider/analytics';
  static const String providerSafety = '/provider/safety';
  static const String providerProfile = '/provider/profile';
  static const String providerSchedule = '/provider/schedule';
  static const String providerInvoices = '/provider/invoices';
  static const String providerSupport = '/provider/support';
  static const String providerInventory = '/provider/inventory';
  static const String providerEarnings = '/provider/earnings';
  static const String providerSettings = '/provider/settings';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminBookings = '/admin/bookings';
  static const String adminReports = '/admin/reports';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminProfile = '/admin/profile';
  static const String adminSettings = '/admin/settings';
  static const String adminManagement = '/admin/management';
}
