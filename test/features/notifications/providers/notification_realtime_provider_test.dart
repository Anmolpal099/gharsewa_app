import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gharsewa/core/websocket/models/websocket_event.dart';
import 'package:gharsewa/core/websocket/models/notification_event_data.dart';
import 'package:gharsewa/features/notifications/providers/notification_realtime_provider.dart';

// Generate mocks
@GenerateMocks([])
void main() {
  group('NotificationRealtime Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be 0 (no unread notifications)', () {
      // Arrange & Act
      final state = container.read(notificationRealtimeProvider);

      // Assert
      expect(state, 0);
    });

    test('incrementUnreadCount should increase the count', () {
      // Arrange
      final notifier = container.read(notificationRealtimeProvider.notifier);

      // Act
      notifier.incrementUnreadCount();
      notifier.incrementUnreadCount();

      // Assert
      expect(container.read(notificationRealtimeProvider), 2);
    });

    test('decrementUnreadCount should decrease the count', () {
      // Arrange
      final notifier = container.read(notificationRealtimeProvider.notifier);
      notifier.incrementUnreadCount();
      notifier.incrementUnreadCount();
      notifier.incrementUnreadCount();

      // Act
      notifier.decrementUnreadCount();

      // Assert
      expect(container.read(notificationRealtimeProvider), 2);
    });

    test('decrementUnreadCount should not go below 0', () {
      // Arrange
      final notifier = container.read(notificationRealtimeProvider.notifier);

      // Act
      notifier.decrementUnreadCount();
      notifier.decrementUnreadCount();

      // Assert
      expect(container.read(notificationRealtimeProvider), 0);
    });

    test('resetUnreadCount should set count to 0', () {
      // Arrange
      final notifier = container.read(notificationRealtimeProvider.notifier);
      notifier.incrementUnreadCount();
      notifier.incrementUnreadCount();
      notifier.incrementUnreadCount();

      // Act
      notifier.resetUnreadCount();

      // Assert
      expect(container.read(notificationRealtimeProvider), 0);
    });

    test('getNotificationRoute should return correct route for booking type', () {
      // Arrange
      final notification = NotificationEventData(
        id: '1',
        title: 'Booking Update',
        message: 'Your booking has been confirmed',
        type: 'booking',
        timestamp: DateTime.now(),
      );

      // Act
      final route = getNotificationRoute(notification);

      // Assert
      expect(route, '/bookings');
    });

    test('getNotificationRoute should return correct route for message type', () {
      // Arrange
      final notification = NotificationEventData(
        id: '2',
        title: 'New Message',
        message: 'You have a new message',
        type: 'message',
        timestamp: DateTime.now(),
      );

      // Act
      final route = getNotificationRoute(notification);

      // Assert
      expect(route, '/messages');
    });

    test('getNotificationRoute should return default route for unknown type', () {
      // Arrange
      final notification = NotificationEventData(
        id: '3',
        title: 'Unknown',
        message: 'Unknown notification',
        type: 'unknown',
        timestamp: DateTime.now(),
      );

      // Act
      final route = getNotificationRoute(notification);

      // Assert
      expect(route, '/notifications');
    });

    test('getNotificationRoute should handle case-insensitive types', () {
      // Arrange
      final notification = NotificationEventData(
        id: '4',
        title: 'Payment',
        message: 'Payment received',
        type: 'PAYMENT',
        timestamp: DateTime.now(),
      );

      // Act
      final route = getNotificationRoute(notification);

      // Assert
      expect(route, '/payments');
    });
  });
}
