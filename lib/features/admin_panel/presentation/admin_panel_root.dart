import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../services/auth/auth_service.dart';
import '../business_logic/admin_navigation_controller.dart';
import 'widgets/admin_sidebar.dart';

/// Main admin panel shell with responsive sidebar (Task 8.1.1).
class AdminPanelRoot extends ConsumerWidget {
  const AdminPanelRoot({super.key, required this.child});

  final Widget child;

  static const double _wideBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = AdminNavigationController.indexForLocation(location)
        .clamp(0, AdminNavigationController.items.length - 1);
    final title = AdminNavigationController.titleForLocation(location);
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    void navigate(int index) {
      context.go(AdminNavigationController.items[index].route);
    }

    Future<void> signOut() async {
      await ref.read(authActionsProvider).signOut();
      if (context.mounted) context.go(RouteConstants.login);
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 240,
              child: AdminSidebar(
                selectedIndex: selectedIndex,
                extended: true,
                onNavigate: navigate,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(title: title, onSignOut: signOut),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: AdminSidebar(
          selectedIndex: selectedIndex,
          extended: true,
          onNavigate: (index) {
            Navigator.pop(context);
            navigate(index);
          },
        ),
      ),
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: signOut,
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: navigate,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Reports'),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.title, required this.onSignOut});

  final String title;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Sign out',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
      ),
    );
  }
}
