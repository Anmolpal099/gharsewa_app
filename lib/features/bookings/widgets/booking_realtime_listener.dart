import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/booking_realtime_provider.dart';

/// BookingRealtimeListener widget
/// 
/// A widget that listens to booking status notifications and displays snackbars.
/// This widget should be placed high in the widget tree (e.g., in the main app scaffold)
/// to ensure notifications are shown regardless of the current screen.
/// 
/// **Requirements**: 10.4, 10.5
/// 
/// Usage:
/// ```dart
/// BookingRealtimeListener(
///   child: YourAppContent(),
/// )
/// ```
class BookingRealtimeListener extends ConsumerStatefulWidget {
  const BookingRealtimeListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<BookingRealtimeListener> createState() =>
      _BookingRealtimeListenerState();
}

class _BookingRealtimeListenerState
    extends ConsumerState<BookingRealtimeListener> {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    
    // Initialize the booking realtime provider
    // This ensures the provider is created and starts listening to events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingRealtimeProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to booking status notifications
    ref.listen<AsyncValue<BookingStatusNotification>>(
      bookingStatusNotificationProvider,
      (previous, next) {
        next.whenData((notification) {
          _showNotification(notification);
        });
      },
    );

    return widget.child;
  }

  /// Show snackbar notification for booking status change
  /// 
  /// **Requirement 10.4**: Show snackbar notification for important status changes
  void _showNotification(BookingStatusNotification notification) {
    _logger.i('Showing notification for booking ${notification.bookingId}: ${notification.newStatus}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForStatus(notification.newStatus),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Update',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.getMessage(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: notification.getColor(),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to booking detail screen
            // This can be implemented based on the app's routing structure
            _logger.d('View booking ${notification.bookingId}');
          },
        ),
      ),
    );
  }

  /// Get appropriate icon for booking status
  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
