import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/service_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final bookingDetailProvider =
    FutureProvider.family<BookingModel, String>((ref, bookingId) async {
  final bookings =
      await ref.read(bookingRepositoryProvider).getCustomerBookings();
  return bookings.firstWhere((b) => b.id == bookingId);
});

final bookingServiceProvider =
    FutureProvider.family<ServiceModel, String>((ref, serviceId) async {
  return ref.read(serviceRepositoryProvider).getServiceById(serviceId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading booking: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
        data: (booking) => _BookingDetailContent(booking: booking),
      ),
    );
  }
}

// ── Content Widget ────────────────────────────────────────────────────────────

class _BookingDetailContent extends ConsumerWidget {
  final BookingModel booking;
  const _BookingDetailContent({required this.booking});

  Color _statusColor() {
    switch (booking.status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _statusIcon() {
    switch (booking.status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.play_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(bookingServiceProvider(booking.serviceId));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: _statusColor(), width: 2),
              ),
            ),
            child: Column(
              children: [
                Icon(_statusIcon(), size: 64, color: _statusColor()),
                const SizedBox(height: 12),
                Text(
                  booking.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking #${booking.id.substring(0, 8)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Information
                _SectionHeader(title: 'Service Details'),
                serviceAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading service: $e'),
                    ),
                  ),
                  data: (service) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.home_repair_service,
                                    color: Colors.blue, size: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      service.category,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.access_time,
                            label: 'Duration',
                            value: '${service.durationMinutes} minutes',
                          ),
                          _InfoRow(
                            icon: Icons.attach_money,
                            label: 'Price',
                            value:
                                '${service.currency} ${service.price.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Booking Information
                _SectionHeader(title: 'Booking Information'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value:
                              '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year}',
                        ),
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value:
                              '${booking.scheduledAt.hour}:${booking.scheduledAt.minute.toString().padLeft(2, '0')}',
                        ),
                        _InfoRow(
                          icon: Icons.payment,
                          label: 'Total Amount',
                          value:
                              '${booking.currency} ${booking.totalPrice.toStringAsFixed(0)}',
                        ),
                        _InfoRow(
                          icon: Icons.event_note,
                          label: 'Booked On',
                          value:
                              '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cancellation Reason (if cancelled)
                if (booking.isCancelled &&
                    booking.cancellationReason != null) ...[
                  _SectionHeader(title: 'Cancellation Reason'),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(booking.cancellationReason!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions
                if (booking.isPending) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, ref),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],

                if (booking.isConfirmed) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your booking is confirmed! The service provider will arrive at the scheduled time.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (booking.isCompleted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: Navigate to review screen
                      },
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Rate Service'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this booking?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
                hintText: 'Why are you cancelling?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBooking(context, ref, reasonController.text);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(
      BuildContext context, WidgetRef ref, String reason) async {
    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancelBooking(booking.id, reason: reason.isEmpty ? null : reason);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel booking: $e')),
        );
      }
    }
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
