# Implementation Plan: Real-Time WebSocket Communication

## Overview

This implementation plan breaks down the real-time WebSocket feature into discrete coding tasks. The implementation uses Laravel Reverb on the backend for WebSocket server functionality and web_socket_channel on the Flutter frontend for cross-platform WebSocket client support. The system enables instant updates for booking status changes, notifications, and user presence tracking with JWT-based authentication and Redis pub/sub for horizontal scaling.

## Tasks

- [x] 1. Set up Laravel Reverb and backend infrastructure
  - [x] 1.1 Install and configure Laravel Reverb package
    - Install Laravel Reverb via Composer
    - Publish Reverb configuration files
    - Create `config/reverb.php` with server settings, app credentials, and scaling configuration
    - Update `config/broadcasting.php` to add Reverb connection driver
    - Add Reverb environment variables to `.env` file
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [x] 1.2 Configure Docker Compose for WebSocket service
    - Verify `docker-compose.yml` has websocket service configured
    - Ensure websocket service runs `php artisan reverb:start` command
    - Configure port mapping (6001:6001)
    - Set up health check endpoint for websocket service
    - Add Redis dependency for websocket service
    - _Requirements: 1.3, 1.5_
  
  - [x] 1.3 Implement JWT authentication middleware for WebSocket connections
    - Create `app/Http/Middleware/WebSocketAuthMiddleware.php`
    - Implement token extraction from query parameter and Authorization header
    - Validate JWT token using JWTAuth facade
    - Extract user identity from JWT payload
    - Handle authentication errors (missing token, expired token, invalid token)
    - Register middleware in Reverb configuration
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [x]* 1.4 Write unit tests for JWT authentication middleware
    - Test valid JWT token acceptance
    - Test expired token rejection
    - Test invalid token rejection
    - Test missing token rejection
    - Test user extraction from token payload
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 2. Implement channel authorization and event classes
  - [x] 2.1 Configure channel authorization in routes/channels.php
    - Define authorization callback for `user.{userId}` private channel
    - Define authorization callback for `booking.{bookingId}` private channel
    - Define authorization callback for `providers` presence channel
    - Define authorization callback for `customers` presence channel
    - Implement role-based access control for presence channels
    - _Requirements: 2.5, 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [x]* 2.2 Write unit tests for channel authorization
    - Test user can subscribe to own channel
    - Test user cannot subscribe to other user's channel
    - Test booking channel authorization for customer and provider
    - Test presence channel role-based access
    - _Requirements: 2.5, 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [x] 2.3 Create BookingStatusChanged event class
    - Create `app/Events/BookingStatusChanged.php`
    - Implement `ShouldBroadcast` interface
    - Define constructor with booking, oldStatus, and newStatus parameters
    - Implement `broadcastOn()` to return private channels for customer, provider, and booking
    - Implement `broadcastAs()` to return 'booking.status.changed'
    - Implement `broadcastWith()` to return event payload with booking_id, old_status, new_status, timestamp
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 17.1, 17.2, 17.5_
  
  - [x] 2.4 Create NotificationCreated event class
    - Create `app/Events/NotificationCreated.php`
    - Implement `ShouldBroadcast` interface
    - Define constructor with notification parameter
    - Implement `broadcastOn()` to return private channel for user
    - Implement `broadcastAs()` to return 'notification.created'
    - Implement `broadcastWith()` to return event payload with id, title, message, type, timestamp
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 17.3, 17.5_
  
  - [x]* 2.5 Write unit tests for event serialization
    - Test BookingStatusChanged event serializes correctly
    - Test NotificationCreated event serializes correctly
    - Test event payload includes all required fields
    - Test timestamp format is ISO 8601
    - _Requirements: 3.4, 4.2, 17.5_

- [x] 3. Integrate event broadcasting into application layer
  - [x] 3.1 Add event broadcasting to booking status updates
    - Locate booking status update logic in BookingController or BookingService
    - Dispatch BookingStatusChanged event when status changes from pending to confirmed
    - Dispatch BookingStatusChanged event when status changes from confirmed to completed
    - Dispatch BookingStatusChanged event when booking is cancelled
    - Ensure event is dispatched with old and new status values
    - _Requirements: 3.1, 3.2, 3.3, 3.5_
  
  - [x] 3.2 Add event broadcasting to notification creation
    - Locate notification creation logic in NotificationService or NotificationController
    - Dispatch NotificationCreated event when new notification is created
    - Ensure event is dispatched within 100ms of notification creation
    - _Requirements: 4.1, 4.4_
  
  - [x]* 3.3 Write integration tests for event broadcasting
    - Test booking status change broadcasts BookingStatusChanged event
    - Test notification creation broadcasts NotificationCreated event
    - Test events are dispatched to correct channels
    - Test event payloads contain correct data
    - _Requirements: 3.1, 3.2, 3.3, 4.1_

- [x] 4. Implement WebSocket health check endpoint
  - [x] 4.1 Create WebSocketHealthController
    - Create `app/Http/Controllers/WebSocketHealthController.php`
    - Implement `health()` method that checks Redis connection
    - Return JSON response with status, uptime, connections, redis status, timestamp
    - Return HTTP 200 when healthy, HTTP 503 when Redis unavailable
    - Add route for `/api/websocket/health` in `routes/api.php`
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_
  
  - [x]* 4.2 Write integration tests for health check endpoint
    - Test health check returns 200 when Redis is connected
    - Test health check returns 503 when Redis is unavailable
    - Test response includes required fields
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_

- [x] 5. Checkpoint - Backend implementation complete
  - Ensure all backend tests pass
  - Verify Reverb server starts successfully with `docker-compose up websocket`
  - Test WebSocket connection manually using a WebSocket client tool
  - Ask the user if questions arise

- [x] 6. Implement Flutter WebSocket connection manager
  - [x] 6.1 Create WebSocket data models
    - Create `lib/core/websocket/models/websocket_event.dart` with freezed model
    - Define WebSocketEvent with event, channel, data, timestamp fields
    - Create `lib/core/websocket/models/connection_state.dart` enum
    - Define ConnectionState enum with disconnected, connecting, connected, error values
    - Create `lib/core/websocket/models/booking_event_data.dart` with freezed model
    - Create `lib/core/websocket/models/notification_event_data.dart` with freezed model
    - Create `lib/core/websocket/models/presence_member.dart` with freezed model
    - Run `flutter pub run build_runner build` to generate freezed code
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.1, 8.2, 8.3_
  
  - [x] 6.2 Implement WebSocketConnectionManager class
    - Create `lib/core/websocket/websocket_connection_manager.dart`
    - Implement connection lifecycle methods (connect, disconnect, reconnect)
    - Implement JWT token authentication in connection URL
    - Implement channel subscription method
    - Implement message handling and event parsing
    - Implement error handling and disconnection handling
    - Implement exponential backoff reconnection strategy (1s, 2s, 4s, 8s, 16s, 30s max)
    - Expose connection state stream and event stream
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 7.1, 7.2, 7.3, 7.4, 7.5, 18.1, 18.2, 18.3, 18.4, 18.5_
  
  - [x]* 6.3 Write unit tests for WebSocketConnectionManager
    - Test connection establishes successfully with valid token
    - Test connection fails with invalid token
    - Test reconnection uses exponential backoff
    - Test event parsing from JSON messages
    - Test connection state transitions
    - Test subscription to channels
    - _Requirements: 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 7. Implement Riverpod providers for WebSocket state management
  - [x] 7.1 Create WebSocket connection provider
    - Create `lib/core/websocket/websocket_provider.dart`
    - Implement WebSocketConnection Riverpod provider
    - Initialize connection when user is authenticated
    - Disconnect when user logs out
    - Expose connection state to UI
    - Implement channel subscription method
    - Expose event stream for filtering
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.1, 8.2, 8.3_
  
  - [x] 7.2 Create event stream providers
    - Create bookingEvents stream provider that filters booking.status.changed events
    - Create notificationEvents stream provider that filters notification.created events
    - Create presenceEvents stream provider that filters presence update events
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [x] 7.3 Implement environment configuration for WebSocket URL
    - Create or update `lib/core/config/environment.dart`
    - Add wsUrl constant with environment variable support
    - Add reverbAppKey constant with environment variable support
    - Add useSecureWebSocket boolean flag for production WSS
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 8. Implement real-time booking updates
  - [x] 8.1 Create BookingRealtime provider
    - Create `lib/features/bookings/providers/booking_realtime_provider.dart`
    - Implement BookingRealtime Riverpod provider
    - Subscribe to bookingEvents stream
    - Handle booking.status.changed events
    - Update booking list state when events are received
    - Show snackbar notification for important status changes
    - _Requirements: 8.4, 8.5, 10.1, 10.2, 10.3, 10.4, 10.5_
  
  - [x]* 8.2 Write integration tests for booking real-time updates
    - Test booking event updates booking list
    - Test booking event shows notification for important statuses
    - Test booking list maintains scroll position
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 9. Implement real-time notification display
  - [x] 9.1 Create NotificationRealtime provider
    - Create `lib/features/notifications/providers/notification_realtime_provider.dart`
    - Implement NotificationRealtime Riverpod provider
    - Subscribe to notificationEvents stream
    - Handle notification.created events
    - Display notification banner when events are received
    - Auto-dismiss banner after 5 seconds
    - Increment unread notification count
    - Navigate to relevant screen on banner tap
    - _Requirements: 8.5, 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [x]* 9.2 Write widget tests for notification banner
    - Test notification banner displays with correct title and message
    - Test notification banner auto-dismisses after 5 seconds
    - Test notification banner navigation on tap
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

- [ ] 10. Implement presence tracking and online indicators
  - [x] 10.1 Create PresenceRealtime provider
    - Create `lib/features/presence/providers/presence_realtime_provider.dart`
    - Implement PresenceRealtime Riverpod provider
    - Subscribe to presence channels (providers, customers)
    - Handle presence join and leave events
    - Maintain list of online users
    - Expose online status for specific user IDs
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 8.3, 12.1, 12.2_
  
  - [x] 10.2 Create online presence indicator widget
    - Create `lib/core/websocket/widgets/online_indicator.dart`
    - Display green dot for online users
    - Display gray dot or no indicator for offline users
    - Show last seen timestamp for offline users on profile pages
    - Update indicator within 1 second of presence change
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_
  
  - [x]* 10.3 Write widget tests for online indicator
    - Test online indicator displays green dot for online users
    - Test online indicator displays gray dot for offline users
    - Test last seen timestamp displays for offline users
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ] 11. Implement connection status UI feedback
  - [~] 11.1 Create ConnectionStatusIndicator widget
    - Create `lib/core/websocket/widgets/connection_status_indicator.dart`
    - Display "Connecting..." indicator when connecting
    - Display "Live" indicator with green status when connected
    - Display "Disconnected" indicator with red status when disconnected
    - Display "Reconnecting..." with attempt count during reconnection
    - Position indicator in app bar or non-intrusive location
    - Animate transitions between states
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [ ]* 11.2 Write widget tests for connection status indicator
    - Test displays "Live" status when connected
    - Test displays "Connecting..." status when connecting
    - Test displays "Disconnected" status when disconnected
    - Test displays "Reconnecting..." status during reconnection
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 12. Implement graceful degradation with HTTP polling fallback
  - [~] 12.1 Implement polling service for bookings and notifications
    - Create `lib/core/services/polling_service.dart`
    - Implement polling for booking updates every 30 seconds
    - Implement polling for notifications every 60 seconds
    - Enable polling when WebSocket fails after 5 connection attempts
    - Disable polling when WebSocket connection is restored
    - _Requirements: 14.1, 14.2, 14.3, 14.4_
  
  - [~] 12.2 Add fallback UI messaging
    - Display "Real-time updates temporarily unavailable" message when using polling
    - Remove message when WebSocket connection is restored
    - _Requirements: 14.5_
  
  - [ ]* 12.3 Write integration tests for graceful degradation
    - Test polling activates after 5 failed WebSocket attempts
    - Test polling deactivates when WebSocket reconnects
    - Test booking updates work via polling
    - Test notification updates work via polling
    - _Requirements: 14.1, 14.2, 14.3, 14.4_

- [~] 13. Checkpoint - Frontend implementation complete
  - Ensure all frontend tests pass
  - Run `flutter analyze` to check for code issues
  - Test WebSocket connection on web platform (Chrome, Firefox)
  - Test WebSocket connection on desktop platform (Windows, macOS, or Linux)
  - Ask the user if questions arise

- [ ] 14. Integration and end-to-end testing
  - [~] 14.1 Test complete booking status change flow
    - Start backend and frontend applications
    - Create a test booking
    - Update booking status via API
    - Verify BookingStatusChanged event is broadcast
    - Verify Flutter app receives event and updates UI
    - Verify notification banner appears for important status changes
    - _Requirements: 3.1, 3.2, 3.3, 10.1, 10.2, 10.3, 10.4_
  
  - [~] 14.2 Test complete notification flow
    - Create a test notification via API
    - Verify NotificationCreated event is broadcast
    - Verify Flutter app receives event and displays banner
    - Verify banner auto-dismisses after 5 seconds
    - Verify unread count increments
    - _Requirements: 4.1, 11.1, 11.2, 11.3, 11.5_
  
  - [~] 14.3 Test presence tracking flow
    - Connect multiple users to WebSocket
    - Verify users appear in presence channel
    - Disconnect a user
    - Verify user is removed from presence channel within 5 seconds
    - Verify online indicators update correctly
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 12.1, 12.2_
  
  - [~] 14.4 Test connection lifecycle and reconnection
    - Establish WebSocket connection
    - Simulate network disconnection
    - Verify automatic reconnection with exponential backoff
    - Verify subscriptions are restored after reconnection
    - Test app pause/resume connection management
    - Test logout/login connection management
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 18.1, 18.2, 18.3, 18.4, 18.5_
  
  - [~] 14.5 Test graceful degradation
    - Stop WebSocket server
    - Verify connection fails after 5 attempts
    - Verify polling fallback activates
    - Verify booking and notification updates work via polling
    - Restart WebSocket server
    - Verify WebSocket reconnects and polling deactivates
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_
  
  - [~] 14.6 Test cross-platform compatibility
    - Test WebSocket connection on Chrome web browser
    - Test WebSocket connection on Firefox web browser
    - Test WebSocket connection on Windows desktop
    - Test WebSocket connection on macOS desktop (if available)
    - Verify identical behavior across platforms
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [~] 15. Final checkpoint and documentation
  - Ensure all tests pass (backend and frontend)
  - Verify Docker Compose starts all services successfully
  - Update README or documentation with WebSocket setup instructions
  - Document environment variables required for WebSocket configuration
  - Document how to run and test WebSocket functionality locally
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Backend tasks use PHP/Laravel with Reverb for WebSocket server
- Frontend tasks use Dart/Flutter with web_socket_channel for cross-platform WebSocket client
- No property-based testing is included as this feature involves infrastructure, I/O, and side effects
- Integration tests and manual testing are the primary validation approaches
- Checkpoints ensure incremental validation at major milestones
- The implementation follows a backend-first approach, then frontend, then integration testing

## Task Dependency Graph

```json
{
  "waves": [
    {
      "id": 0,
      "tasks": ["1.1", "1.2"]
    },
    {
      "id": 1,
      "tasks": ["1.3", "1.4"]
    },
    {
      "id": 2,
      "tasks": ["2.1", "2.2"]
    },
    {
      "id": 3,
      "tasks": ["2.3", "2.4", "2.5"]
    },
    {
      "id": 4,
      "tasks": ["3.1", "3.2"]
    },
    {
      "id": 5,
      "tasks": ["3.3", "4.1"]
    },
    {
      "id": 6,
      "tasks": ["4.2", "6.1"]
    },
    {
      "id": 7,
      "tasks": ["6.2", "6.3"]
    },
    {
      "id": 8,
      "tasks": ["7.1", "7.2", "7.3"]
    },
    {
      "id": 9,
      "tasks": ["8.1", "9.1", "10.1"]
    },
    {
      "id": 10,
      "tasks": ["8.2", "9.2", "10.2", "10.3"]
    },
    {
      "id": 11,
      "tasks": ["11.1", "11.2"]
    },
    {
      "id": 12,
      "tasks": ["12.1", "12.2"]
    },
    {
      "id": 13,
      "tasks": ["12.3", "14.1", "14.2", "14.3"]
    },
    {
      "id": 14,
      "tasks": ["14.4", "14.5", "14.6"]
    }
  ]
}
```
