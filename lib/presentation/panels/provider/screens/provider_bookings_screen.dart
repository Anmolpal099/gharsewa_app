import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import 'provider_dashboard_screen.dart';

final providerBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  return ref.read(bookingRepositoryProvider).getProviderBookings();
});

class ProviderBookingsScreen extends ConsumerWidget {
  const ProviderBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(providerBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bookings) {
          final pending = bookings.where((b) => b.isPending).toList();
          final others  = bookings.where((b) => !b.isPending).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(providerBookingsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  const Text('Pending Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...pending.map((b) => _BookingRequestCard(
                        booking: b,
                        onAccept: () async {
                          await ref.read(bookingRepositoryProvider).acceptBooking(b.id);
                          ref.invalidate(providerBookingsProvider);
                          ref.invalidate(providerDashboardProvider);
                        },
                        onReject: () async {
                          await _showRejectDialog(context, ref, b.id);
                        },
                      )),
                  const SizedBox(height: 16),
                ],
                if (others.isNotEmpty) ...[
                  const Text('All Bookings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...others.map((b) => _BookingHistoryCard(booking: b, ref: ref)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRejectDialog(
      BuildContext context, WidgetRef ref, String bookingId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(bookingRepositoryProvider)
          .rejectBooking(bookingId, reasonCtrl.text);
      ref.invalidate(providerBookingsProvider);
    }
  }
}

class _BookingRequestCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BookingRequestCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking #${booking.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  'Scheduled: ${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year}'),
              Text('Amount: NPR ${booking.totalPrice.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red)),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _BookingHistoryCard extends ConsumerWidget {
  final BookingModel booking;
  final WidgetRef ref;
  const _BookingHistoryCard({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text('Booking #${booking.id.substring(0, 8)}'),
          subtitle: Text(
              '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} • NPR ${booking.totalPrice.toStringAsFixed(0)}'),
          trailing: booking.isConfirmed
              ? FilledButton(
                  onPressed: () async {
                    await ref
                        .read(bookingRepositoryProvider)
                        .completeBooking(booking.id);
                    ref.invalidate(providerBookingsProvider);
                  },
                  child: const Text('Complete'),
                )
              : Chip(label: Text(booking.status.name)),
        ),
      );
}
