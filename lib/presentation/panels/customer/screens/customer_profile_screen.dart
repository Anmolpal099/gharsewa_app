import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          final user = auth.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user?.name ?? 'Customer',
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
                onTap: () => context.push('/customer/profile/edit'),
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
              
              // Show "Become Service Provider" button if user is not already a provider
              if (user != null && !user.hasRole('serviceProvider'))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Become a Service Provider'),
                          content: const Text(
                            'Would you like to upgrade your account to offer services? '
                            'You\'ll be able to access both customer and provider features.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Upgrade'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Call API to become service provider
                          await ref.read(authActionsProvider).becomeServiceProvider();

                          if (context.mounted) {
                            // Close loading indicator
                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 You are now a service provider!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );

                            // Navigate to provider dashboard
                            context.go('/provider/dashboard');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            // Close loading indicator
                            Navigator.pop(context);

                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.business_center),
                    label: const Text('Become a Service Provider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
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
