import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/service_repository.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const BookingScreen({super.key, required this.serviceId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  List<String> _slots = [];
  bool _loadingSlots = false;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
      _loadingSlots = true;
    });
    final slots = await ref.read(bookingRepositoryProvider).checkAvailability(
          serviceId: widget.serviceId,
          date: date,
        );
    if (mounted) {
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    }
  }

  Future<void> _confirmBooking() async {
    final strings = ref.read(appStringsProvider);
    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.selectTimeSlot)),
      );
      return;
    }

    final parts = _selectedSlot!.split(':');
    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final service = await ref
        .read(serviceRepositoryProvider)
        .getServiceById(widget.serviceId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.confirmBooking),
        content: Text(
          'Book "${service.name}" on ${_selectedDate!.toLocal().toString().split(' ').first} at $_selectedSlot for ${service.currency} ${service.price.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirmBooking),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(bookingRepositoryProvider).createBooking({
        'service_id': widget.serviceId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'total_price': service.price,
        'currency': service.currency,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.bookingConfirmed),
            backgroundColor: Colors.green,
          ),
        );
        context.go(RouteConstants.customerBookings);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.confirmBooking)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Select Date'),
                subtitle: Text(_selectedDate == null
                    ? 'Tap to choose a date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                onTap: _pickDate,
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_selectedDate != null) ...[
              Text(strings.selectTimeSlot,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_slots.isEmpty)
                Text(strings.noSlots)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final selected = _selectedSlot == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                    );
                  }).toList(),
                ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _isLoading ? null : _confirmBooking,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(strings.confirmBooking, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
