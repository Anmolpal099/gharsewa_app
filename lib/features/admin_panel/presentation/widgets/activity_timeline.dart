import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_dashboard_data.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, required this.activities});

  final List<AdminActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No recent platform activity'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...activities.map((a) => _ActivityRow(activity: a)),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final AdminActivity activity;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(activity.type);
    final time = activity.timestamp != null
        ? DateFormat('MMM d, HH:mm').format(activity.timestamp!)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: icon.color.withValues(alpha: 0.15),
            child: Icon(icon.icon, size: 18, color: icon.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.message),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _iconForType(String type) {
    switch (type) {
      case 'new_booking':
        return (icon: Icons.event, color: Colors.orange);
      case 'new_user':
        return (icon: Icons.person_add, color: Colors.blue);
      default:
        return (icon: Icons.notifications, color: Colors.grey);
    }
  }
}
