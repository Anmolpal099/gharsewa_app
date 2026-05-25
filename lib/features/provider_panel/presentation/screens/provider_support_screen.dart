import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/provider_accessibility.dart';

/// Help & support (plan 10.5).
class ProviderSupportScreen extends StatelessWidget {
  const ProviderSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SupportTile(
            icon: Icons.help_outline,
            title: 'FAQs',
            subtitle: 'Booking policies, payments, and account help',
            onTap: () {},
          ),
          _SupportTile(
            icon: Icons.mail_outline,
            title: 'Email support',
            subtitle: 'support@gharsewa.com',
            onTap: () => launchUrl(Uri.parse('mailto:support@gharsewa.com')),
          ),
          _SupportTile(
            icon: Icons.phone_outlined,
            title: 'Call support',
            subtitle: '+977-1-XXXXXXX',
            onTap: () => launchUrl(Uri.parse('tel:+9771000000000')),
          ),
          const SizedBox(height: 24),
          Semantics(
            label: 'Report an issue',
            button: true,
            child: FilledButton.icon(
              style: ProviderAccessibility.minTouchButton(null),
              onPressed: () {
                ProviderAccessibility.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Issue report submitted')),
                );
              },
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report an issue'),
            ),
          ),
        ],
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, $subtitle',
      button: true,
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          onTap: onTap,
        ),
      ),
    );
  }
}
