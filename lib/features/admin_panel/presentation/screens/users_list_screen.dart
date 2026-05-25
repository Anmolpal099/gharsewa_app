import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../business_logic/admin_providers.dart';
import '../../data/models/admin_user.dart';
import '../../data/services/admin_api_service.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SearchBar(
                hintText: 'Search by name, email, or phone...',
                leading: const Icon(Icons.search),
                onChanged: (v) =>
                    ref.read(adminUserSearchProvider.notifier).state = v,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const _RoleChip(label: 'All roles', value: null),
                    _RoleChip(label: 'Customer', value: 'customer'),
                    _RoleChip(label: 'Provider', value: 'serviceProvider'),
                    _RoleChip(label: 'Admin', value: 'admin'),
                    const SizedBox(width: 16),
                    const _StatusChip(label: 'All', value: null),
                    _StatusChip(label: 'Active', value: 'active'),
                    _StatusChip(label: 'Inactive', value: 'inactive'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$e'),
                  FilledButton(
                    onPressed: () => ref.invalidate(adminUsersProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(adminUsersProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) =>
                      _UserTile(user: users[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends ConsumerWidget {
  const _RoleChip({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(adminUserRoleFilterProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: current == value,
        onSelected: (_) =>
            ref.read(adminUserRoleFilterProvider.notifier).state = value,
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  const _StatusChip({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(adminUserStatusFilterProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: current == value,
        onSelected: (_) =>
            ref.read(adminUserStatusFilterProvider.notifier).state = value,
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.go('/admin/users/${user.id}'),
        leading: CircleAvatar(
          backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(color: _roleColor(user.role)),
          ),
        ),
        title: Text(user.name),
        subtitle: Text('${user.email}\n${user.totalBookings} bookings'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(context, ref, action),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: user.isActive ? 'deactivate' : 'activate',
              child: Text(user.isActive ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: Text('Reset password'),
            ),
            const PopupMenuItem(value: 'detail', child: Text('View details')),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final api = ref.read(adminApiServiceProvider);
    try {
      if (action == 'detail') {
        context.go('/admin/users/${user.id}');
        return;
      }
      if (action == 'activate') {
        await api.activateUser(user.id);
        ref.invalidate(adminUsersProvider);
        _snack(context, 'User activated');
      } else if (action == 'deactivate') {
        final reason = await _promptReason(context);
        if (reason == null) return;
        await api.deactivateUser(user.id, reason);
        ref.invalidate(adminUsersProvider);
        _snack(context, 'User deactivated');
      } else if (action == 'reset') {
        final temp = await api.resetUserPassword(user.id);
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
      }
    } catch (e) {
      _snack(context, '$e', isError: true);
    }
  }

  Future<String?> _promptReason(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivation reason'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 3,
        ),
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

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'serviceProvider':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
