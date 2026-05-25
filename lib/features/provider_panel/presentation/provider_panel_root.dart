import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../services/auth/auth_service.dart';
import '../business_logic/profile_manager.dart';
import '../business_logic/provider_navigation_controller.dart';
import 'widgets/provider_drawer.dart';
import 'widgets/provider_panel_theme.dart';

/// Provider shell: drawer + app bar + bottom tabs.
class ProviderPanelRoot extends ConsumerStatefulWidget {
  final Widget child;

  const ProviderPanelRoot({super.key, required this.child});

  @override
  ConsumerState<ProviderPanelRoot> createState() => _ProviderPanelRootState();
}

class _ProviderPanelRootState extends ConsumerState<ProviderPanelRoot> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileManagerProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authServiceProvider);
    final user = authAsync.value?.user;
    final location = GoRouterState.of(context).uri.toString();
    final nav = ref.read(providerNavigationControllerProvider);
    final index = nav.indexForLocation(location);
    final showBottomNav = ProviderNavigationController.isTabRoute(location);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Theme(
      data: ProviderPanelTheme.theme(context),
      child: Scaffold(
        drawer: const ProviderDrawer(),
        appBar: AppBar(
          title: Text(nav.titleForLocation(location)),
          actions: [
            if (user?.hasMultipleRoles == true && user?.isCustomer == true)
              TextButton.icon(
                onPressed: () => context.go(RouteConstants.customerHome),
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                label: const Text(
                  'Customer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: reducedMotion
            ? widget.child
            : AnimatedSwitcher(
                duration: ProviderPanelTheme.transitionDuration,
                child: widget.child,
              ),
        bottomNavigationBar: showBottomNav
            ? NavigationBar(
                selectedIndex: index,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view),
                    label: 'Explore',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month),
                    label: 'Bookings',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shield_outlined),
                    label: 'Safety',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
                onDestinationSelected: (i) => ref
                    .read(providerNavigationControllerProvider)
                    .navigateToTab(context, i),
              )
            : null,
      ),
    );
  }
}
