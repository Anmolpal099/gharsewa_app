import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../business_logic/admin_providers.dart';
import '../../data/services/admin_api_service.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserDetailProvider(userId));

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$e'),
            FilledButton(
              onPressed: () => ref.invalidate(adminUserDetailProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (user) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(user.email),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(user.role)),
                          Chip(
                            label: Text(user.isActive ? 'Active' : 'Inactive'),
                            backgroundColor: user.isActive
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoGrid(
              items: {
                'Phone': user.phone ?? '—',
                'Bookings': '${user.totalBookings}',
                'Total spent': user.totalSpent != null
                    ? 'NPR ${user.totalSpent!.toStringAsFixed(0)}'
                    : '—',
                'Joined': user.createdAt != null
                    ? DateFormat.yMMMd().format(user.createdAt!)
                    : '—',
                'Last login': user.lastLoginAt != null
                    ? DateFormat.yMMMd().add_jm().format(user.lastLoginAt!)
                    : '—',
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _toggleActive(context, ref, user.isActive),
                  icon: Icon(user.isActive ? Icons.block : Icons.check),
                  label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _resetPassword(context, ref),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset password'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Recent bookings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (user.recentBookings.isEmpty)
              const Text('No booking history')
            else
              ...user.recentBookings.map(
                (b) => Card(
                  child: ListTile(
                    title: Text(b['service_name']?.toString() ?? 'Booking'),
                    subtitle: Text(
                      '${b['status']} • ${b['scheduled_at'] ?? ''}',
                    ),
                    trailing: Text(
                      'NPR ${(b['total_price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    bool isActive,
  ) async {
    final api = ref.read(adminApiServiceProvider);
    try {
      if (isActive) {
        final reason = await _reasonDialog(context);
        if (reason == null) return;
        await api.deactivateUser(userId, reason);
      } else {
        await api.activateUser(userId);
      }
      ref.invalidate(adminUserDetailProvider(userId));
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isActive ? 'User deactivated' : 'User activated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    try {
      final temp = await ref.read(adminApiServiceProvider).resetUserPassword(userId);
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Temporary password'),
            content: SelectableText(temp),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _reasonDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reason'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) return ctrl.text.trim();
    return null;
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 32,
          runSpacing: 12,
          children: items.entries
              .map(
                (e) => SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        e.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
