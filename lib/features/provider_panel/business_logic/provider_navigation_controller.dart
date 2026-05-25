import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

final providerNavigationControllerProvider =
    ChangeNotifierProvider<ProviderNavigationController>((ref) {
  return ProviderNavigationController();
});

/// Drawer menu entry.
class ProviderDrawerItem {
  final String label;
  final IconData icon;
  final String route;

  const ProviderDrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Bottom-nav and drawer navigation for provider panel.
class ProviderNavigationController extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  static const _tabRoutes = [
    RouteConstants.providerDashboard,
    RouteConstants.providerBookings,
    RouteConstants.providerSafety,
    RouteConstants.providerProfile,
  ];

  static const drawerItems = [
    ProviderDrawerItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: RouteConstants.providerDashboard,
    ),
    ProviderDrawerItem(
      label: 'My Jobs',
      icon: Icons.work_outline,
      route: RouteConstants.providerBookings,
    ),
    ProviderDrawerItem(
      label: 'Earnings',
      icon: Icons.payments_outlined,
      route: RouteConstants.providerEarnings,
    ),
    ProviderDrawerItem(
      label: 'Skills & Profile',
      icon: Icons.verified_user_outlined,
      route: RouteConstants.providerProfile,
    ),
    ProviderDrawerItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: RouteConstants.providerSettings,
    ),
  ];

  static bool isTabRoute(String location) {
    return _tabRoutes.any((r) => location.startsWith(r));
  }

  bool isDrawerRouteSelected(String location, String route) {
    return location.startsWith(route);
  }

  String titleForLocation(String location) {
    if (location.startsWith(RouteConstants.providerBookings)) {
      return 'My Jobs';
    }
    if (location.startsWith(RouteConstants.providerEarnings)) {
      return 'Earnings';
    }
    if (location.startsWith(RouteConstants.providerProfile)) {
      return 'Skills & Profile';
    }
    if (location.startsWith(RouteConstants.providerSettings)) {
      return 'Settings';
    }
    if (location.startsWith(RouteConstants.providerSafety)) {
      return 'Safety';
    }
    if (location.startsWith(RouteConstants.providerSchedule)) {
      return 'Schedule';
    }
    if (location.startsWith(RouteConstants.providerServices)) {
      return 'Services';
    }
    if (location.startsWith(RouteConstants.providerSupport)) {
      return 'Support';
    }
    return 'Dashboard';
  }

  int indexForLocation(String location) {
    if (location.startsWith(RouteConstants.providerBookings)) return 1;
    if (location.startsWith(RouteConstants.providerSafety)) return 2;
    if (location.startsWith(RouteConstants.providerProfile)) return 3;
    return 0;
  }

  void syncFromLocation(String location) {
    final index = indexForLocation(location);
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void navigateToTab(BuildContext context, int index) {
    if (index < 0 || index >= _tabRoutes.length) return;
    _selectedIndex = index;
    notifyListeners();
    context.go(_tabRoutes[index]);
  }

  void navigateToScreen(BuildContext context, String route) {
    context.go(route);
    syncFromLocation(route);
  }

  bool canPop(BuildContext context) => context.canPop();

  void pop(BuildContext context) {
    if (context.canPop()) context.pop();
  }
}
