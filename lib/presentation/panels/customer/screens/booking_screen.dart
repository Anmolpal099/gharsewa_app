import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
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
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final scheduledAt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Get service details for price
      final service = await ref
          .read(serviceRepositoryProvider)
          .getServiceById(widget.serviceId);

      await ref.read(bookingRepositoryProvider).createBooking({
        'service_id': widget.serviceId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'total_price': service.price,
        'currency': service.currency,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully!'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date picker
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

            // Time picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.blue),
                title: const Text('Select Time'),
                subtitle: Text(_selectedTime == null
                    ? 'Tap to choose a time'
                    : _selectedTime!.format(context)),
                onTap: _pickTime,
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const Spacer(),

            // Confirm button
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
