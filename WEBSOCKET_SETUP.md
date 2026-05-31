# WebSocket Real-Time Updates Setup Guide

This document provides comprehensive instructions for setting up and testing the WebSocket real-time updates feature in the Gharsewa application.

## Overview

The Gharsewa application uses **Laravel Reverb** for WebSocket server functionality, providing real-time updates for:
- Booking status changes
- Notifications
- User presence tracking (online/offline status)
- Graceful degradation with HTTP polling fallback

## Architecture

### Backend (Laravel Reverb)
- **WebSocket Server**: Laravel Reverb with Redis scaling
- **Broadcasting**: Laravel Broadcasting with Pusher protocol
- **Authentication**: JWT-based WebSocket authentication middleware
- **Events**: BookingStatusChanged, NotificationCreated
- **Channels**: Private channels for bookings/notifications, Presence channels for online status

### Frontend (Flutter)
- **WebSocket Client**: `web_socket_channel` package for cross-platform support
- **State Management**: Riverpod for reactive state management
- **Connection Manager**: Automatic reconnection with exponential backoff
- **Fallback**: HTTP polling after 5 failed connection attempts

## Prerequisites

- Docker and Docker Compose installed
- PHP 8.2+ with Laravel 11
- Flutter 3.44.0+
- Redis server (included in Docker Compose)

## Environment Configuration

### Backend (.env)

Add the following environment variables to your `backend/.env` file:

```env
# Broadcasting Configuration
BROADCAST_DRIVER=reverb

# Reverb Configuration
REVERB_APP_ID=gharsewa-app
REVERB_APP_KEY=your-reverb-app-key-here
REVERB_APP_SECRET=your-reverb-app-secret-here
REVERB_HOST=0.0.0.0
REVERB_PORT=8080
REVERB_SCHEME=http

# Redis Configuration (for Reverb scaling)
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Queue Configuration (for broadcasting)
QUEUE_CONNECTION=redis
```

### Frontend (lib/core/config/env_config.dart)

The frontend WebSocket configuration is managed in `EnvConfig`:

```dart
class EnvConfig {
  // WebSocket Configuration
  static const String wsUrl = 'ws://localhost:8080/app/gharsewa-app';
  static const String reverbAppKey = 'your-reverb-app-key-here';
  static const bool useSecureWebSocket = false; // Set to true for wss://
}
```

**Important**: 
- For production, use `wss://` (secure WebSocket) and set `useSecureWebSocket = true`
- Update `wsUrl` to match your production Reverb server URL
- Ensure `reverbAppKey` matches the backend `REVERB_APP_KEY`

## Docker Compose Setup

The WebSocket server is configured in `backend/docker-compose.yml`:

```yaml
services:
  reverb:
    image: php:8.2-cli
    container_name: gharsewa-reverb
    working_dir: /var/www
    volumes:
      - ./:/var/www
    ports:
      - "8080:8080"
    command: php artisan reverb:start --host=0.0.0.0 --port=8080
    depends_on:
      - redis
    networks:
      - gharsewa-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Installation Steps

### 1. Backend Setup

```bash
cd backend

# Install dependencies
composer install

# Generate Reverb configuration
php artisan reverb:install

# Run migrations (if not already done)
php artisan migrate

# Start Docker services (including Reverb)
docker-compose up -d
```

### 2. Frontend Setup

```bash
# Install dependencies
flutter pub get

# Generate freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run -d chrome  # For web
flutter run -d windows # For Windows desktop
```

## Testing WebSocket Functionality

### 1. Test WebSocket Connection

1. Start the backend services:
   ```bash
   cd backend
   docker-compose up -d
   ```

2. Verify Reverb is running:
   ```bash
   curl http://localhost:8080/health
   ```
   Expected response: `{"status":"ok"}`

3. Start the Flutter app and log in

4. Check the connection status indicator in the app:
   - **Green "Live"**: WebSocket connected successfully
   - **Orange "Connecting..."**: Attempting to connect
   - **Red "Disconnected"**: Connection failed

### 2. Test Booking Status Updates

1. Create a test booking through the app

2. Update the booking status via API or admin panel:
   ```bash
   curl -X PATCH http://localhost:8000/api/bookings/{booking_id}/status \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"status":"confirmed"}'
   ```

3. Verify the Flutter app receives the update in real-time:
   - Booking list updates automatically
   - Notification banner appears
   - No page refresh required

### 3. Test Notification Flow

1. Create a test notification via API:
   ```bash
   curl -X POST http://localhost:8000/api/notifications \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": 1,
       "title": "Test Notification",
       "message": "This is a test notification",
       "type": "info"
     }'
   ```

2. Verify the Flutter app:
   - Displays notification banner
   - Banner auto-dismisses after 5 seconds
   - Unread count increments

### 4. Test Presence Tracking

1. Open the app in multiple browser tabs or devices

2. Log in with different user accounts

3. Navigate to a screen showing online indicators (e.g., provider list)

4. Verify:
   - Online users show green dot
   - Offline users show gray dot or no indicator
   - Status updates within 1 second of connection/disconnection

### 5. Test Connection Lifecycle

1. **Test Reconnection**:
   - Stop the Reverb server: `docker-compose stop reverb`
   - Observe "Reconnecting..." status with attempt count
   - Restart the server: `docker-compose start reverb`
   - Verify automatic reconnection

2. **Test App Pause/Resume**:
   - Minimize the app or switch tabs
   - Wait 30 seconds
   - Return to the app
   - Verify connection is restored

3. **Test Logout/Login**:
   - Log out of the app
   - Verify WebSocket disconnects
   - Log back in
   - Verify WebSocket reconnects

### 6. Test Graceful Degradation (Polling Fallback)

1. Stop the Reverb server:
   ```bash
   docker-compose stop reverb
   ```

2. Wait for 5 connection attempts to fail (approximately 30 seconds)

3. Verify polling fallback activates:
   - Orange "Polling mode" indicator appears
   - Banner: "Real-time updates temporarily unavailable"
   - Updates still work via HTTP polling (every 30-60 seconds)

4. Restart the Reverb server:
   ```bash
   docker-compose start reverb
   ```

5. Verify:
   - WebSocket reconnects automatically
   - Polling deactivates
   - "Live" status indicator returns

### 7. Test Cross-Platform Compatibility

Test the WebSocket connection on multiple platforms:

```bash
# Web (Chrome)
flutter run -d chrome

# Web (Firefox)
flutter run -d web-server --web-port=8081
# Then open http://localhost:8081 in Firefox

# Windows Desktop
flutter run -d windows

# macOS Desktop (if available)
flutter run -d macos

# Linux Desktop (if available)
flutter run -d linux
```

Verify identical behavior across all platforms.

## Monitoring and Debugging

### Backend Logs

View Reverb server logs:
```bash
docker-compose logs -f reverb
```

View Laravel logs:
```bash
tail -f backend/storage/logs/laravel.log
```

### Frontend Logs

The WebSocket connection manager logs all connection events:
- Connection attempts
- Successful connections
- Disconnections
- Reconnection attempts
- Polling activation/deactivation

Check the Flutter console for detailed logs.

### Health Check Endpoint

Check WebSocket server health:
```bash
curl http://localhost:8080/health
```

Check Laravel health:
```bash
curl http://localhost:8000/api/health/websocket
```

## Troubleshooting

### Connection Fails Immediately

**Symptoms**: Red "Disconnected" status, no reconnection attempts

**Solutions**:
1. Verify Reverb is running: `docker-compose ps`
2. Check Reverb logs: `docker-compose logs reverb`
3. Verify `REVERB_APP_KEY` matches in backend `.env` and frontend `EnvConfig`
4. Check firewall settings (port 8080 must be open)

### Connection Succeeds but No Events Received

**Symptoms**: Green "Live" status, but no real-time updates

**Solutions**:
1. Verify JWT token is valid and not expired
2. Check channel authorization in `backend/routes/channels.php`
3. Verify events are being broadcast: check Laravel logs
4. Ensure Redis is running: `docker-compose ps redis`

### Polling Fallback Not Activating

**Symptoms**: Connection fails but polling doesn't start

**Solutions**:
1. Verify `PollingService` is initialized in the app
2. Check that 5 connection attempts have failed (wait ~30 seconds)
3. Review frontend logs for polling service messages

### Cross-Platform Issues

**Symptoms**: Works on web but not desktop (or vice versa)

**Solutions**:
1. Verify `web_socket_channel` package is compatible with the platform
2. Check platform-specific network permissions
3. For web: ensure CORS is configured correctly in backend
4. For desktop: check firewall and antivirus settings

## Production Deployment

### Backend

1. Update `.env` for production:
   ```env
   REVERB_SCHEME=https
   REVERB_HOST=your-domain.com
   REVERB_PORT=443
   ```

2. Configure SSL/TLS for Reverb (use reverse proxy like Nginx)

3. Scale Reverb with Redis:
   ```bash
   php artisan reverb:start --host=0.0.0.0 --port=8080 --scaling=redis
   ```

### Frontend

1. Update `EnvConfig` for production:
   ```dart
   static const String wsUrl = 'wss://your-domain.com/app/gharsewa-app';
   static const bool useSecureWebSocket = true;
   ```

2. Build for production:
   ```bash
   flutter build web --release
   flutter build windows --release
   ```

## Performance Considerations

- **Connection Pooling**: Reverb supports up to 10,000 concurrent connections per instance
- **Redis Scaling**: Use Redis for horizontal scaling across multiple Reverb instances
- **Polling Fallback**: Reduces server load when WebSocket is unavailable
- **Exponential Backoff**: Prevents connection storms during outages

## Security Considerations

- **JWT Authentication**: All WebSocket connections require valid JWT tokens
- **Channel Authorization**: Private and presence channels enforce user permissions
- **HTTPS/WSS**: Always use secure connections in production
- **Rate Limiting**: Implement rate limiting for WebSocket connections
- **Input Validation**: Validate all event data before broadcasting

## API Reference

### WebSocket Events

#### BookingStatusChanged
```json
{
  "event": "booking.status.changed",
  "data": {
    "booking_id": 123,
    "status": "confirmed",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

#### NotificationCreated
```json
{
  "event": "notification.created",
  "data": {
    "id": 456,
    "title": "Booking Confirmed",
    "message": "Your booking has been confirmed",
    "type": "success",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### Channel Names

- **Private Booking Channel**: `private-booking.{user_id}`
- **Private Notification Channel**: `private-notification.{user_id}`
- **Presence Provider Channel**: `presence-providers`
- **Presence Customer Channel**: `presence-customers`

## Additional Resources

- [Laravel Reverb Documentation](https://laravel.com/docs/11.x/reverb)
- [Laravel Broadcasting Documentation](https://laravel.com/docs/11.x/broadcasting)
- [Flutter web_socket_channel Package](https://pub.dev/packages/web_socket_channel)
- [Riverpod Documentation](https://riverpod.dev/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review backend and frontend logs
3. Consult the Laravel Reverb documentation
4. Open an issue in the project repository

---

**Last Updated**: January 2024
**Version**: 1.0.0
