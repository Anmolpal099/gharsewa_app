import '../../services/auth/auth_state.dart';

/// Panel configuration (Tasks 3.3.2, 5.1.4).
class PanelConfig {
  final PanelType type;
  final String rootRoute;
  final String title;
  final bool requiresWeb;

  const PanelConfig({
    required this.type,
    required this.rootRoute,
    required this.title,
    this.requiresWeb = false,
  });

  static PanelConfig forRole(UserRole role) {
    switch (role) {
      case UserRole.serviceProvider:
        return provider;
      case UserRole.admin:
        return admin;
      default:
        return customer;
    }
  }

  static const customer = PanelConfig(
    type: PanelType.customer,
    rootRoute: '/customer/home',
    title: 'Customer',
  );

  static const provider = PanelConfig(
    type: PanelType.provider,
    rootRoute: '/provider/dashboard',
    title: 'Provider',
  );

  static const admin = PanelConfig(
    type: PanelType.admin,
    rootRoute: '/admin/dashboard',
    title: 'Admin',
    requiresWeb: true,
  );
}

enum PanelType { customer, provider, admin }
