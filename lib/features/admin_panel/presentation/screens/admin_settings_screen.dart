import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin Settings Screen - Security, Notifications, and System Configuration
/// Modern Material Design 3 implementation
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // Security Settings
  bool _twoFactorEnabled = false;
  bool _loginNotifications = true;
  bool _sessionTimeout = true;
  int _sessionTimeoutMinutes = 30;

  // Notification Settings
  bool _emailNotifications = true;
  bool _newUserNotifications = true;
  bool _bookingNotifications = true;
  bool _systemAlerts = true;

  // System Settings
  bool _maintenanceMode = false;
  bool _debugMode = false;
  String _selectedTheme = 'System';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage security, notifications, and system configuration',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Security Settings Section
            _SectionHeader(
              icon: Icons.security,
              title: 'Security Settings',
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.verified_user),
                    title: const Text('Two-Factor Authentication'),
                    subtitle: const Text('Require 2FA for admin login'),
                    value: _twoFactorEnabled,
                    onChanged: (value) {
                      setState(() => _twoFactorEnabled = value);
                      _showSaveSnackbar(context, 'Two-factor authentication ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active),
                    title: const Text('Login Notifications'),
                    subtitle: const Text('Get notified of admin logins'),
                    value: _loginNotifications,
                    onChanged: (value) {
                      setState(() => _loginNotifications = value);
                      _showSaveSnackbar(context, 'Login notifications ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.timer),
                    title: const Text('Session Timeout'),
                    subtitle: Text('Auto logout after $_sessionTimeoutMinutes minutes of inactivity'),
                    value: _sessionTimeout,
                    onChanged: (value) {
                      setState(() => _sessionTimeout = value);
                      _showSaveSnackbar(context, 'Session timeout ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  if (_sessionTimeout) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Timeout Duration'),
                      subtitle: Slider(
                        value: _sessionTimeoutMinutes.toDouble(),
                        min: 15,
                        max: 120,
                        divisions: 7,
                        label: '$_sessionTimeoutMinutes minutes',
                        onChanged: (value) {
                          setState(() => _sessionTimeoutMinutes = value.toInt());
                        },
                        onChangeEnd: (value) {
                          _showSaveSnackbar(context, 'Session timeout set to ${value.toInt()} minutes');
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your admin password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Notification Settings Section
            _SectionHeader(
              icon: Icons.notifications,
              title: 'Notification Preferences',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.email),
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive notifications via email'),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                      _showSaveSnackbar(context, 'Email notifications ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.person_add),
                    title: const Text('New User Registrations'),
                    subtitle: const Text('Notify when new users register'),
                    value: _newUserNotifications,
                    onChanged: (value) {
                      setState(() => _newUserNotifications = value);
                      _showSaveSnackbar(context, 'New user notifications ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.book_online),
                    title: const Text('Booking Updates'),
                    subtitle: const Text('Notify about booking changes'),
                    value: _bookingNotifications,
                    onChanged: (value) {
                      setState(() => _bookingNotifications = value);
                      _showSaveSnackbar(context, 'Booking notifications ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.warning),
                    title: const Text('System Alerts'),
                    subtitle: const Text('Critical system notifications'),
                    value: _systemAlerts,
                    onChanged: (value) {
                      setState(() => _systemAlerts = value);
                      _showSaveSnackbar(context, 'System alerts ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // System Configuration Section
            _SectionHeader(
              icon: Icons.settings,
              title: 'System Configuration',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.construction, color: Colors.orange[700]),
                    title: const Text('Maintenance Mode'),
                    subtitle: const Text('Disable app for maintenance'),
                    value: _maintenanceMode,
                    onChanged: (value) {
                      _showMaintenanceModeConfirmation(context, value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.bug_report, color: Colors.red[700]),
                    title: const Text('Debug Mode'),
                    subtitle: const Text('Enable detailed error logging'),
                    value: _debugMode,
                    onChanged: (value) {
                      setState(() => _debugMode = value);
                      _showSaveSnackbar(context, 'Debug mode ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                    subtitle: Text(_selectedTheme),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0 (Build 1)'),
                    trailing: Chip(
                      label: const Text('Latest'),
                      backgroundColor: Colors.green[100],
                      labelStyle: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Danger Zone
            _SectionHeader(
              icon: Icons.warning,
              title: 'Danger Zone',
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red[700]),
                    title: Text(
                      'Clear All Cache',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    subtitle: const Text('Remove all cached data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showClearCacheConfirmation(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.restore, color: Colors.red[700]),
                    title: Text(
                      'Reset to Defaults',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    subtitle: const Text('Restore all settings to default'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showResetConfirmation(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 8) return 'Min 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // TODO: Implement password change API
                Navigator.pop(context);
                _showSaveSnackbar(context, 'Password changed successfully');
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceModeConfirmation(BuildContext context, bool enable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enable ? 'Enable Maintenance Mode' : 'Disable Maintenance Mode'),
        content: Text(
          enable
              ? 'This will make the app unavailable to all users. Only admins will be able to access the system.'
              : 'This will make the app available to all users again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _maintenanceMode = enable);
              Navigator.pop(context);
              _showSaveSnackbar(
                context,
                'Maintenance mode ${enable ? 'enabled' : 'disabled'}',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: enable ? Colors.orange[700] : null,
            ),
            child: Text(enable ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
                _showSaveSnackbar(context, 'Theme set to $value');
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
                _showSaveSnackbar(context, 'Theme set to $value');
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
                _showSaveSnackbar(context, 'Theme set to $value');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache'),
        content: const Text(
          'This will remove all cached data. Users may experience slower load times temporarily.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
              _showSaveSnackbar(context, 'Cache cleared successfully');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will restore all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Reset all settings
              setState(() {
                _twoFactorEnabled = false;
                _loginNotifications = true;
                _sessionTimeout = true;
                _sessionTimeoutMinutes = 30;
                _emailNotifications = true;
                _newUserNotifications = true;
                _bookingNotifications = true;
                _systemAlerts = true;
                _maintenanceMode = false;
                _debugMode = false;
                _selectedTheme = 'System';
              });
              Navigator.pop(context);
              _showSaveSnackbar(context, 'Settings reset to defaults');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
