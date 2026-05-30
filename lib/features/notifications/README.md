# Notifications Feature

This feature provides real-time notification handling using WebSocket events.

## Components

### NotificationRealtime Provider

The `NotificationRealtime` provider manages real-time notification events from WebSocket:

- Subscribes to notification events from WebSocket
- Displays notification banners when events are received
- Auto-dismisses banners after 5 seconds
- Increments unread notification count
- Handles navigation to relevant screens on banner tap

**Requirements**: 8.5, 11.1, 11.2, 11.3, 11.4, 11.5

### NotificationBannerListener Widget

A widget that listens to notification events and displays banners at the top of the screen.

## Usage

### 1. Wrap your app with NotificationBannerListener

In your main app widget or router, wrap the content with `NotificationBannerListener`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notifications/notifications.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: NotificationBannerListener(
        child: YourHomeScreen(),
      ),
    );
  }
}
```

### 2. Display unread notification count

Use the `notificationRealtimeProvider` to display the unread count:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notifications/notifications.dart';

class NotificationBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationRealtimeProvider);
    
    return Badge(
      label: Text('$unreadCount'),
      isLabelVisible: unreadCount > 0,
      child: Icon(Icons.notifications),
    );
  }
}
```

### 3. Reset unread count when viewing notifications

When the user views the notifications screen, reset the count:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notifications/notifications.dart';

class NotificationsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset unread count when screen is opened
    ref.read(notificationRealtimeProvider.notifier).resetUnreadCount();
    
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: NotificationsList(),
    );
  }
}
```

## Notification Types and Navigation

The notification banner automatically navigates to the appropriate screen based on the notification type:

- `booking`, `booking_status` → `/bookings`
- `message`, `chat` → `/messages`
- `payment` → `/payments`
- `profile` → `/profile`
- Default → `/notifications`

## Customization

### Custom notification routes

To customize the navigation behavior, modify the `getNotificationRoute` function in `notification_realtime_provider.dart`:

```dart
String getNotificationRoute(NotificationEventData notification) {
  switch (notification.type.toLowerCase()) {
    case 'custom_type':
      return '/custom-route';
    default:
      return '/notifications';
  }
}
```

### Custom banner appearance

To customize the banner appearance, modify the `_getBackgroundColor`, `_getBorderColor`, and `_getIcon` methods in `notification_banner.dart`.

## Testing

The notification realtime provider can be tested by:

1. Establishing a WebSocket connection
2. Broadcasting a notification event from the backend
3. Verifying the banner is displayed
4. Verifying the unread count is incremented
5. Verifying navigation works on tap
6. Verifying auto-dismiss after 5 seconds

Example test notification event:

```json
{
  "event": "notification.created",
  "channel": "private-user.123",
  "data": {
    "id": "notif-123",
    "title": "New Booking",
    "message": "You have a new booking request",
    "type": "booking",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```
