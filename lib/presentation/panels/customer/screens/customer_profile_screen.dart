import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/auth/auth_service.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (auth) {
          final user = auth.firebaseUser;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (user?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user?.displayName ?? 'Customer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              // Profile options
              _ProfileTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.read(authActionsProvider).signOut(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
