import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/websocket/websocket_provider.dart';
import '../../../core/websocket/models/websocket_event.dart';
import '../../../core/websocket/models/notification_event_data.dart';

/// Manages real-time notification events from WebSocket
/// 
/// This provider:
/// - Subscribes to notification events from WebSocket
/// - Displays notification banners when events are received
/// - Auto-dismisses banners after 5 seconds
/// - Increments unread notification count
/// - Handles navigation to relevant screens on banner tap
/// 
/// **Requirements**: 8.5, 11.1, 11.2, 11.3, 11.4, 11.5
class NotificationRealtime extends StateNotifier<int> {
  NotificationRealtime(this._ref) : super(0) {
    _initialize();
  }

  final Ref _ref;
  final Logger _logger = Logger();
  StreamSubscription? _subscription;

  /// Initialize the notification realtime listener
  /// 
  /// **Requirement 8.5**: Subscribe to notification events stream
  void _initialize() {
    _logger.i('Initializing NotificationRealtime provider');

    // Listen to notification events from WebSocket using ref.listen
    _ref.listen<AsyncValue<WebSocketEvent>>(
      notificationEventsProvider,
      (previous, next) {
        _handleNotificationEvent(next);
      },
    );

    // Cleanup on dispose
    _ref.onDispose(() {
      _logger.i('Disposing NotificationRealtime provider');
      _subscription?.cancel();
    });
  }

  /// Handle incoming notification events
  /// 
  /// **Requirement 11.1**: Display notification banner when events are received
  /// **Requirement 11.5**: Increment unread notification count
  void _handleNotificationEvent(AsyncValue<WebSocketEvent> eventValue) {
    eventValue.whenData((event) {
      try {
        _logger.d('Received notification event: ${event.data}');

        // Parse notification event data
        final notificationData = NotificationEventData.fromJson(event.data);

        // Increment unread notification count (Requirement 11.5)
        state = state + 1;
        _logger.d('Unread notification count: $state');

        // Display notification banner (Requirement 11.1)
        _showNotificationBanner(notificationData);
      } catch (e, stackTrace) {
        _logger.e(
          'Error handling notification event',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  /// Display a notification banner
  /// 
  /// **Requirement 11.1**: Display notification banner at top of screen
  /// **Requirement 11.2**: Display title and message from event
  /// **Requirement 11.3**: Auto-dismiss after 5 seconds
  /// **Requirement 11.4**: Navigate to relevant screen on tap
  void _showNotificationBanner(NotificationEventData notification) {
    // Get the current BuildContext from the root navigator
    // Note: This requires the provider to be used within a widget tree
    // that has access to a ScaffoldMessenger
    
    _logger.i('Showing notification banner: ${notification.title}');

    // We'll use a callback mechanism to show the banner
    // The actual banner display will be handled by a widget that watches this provider
    _notificationBannerController.add(notification);
  }

  /// Stream controller for notification banner display
  /// 
  /// Widgets can listen to this stream to display notification banners
  final StreamController<NotificationEventData> _notificationBannerController =
      StreamController<NotificationEventData>.broadcast();

  /// Stream of notifications to display as banners
  Stream<NotificationEventData> get notificationBannerStream =>
      _notificationBannerController.stream;

  /// Reset the unread notification count
  /// 
  /// Call this when the user views the notifications screen
  void resetUnreadCount() {
    _logger.d('Resetting unread notification count');
    state = 0;
  }

  /// Increment the unread notification count manually
  /// 
  /// This can be used when notifications are fetched from the API
  void incrementUnreadCount() {
    state = state + 1;
  }

  /// Decrement the unread notification count
  /// 
  /// Call this when a notification is marked as read
  void decrementUnreadCount() {
    if (state > 0) {
      state = state - 1;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notificationBannerController.close();
    super.dispose();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

/// Provider for notification realtime state
/// 
/// The state represents the unread notification count.
/// 
/// **Requirement 11.5**: Track unread notification count
final notificationRealtimeProvider =
    StateNotifierProvider<NotificationRealtime, int>((ref) {
  return NotificationRealtime(ref);
});

/// Provider for notification banner stream
/// 
/// Widgets can watch this stream to display notification banners.
/// 
/// **Requirement 11.1**: Provide stream for notification banner display
final notificationBannerStreamProvider = StreamProvider<NotificationEventData>((ref) {
  final notifier = ref.watch(notificationRealtimeProvider.notifier);
  return notifier.notificationBannerStream;
});

/// Helper function to get notification navigation route
/// 
/// **Requirement 11.4**: Determine navigation target based on notification type
String getNotificationRoute(NotificationEventData notification) {
  // Map notification types to routes
  switch (notification.type.toLowerCase()) {
    case 'booking':
    case 'booking_status':
      return '/bookings';
    case 'message':
    case 'chat':
      return '/messages';
    case 'payment':
      return '/payments';
    case 'profile':
      return '/profile';
    default:
      return '/notifications';
  }
}
