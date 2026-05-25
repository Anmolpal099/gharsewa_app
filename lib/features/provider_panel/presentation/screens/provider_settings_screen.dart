import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../services/auth/auth_service.dart';

/// Provider settings (drawer). Expand with preferences as needed.
class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Booking notifications'),
                subtitle: const Text('Alerts for new job requests'),
                value: true,
                onChanged: (_) {},
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Scheduling assistant tips'),
                subtitle: const Text('Show gap suggestions on My Jobs'),
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(RouteConstants.providerSupport),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Inventory'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(RouteConstants.providerInventory),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Schedule'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(RouteConstants.providerSchedule),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            await ref.read(authActionsProvider).signOut();
            if (context.mounted) context.go(RouteConstants.login);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
