import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../services/auth/auth_service.dart';
import '../../business_logic/performance_tracker.dart';
import '../../business_logic/profile_manager.dart';
import '../../business_logic/provider_navigation_controller.dart';

/// Side navigation drawer for the provider panel (Stitch design).
class ProviderDrawer extends ConsumerWidget {
  const ProviderDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final auth = ref.watch(authServiceProvider).value;
    final user = auth?.user;
    final profileAsync = ref.watch(profileManagerProvider);
    final metricsAsync = ref.watch(performanceTrackerProvider);
    final nav = ref.read(providerNavigationControllerProvider);

    final name = profileAsync.value?.name ?? user?.name ?? 'Provider';
    final rawPhoto = profileAsync.value?.photoUrl;
    final photoUrl =
        rawPhoto != null && rawPhoto.isNotEmpty ? resolveMediaUrl(rawPhoto) : null;
    final rating = metricsAsync.value?.formattedRating ?? '—';

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1565C0),
                              ),
                        ),
                        Text(
                          'Pro Member',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Rating: $rating',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in ProviderNavigationController.drawerItems)
                    _DrawerTile(
                      item: item,
                      selected: nav.isDrawerRouteSelected(location, item.route),
                      onTap: () {
                        Navigator.pop(context);
                        nav.navigateToScreen(context, item.route);
                      },
                    ),
                ],
              ),
            ),
            if (user?.hasMultipleRoles == true) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Switch to Customer'),
                onTap: () {
                  Navigator.pop(context);
                  context.go(RouteConstants.customerHome);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ProviderDrawerItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = const Color(0xFFE3F2FD);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? highlight : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: ListTile(
          leading: Icon(
            item.icon,
            color: selected ? const Color(0xFF1565C0) : Colors.grey[700],
          ),
          title: Text(
            item.label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? const Color(0xFF1565C0) : Colors.black87,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          onTap: onTap,
        ),
      ),
    );
  }
}
