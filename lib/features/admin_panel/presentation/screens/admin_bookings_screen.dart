import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/id_display.dart';
import '../../business_logic/admin_providers.dart';
import '../../data/models/admin_booking_item.dart';
import '../widgets/booking_detail_modal.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminBookingsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SearchBar(
            hintText: 'Search ID, customer, provider, or service...',
            leading: const Icon(Icons.search),
            onChanged: (v) =>
                ref.read(adminBookingSearchProvider.notifier).state = v,
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _StatusFilterChip(label: 'All', value: null),
              _StatusFilterChip(label: 'Pending', value: 'pending'),
              _StatusFilterChip(label: 'Confirmed', value: 'confirmed'),
              _StatusFilterChip(label: 'Completed', value: 'completed'),
              _StatusFilterChip(label: 'Cancelled', value: 'cancelled'),
            ],
          ),
        ),
        Expanded(
          child: bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$e'),
                  FilledButton(
                    onPressed: () => ref.invalidate(adminBookingsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (bookings) {
              if (bookings.isEmpty) {
                return const Center(child: Text('No bookings found'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(adminBookingsProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) =>
                      _BookingRow(
                        booking: bookings[index],
                        onTap: () => showAdminBookingDetailModal(
                          context,
                          ref,
                          bookings[index],
                        ),
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends ConsumerWidget {
  const _StatusFilterChip({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(adminBookingStatusFilterProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: current == value,
        onSelected: (_) =>
            ref.read(adminBookingStatusFilterProvider.notifier).state = value,
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.onTap});

  final AdminBookingItem booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final schedule = booking.scheduledAt != null
        ? DateFormat('MMM d, yyyy HH:mm').format(booking.scheduledAt!)
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _statusColor(booking.status).withValues(alpha: 0.15),
          child: Icon(Icons.event, color: _statusColor(booking.status), size: 20),
        ),
        title: Text(
          booking.serviceName ?? 'Booking #${shortId(booking.id)}',
        ),
        subtitle: Text(
          '${booking.customerName ?? 'Customer'} → ${booking.providerName ?? 'Provider'}\n$schedule',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${booking.currency} ${booking.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text(booking.status, style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
