import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/service_repository.dart';

final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final bookings = await ref.read(bookingRepositoryProvider).getProviderBookings();
  final services = await ref.read(serviceRepositoryProvider).getServices();

  final totalRevenue = bookings
      .where((b) => b.isCompleted)
      .fold(0.0, (sum, b) => sum + b.totalPrice);

  return {
    'total_bookings': bookings.length,
    'pending_bookings': bookings.where((b) => b.isPending).length,
    'completed_bookings': bookings.where((b) => b.isCompleted).length,
    'total_services': services.length,
    'total_revenue': totalRevenue,
    'recent_bookings': bookings.take(5).toList(),
  };
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(adminDashboardProvider)),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Revenue Card ───────────────────────────────────
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 48, color: Colors.orange),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Revenue',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            'NPR ${(data['total_revenue'] as double).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats Grid ─────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard('Total Bookings',
                      data['total_bookings'].toString(), Icons.book, Colors.blue),
                  _StatCard('Pending',
                      data['pending_bookings'].toString(), Icons.pending, Colors.orange),
                  _StatCard('Completed',
                      data['completed_bookings'].toString(), Icons.check_circle, Colors.green),
                  _StatCard('Services',
                      data['total_services'].toString(), Icons.design_services, Colors.purple),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Activity ────────────────────────────────
              const Text('Recent Bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...(data['recent_bookings'] as List).map((b) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.book_online)),
                      title: Text('Booking #${b.id.substring(0, 8)}'),
                      subtitle: Text(
                          '${b.scheduledAt.day}/${b.scheduledAt.month}/${b.scheduledAt.year}'),
                      trailing: Chip(label: Text(b.status.name)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
