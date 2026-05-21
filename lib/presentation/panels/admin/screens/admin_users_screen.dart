import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';

final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(apiClientProvider).get(ApiConstants.adminUsers);
  final data = res.data['data'] as List? ?? [];
  return data.cast<Map<String, dynamic>>();
});

final userSearchProvider = StateProvider<String>((ref) => '');

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final search = ref.watch(userSearchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search users...',
              leading: const Icon(Icons.search),
              onChanged: (v) =>
                  ref.read(userSearchProvider.notifier).state = v,
            ),
          ),

          // Users list
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('$e'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminUsersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                final filtered = search.isEmpty
                    ? users
                    : users.where((u) =>
                        (u['name'] as String? ?? '')
                            .toLowerCase()
                            .contains(search.toLowerCase()) ||
                        (u['email'] as String? ?? '')
                            .toLowerCase()
                            .contains(search.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _UserCard(user: filtered[index], ref: ref),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final WidgetRef ref;
  const _UserCard({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? true;
    final role = user['role'] as String? ?? 'customer';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(role).withOpacity(0.2),
          child: Text(
            (user['name'] as String? ?? 'U')[0].toUpperCase(),
            style: TextStyle(color: _roleColor(role)),
          ),
        ),
        title: Text(user['name'] as String? ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] as String? ?? ''),
            Row(
              children: [
                Chip(
                  label: Text(role),
                  backgroundColor: _roleColor(role).withOpacity(0.1),
                  labelStyle: TextStyle(color: _roleColor(role), fontSize: 11),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(isActive ? 'Active' : 'Inactive'),
                  backgroundColor: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  labelStyle: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 11),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
          ],
          onSelected: (value) async {
            final api = ref.read(apiClientProvider);
            if (value == 'toggle') {
              final action = isActive ? 'deactivate' : 'activate';
              await api.post('${ApiConstants.adminUsers}/${user['id']}/$action');
              ref.invalidate(adminUsersProvider);
            }
          },
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.orange;
      case 'serviceProvider': return Colors.green;
      default: return Colors.blue;
    }
  }
}
