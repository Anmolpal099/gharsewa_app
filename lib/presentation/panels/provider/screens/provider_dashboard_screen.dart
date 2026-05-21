import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';

final providerDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final bookings = await ref.read(bookingRepositoryProvider).getProviderBookings();
  final pending   = bookings.where((b) => b.isPending).length;
  final confirmed = bookings.where((b) => b.isConfirmed).length;
  final completed = bookings.where((b) => b.isCompleted).length;
  final earnings  = bookings
      .where((b) => b.isCompleted)
      .fold(0.0, (sum, b) => sum + b.totalPrice);

  return {
    'pending': pending,
    'confirmed': confirmed,
    'completed': completed,
    'earnings': earnings,
    'bookings': bookings,
  };
});

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(providerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(providerDashboardProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Earnings Card ──────────────────────────────────
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This Month Earnings',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        'NPR ${(data['earnings'] as double).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats Row ──────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _StatCard('Pending', data['pending'].toString(), Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard('Confirmed', data['confirmed'].toString(), Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard('Completed', data['completed'].toString(), Colors.green)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Bookings ────────────────────────────────
              const Text('Recent Bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...(data['bookings'] as List<BookingModel>)
                  .take(5)
                  .map((b) => _BookingTile(booking: b)),
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
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: const Icon(Icons.person, color: Colors.green),
          ),
          title: Text('Booking #${booking.id.substring(0, 8)}'),
          subtitle: Text(
              '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(booking.status.name,
                style: const TextStyle(fontSize: 12, color: Colors.green)),
          ),
        ),
      );
}
