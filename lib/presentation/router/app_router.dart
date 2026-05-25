import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/route_constants.dart';
import '../../core/config/platform_config.dart';
import '../../data/models/panel_config.dart';
import '../../presentation/panel_manager/panel_manager.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_state.dart';
import '../panels/customer/screens/service_list_screen.dart';

import '../panels/customer/screens/customer_home_screen.dart';
import '../panels/customer/screens/service_detail_screen.dart';
import '../panels/customer/screens/booking_screen.dart';
import '../panels/customer/screens/bookings_list_screen.dart';
import '../panels/customer/screens/booking_detail_screen.dart';
import '../panels/customer/screens/customer_profile_screen.dart';
import '../panels/customer/screens/edit_profile_screen.dart';
import '../panels/customer/screens/ai_assistant_screen.dart';
import '../../features/provider_panel/presentation/provider_panel_root.dart';
import '../../features/provider_panel/presentation/screens/modern_dashboard_screen.dart';
import '../../features/provider_panel/presentation/screens/provider_profile_screen.dart';
import '../../features/provider_panel/presentation/screens/safety_center_screen.dart';
import '../../features/provider_panel/presentation/screens/provider_schedule_screen.dart';
import '../../features/provider_panel/presentation/screens/provider_invoices_screen.dart';
import '../../features/provider_panel/presentation/screens/provider_support_screen.dart';
import '../../features/provider_panel/presentation/screens/provider_inventory_screen.dart';
import '../../features/provider_panel/presentation/screens/provider_earnings_screen.dart';
import '../../features/provider_panel/presentation/screens/provider_settings_screen.dart';
import '../panels/provider/screens/provider_bookings_screen.dart';
import '../panels/provider/screens/provider_services_screen.dart';
import '../../features/admin_panel/presentation/admin_panel_root.dart';
import '../../features/admin_panel/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin_panel/presentation/screens/users_list_screen.dart';
import '../../features/admin_panel/presentation/screens/user_detail_screen.dart';
import '../../features/admin_panel/presentation/screens/admin_bookings_screen.dart';
import '../../features/admin_panel/presentation/screens/reports_screen.dart';
import '../shared/screens/login_screen.dart';
import '../shared/screens/email_verification_screen.dart';
import '../shared/screens/splash_screen.dart';
import '../shared/screens/forgot_password_screen.dart';
import '../shared/screens/otp_input_screen.dart';
import '../shared/screens/new_password_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes to refresh router
  final authState = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    // Deep linking: paths work on web; mobile uses same route table (Task 3.2.4).
    refreshListenable: _AuthNotifier(ref),
    redirect: (context, state) {
      final auth = authState.value;
      final isLoading = authState.isLoading;
      final isLoggedIn = auth?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.splash ||
          state.matchedLocation == '/email-verification' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation.startsWith('/otp-input') ||
          state.matchedLocation == '/new-password';

      // Still loading — stay on splash
      if (isLoading) return null;

      // Not logged in — redirect to login (except auth routes)
      if (!isLoggedIn && !isAuthRoute) return RouteConstants.login;

      // Logged in — redirect from login/splash to correct panel
      // BUT allow OTP verification and password reset flows to complete
      if (isLoggedIn && 
          (state.matchedLocation == RouteConstants.login || 
           state.matchedLocation == RouteConstants.splash)) {
        // For users with multiple roles, prefer their primary role
        // Primary role is stored in the 'role' field
        switch (auth?.role) {
          case UserRole.serviceProvider:
            return RouteConstants.providerDashboard;
          case UserRole.admin:
            return RouteConstants.adminDashboard;
          default:
            return RouteConstants.customerHome;
        }
      }

      // Allow users with multiple roles to access any panel they have access to
      final isProviderRoute = state.matchedLocation.startsWith('/provider');
      if (isProviderRoute && auth?.user != null && !(auth?.user?.isServiceProvider ?? false)) {
        // User trying to access provider panel without provider role
        return RouteConstants.customerHome;
      }

      // Platform guard: Admin panel is web-only
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      if (isAdminRoute && !PlatformConfig.current.supportsAdminPanel) {
        return RouteConstants.customerHome;
      }

      final panelManager = ref.read(panelManagerProvider);
      if (isProviderRoute && !panelManager.canAccess(PanelType.provider)) {
        return RouteConstants.customerHome;
      }
      if (isAdminRoute && !panelManager.canAccess(PanelType.admin)) {
        return RouteConstants.customerHome;
      }

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      GoRoute(
        path: '/otp-input',
        builder: (context, state) {
          final email = state.extra as String;
          final type = state.uri.queryParameters['type'] ?? 'email_verification';
          return OtpInputScreen(email: email, type: type);
        },
      ),
      
      GoRoute(
        path: '/new-password',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return NewPasswordScreen(data: data);
        },
      ),

      // ── Customer Panel ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.customerHome,
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: RouteConstants.customerServiceList,
            builder: (context, state) => const ServiceListScreen(),
          ),
          GoRoute(
            path: RouteConstants.customerBookings,
            builder: (context, state) => const BookingsListScreen(),
          ),
          GoRoute(
            path: RouteConstants.customerProfile,
            builder: (context, state) => const CustomerProfileScreen(),
          ),
          GoRoute(
            path: '/customer/services/:id',
            builder: (context, state) => ServiceDetailScreen(
              serviceId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/customer/booking/:serviceId',
            builder: (context, state) => BookingScreen(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: '/customer/bookings/:id',
            builder: (context, state) => BookingDetailScreen(
              bookingId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/customer/profile/edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),

      // ── AI Assistant (Full Screen - Outside Shell) ──────────────
      GoRoute(
        path: RouteConstants.customerAIAssistant,
        builder: (context, state) => const AIAssistantScreen(),
      ),

      // ── Provider Panel (Material 3 modernization) ───────────────
      ShellRoute(
        builder: (context, state, child) => ProviderPanelRoot(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.providerDashboard,
            builder: (context, state) => const ModernDashboardScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerBookings,
            builder: (context, state) => const ProviderBookingsScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerSafety,
            builder: (context, state) => const SafetyCenterScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerProfile,
            builder: (context, state) => const ProviderProfileScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerServices,
            builder: (context, state) => const ProviderServicesScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerSchedule,
            builder: (context, state) => const ProviderScheduleScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerInvoices,
            builder: (context, state) => const ProviderInvoicesScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerSupport,
            builder: (context, state) => const ProviderSupportScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerInventory,
            builder: (context, state) => const ProviderInventoryScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerEarnings,
            builder: (context, state) => const ProviderEarningsScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerSettings,
            builder: (context, state) => const ProviderSettingsScreen(),
          ),
        ],
      ),

      // ── Admin Panel (Web only) ───────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminPanelRoot(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.adminDashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: RouteConstants.adminUsers,
            builder: (context, state) => const UsersListScreen(),
          ),
          GoRoute(
            path: RouteConstants.adminUserDetail,
            builder: (context, state) => UserDetailScreen(
              userId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: RouteConstants.adminBookings,
            builder: (context, state) => const AdminBookingsScreen(),
          ),
          GoRoute(
            path: RouteConstants.adminReports,
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

// ── Shell widgets (bottom nav / sidebar wrappers) ─────────────────────────────

class CustomerShell extends ConsumerWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authServiceProvider);
    final user = authAsync.value?.user;

    return Scaffold(
      appBar: user?.hasMultipleRoles == true
          ? AppBar(
              title: const Text('Customer Panel'),
              actions: [
                // Role switcher button
                if (user?.isServiceProvider == true)
                  TextButton.icon(
                    onPressed: () => context.go(RouteConstants.providerDashboard),
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    label: const Text(
                      'Switch to Provider',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            )
          : null,
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome, size: 32), 
            label: 'AI Assistant',
          ),
          NavigationDestination(icon: Icon(Icons.store), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: 
              context.go(RouteConstants.customerHome);
            case 1: 
              context.go(RouteConstants.customerBookings);
            case 2: 
              context.go(RouteConstants.customerAIAssistant);
            case 3:
              // Store not implemented yet - show coming soon message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Store feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            case 4: 
              context.go(RouteConstants.customerProfile);
          }
        },
      ),
    );
  }
}

/// Notifies go_router to re-evaluate redirects when auth state changes
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authServiceProvider, (_, __) => notifyListeners());
  }
}
