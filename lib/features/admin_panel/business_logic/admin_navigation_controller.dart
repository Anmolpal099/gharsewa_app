import '../../../core/constants/route_constants.dart';

class AdminNavItem {
  final String label;
  final String route;
  final int iconIndex;

  const AdminNavItem({
    required this.label,
    required this.route,
    required this.iconIndex,
  });
}

/// Admin sidebar / rail destinations (Tasks 8.1.2–8.1.3).
class AdminNavigationController {
  static const items = [
    AdminNavItem(
      label: 'Dashboard',
      route: RouteConstants.adminDashboard,
      iconIndex: 0,
    ),
    AdminNavItem(
      label: 'Users',
      route: RouteConstants.adminUsers,
      iconIndex: 1,
    ),
    AdminNavItem(
      label: 'Bookings',
      route: RouteConstants.adminBookings,
      iconIndex: 2,
    ),
    AdminNavItem(
      label: 'Reports',
      route: RouteConstants.adminReports,
      iconIndex: 3,
    ),
  ];

  static int indexForLocation(String location) {
    if (location.startsWith(RouteConstants.adminUsers)) return 1;
    if (location.startsWith(RouteConstants.adminBookings)) return 2;
    if (location.startsWith(RouteConstants.adminReports)) return 3;
    return 0;
  }

  static String titleForLocation(String location) {
    if (location.startsWith(RouteConstants.adminUsers)) {
      return location.contains('/users/') && !location.endsWith('/users')
          ? 'User Details'
          : 'User Management';
    }
    if (location.startsWith(RouteConstants.adminBookings)) {
      return 'Booking Oversight';
    }
    if (location.startsWith(RouteConstants.adminReports)) {
      return 'Reports';
    }
    return 'Admin Dashboard';
  }
}
