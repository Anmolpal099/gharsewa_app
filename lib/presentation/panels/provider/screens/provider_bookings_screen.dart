import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../features/provider_panel/business_logic/dashboard_controller.dart';
import '../../../../features/provider_panel/business_logic/provider_bookings_providers.dart';
import '../../../../features/provider_panel/presentation/widgets/recommended_bookings_section.dart';
import '../../../../features/provider_panel/presentation/widgets/scheduling_assistant_banner.dart';

class ProviderBookingsScreen extends ConsumerStatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  ConsumerState<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends ConsumerState<ProviderBookingsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(providerBookingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SchedulingAssistantBanner(),
        const RecommendedBookingsSection(),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Completed'),
              Tab(text: 'All'),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(providerBookingsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (bookings) {
              final pending = bookings.where((b) => b.isPending).toList();
              final confirmed = bookings.where((b) => b.isConfirmed).toList();
              final completed = bookings.where((b) => b.isCompleted).toList();

              return RefreshIndicator(
                onRefresh: () => ref.refresh(providerBookingsProvider.future),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(pending, BookingListType.pending),
                    _buildBookingList(confirmed, BookingListType.confirmed),
                    _buildBookingList(completed, BookingListType.completed),
                    _buildBookingList(bookings, BookingListType.all),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, BookingListType type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${type.name} bookings',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        if (booking.isPending) {
          return _BookingRequestCard(
            booking: booking,
            onAccept: () => _handleAccept(booking.id),
            onReject: () => _handleReject(booking.id),
          );
        } else {
          return _BookingHistoryCard(
            booking: booking,
            onComplete: booking.isConfirmed 
                ? () => _handleComplete(booking.id)
                : null,
          );
        }
      },
    );
  }

  Future<void> _handleAccept(String bookingId) async {
    try {
      await ref.read(bookingRepositoryProvider).acceptBooking(bookingId);
      ref.invalidate(providerBookingsProvider);
      ref.invalidate(dashboardControllerProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(String bookingId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Not available at this time',
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonCtrl.text.isNotEmpty) {
      try {
        await ref
            .read(bookingRepositoryProvider)
            .rejectBooking(bookingId, reasonCtrl.text);
        ref.invalidate(providerBookingsProvider);
        ref.invalidate(dashboardControllerProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleComplete(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Booking'),
        content: const Text('Mark this booking as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingRepositoryProvider).completeBooking(bookingId);
        ref.invalidate(providerBookingsProvider);
        ref.invalidate(dashboardControllerProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

enum BookingListType { pending, confirmed, completed, all }

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
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.pending_actions, color: Colors.orange[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking #${booking.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'New booking request',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} at ${booking.scheduledAt.hour}:${booking.scheduledAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'NPR ${booking.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _BookingHistoryCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onComplete;

  const _BookingHistoryCard({
    required this.booking,
    this.onComplete,
  });

  Color _getStatusColor() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor().withOpacity(0.2),
            child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          ),
          title: Text(
            'Booking #${booking.id.substring(0, 8)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} • NPR ${booking.totalPrice.toStringAsFixed(0)}',
          ),
          trailing: onComplete != null
              ? FilledButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                  ),
                  child: Text(
                    booking.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
        ),
      );
}
