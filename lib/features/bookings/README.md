# Bookings Feature

This feature provides real-time booking updates via WebSocket integration.

## Overview

The bookings feature listens to WebSocket events for booking status changes and automatically updates the booking list in the UI. It also displays snackbar notifications for important status changes (confirmed, completed, cancelled).

## Components

### Providers

#### `BookingRealtime`
- **File**: `providers/booking_realtime_provider.dart`
- **Purpose**: Manages real-time booking updates via WebSocket events
- **Requirements**: 8.4, 8.5, 10.1, 10.2, 10.3, 10.4, 10.5

**Features**:
- Subscribes to `bookingEvents` stream from WebSocket
- Handles `booking.status.changed` events
- Invalidates booking list providers to trigger UI refresh
- Determines which status changes should show notifications

**Providers exposed**:
- `bookingRealtimeProvider`: Main provider for booking realtime functionality
- `bookingStatusNotificationProvider`: Stream provider for status change notifications
- `providerBookingsProvider`: Reference to provider bookings list
- `customerBookingsProvider`: Reference to customer bookings list

### Widgets

#### `BookingRealtimeListener`
- **File**: `widgets/booking_realtime_listener.dart`
- **Purpose**: Listens to booking status notifications and displays snackbars
- **Requirements**: 10.4, 10.5

**Features**:
- Automatically initializes the booking realtime provider
- Listens to booking status notification stream
- Displays snackbar with appropriate icon, color, and message
- Provides "View" action to navigate to booking details

## Usage

### 1. Initialize the BookingRealtimeListener

Add the `BookingRealtimeListener` widget high in your widget tree (e.g., in your main app scaffold or router):

```dart
import 'package:gharsewa/features/bookings/bookings.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: BookingRealtimeListener(
        child: YourAppContent(),
      ),
    );
  }
}
```

### 2. The provider will automatically:
- Subscribe to WebSocket booking events
- Update booking lists when status changes occur
- Show snackbar notifications for important status changes

### 3. Booking lists will automatically refresh

The existing booking list screens will automatically refresh when booking events are received because the provider invalidates the booking list providers:

- `providerBookingsProvider` (for service providers)
- `customerBookingsProvider` (for customers)

## Event Flow

```
WebSocket Server
    ↓
booking.status.changed event
    ↓
bookingEventsProvider (websocket_provider.dart)
    ↓
BookingRealtime provider
    ↓
├─→ Invalidate booking list providers → UI refresh
└─→ bookingStatusNotificationProvider → BookingRealtimeListener → Snackbar
```

## Status Notifications

Notifications are shown for the following status changes:
- **Confirmed**: Green snackbar with check icon
- **Completed**: Blue snackbar with task icon
- **Cancelled**: Orange snackbar with cancel icon

Other status changes (e.g., pending, in-progress) do not trigger notifications but still update the booking list.

## Requirements Mapping

| Requirement | Implementation |
|-------------|----------------|
| 8.4 | Subscribe to bookingEvents stream in `BookingRealtime._initialize()` |
| 8.5 | Handle booking.status.changed events in `BookingRealtime._handleBookingEvent()` |
| 10.1 | Update booking list state by invalidating providers in `_invalidateBookingProviders()` |
| 10.2 | Booking list providers automatically refetch data, adding new bookings if they match filters |
| 10.3 | Booking list providers refetch data, moving bookings to appropriate sections based on status |
| 10.4 | Show snackbar notification via `BookingRealtimeListener._showNotification()` |
| 10.5 | Maintain scroll position is handled by Flutter's ListView automatically when using provider invalidation |

## Testing

To test the booking realtime functionality:

1. **Start the backend WebSocket server**:
   ```bash
   cd backend
   docker-compose up websocket
   ```

2. **Run the Flutter app**:
   ```bash
   flutter run
   ```

3. **Trigger a booking status change**:
   - Use the backend API to update a booking status
   - Or use the provider panel to accept/complete a booking

4. **Verify**:
   - The booking list should automatically update
   - A snackbar notification should appear for confirmed/completed/cancelled statuses
   - The WebSocket connection status indicator should show "Live"

## Troubleshooting

### Notifications not showing
- Check that `BookingRealtimeListener` is added to your widget tree
- Verify WebSocket connection is established (check connection status indicator)
- Check logs for any errors in booking event handling

### Booking list not updating
- Verify the booking list screen is using the correct provider (`providerBookingsProvider` or `customerBookingsProvider`)
- Check that the provider is properly invalidated in `_invalidateBookingProviders()`
- Ensure the WebSocket event contains valid `booking_id` and `new_status` fields

### WebSocket connection issues
- Check that the backend WebSocket server is running
- Verify the WebSocket URL in environment configuration
- Check JWT token is valid and not expired
- Review WebSocket connection logs in the console

## Future Enhancements

- Add navigation to booking detail screen when "View" action is tapped
- Add sound/vibration for important notifications
- Add notification history/inbox
- Add ability to dismiss notifications
- Add notification preferences (enable/disable per status type)
