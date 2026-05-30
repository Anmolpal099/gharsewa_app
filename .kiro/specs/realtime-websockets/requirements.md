# Requirements Document

## Introduction

This document specifies the requirements for implementing real-time features using WebSockets in the Gharsewa home services platform. The system will enable bidirectional communication between the Laravel backend and Flutter clients (web and desktop) to provide instant updates for booking status changes, notifications, and user presence information. The implementation will use JWT-based authentication for secure WebSocket connections and will be deployed within the existing Docker infrastructure.

## Glossary

- **WebSocket_Server**: The Laravel WebSockets service that manages real-time connections and broadcasts events
- **WebSocket_Client**: The Flutter application component that establishes and maintains WebSocket connections
- **JWT_Token**: JSON Web Token used for authenticating WebSocket connections
- **Booking_Event**: A real-time event triggered when a booking status changes
- **Notification_Event**: A real-time event triggered when a new notification is created
- **Presence_Channel**: A WebSocket channel that tracks online/offline status of users
- **Connection_Manager**: The Flutter component responsible for managing WebSocket connection lifecycle
- **Event_Broadcaster**: The Laravel component that publishes events to WebSocket channels
- **Reconnection_Strategy**: The algorithm that handles automatic reconnection with exponential backoff
- **Channel**: A named communication pathway for specific types of events
- **Backend**: The Laravel application server
- **Frontend**: The Flutter application (web and desktop)

## Requirements

### Requirement 1: WebSocket Server Installation and Configuration

**User Story:** As a system administrator, I want to install and configure the Laravel WebSockets server, so that the platform can support real-time communication.

#### Acceptance Criteria

1. THE Backend SHALL install the beyondcode/laravel-websockets package
2. THE WebSocket_Server SHALL listen on a dedicated port separate from the HTTP server
3. THE WebSocket_Server SHALL be configured in the Docker Compose file as a separate service
4. THE Backend SHALL publish WebSocket configuration files to the application config directory
5. WHERE Docker deployment is used, THE WebSocket_Server SHALL start automatically with the application stack

### Requirement 2: WebSocket Authentication

**User Story:** As a security engineer, I want WebSocket connections to be authenticated using JWT tokens, so that only authorized users can establish real-time connections.

#### Acceptance Criteria

1. WHEN a client attempts to establish a WebSocket connection, THE WebSocket_Server SHALL require a valid JWT_Token
2. WHEN an invalid JWT_Token is provided, THE WebSocket_Server SHALL reject the connection with an authentication error
3. WHEN a JWT_Token expires during an active connection, THE WebSocket_Server SHALL close the connection
4. THE WebSocket_Server SHALL validate JWT_Token signatures using the same secret key as the REST API
5. THE WebSocket_Server SHALL extract user identity from the JWT_Token for channel authorization

### Requirement 3: Booking Status Event Broadcasting

**User Story:** As a user, I want to receive instant updates when my booking status changes, so that I know the current state without refreshing the page.

#### Acceptance Criteria

1. WHEN a booking status changes from pending to confirmed, THE Event_Broadcaster SHALL publish a Booking_Event to the user's private channel
2. WHEN a booking status changes from confirmed to completed, THE Event_Broadcaster SHALL publish a Booking_Event to the user's private channel
3. WHEN a booking is cancelled, THE Event_Broadcaster SHALL publish a Booking_Event to the user's private channel
4. THE Booking_Event SHALL include the booking identifier, new status, and timestamp
5. THE Event_Broadcaster SHALL publish Booking_Event to both customer and provider channels for the same booking

### Requirement 4: Notification Event Broadcasting

**User Story:** As a user, I want to receive instant in-app notifications, so that I am immediately aware of important updates.

#### Acceptance Criteria

1. WHEN a new notification is created for a user, THE Event_Broadcaster SHALL publish a Notification_Event to the user's private channel
2. THE Notification_Event SHALL include the notification identifier, title, message, and timestamp
3. THE Notification_Event SHALL include the notification type for proper UI rendering
4. THE Event_Broadcaster SHALL publish Notification_Event within 100 milliseconds of notification creation

### Requirement 5: Presence Channel Implementation

**User Story:** As a user, I want to see which service providers are currently online, so that I can choose providers who are immediately available.

#### Acceptance Criteria

1. WHEN a user establishes a WebSocket connection, THE WebSocket_Server SHALL add the user to the Presence_Channel
2. WHEN a user disconnects, THE WebSocket_Server SHALL remove the user from the Presence_Channel within 5 seconds
3. WHEN a user joins the Presence_Channel, THE WebSocket_Server SHALL broadcast a presence update to all channel subscribers
4. WHEN a user leaves the Presence_Channel, THE WebSocket_Server SHALL broadcast a presence update to all channel subscribers
5. THE Presence_Channel SHALL maintain a list of currently connected user identifiers

### Requirement 6: Flutter WebSocket Client Connection Management

**User Story:** As a mobile developer, I want a robust WebSocket client implementation, so that the Flutter app maintains reliable real-time connections.

#### Acceptance Criteria

1. WHEN the Frontend starts, THE Connection_Manager SHALL establish a WebSocket connection using the stored JWT_Token
2. WHEN the JWT_Token is not available, THE Connection_Manager SHALL defer connection until authentication completes
3. WHEN the WebSocket connection is established, THE Connection_Manager SHALL subscribe to the user's private channel
4. WHEN the WebSocket connection is established, THE Connection_Manager SHALL subscribe to the Presence_Channel
5. THE Connection_Manager SHALL expose connection state (connecting, connected, disconnected, error) to the UI layer

### Requirement 7: Automatic Reconnection with Exponential Backoff

**User Story:** As a user, I want the app to automatically reconnect when the connection is lost, so that I don't miss real-time updates due to temporary network issues.

#### Acceptance Criteria

1. WHEN the WebSocket connection is lost, THE Reconnection_Strategy SHALL attempt to reconnect after 1 second
2. WHEN the first reconnection attempt fails, THE Reconnection_Strategy SHALL wait 2 seconds before the next attempt
3. WHEN subsequent reconnection attempts fail, THE Reconnection_Strategy SHALL double the wait time up to a maximum of 30 seconds
4. WHEN a reconnection succeeds, THE Reconnection_Strategy SHALL reset the wait time to 1 second
5. THE Reconnection_Strategy SHALL continue reconnection attempts indefinitely until successful or explicitly stopped

### Requirement 8: Event Listener Registration

**User Story:** As a mobile developer, I want to register listeners for specific event types, so that different parts of the app can respond to relevant real-time updates.

#### Acceptance Criteria

1. THE Connection_Manager SHALL provide a method to register listeners for Booking_Event
2. THE Connection_Manager SHALL provide a method to register listeners for Notification_Event
3. THE Connection_Manager SHALL provide a method to register listeners for presence updates
4. WHEN a Booking_Event is received, THE Connection_Manager SHALL invoke all registered Booking_Event listeners with the event data
5. WHEN a Notification_Event is received, THE Connection_Manager SHALL invoke all registered Notification_Event listeners with the event data
6. THE Connection_Manager SHALL provide a method to unregister listeners to prevent memory leaks

### Requirement 9: Cross-Platform WebSocket Support

**User Story:** As a product manager, I want WebSocket functionality to work on both web and desktop platforms, so that all users have a consistent real-time experience.

#### Acceptance Criteria

1. THE Connection_Manager SHALL use the web_socket_channel package for cross-platform compatibility
2. WHEN running on web platform, THE Connection_Manager SHALL establish WebSocket connections using the browser WebSocket API
3. WHEN running on desktop platform, THE Connection_Manager SHALL establish WebSocket connections using native socket implementation
4. THE Connection_Manager SHALL provide identical API and behavior across web and desktop platforms
5. THE Connection_Manager SHALL handle platform-specific connection errors appropriately

### Requirement 10: Real-Time Booking List Updates

**User Story:** As a user, I want my booking list to update automatically when booking statuses change, so that I always see current information without manual refresh.

#### Acceptance Criteria

1. WHEN a Booking_Event is received, THE Frontend SHALL update the corresponding booking in the displayed list
2. WHEN a booking is not currently in the displayed list, THE Frontend SHALL add it if it matches the current filter criteria
3. WHEN a booking status changes to completed, THE Frontend SHALL move it to the completed bookings section
4. THE Frontend SHALL animate booking list changes to provide visual feedback
5. THE Frontend SHALL maintain scroll position when updating the booking list

### Requirement 11: In-App Notification Display

**User Story:** As a user, I want to see real-time notifications appear in the app, so that I am immediately informed of important events.

#### Acceptance Criteria

1. WHEN a Notification_Event is received, THE Frontend SHALL display a notification banner at the top of the screen
2. THE Frontend SHALL display the notification title and message from the Notification_Event
3. THE Frontend SHALL automatically dismiss the notification banner after 5 seconds
4. WHEN a user taps the notification banner, THE Frontend SHALL navigate to the relevant screen
5. THE Frontend SHALL increment the unread notification count when a Notification_Event is received

### Requirement 12: Online Presence Indicators

**User Story:** As a customer, I want to see which service providers are currently online, so that I can prioritize providers who are immediately available.

#### Acceptance Criteria

1. WHEN displaying a list of service providers, THE Frontend SHALL show an online indicator for users in the Presence_Channel
2. WHEN a presence update is received, THE Frontend SHALL update the online indicator within 1 second
3. THE Frontend SHALL display online indicators as a green dot next to the provider's name
4. THE Frontend SHALL display offline status as a gray dot or no indicator
5. WHERE a provider profile is displayed, THE Frontend SHALL show the last seen timestamp for offline providers

### Requirement 13: Connection State UI Feedback

**User Story:** As a user, I want to know when the real-time connection is active or experiencing issues, so that I understand whether I'm receiving live updates.

#### Acceptance Criteria

1. WHEN the WebSocket connection is connecting, THE Frontend SHALL display a "Connecting..." indicator
2. WHEN the WebSocket connection is connected, THE Frontend SHALL display a "Live" indicator with a green status
3. WHEN the WebSocket connection is disconnected, THE Frontend SHALL display a "Disconnected" indicator with a red status
4. WHEN the Reconnection_Strategy is attempting to reconnect, THE Frontend SHALL display "Reconnecting..." with the attempt count
5. THE Frontend SHALL position connection status indicators in a non-intrusive location such as the app bar

### Requirement 14: Graceful Degradation

**User Story:** As a user, I want the app to remain functional when WebSocket connections are unavailable, so that I can still use core features during connectivity issues.

#### Acceptance Criteria

1. WHEN the WebSocket connection fails to establish after 5 attempts, THE Frontend SHALL continue operating with polling-based updates
2. WHEN operating without WebSocket connection, THE Frontend SHALL poll for booking updates every 30 seconds
3. WHEN operating without WebSocket connection, THE Frontend SHALL poll for notifications every 60 seconds
4. WHEN the WebSocket connection is restored, THE Frontend SHALL disable polling and resume real-time updates
5. THE Frontend SHALL display a message informing users that real-time updates are temporarily unavailable

### Requirement 15: WebSocket Server Scalability

**User Story:** As a system administrator, I want the WebSocket server to handle multiple concurrent connections efficiently, so that the system can scale with user growth.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL support at least 1000 concurrent connections on a single instance
2. THE WebSocket_Server SHALL use Redis for horizontal scaling across multiple instances
3. WHEN multiple WebSocket_Server instances are running, THE Event_Broadcaster SHALL publish events to all instances via Redis
4. THE WebSocket_Server SHALL log connection count metrics every 60 seconds
5. THE WebSocket_Server SHALL reject new connections when the maximum connection limit is reached

### Requirement 16: WebSocket Security Configuration

**User Story:** As a security engineer, I want WebSocket connections to be secured with proper configuration, so that the system is protected against common WebSocket vulnerabilities.

#### Acceptance Criteria

1. WHERE production environment is used, THE WebSocket_Server SHALL require secure WebSocket connections (WSS protocol)
2. THE WebSocket_Server SHALL validate the origin header to prevent cross-site WebSocket hijacking
3. THE WebSocket_Server SHALL implement rate limiting of 100 messages per minute per connection
4. WHEN rate limiting is exceeded, THE WebSocket_Server SHALL close the connection with a rate limit error
5. THE WebSocket_Server SHALL log all authentication failures for security monitoring

### Requirement 17: Event Payload Validation

**User Story:** As a backend developer, I want event payloads to be validated before broadcasting, so that clients receive well-formed data.

#### Acceptance Criteria

1. WHEN broadcasting a Booking_Event, THE Event_Broadcaster SHALL validate that the booking identifier is present
2. WHEN broadcasting a Booking_Event, THE Event_Broadcaster SHALL validate that the status is a valid booking status value
3. WHEN broadcasting a Notification_Event, THE Event_Broadcaster SHALL validate that the notification identifier, title, and message are present
4. IF event payload validation fails, THEN THE Event_Broadcaster SHALL log an error and skip broadcasting
5. THE Event_Broadcaster SHALL serialize event payloads as JSON before broadcasting

### Requirement 18: WebSocket Connection Lifecycle Management

**User Story:** As a mobile developer, I want proper connection lifecycle management, so that WebSocket connections are cleaned up appropriately.

#### Acceptance Criteria

1. WHEN the Frontend app is paused or backgrounded, THE Connection_Manager SHALL close the WebSocket connection
2. WHEN the Frontend app is resumed or foregrounded, THE Connection_Manager SHALL re-establish the WebSocket connection
3. WHEN a user logs out, THE Connection_Manager SHALL close the WebSocket connection immediately
4. WHEN a user logs in, THE Connection_Manager SHALL establish a new WebSocket connection with the new JWT_Token
5. THE Connection_Manager SHALL dispose of all event listeners when the connection is closed

### Requirement 19: WebSocket Monitoring and Logging

**User Story:** As a system administrator, I want comprehensive logging of WebSocket activity, so that I can troubleshoot connection issues and monitor system health.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL log all connection establishment attempts with user identifier and timestamp
2. THE WebSocket_Server SHALL log all connection closures with reason code and duration
3. THE WebSocket_Server SHALL log all authentication failures with client IP address
4. THE WebSocket_Server SHALL log all event broadcasts with event type and channel name
5. WHERE an error occurs during event broadcasting, THE WebSocket_Server SHALL log the error with full stack trace

### Requirement 20: WebSocket Health Check Endpoint

**User Story:** As a DevOps engineer, I want a health check endpoint for the WebSocket server, so that monitoring systems can verify service availability.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL expose an HTTP health check endpoint at /health
2. WHEN the health check endpoint is accessed, THE WebSocket_Server SHALL return HTTP 200 if the service is operational
3. THE health check response SHALL include the current connection count
4. THE health check response SHALL include the server uptime
5. IF the WebSocket_Server cannot connect to Redis, THEN the health check SHALL return HTTP 503
