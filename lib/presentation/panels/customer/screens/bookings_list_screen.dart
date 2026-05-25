import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';

final customerBookingsProvider =
    FutureProvider<List<BookingModel>>((ref) async {
  return ref.read(bookingRepositoryProvider).getCustomerBookings();
});

final bookingStatusFilterProvider =
    StateProvider<BookingStatus?>((ref) => null);

class BookingsListScreen extends ConsumerWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);
    final statusFilter = ref.watch(bookingStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _filterChip(context, ref, null, 'All', statusFilter),
                _filterChip(context, ref, BookingStatus.pending, 'Pending', statusFilter),
                _filterChip(context, ref, BookingStatus.confirmed, 'Confirmed', statusFilter),
                _filterChip(context, ref, BookingStatus.completed, 'Completed', statusFilter),
                _filterChip(context, ref, BookingStatus.cancelled, 'Cancelled', statusFilter),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (bookings) {
                final filtered = statusFilter == null
                    ? bookings
                    : bookings.where((b) => b.status == statusFilter).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No bookings found'));
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(customerBookingsProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _BookingCard(booking: filtered[index], ref: ref),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, WidgetRef ref,
      BookingStatus? status, String label, BookingStatus? current) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: current == status,
        onSelected: (_) =>
            ref.read(bookingStatusFilterProvider.notifier).state = status,
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final WidgetRef ref;
  const _BookingCard({required this.booking, required this.ref});

  Color _statusColor() {
    switch (booking.status) {
      case BookingStatus.pending:   return Colors.orange;
      case BookingStatus.confirmed: return Colors.blue;
      case BookingStatus.inProgress: return Colors.purple;
      case BookingStatus.completed: return Colors.green;
      case BookingStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/customer/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Booking #${booking.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor()),
                    ),
                    child: Text(booking.status.name,
                        style: TextStyle(color: _statusColor(), fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Scheduled: ${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} at ${booking.scheduledAt.hour}:${booking.scheduledAt.minute.toString().padLeft(2, '0')}'),
              Text('Total: ${booking.currency} ${booking.totalPrice.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/customer/bookings/${booking.id}'),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                  if (booking.isPending)
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
                        ref.invalidate(customerBookingsProvider);
                      },
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
