import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/id_display.dart';
import '../../business_logic/admin_providers.dart';
import '../../data/models/admin_booking_item.dart';
import '../../data/services/admin_api_service.dart';

Future<void> showAdminBookingDetailModal(
  BuildContext context,
  WidgetRef ref,
  AdminBookingItem booking,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _BookingDetailDialog(booking: booking),
  );
}

class _BookingDetailDialog extends ConsumerStatefulWidget {
  const _BookingDetailDialog({required this.booking});

  final AdminBookingItem booking;

  @override
  ConsumerState<_BookingDetailDialog> createState() =>
      _BookingDetailDialogState();
}

class _BookingDetailDialogState extends ConsumerState<_BookingDetailDialog> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final schedule = b.scheduledAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(b.scheduledAt!)
        : '—';

    return AlertDialog(
      title: Text('Booking #${shortId(b.id)}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _row('Status', b.status),
              _row('Service', b.serviceName ?? '—'),
              _row('Customer', '${b.customerName ?? '—'} (${b.customerEmail ?? ''})'),
              _row('Provider', b.providerName ?? '—'),
              _row('Scheduled', schedule),
              _row('Amount', '${b.currency} ${b.totalPrice.toStringAsFixed(0)}'),
              if (b.cancellationReason != null)
                _row('Cancellation', b.cancellationReason!),
              const SizedBox(height: 12),
              const Text('Admin notes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (b.adminNotes.isEmpty)
                const Text('No notes yet', style: TextStyle(color: Colors.grey))
              else
                ...b.adminNotes.map(
                  (n) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(n.note),
                    subtitle: n.createdAt != null
                        ? Text(DateFormat('MMM d, HH:mm').format(n.createdAt!))
                        : null,
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Add note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (b.canCancel)
          TextButton(
            onPressed: () => _cancelBooking(context),
            child: const Text('Cancel booking',
                style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _noteCtrl.text.trim().isEmpty ? null : _addNote,
          child: const Text('Save note'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _addNote() async {
    try {
      await ref
          .read(adminApiServiceProvider)
          .addBookingNote(widget.booking.id, _noteCtrl.text.trim());
      ref.invalidate(adminBookingsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonCtrl.text.trim().isEmpty) return;

    try {
      await ref.read(adminApiServiceProvider).cancelBooking(
            widget.booking.id,
            reason: reasonCtrl.text.trim(),
          );
      ref.invalidate(adminBookingsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
