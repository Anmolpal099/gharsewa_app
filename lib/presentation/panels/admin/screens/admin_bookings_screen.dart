import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';

final adminBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  return ref.read(bookingRepositoryProvider).getProviderBookings();
});

final adminBookingSearchProvider = StateProvider<String>((ref) => '');
final adminBookingStatusProvider = StateProvider<BookingStatus?>((ref) => null);

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminBookingsProvider);
    final search = ref.watch(adminBookingSearchProvider);
    final statusFilter = ref.watch(adminBookingStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Oversight')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SearchBar(
              hintText: 'Search by booking ID...',
              leading: const Icon(Icons.search),
              onChanged: (v) =>
                  ref.read(adminBookingSearchProvider.notifier).state = v,
            ),
          ),

          // Status filters
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip(ref, null, 'All', statusFilter),
                _chip(ref, BookingStatus.pending, 'Pending', statusFilter),
                _chip(ref, BookingStatus.confirmed, 'Confirmed', statusFilter),
                _chip(ref, BookingStatus.completed, 'Completed', statusFilter),
                _chip(ref, BookingStatus.cancelled, 'Cancelled', statusFilter),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (bookings) {
                var filtered = bookings;
                if (search.isNotEmpty) {
                  filtered = filtered
                      .where((b) => b.id.contains(search))
                      .toList();
                }
                if (statusFilter != null) {
                  filtered = filtered
                      .where((b) => b.status == statusFilter)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('No bookings found'));
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(adminBookingsProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _AdminBookingCard(booking: filtered[index], ref: ref),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(WidgetRef ref, BookingStatus? status, String label,
      BookingStatus? current) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: current == status,
        onSelected: (_) =>
            ref.read(adminBookingStatusProvider.notifier).state = status,
      ),
    );
  }
}

class _AdminBookingCard extends ConsumerWidget {
  final BookingModel booking;
  final WidgetRef ref;
  const _AdminBookingCard({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.book_online)),
        title: Text('Booking #${booking.id.substring(0, 8)}'),
        subtitle: Text(
            '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} • NPR ${booking.totalPrice.toStringAsFixed(0)}'),
        trailing: Chip(
          label: Text(booking.status.name),
          backgroundColor: _statusColor(booking.status).withOpacity(0.1),
          labelStyle: TextStyle(color: _statusColor(booking.status)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer ID: ${booking.customerId.substring(0, 8)}...'),
                Text('Provider ID: ${booking.providerId.substring(0, 8)}...'),
                Text('Service ID: ${booking.serviceId.substring(0, 8)}...'),
                if (booking.cancellationReason != null)
                  Text('Reason: ${booking.cancellationReason}'),
                const SizedBox(height: 12),
                if (booking.isPending || booking.isConfirmed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(bookingRepositoryProvider)
                            .cancelBooking(booking.id,
                                reason: 'Cancelled by admin');
                        ref.invalidate(adminBookingsProvider);
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red)),
                      child: const Text('Cancel Booking'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:    return Colors.orange;
      case BookingStatus.confirmed:  return Colors.blue;
      case BookingStatus.inProgress: return Colors.purple;
      case BookingStatus.completed:  return Colors.green;
      case BookingStatus.cancelled:  return Colors.red;
    }
  }
}
