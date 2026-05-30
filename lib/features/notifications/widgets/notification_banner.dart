import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/websocket/models/notification_event_data.dart';
import '../providers/notification_realtime_provider.dart';

/// Widget that displays notification banners when real-time events are received
/// 
/// This widget listens to the notification banner stream and displays
/// a banner at the top of the screen when a notification is received.
/// 
/// **Requirements**: 11.1, 11.2, 11.3, 11.4
class NotificationBannerListener extends ConsumerStatefulWidget {
  const NotificationBannerListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<NotificationBannerListener> createState() =>
      _NotificationBannerListenerState();
}

class _NotificationBannerListenerState
    extends ConsumerState<NotificationBannerListener> {
  StreamSubscription<NotificationEventData>? _subscription;
  Timer? _dismissTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeListener();
  }

  /// Initialize the notification banner listener
  void _initializeListener() {
    // Listen to notification banner stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscription = ref
          .read(notificationRealtimeProvider.notifier)
          .notificationBannerStream
          .listen(_showBanner);
    });
  }

  /// Show a notification banner
  /// 
  /// **Requirement 11.1**: Display banner at top of screen
  /// **Requirement 11.2**: Display title and message
  /// **Requirement 11.3**: Auto-dismiss after 5 seconds
  /// **Requirement 11.4**: Navigate on tap
  void _showBanner(NotificationEventData notification) {
    // Remove any existing banner
    _removeBanner();

    // Create overlay entry for the banner
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              _handleBannerTap(notification);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBackgroundColor(notification.type),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBorderColor(notification.type),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Icon(
                    _getIcon(notification.type),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title (Requirement 11.2)
                        Text(
                          notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Message (Requirement 11.2)
                        Text(
                          notification.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _removeBanner,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-dismiss after 5 seconds (Requirement 11.3)
    _dismissTimer = Timer(const Duration(seconds: 5), _removeBanner);
  }

  /// Handle banner tap
  /// 
  /// **Requirement 11.4**: Navigate to relevant screen on tap
  void _handleBannerTap(NotificationEventData notification) {
    // Remove the banner
    _removeBanner();

    // Navigate to the relevant screen
    final route = getNotificationRoute(notification);
    if (mounted) {
      context.go(route);
    }
  }

  /// Remove the current banner
  void _removeBanner() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Get background color based on notification type
  Color _getBackgroundColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Colors.green.shade600;
      case 'error':
      case 'warning':
        return Colors.orange.shade600;
      case 'info':
        return Colors.blue.shade600;
      case 'booking':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  /// Get border color based on notification type
  Color _getBorderColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Colors.green.shade800;
      case 'error':
      case 'warning':
        return Colors.orange.shade800;
      case 'info':
        return Colors.blue.shade800;
      case 'booking':
        return Colors.purple.shade800;
      default:
        return Colors.grey.shade900;
    }
  }

  /// Get icon based on notification type
  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'booking':
        return Icons.calendar_today;
      case 'message':
        return Icons.message;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _removeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
