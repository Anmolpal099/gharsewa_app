import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../services/auth/auth_service.dart';

/// Admin Profile Screen with modern Material Design 3
/// Shows admin info, quick actions, and settings
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return authAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (authState) {
        final user = authState?.user;
        if (user == null) {
          return const Center(child: Text('No user data'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 50,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              avatar: const Icon(Icons.verified_user, size: 18),
                              label: Text(
                                'Administrator',
                                style: TextStyle(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: colorScheme.secondaryContainer,
                            ),
                          ],
                        ),
                      ),
                      // Edit Button
                      IconButton.filledTonal(
                        onPressed: () {
                          // TODO: Implement edit profile
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit profile coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions Section
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _QuickActionCard(
                    icon: Icons.people_alt,
                    title: 'Manage Users',
                    subtitle: 'View & edit users',
                    color: Colors.blue,
                    onTap: () => context.go(RouteConstants.adminUsers),
                  ),
                  _QuickActionCard(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Management',
                    subtitle: 'Add/remove admins',
                    color: Colors.purple,
                    onTap: () => context.go(RouteConstants.adminManagement),
                  ),
                  _QuickActionCard(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App configuration',
                    color: Colors.orange,
                    onTap: () => context.go(RouteConstants.adminSettings),
                  ),
                  _QuickActionCard(
                    icon: Icons.book_online,
                    title: 'Bookings',
                    subtitle: 'Manage bookings',
                    color: Colors.green,
                    onTap: () => context.go(RouteConstants.adminBookings),
                  ),
                  _QuickActionCard(
                    icon: Icons.assessment,
                    title: 'Reports',
                    subtitle: 'View analytics',
                    color: Colors.teal,
                    onTap: () => context.go(RouteConstants.adminReports),
                  ),
                  _QuickActionCard(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    subtitle: 'Overview',
                    color: Colors.indigo,
                    onTap: () => context.go(RouteConstants.adminDashboard),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Account Actions Section
              Text(
                'Account',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock, color: colorScheme.primary),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement change password
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Change password coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.security, color: colorScheme.primary),
                      title: const Text('Security Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.go(RouteConstants.adminSettings);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.notifications, color: colorScheme.primary),
                      title: const Text('Notification Preferences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement notification settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red[700]),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          await ref.read(authActionsProvider).signOut();
                          if (context.mounted) {
                            context.go(RouteConstants.login);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
