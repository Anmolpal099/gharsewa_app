# BookingRealtime Usage Example

This document provides practical examples of how to integrate the BookingRealtime feature into your Flutter app.

## Quick Start

### Step 1: Add BookingRealtimeListener to Your App

The simplest way to enable real-time booking updates is to wrap your app content with the `BookingRealtimeListener` widget:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/features/bookings/bookings.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Gharsewa',
      home: BookingRealtimeListener(
        child: MainNavigationScreen(),
      ),
    );
  }
}
```

### Step 2: That's It!

Once you've added the `BookingRealtimeListener`, the following will happen automatically:

1. **WebSocket Connection**: The app will connect to the WebSocket server when the user is authenticated
2. **Event Listening**: The provider will listen for `booking.status.changed` events
3. **UI Updates**: Booking lists will automatically refresh when status changes occur
4. **Notifications**: Snackbar notifications will appear for important status changes (confirmed, completed, cancelled)

## Advanced Usage

### Custom Notification Handling

If you want to customize how notifications are displayed, you can listen to the `bookingStatusNotificationProvider` directly:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/features/bookings/bookings.dart';

class CustomBookingNotificationListener extends ConsumerWidget {
  const CustomBookingNotificationListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to booking status notifications
    ref.listen<AsyncValue<BookingStatusNotification>>(
      bookingStatusNotificationProvider,
      (previous, next) {
        next.whenData((notification) {
          // Custom notification handling
          _showCustomNotification(context, notification);
        });
      },
    );

    return child;
  }

  void _showCustomNotification(
    BuildContext context,
    BookingStatusNotification notification,
  ) {
    // Your custom notification logic here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Update'),
        content: Text(notification.getMessage()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to booking detail
              Navigator.pushNamed(
                context,
                '/booking/${notification.bookingId}',
              );
            },
            child: const Text('View Booking'),
          ),
        ],
      ),
    );
  }
}
```

### Manual Provider Initialization

If you need more control over when the provider is initialized, you can manually initialize it:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/features/bookings/bookings.dart';

class MyBookingScreen extends ConsumerStatefulWidget {
  const MyBookingScreen({super.key});

  @override
  ConsumerState<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends ConsumerState<MyBookingScreen> {
  @override
  void initState() {
    super.initState();
    
    // Manually initialize the booking realtime provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingRealtimeProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Your screen content
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: const BookingList(),
    );
  }
}
```

### Accessing Booking Events Directly

If you need to handle booking events in a custom way, you can listen to the `bookingEventsProvider`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/core/websocket/websocket_provider.dart';

class CustomBookingEventHandler extends ConsumerWidget {
  const CustomBookingEventHandler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to booking events
    ref.listen<AsyncValue<WebSocketEvent>>(
      bookingEventsProvider,
      (previous, next) {
        next.whenData((event) {
          // Handle the event
          final bookingId = event.data['booking_id'] as String?;
          final newStatus = event.data['new_status'] as String?;
          
          print('Booking $bookingId changed to $newStatus');
          
          // Your custom logic here
        });
      },
    );

    return const YourWidget();
  }
}
```

## Integration with Existing Screens

### Provider Bookings Screen

The provider bookings screen will automatically refresh when booking events are received because the `BookingRealtime` provider invalidates the `providerBookingsProvider`:

```dart
// No changes needed! The existing screen will work automatically
class ProviderBookingsScreen extends ConsumerWidget {
  const ProviderBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(providerBookingsProvider);

    return bookingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (bookings) => BookingList(bookings: bookings),
    );
  }
}
```

### Customer Bookings Screen

Similarly, the customer bookings screen will automatically refresh:

```dart
// No changes needed! The existing screen will work automatically
class CustomerBookingsScreen extends ConsumerWidget {
  const CustomerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return bookingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (bookings) => BookingList(bookings: bookings),
    );
  }
}
```

## Testing

### Unit Testing the Provider

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/features/bookings/bookings.dart';

void main() {
  test('BookingRealtime provider initializes correctly', () {
    final container = ProviderContainer();
    
    // Read the provider to initialize it
    container.read(bookingRealtimeProvider);
    
    // Verify it doesn't throw
    expect(container.read(bookingRealtimeProvider), isNotNull);
    
    container.dispose();
  });
}
```

### Integration Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/features/bookings/bookings.dart';

void main() {
  testWidgets('BookingRealtimeListener shows notifications', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: BookingRealtimeListener(
            child: Scaffold(
              body: const Text('Test'),
            ),
          ),
        ),
      ),
    );

    // Verify the widget builds
    expect(find.text('Test'), findsOneWidget);
  });
}
```

## Troubleshooting

### Notifications Not Showing

If notifications are not appearing:

1. **Check WebSocket Connection**: Ensure the WebSocket connection is established
   ```dart
   final connectionState = ref.watch(webSocketConnectionProvider);
   print('Connection state: $connectionState');
   ```

2. **Verify BookingRealtimeListener**: Make sure `BookingRealtimeListener` is in your widget tree
   ```dart
   // Should be high in the tree, e.g., wrapping your MaterialApp content
   BookingRealtimeListener(child: YourApp())
   ```

3. **Check Event Data**: Verify the WebSocket event contains the required fields
   ```dart
   ref.listen(bookingEventsProvider, (previous, next) {
     next.whenData((event) {
       print('Event data: ${event.data}');
     });
   });
   ```

### Booking List Not Updating

If the booking list doesn't update:

1. **Verify Provider Usage**: Ensure your screen uses the correct provider
   ```dart
   // For providers:
   final bookings = ref.watch(providerBookingsProvider);
   
   // For customers:
   final bookings = ref.watch(customerBookingsProvider);
   ```

2. **Check Provider Invalidation**: The provider should be invalidated automatically, but you can verify:
   ```dart
   ref.listen(bookingEventsProvider, (previous, next) {
     next.whenData((event) {
       print('Invalidating providers...');
       ref.invalidate(providerBookingsProvider);
     });
   });
   ```

## Best Practices

1. **Place BookingRealtimeListener High in Widget Tree**: Add it near the root of your app to ensure it's always active
2. **Don't Create Multiple Instances**: Only create one `BookingRealtimeListener` in your app
3. **Use Existing Providers**: The booking list providers are automatically invalidated, so use them as-is
4. **Handle Errors Gracefully**: Always handle potential errors in event processing
5. **Test WebSocket Connection**: Verify the WebSocket connection is working before expecting real-time updates

## Next Steps

- Review the [README.md](README.md) for detailed architecture information
- Check the [design document](../../../.kiro/specs/realtime-websockets/design.md) for technical specifications
- Explore the [WebSocket provider](../../../core/websocket/websocket_provider.dart) for connection management
