import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/route_constants.dart';
import '../../core/utils/platform_detector.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_state.dart';

import '../panels/customer/screens/customer_home_screen.dart';
import '../panels/customer/screens/service_detail_screen.dart';
import '../panels/customer/screens/booking_screen.dart';
import '../panels/customer/screens/bookings_list_screen.dart';
import '../panels/customer/screens/customer_profile_screen.dart';
import '../panels/provider/screens/provider_dashboard_screen.dart';
import '../panels/admin/screens/admin_dashboard_screen.dart';
import '../shared/screens/login_screen.dart';
import '../shared/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes to refresh router
  final authState = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    refreshListenable: _AuthNotifier(ref),
    redirect: (context, state) {
      final auth = authState.value;
      final isLoading = authState.isLoading;
      final isLoggedIn = auth?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.splash;

      // Still loading — stay on splash
      if (isLoading) return null;

      // Not logged in — redirect to login (except auth routes)
      if (!isLoggedIn && !isAuthRoute) return RouteConstants.login;

      // Logged in — redirect from login/splash to correct panel
      if (isLoggedIn && isAuthRoute) {
        switch (auth?.role) {
          case UserRole.serviceProvider:
            return RouteConstants.providerDashboard;
          case UserRole.admin:
            return RouteConstants.adminDashboard;
          default:
            return RouteConstants.customerHome;
        }
      }

      // Platform guard: Admin panel is web-only
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      if (isAdminRoute && !PlatformDetector.isWeb) {
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

      // ── Customer Panel ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.customerHome,
            builder: (context, state) => const CustomerHomeScreen(),
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
        ],
      ),

      // ── Provider Panel ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ProviderShell(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.providerDashboard,
            builder: (context, state) => const ProviderDashboardScreen(),
          ),
          GoRoute(
            path: RouteConstants.providerBookings,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Provider Bookings')),
            ),
          ),
          GoRoute(
            path: RouteConstants.providerServices,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Provider Services')),
            ),
          ),
        ],
      ),

      // ── Admin Panel (Web only) ───────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.adminDashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: RouteConstants.adminUsers,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Users')),
            ),
          ),
          GoRoute(
            path: RouteConstants.adminBookings,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Bookings')),
            ),
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

class CustomerShell extends StatelessWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go(RouteConstants.customerHome);
            case 1: context.go(RouteConstants.customerBookings);
            case 2: context.go(RouteConstants.customerProfile);
          }
        },
      ),
    );
  }
}

class ProviderShell extends StatelessWidget {
  final Widget child;
  const ProviderShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.design_services), label: 'Services'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go(RouteConstants.providerDashboard);
            case 1: context.go(RouteConstants.providerBookings);
            case 2: context.go(RouteConstants.providerServices);
          }
        },
      ),
    );
  }
}

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Users')),
              NavigationRailDestination(icon: Icon(Icons.book), label: Text('Bookings')),
            ],
            selectedIndex: 0,
            onDestinationSelected: (index) {
              switch (index) {
                case 0: context.go(RouteConstants.adminDashboard);
                case 1: context.go(RouteConstants.adminUsers);
                case 2: context.go(RouteConstants.adminBookings);
              }
            },
          ),
          Expanded(child: child),
        ],
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
