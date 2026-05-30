# Design Document: Real-Time WebSocket Communication

## Overview

This design document specifies the technical implementation of real-time bidirectional communication for the Gharsewa home services platform using WebSockets. The system enables instant updates for booking status changes, notifications, and user presence tracking across Flutter web and desktop clients.

### Technology Stack

**Backend:**
- **Laravel Reverb**: Modern, scalable WebSocket server built into Laravel 11
- **Redis**: Message broker for horizontal scaling and pub/sub
- **JWT Authentication**: Secure connection authentication using existing JWT infrastructure

**Frontend:**
- **web_socket_channel**: Cross-platform WebSocket client (web and desktop)
- **Riverpod**: State management for connection state and event handling
- **Dio**: HTTP client for fallback polling

### Key Design Decisions

1. **Laravel Reverb over beyondcode/laravel-websockets**: Reverb is the official Laravel WebSocket solution with better performance, native Laravel 11 integration, and active maintenance.

2. **web_socket_channel over pusher_channels_flutter**: Direct WebSocket implementation provides more control, reduces dependencies, and works seamlessly across web/desktop platforms.

3. **JWT-based authentication**: Leverages existing authentication infrastructure, avoiding separate auth mechanisms.

4. **Redis pub/sub**: Enables horizontal scaling across multiple Reverb instances for production scalability.

5. **Graceful degradation**: Automatic fallback to HTTP polling ensures functionality during WebSocket unavailability.


## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  UI Layer (Screens, Widgets)                              │  │
│  └────────────────┬─────────────────────────────────────────┘  │
│                   │                                              │
│  ┌────────────────▼─────────────────────────────────────────┐  │
│  │  State Management (Riverpod Providers)                    │  │
│  │  - BookingNotifier                                        │  │
│  │  - NotificationNotifier                                   │  │
│  │  - PresenceNotifier                                       │  │
│  └────────────────┬─────────────────────────────────────────┘  │
│                   │                                              │
│  ┌────────────────▼─────────────────────────────────────────┐  │
│  │  WebSocketConnectionManager                               │  │
│  │  - Connection lifecycle                                   │  │
│  │  - Event routing                                          │  │
│  │  - Reconnection strategy                                  │  │
│  └────────────────┬─────────────────────────────────────────┘  │
│                   │                                              │
│  ┌────────────────▼─────────────────────────────────────────┐  │
│  │  web_socket_channel                                       │  │
│  └────────────────┬─────────────────────────────────────────┘  │
└───────────────────┼──────────────────────────────────────────┘
                    │ WSS Connection (JWT Auth)
                    │
┌───────────────────▼──────────────────────────────────────────┐
│                   Laravel Backend                             │
│  ┌──────────────────────────────────────────────────────────┐│
│  │  Laravel Reverb WebSocket Server                         ││
│  │  - Connection authentication                             ││
│  │  - Channel authorization                                 ││
│  │  - Event broadcasting                                    ││
│  └────────────────┬─────────────────────────────────────────┘│
│                   │                                            │
│  ┌────────────────▼─────────────────────────────────────────┐│
│  │  Redis Pub/Sub                                           ││
│  │  - Message broker                                        ││
│  │  - Horizontal scaling                                    ││
│  └────────────────┬─────────────────────────────────────────┘│
│                   │                                            │
│  ┌────────────────▼─────────────────────────────────────────┐│
│  │  Application Layer                                       ││
│  │  - BookingController                                     ││
│  │  - NotificationService                                   ││
│  │  - Event Broadcasters                                    ││
│  └──────────────────────────────────────────────────────────┘│
└───────────────────────────────────────────────────────────────┘
```


### Connection Flow

```
┌────────┐                  ┌──────────┐                 ┌────────┐
│ Client │                  │  Reverb  │                 │  Redis │
└───┬────┘                  └────┬─────┘                 └───┬────┘
    │                            │                           │
    │ 1. Connect with JWT        │                           │
    ├───────────────────────────>│                           │
    │                            │                           │
    │                            │ 2. Validate JWT           │
    │                            │                           │
    │                            │ 3. Subscribe to Redis     │
    │                            ├──────────────────────────>│
    │                            │                           │
    │ 4. Connection Established  │                           │
    │<───────────────────────────┤                           │
    │                            │                           │
    │ 5. Subscribe to channels   │                           │
    ├───────────────────────────>│                           │
    │                            │                           │
    │ 6. Subscription confirmed  │                           │
    │<───────────────────────────┤                           │
    │                            │                           │
    │                            │ 7. Event published        │
    │                            │<──────────────────────────┤
    │                            │                           │
    │ 8. Event delivered         │                           │
    │<───────────────────────────┤                           │
    │                            │                           │
```

### Channel Structure

**Private Channels** (user-specific):
- `private-user.{userId}`: User-specific events (bookings, notifications)
- `private-booking.{bookingId}`: Booking-specific events for involved parties

**Presence Channels** (online status):
- `presence-providers`: Online service providers
- `presence-customers`: Online customers


## Components and Interfaces

### Backend Components

#### 1. Reverb Configuration

**File**: `config/reverb.php`

```php
return [
    'default' => env('REVERB_SERVER', 'reverb'),
    
    'servers' => [
        'reverb' => [
            'host' => env('REVERB_SERVER_HOST', '0.0.0.0'),
            'port' => env('REVERB_SERVER_PORT', 6001),
            'hostname' => env('REVERB_HOST', 'localhost'),
            'options' => [
                'tls' => [
                    'local_cert' => env('REVERB_TLS_CERT'),
                    'local_pk' => env('REVERB_TLS_KEY'),
                ],
            ],
            'scaling' => [
                'enabled' => env('REVERB_SCALING_ENABLED', true),
                'channel' => env('REVERB_SCALING_CHANNEL', 'reverb'),
            ],
            'pulse_ingest_interval' => env('REVERB_PULSE_INGEST_INTERVAL', 15),
            'telescope_ingest_interval' => env('REVERB_TELESCOPE_INGEST_INTERVAL', 15),
        ],
    ],
    
    'apps' => [
        [
            'id' => env('REVERB_APP_ID'),
            'key' => env('REVERB_APP_KEY'),
            'secret' => env('REVERB_APP_SECRET'),
            'capacity' => env('REVERB_APP_CAPACITY', 10000),
            'allowed_origins' => ['*'],
            'ping_interval' => env('REVERB_APP_PING_INTERVAL', 60),
            'max_message_size' => env('REVERB_APP_MAX_MESSAGE_SIZE', 10000),
        ],
    ],
];
```


#### 2. Broadcasting Configuration

**File**: `config/broadcasting.php`

```php
'connections' => [
    'reverb' => [
        'driver' => 'reverb',
        'key' => env('REVERB_APP_KEY'),
        'secret' => env('REVERB_APP_SECRET'),
        'app_id' => env('REVERB_APP_ID'),
        'options' => [
            'host' => env('REVERB_HOST', 'localhost'),
            'port' => env('REVERB_PORT', 6001),
            'scheme' => env('REVERB_SCHEME', 'http'),
            'useTLS' => env('REVERB_SCHEME', 'http') === 'https',
        ],
    ],
],
```

#### 3. JWT Authentication Middleware

**File**: `app/Http/Middleware/WebSocketAuthMiddleware.php`

```php
class WebSocketAuthMiddleware
{
    public function handle($request, Closure $next)
    {
        $token = $request->query('token') ?? $request->header('Authorization');
        
        if (!$token) {
            throw new UnauthorizedException('Missing authentication token');
        }
        
        try {
            $payload = JWTAuth::setToken($token)->getPayload();
            $user = User::find($payload->get('sub'));
            
            if (!$user) {
                throw new UnauthorizedException('User not found');
            }
            
            Auth::setUser($user);
            return $next($request);
            
        } catch (TokenExpiredException $e) {
            throw new UnauthorizedException('Token expired');
        } catch (JWTException $e) {
            throw new UnauthorizedException('Invalid token');
        }
    }
}
```


#### 4. Channel Authorization

**File**: `routes/channels.php`

```php
Broadcast::channel('user.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

Broadcast::channel('booking.{bookingId}', function ($user, $bookingId) {
    $booking = Booking::find($bookingId);
    return $booking && (
        $booking->customer_id === $user->id || 
        $booking->provider_id === $user->id
    );
});

Broadcast::channel('providers', function ($user) {
    return $user->hasRole('provider') ? [
        'id' => $user->id,
        'name' => $user->name,
    ] : null;
});

Broadcast::channel('customers', function ($user) {
    return $user->hasRole('customer') ? [
        'id' => $user->id,
        'name' => $user->name,
    ] : null;
});
```


#### 5. Event Classes

**File**: `app/Events/BookingStatusChanged.php`

```php
class BookingStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    
    public function __construct(
        public Booking $booking,
        public string $oldStatus,
        public string $newStatus
    ) {}
    
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("user.{$this->booking->customer_id}"),
            new PrivateChannel("user.{$this->booking->provider_id}"),
            new PrivateChannel("booking.{$this->booking->id}"),
        ];
    }
    
    public function broadcastAs(): string
    {
        return 'booking.status.changed';
    }
    
    public function broadcastWith(): array
    {
        return [
            'booking_id' => $this->booking->id,
            'old_status' => $this->oldStatus,
            'new_status' => $this->newStatus,
            'timestamp' => now()->toIso8601String(),
        ];
    }
}
```

**File**: `app/Events/NotificationCreated.php`

```php
class NotificationCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    
    public function __construct(
        public Notification $notification
    ) {}
    
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("user.{$this->notification->user_id}"),
        ];
    }
    
    public function broadcastAs(): string
    {
        return 'notification.created';
    }
    
    public function broadcastWith(): array
    {
        return [
            'id' => $this->notification->id,
            'title' => $this->notification->title,
            'message' => $this->notification->message,
            'type' => $this->notification->type,
            'timestamp' => $this->notification->created_at->toIso8601String(),
        ];
    }
}
```


#### 6. Health Check Controller

**File**: `app/Http/Controllers/WebSocketHealthController.php`

```php
class WebSocketHealthController extends Controller
{
    public function health()
    {
        try {
            $redis = Redis::connection();
            $redis->ping();
            
            $stats = [
                'status' => 'healthy',
                'uptime' => $this->getUptime(),
                'connections' => $this->getConnectionCount(),
                'redis' => 'connected',
                'timestamp' => now()->toIso8601String(),
            ];
            
            return response()->json($stats, 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'unhealthy',
                'error' => 'Redis connection failed',
                'timestamp' => now()->toIso8601String(),
            ], 503);
        }
    }
    
    private function getUptime(): int
    {
        // Implementation depends on process tracking
        return 0;
    }
    
    private function getConnectionCount(): int
    {
        // Implementation depends on Reverb metrics
        return 0;
    }
}
```


### Frontend Components

#### 1. WebSocket Connection Manager

**File**: `lib/core/websocket/websocket_connection_manager.dart`

```dart
class WebSocketConnectionManager {
  final String wsUrl;
  final String Function() getToken;
  
  WebSocketChannel? _channel;
  ConnectionState _state = ConnectionState.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  
  Stream<ConnectionState> get stateStream => _stateController.stream;
  Stream<WebSocketEvent> get eventStream => _eventController.stream;
  ConnectionState get state => _state;
  
  Future<void> connect() async {
    if (_state == ConnectionState.connected || 
        _state == ConnectionState.connecting) {
      return;
    }
    
    _updateState(ConnectionState.connecting);
    
    try {
      final token = getToken();
      final uri = Uri.parse('$wsUrl?token=$token');
      
      _channel = WebSocketChannel.connect(uri);
      
      await _channel!.ready;
      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
    } catch (e) {
      _handleError(e);
    }
  }
  
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _updateState(ConnectionState.disconnected);
  }
  
  void subscribe(String channel) {
    _send({
      'event': 'pusher:subscribe',
      'data': {'channel': channel},
    });
  }
  
  void _handleMessage(dynamic message) {
    final data = jsonDecode(message);
    final event = WebSocketEvent.fromJson(data);
    _eventController.add(event);
  }
  
  void _handleError(dynamic error) {
    _updateState(ConnectionState.error);
    _scheduleReconnect();
  }
  
  void _handleDisconnect() {
    _updateState(ConnectionState.disconnected);
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    final delay = _calculateBackoff();
    _reconnectTimer = Timer(delay, connect);
  }
  
  Duration _calculateBackoff() {
    final seconds = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;
    return Duration(seconds: seconds);
  }
  
  void _updateState(ConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }
  
  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }
  
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _eventController.close();
  }
}
```


#### 2. WebSocket Provider (Riverpod)

**File**: `lib/core/websocket/websocket_provider.dart`

```dart
@riverpod
class WebSocketConnection extends _$WebSocketConnection {
  WebSocketConnectionManager? _manager;
  
  @override
  ConnectionState build() {
    final authState = ref.watch(authProvider);
    
    if (authState.isAuthenticated) {
      _initializeConnection();
    } else {
      _manager?.disconnect();
    }
    
    return ConnectionState.disconnected;
  }
  
  void _initializeConnection() {
    _manager ??= WebSocketConnectionManager(
      wsUrl: 'ws://localhost:6001/app/${Environment.reverbAppKey}',
      getToken: () => ref.read(authProvider).token ?? '',
    );
    
    _manager!.stateStream.listen((newState) {
      state = newState;
    });
    
    _manager!.connect();
  }
  
  void subscribe(String channel) {
    _manager?.subscribe(channel);
  }
  
  Stream<WebSocketEvent> get eventStream => 
    _manager?.eventStream ?? Stream.empty();
}

@riverpod
Stream<WebSocketEvent> bookingEvents(BookingEventsRef ref) {
  final connection = ref.watch(webSocketConnectionProvider.notifier);
  return connection.eventStream
    .where((event) => event.event == 'booking.status.changed');
}

@riverpod
Stream<WebSocketEvent> notificationEvents(NotificationEventsRef ref) {
  final connection = ref.watch(webSocketConnectionProvider.notifier);
  return connection.eventStream
    .where((event) => event.event == 'notification.created');
}
```


#### 3. Booking Event Listener

**File**: `lib/features/bookings/providers/booking_realtime_provider.dart`

```dart
@riverpod
class BookingRealtime extends _$BookingRealtime {
  StreamSubscription? _subscription;
  
  @override
  void build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    
    _subscription = ref
      .watch(bookingEventsProvider)
      .listen(_handleBookingEvent);
  }
  
  void _handleBookingEvent(WebSocketEvent event) {
    final bookingId = event.data['booking_id'] as String;
    final newStatus = event.data['new_status'] as String;
    
    // Update booking in local state
    ref.read(bookingListProvider.notifier)
      .updateBookingStatus(bookingId, newStatus);
    
    // Show notification if needed
    if (_shouldShowNotification(newStatus)) {
      ref.read(snackbarProvider.notifier)
        .show('Booking status updated to $newStatus');
    }
  }
  
  bool _shouldShowNotification(String status) {
    return ['confirmed', 'completed', 'cancelled'].contains(status);
  }
}
```


#### 4. Connection Status Widget

**File**: `lib/core/websocket/widgets/connection_status_indicator.dart`

```dart
class ConnectionStatusIndicator extends ConsumerWidget {
  const ConnectionStatusIndicator({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(webSocketConnectionProvider);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor(connectionState),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(connectionState),
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            _getLabel(connectionState),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getColor(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => Colors.green,
      ConnectionState.connecting => Colors.orange,
      ConnectionState.disconnected => Colors.grey,
      ConnectionState.error => Colors.red,
    };
  }
  
  IconData _getIcon(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => Icons.check_circle,
      ConnectionState.connecting => Icons.sync,
      ConnectionState.disconnected => Icons.cloud_off,
      ConnectionState.error => Icons.error,
    };
  }
  
  String _getLabel(ConnectionState state) {
    return switch (state) {
      ConnectionState.connected => 'Live',
      ConnectionState.connecting => 'Connecting...',
      ConnectionState.disconnected => 'Offline',
      ConnectionState.error => 'Error',
    };
  }
}
```


## Data Models

### WebSocket Event Model

**File**: `lib/core/websocket/models/websocket_event.dart`

```dart
@freezed
class WebSocketEvent with _$WebSocketEvent {
  const factory WebSocketEvent({
    required String event,
    required String channel,
    required Map<String, dynamic> data,
    @Default(null) String? timestamp,
  }) = _WebSocketEvent;
  
  factory WebSocketEvent.fromJson(Map<String, dynamic> json) =>
    _$WebSocketEventFromJson(json);
}
```

### Connection State Enum

```dart
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}
```

### Booking Event Data

```dart
@freezed
class BookingEventData with _$BookingEventData {
  const factory BookingEventData({
    required String bookingId,
    required String oldStatus,
    required String newStatus,
    required DateTime timestamp,
  }) = _BookingEventData;
  
  factory BookingEventData.fromJson(Map<String, dynamic> json) =>
    _$BookingEventDataFromJson(json);
}
```

### Notification Event Data

```dart
@freezed
class NotificationEventData with _$NotificationEventData {
  const factory NotificationEventData({
    required String id,
    required String title,
    required String message,
    required String type,
    required DateTime timestamp,
  }) = _NotificationEventData;
  
  factory NotificationEventData.fromJson(Map<String, dynamic> json) =>
    _$NotificationEventDataFromJson(json);
}
```

### Presence Member

```dart
@freezed
class PresenceMember with _$PresenceMember {
  const factory PresenceMember({
    required String id,
    required String name,
    @Default(null) String? avatar,
  }) = _PresenceMember;
  
  factory PresenceMember.fromJson(Map<String, dynamic> json) =>
    _$PresenceMemberFromJson(json);
}
```


## Error Handling

### Backend Error Handling

#### 1. Authentication Errors

**Scenario**: Invalid or expired JWT token
- **Response**: Close connection with 4401 code
- **Logging**: Log authentication failure with client IP
- **Client Action**: Attempt to refresh token and reconnect

**Scenario**: Missing authentication token
- **Response**: Reject connection immediately with 4401 code
- **Logging**: Log unauthorized connection attempt
- **Client Action**: Defer connection until authentication completes

#### 2. Authorization Errors

**Scenario**: User attempts to subscribe to unauthorized channel
- **Response**: Send subscription error event
- **Logging**: Log authorization failure with user ID and channel
- **Client Action**: Display error message, do not retry

#### 3. Rate Limiting

**Scenario**: Client exceeds 100 messages per minute
- **Response**: Close connection with 4429 code
- **Logging**: Log rate limit violation with user ID
- **Client Action**: Exponential backoff before reconnection

#### 4. Redis Connection Failures

**Scenario**: Redis becomes unavailable
- **Response**: Continue accepting connections but log errors
- **Logging**: Log Redis connection errors with stack trace
- **Recovery**: Automatic reconnection with exponential backoff
- **Monitoring**: Health check returns 503 status


#### 5. Event Broadcasting Failures

**Scenario**: Event payload validation fails
- **Response**: Skip broadcasting, log error
- **Logging**: Log validation error with event type and payload
- **Recovery**: No automatic retry (requires code fix)

**Scenario**: Broadcasting to channel fails
- **Response**: Log error, continue with other channels
- **Logging**: Log broadcast failure with channel and error
- **Recovery**: Event will be missed (acceptable for real-time)

### Frontend Error Handling

#### 1. Connection Failures

**Scenario**: Initial connection fails
- **Action**: Display "Connecting..." indicator
- **Recovery**: Automatic reconnection with exponential backoff (1s, 2s, 4s, 8s, 16s, 30s max)
- **Fallback**: After 5 failed attempts, switch to HTTP polling

**Scenario**: Connection drops during active session
- **Action**: Display "Reconnecting..." indicator
- **Recovery**: Immediate reconnection attempt, then exponential backoff
- **State**: Maintain subscription list for re-subscription after reconnection

#### 2. Message Parsing Errors

**Scenario**: Received message is malformed JSON
- **Action**: Log error, discard message
- **Recovery**: Continue listening for next message
- **Monitoring**: Track parsing error rate

**Scenario**: Event data missing required fields
- **Action**: Log error with event type
- **Recovery**: Discard event, continue processing
- **Monitoring**: Track validation error rate


#### 3. Platform-Specific Errors

**Web Platform**:
- **Browser WebSocket API errors**: Map to ConnectionState.error
- **CORS issues**: Ensure Reverb allows origin
- **Mixed content (HTTP/HTTPS)**: Use WSS in production

**Desktop Platform**:
- **Native socket errors**: Map to ConnectionState.error
- **Firewall blocking**: Display helpful error message
- **Certificate validation**: Handle self-signed certs in development

#### 4. Graceful Degradation

**Scenario**: WebSocket unavailable after 5 connection attempts
- **Action**: Display "Real-time updates temporarily unavailable" message
- **Fallback**: Enable HTTP polling
  - Bookings: Poll every 30 seconds
  - Notifications: Poll every 60 seconds
- **Recovery**: Attempt WebSocket reconnection every 5 minutes
- **Transition**: When WebSocket reconnects, disable polling seamlessly

### Error Logging Strategy

**Backend Logging Levels**:
- **INFO**: Connection established, connection closed (normal)
- **WARNING**: Authentication failures, rate limiting
- **ERROR**: Redis connection failures, event broadcasting errors
- **CRITICAL**: Reverb server crashes, unrecoverable errors

**Frontend Logging**:
- **Debug**: All WebSocket messages (development only)
- **Info**: Connection state changes
- **Warning**: Reconnection attempts
- **Error**: Message parsing failures, unhandled events


## Testing Strategy

### Why Property-Based Testing Does NOT Apply

This feature is **not suitable for property-based testing** because:

1. **Infrastructure Configuration**: WebSocket server setup is declarative configuration, not algorithmic logic
2. **External I/O**: Network communication involves external services (Redis, WebSocket protocol) that cannot be meaningfully property-tested
3. **Side Effects**: Event broadcasting and connection management are inherently side-effect operations
4. **Integration-Heavy**: Most behaviors require integration with external systems
5. **UI Rendering**: Connection status indicators are visual components

**Appropriate Testing Approaches**:
- **Unit Tests**: For pure functions (event serialization, validation logic)
- **Integration Tests**: For WebSocket connection flow, event broadcasting
- **Mock-Based Tests**: For connection manager behavior with mocked WebSocket
- **Manual Testing**: For cross-platform compatibility and UI feedback

### Backend Testing

#### 1. Unit Tests

**Authentication Middleware Tests**:
```php
// Test valid JWT token
test('accepts valid JWT token', function () {
    $user = User::factory()->create();
    $token = JWTAuth::fromUser($user);
    
    $request = Request::create('/ws', 'GET', ['token' => $token]);
    $middleware = new WebSocketAuthMiddleware();
    
    $response = $middleware->handle($request, fn($req) => $req);
    
    expect(Auth::user())->toBe($user);
});

// Test expired token
test('rejects expired JWT token', function () {
    $token = 'expired.jwt.token';
    $request = Request::create('/ws', 'GET', ['token' => $token]);
    $middleware = new WebSocketAuthMiddleware();
    
    expect(fn() => $middleware->handle($request, fn($req) => $req))
        ->toThrow(UnauthorizedException::class);
});
```


**Channel Authorization Tests**:
```php
// Test user can access own channel
test('user can subscribe to own channel', function () {
    $user = User::factory()->create();
    
    $result = Broadcast::channel('user.{userId}', function ($u, $userId) {
        return (int) $u->id === (int) $userId;
    })($user, $user->id);
    
    expect($result)->toBeTrue();
});

// Test user cannot access other user's channel
test('user cannot subscribe to other user channel', function () {
    $user = User::factory()->create();
    $otherUserId = 999;
    
    $result = Broadcast::channel('user.{userId}', function ($u, $userId) {
        return (int) $u->id === (int) $userId;
    })($user, $otherUserId);
    
    expect($result)->toBeFalse();
});
```

**Event Serialization Tests**:
```php
// Test booking event serialization
test('booking event serializes correctly', function () {
    $booking = Booking::factory()->create();
    $event = new BookingStatusChanged($booking, 'pending', 'confirmed');
    
    $data = $event->broadcastWith();
    
    expect($data)->toHaveKeys(['booking_id', 'old_status', 'new_status', 'timestamp']);
    expect($data['booking_id'])->toBe($booking->id);
    expect($data['new_status'])->toBe('confirmed');
});
```


#### 2. Integration Tests

**Event Broadcasting Integration**:
```php
// Test booking status change broadcasts event
test('booking status change broadcasts to correct channels', function () {
    Event::fake();
    
    $booking = Booking::factory()->create([
        'status' => 'pending',
        'customer_id' => 1,
        'provider_id' => 2,
    ]);
    
    $booking->update(['status' => 'confirmed']);
    
    Event::assertDispatched(BookingStatusChanged::class, function ($event) use ($booking) {
        return $event->booking->id === $booking->id
            && $event->newStatus === 'confirmed';
    });
});

// Test notification creation broadcasts event
test('notification creation broadcasts to user channel', function () {
    Event::fake();
    
    $user = User::factory()->create();
    $notification = Notification::create([
        'user_id' => $user->id,
        'title' => 'Test',
        'message' => 'Test message',
        'type' => 'info',
    ]);
    
    Event::assertDispatched(NotificationCreated::class, function ($event) use ($notification) {
        return $event->notification->id === $notification->id;
    });
});
```

**Health Check Integration**:
```php
// Test health check returns 200 when healthy
test('health check returns healthy status', function () {
    Redis::shouldReceive('connection->ping')->andReturn(true);
    
    $response = $this->get('/api/websocket/health');
    
    $response->assertStatus(200);
    $response->assertJson(['status' => 'healthy']);
});

// Test health check returns 503 when Redis unavailable
test('health check returns unhealthy when Redis down', function () {
    Redis::shouldReceive('connection->ping')->andThrow(new Exception('Connection failed'));
    
    $response = $this->get('/api/websocket/health');
    
    $response->assertStatus(503);
    $response->assertJson(['status' => 'unhealthy']);
});
```


### Frontend Testing

#### 1. Unit Tests

**Connection Manager Tests** (with mocked WebSocket):
```dart
// Test connection establishes successfully
test('connection manager establishes connection', () async {
  final mockChannel = MockWebSocketChannel();
  final manager = WebSocketConnectionManager(
    wsUrl: 'ws://test',
    getToken: () => 'test-token',
    channelFactory: (_) => mockChannel,
  );
  
  when(mockChannel.ready).thenAnswer((_) async => null);
  when(mockChannel.stream).thenAnswer((_) => Stream.empty());
  
  await manager.connect();
  
  expect(manager.state, ConnectionState.connected);
});

// Test reconnection with exponential backoff
test('reconnection uses exponential backoff', () async {
  final manager = WebSocketConnectionManager(
    wsUrl: 'ws://test',
    getToken: () => 'test-token',
  );
  
  // Simulate connection failures
  for (int i = 0; i < 5; i++) {
    manager.handleError(Exception('Connection failed'));
  }
  
  // Verify backoff delays: 1s, 2s, 4s, 8s, 16s
  expect(manager.reconnectAttempts, 5);
  expect(manager.calculateBackoff().inSeconds, 16);
});

// Test event parsing
test('parses booking event correctly', () {
  final json = {
    'event': 'booking.status.changed',
    'channel': 'private-user.1',
    'data': {
      'booking_id': '123',
      'old_status': 'pending',
      'new_status': 'confirmed',
      'timestamp': '2024-01-01T00:00:00Z',
    },
  };
  
  final event = WebSocketEvent.fromJson(json);
  
  expect(event.event, 'booking.status.changed');
  expect(event.data['booking_id'], '123');
  expect(event.data['new_status'], 'confirmed');
});
```


#### 2. Widget Tests

**Connection Status Indicator Tests**:
```dart
// Test displays correct status for each state
testWidgets('displays connected status', (tester) async {
  final container = ProviderScope(
    overrides: [
      webSocketConnectionProvider.overrideWith((ref) => ConnectionState.connected),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: ConnectionStatusIndicator(),
      ),
    ),
  );
  
  await tester.pumpWidget(container);
  
  expect(find.text('Live'), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
});

testWidgets('displays reconnecting status', (tester) async {
  final container = ProviderScope(
    overrides: [
      webSocketConnectionProvider.overrideWith((ref) => ConnectionState.connecting),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: ConnectionStatusIndicator(),
      ),
    ),
  );
  
  await tester.pumpWidget(container);
  
  expect(find.text('Connecting...'), findsOneWidget);
  expect(find.byIcon(Icons.sync), findsOneWidget);
});
```


#### 3. Integration Tests

**End-to-End WebSocket Flow** (requires test WebSocket server):
```dart
// Test complete connection and event flow
testWidgets('receives booking event and updates UI', (tester) async {
  final testServer = await startTestWebSocketServer();
  
  final container = ProviderScope(
    overrides: [
      webSocketConnectionProvider.overrideWith((ref) {
        return WebSocketConnection(
          wsUrl: testServer.url,
          getToken: () => 'test-token',
        );
      }),
    ],
    child: const MaterialApp(home: BookingListScreen()),
  );
  
  await tester.pumpWidget(container);
  await tester.pumpAndSettle();
  
  // Simulate server sending booking event
  testServer.sendEvent({
    'event': 'booking.status.changed',
    'data': {
      'booking_id': '123',
      'new_status': 'confirmed',
    },
  });
  
  await tester.pumpAndSettle();
  
  // Verify UI updated
  expect(find.text('Confirmed'), findsOneWidget);
  
  await testServer.close();
});
```

### Manual Testing Checklist

#### Cross-Platform Testing
- [ ] WebSocket connection works on Chrome (web)
- [ ] WebSocket connection works on Firefox (web)
- [ ] WebSocket connection works on Safari (web)
- [ ] WebSocket connection works on Windows desktop
- [ ] WebSocket connection works on macOS desktop
- [ ] WebSocket connection works on Linux desktop

#### Connection Lifecycle
- [ ] Connection establishes on app start
- [ ] Connection closes on app background (mobile)
- [ ] Connection reopens on app foreground (mobile)
- [ ] Connection closes on logout
- [ ] Connection opens on login

#### Reconnection Behavior
- [ ] Automatic reconnection after network loss
- [ ] Exponential backoff delays are correct
- [ ] Fallback to polling after 5 failed attempts
- [ ] Return to WebSocket when available

#### Event Handling
- [ ] Booking status changes appear in real-time
- [ ] Notifications appear as banners
- [ ] Presence indicators update correctly
- [ ] Multiple events handled without loss

#### Error Scenarios
- [ ] Invalid token shows appropriate error
- [ ] Expired token triggers re-authentication
- [ ] Rate limiting handled gracefully
- [ ] Malformed events logged and discarded


### Performance Testing

#### Load Testing
- **Objective**: Verify Reverb handles 1000+ concurrent connections
- **Tool**: Artillery or k6
- **Metrics**: Connection success rate, message latency, memory usage
- **Acceptance**: 95% success rate, <100ms message latency

#### Stress Testing
- **Objective**: Identify breaking point and recovery behavior
- **Approach**: Gradually increase connections until failure
- **Metrics**: Max connections before degradation, recovery time
- **Acceptance**: Graceful degradation, no data loss

#### Endurance Testing
- **Objective**: Verify stability over extended periods
- **Duration**: 24 hours with 500 concurrent connections
- **Metrics**: Memory leaks, connection drops, error rate
- **Acceptance**: Stable memory, <1% connection drop rate

### Security Testing

#### Authentication Testing
- [ ] Connections without tokens are rejected
- [ ] Expired tokens are rejected
- [ ] Invalid tokens are rejected
- [ ] Token refresh works correctly

#### Authorization Testing
- [ ] Users cannot subscribe to unauthorized channels
- [ ] Private channels enforce user ownership
- [ ] Presence channels enforce role requirements

#### Rate Limiting Testing
- [ ] Connections exceeding 100 msg/min are closed
- [ ] Rate limit errors are logged
- [ ] Legitimate traffic is not affected

#### Origin Validation Testing
- [ ] Cross-origin connections are validated
- [ ] Allowed origins can connect
- [ ] Disallowed origins are rejected


## Deployment Configuration

### Environment Variables

**Backend (.env)**:
```bash
# Reverb Configuration
REVERB_APP_ID=gharsewa-app
REVERB_APP_KEY=your-app-key-here
REVERB_APP_SECRET=your-app-secret-here
REVERB_HOST=localhost
REVERB_PORT=6001
REVERB_SCHEME=http

# Production overrides
REVERB_SCHEME=https  # Use WSS in production
REVERB_HOST=ws.gharsewa.com
REVERB_TLS_CERT=/path/to/cert.pem
REVERB_TLS_KEY=/path/to/key.pem

# Scaling
REVERB_SCALING_ENABLED=true
REVERB_SCALING_CHANNEL=reverb

# Capacity
REVERB_APP_CAPACITY=10000
REVERB_APP_PING_INTERVAL=60
REVERB_APP_MAX_MESSAGE_SIZE=10000

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

**Frontend (environment.dart)**:
```dart
class Environment {
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:6001',
  );
  
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'your-app-key-here',
  );
  
  static const bool useSecureWebSocket = bool.fromEnvironment(
    'USE_WSS',
    defaultValue: false,
  );
}
```


### Docker Configuration Updates

**docker-compose.yml** (already configured, verify settings):
```yaml
websocket:
  build:
    context: .
    dockerfile: Dockerfile
  container_name: gharsewa_websocket
  restart: unless-stopped
  working_dir: /var/www
  command: php artisan reverb:start --host=0.0.0.0 --port=6001
  ports:
    - "6001:6001"
  volumes:
    - .:/var/www
    - /var/www/vendor
    - /var/www/node_modules
  environment:
    - REVERB_SERVER_HOST=0.0.0.0
    - REVERB_SERVER_PORT=6001
    - REDIS_HOST=redis
  networks:
    - gharsewa_network
  depends_on:
    - app
    - redis
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:6001/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### Production Deployment

#### SSL/TLS Configuration

**Nginx Reverse Proxy** (for WSS):
```nginx
# /etc/nginx/sites-available/websocket
upstream websocket {
    server localhost:6001;
}

server {
    listen 443 ssl http2;
    server_name ws.gharsewa.com;
    
    ssl_certificate /etc/letsencrypt/live/ws.gharsewa.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ws.gharsewa.com/privkey.pem;
    
    location / {
        proxy_pass http://websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
```


#### Horizontal Scaling

**Multiple Reverb Instances**:
```yaml
# docker-compose.prod.yml
websocket-1:
  <<: *websocket-service
  container_name: gharsewa_websocket_1
  ports:
    - "6001:6001"

websocket-2:
  <<: *websocket-service
  container_name: gharsewa_websocket_2
  ports:
    - "6002:6001"

websocket-3:
  <<: *websocket-service
  container_name: gharsewa_websocket_3
  ports:
    - "6003:6001"
```

**Load Balancer Configuration**:
```nginx
upstream websocket_cluster {
    ip_hash;  # Sticky sessions for WebSocket
    server websocket-1:6001;
    server websocket-2:6001;
    server websocket-3:6001;
}

server {
    listen 443 ssl http2;
    server_name ws.gharsewa.com;
    
    location / {
        proxy_pass http://websocket_cluster;
        # ... (same proxy settings as above)
    }
}
```

### Monitoring and Observability

#### Metrics to Track

**Connection Metrics**:
- Active connections count
- Connection establishment rate
- Connection duration distribution
- Connection failure rate
- Reconnection attempts

**Message Metrics**:
- Messages sent per second
- Messages received per second
- Message latency (p50, p95, p99)
- Message size distribution
- Failed message deliveries

**Error Metrics**:
- Authentication failures
- Authorization failures
- Rate limit violations
- Redis connection errors
- Event broadcasting failures


#### Logging Configuration

**Laravel Logging** (config/logging.php):
```php
'channels' => [
    'websocket' => [
        'driver' => 'daily',
        'path' => storage_path('logs/websocket.log'),
        'level' => env('LOG_LEVEL', 'info'),
        'days' => 14,
    ],
],
```

**Reverb Event Logging**:
```php
// app/Providers/EventServiceProvider.php
protected $listen = [
    ConnectionEstablished::class => [
        LogConnectionEstablished::class,
    ],
    ConnectionClosed::class => [
        LogConnectionClosed::class,
    ],
    MessageSent::class => [
        LogMessageSent::class,
    ],
];
```

#### Health Monitoring

**Health Check Endpoint**:
- **URL**: `GET /api/websocket/health`
- **Frequency**: Every 30 seconds
- **Alert Threshold**: 3 consecutive failures
- **Response Time**: <500ms

**Monitoring Dashboard Metrics**:
```
┌─────────────────────────────────────────────────────────┐
│ WebSocket Server Health                                 │
├─────────────────────────────────────────────────────────┤
│ Status: ● Healthy                                       │
│ Active Connections: 847 / 10,000                        │
│ Uptime: 5d 12h 34m                                      │
│ Redis: ● Connected                                      │
│ Message Rate: 1,234 msg/s                               │
│ Avg Latency: 45ms (p95: 120ms)                         │
│ Error Rate: 0.02%                                       │
└─────────────────────────────────────────────────────────┘
```


## Migration and Rollout Strategy

### Phase 1: Infrastructure Setup (Week 1)
1. Install and configure Laravel Reverb
2. Set up Redis for pub/sub
3. Configure Docker Compose services
4. Deploy to staging environment
5. Verify health checks and monitoring

### Phase 2: Backend Implementation (Week 2)
1. Implement JWT authentication middleware
2. Configure channel authorization
3. Create event classes (BookingStatusChanged, NotificationCreated)
4. Implement event broadcasting in controllers
5. Write and run backend tests

### Phase 3: Frontend Implementation (Week 3)
1. Implement WebSocketConnectionManager
2. Create Riverpod providers for connection state
3. Implement event listeners for bookings and notifications
4. Create connection status UI components
5. Write and run frontend tests

### Phase 4: Integration Testing (Week 4)
1. End-to-end testing on staging
2. Cross-platform testing (web, desktop)
3. Load testing with 1000+ concurrent connections
4. Security testing (authentication, authorization)
5. Performance optimization

### Phase 5: Gradual Rollout (Week 5)
1. **10% rollout**: Enable for 10% of users, monitor metrics
2. **25% rollout**: Expand to 25% if no issues
3. **50% rollout**: Expand to 50% if metrics are healthy
4. **100% rollout**: Full deployment if all metrics pass

### Rollback Plan
- **Trigger**: Error rate >5%, connection failure rate >10%
- **Action**: Disable WebSocket feature flag, revert to HTTP polling
- **Recovery**: Fix issues, redeploy to staging, restart rollout


## Security Considerations

### Authentication Security
- **JWT Validation**: All connections must provide valid, non-expired JWT tokens
- **Token Transmission**: Tokens sent via query parameter (initial handshake) or Authorization header
- **Token Refresh**: Client must handle token expiration and refresh before reconnection
- **Secret Key**: Use same JWT secret as REST API for consistency

### Authorization Security
- **Channel Access Control**: Private channels enforce user ownership
- **Presence Channels**: Role-based access (providers, customers)
- **Booking Channels**: Only customer and provider can access booking-specific channels
- **Authorization Callbacks**: Server-side validation for all channel subscriptions

### Transport Security
- **Development**: Use WS (unencrypted) for local development
- **Production**: Use WSS (encrypted) with valid SSL certificates
- **Certificate Validation**: Enforce certificate validation in production
- **Mixed Content**: Ensure HTTPS pages use WSS connections

### Rate Limiting
- **Message Rate**: 100 messages per minute per connection
- **Connection Rate**: 10 connection attempts per minute per IP
- **Enforcement**: Close connections exceeding limits with 4429 code
- **Logging**: Log all rate limit violations for security monitoring

### Origin Validation
- **CORS Configuration**: Validate origin header for all connections
- **Allowed Origins**: Configure allowed origins in Reverb config
- **Production**: Restrict to specific domains (app.gharsewa.com)
- **Development**: Allow localhost and development domains

### Data Privacy
- **Sensitive Data**: Never broadcast sensitive data (passwords, payment info)
- **User Data**: Only broadcast data user is authorized to see
- **Encryption**: All data encrypted in transit via WSS
- **Logging**: Sanitize logs to remove sensitive information


## Performance Optimization

### Backend Optimizations

#### Connection Pooling
- **Redis Connections**: Use persistent Redis connections
- **Database Connections**: Minimize database queries in event handlers
- **Connection Reuse**: Reuse connections across requests

#### Event Broadcasting
- **Async Broadcasting**: Use queued events for non-critical broadcasts
- **Batch Broadcasting**: Group multiple events when possible
- **Selective Broadcasting**: Only broadcast to relevant channels

#### Memory Management
- **Connection Limits**: Set max connections per instance (10,000)
- **Message Size Limits**: Limit message size to 10KB
- **Garbage Collection**: Regular cleanup of closed connections

### Frontend Optimizations

#### Connection Management
- **Single Connection**: Maintain one WebSocket connection per app instance
- **Connection Pooling**: Reuse connection across components
- **Lazy Connection**: Defer connection until user is authenticated

#### Event Handling
- **Event Debouncing**: Debounce rapid UI updates
- **Selective Listening**: Only listen to relevant event types
- **Memory Cleanup**: Unregister listeners when components unmount

#### UI Updates
- **Batch Updates**: Group multiple state updates
- **Optimistic Updates**: Update UI immediately, sync with server
- **Virtual Scrolling**: Use virtual scrolling for large lists

### Network Optimizations

#### Message Compression
- **Gzip Compression**: Enable compression for large messages
- **JSON Minification**: Remove whitespace from JSON payloads
- **Binary Protocol**: Consider binary protocol for high-frequency updates

#### Bandwidth Management
- **Message Throttling**: Limit message frequency for high-volume events
- **Delta Updates**: Send only changed data, not full objects
- **Presence Throttling**: Batch presence updates every 5 seconds


## Future Enhancements

### Phase 2 Features (Post-MVP)

#### 1. Typing Indicators
- Show when provider is typing a response
- Broadcast typing events with debouncing
- Display "Provider is typing..." indicator

#### 2. Read Receipts
- Track when messages are read
- Broadcast read events to sender
- Display read status in message list

#### 3. Geolocation Tracking
- Real-time provider location updates
- Display provider location on map
- Estimate arrival time based on location

#### 4. Video Call Integration
- WebRTC signaling via WebSocket
- Real-time call status updates
- Call quality metrics

#### 5. Chat Messaging
- Real-time chat between customer and provider
- Message delivery and read receipts
- File sharing via WebSocket

#### 6. Advanced Presence
- Custom presence states (available, busy, away)
- Last seen timestamps
- Activity status (viewing booking, in chat)

### Scalability Improvements

#### 1. Multi-Region Deployment
- Deploy Reverb instances in multiple regions
- Route connections to nearest region
- Cross-region event synchronization

#### 2. Connection Sharding
- Shard connections across multiple instances
- Consistent hashing for user-to-instance mapping
- Automatic rebalancing on instance failure

#### 3. Event Replay
- Store events in persistent queue
- Replay missed events on reconnection
- Event deduplication

#### 4. Analytics and Insights
- Real-time connection analytics dashboard
- Event flow visualization
- Performance bottleneck identification


## Appendix

### A. WebSocket Protocol Reference

**Connection Handshake**:
```
GET /app/gharsewa-app?token=eyJ0eXAiOiJKV1QiLCJhbGc... HTTP/1.1
Host: localhost:6001
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
```

**Subscription Message**:
```json
{
  "event": "pusher:subscribe",
  "data": {
    "channel": "private-user.123"
  }
}
```

**Event Message**:
```json
{
  "event": "booking.status.changed",
  "channel": "private-user.123",
  "data": {
    "booking_id": "456",
    "old_status": "pending",
    "new_status": "confirmed",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

**Ping/Pong**:
```json
{
  "event": "pusher:ping",
  "data": {}
}
```

### B. Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 4000 | Normal closure | No action needed |
| 4001 | Going away | Reconnect |
| 4401 | Unauthorized | Refresh token and reconnect |
| 4403 | Forbidden | Do not retry |
| 4429 | Rate limited | Exponential backoff |
| 4500 | Server error | Retry with backoff |


### C. Troubleshooting Guide

#### Connection Issues

**Problem**: Connection fails immediately
- **Check**: JWT token is valid and not expired
- **Check**: WebSocket server is running (`docker ps`)
- **Check**: Port 6001 is accessible
- **Check**: Firewall allows WebSocket connections

**Problem**: Connection drops frequently
- **Check**: Network stability
- **Check**: Server resource usage (CPU, memory)
- **Check**: Redis connection is stable
- **Check**: Nginx timeout settings

**Problem**: Cannot subscribe to channel
- **Check**: User has permission for channel
- **Check**: Channel name format is correct
- **Check**: Authorization callback returns true

#### Event Issues

**Problem**: Events not received
- **Check**: Subscription was successful
- **Check**: Event is being broadcast (check logs)
- **Check**: Redis pub/sub is working
- **Check**: Event listener is registered

**Problem**: Duplicate events received
- **Check**: Multiple subscriptions to same channel
- **Check**: Multiple event listeners registered
- **Check**: Reconnection creating duplicate subscriptions

#### Performance Issues

**Problem**: High latency
- **Check**: Network latency between client and server
- **Check**: Redis performance
- **Check**: Server CPU/memory usage
- **Check**: Number of concurrent connections

**Problem**: Memory leaks
- **Check**: Event listeners are being disposed
- **Check**: Connections are being closed properly
- **Check**: No circular references in event handlers

### D. References

- [Laravel Reverb Documentation](https://laravel.com/docs/11.x/reverb)
- [Laravel Broadcasting Documentation](https://laravel.com/docs/11.x/broadcasting)
- [web_socket_channel Package](https://pub.dev/packages/web_socket_channel)
- [WebSocket Protocol RFC 6455](https://tools.ietf.org/html/rfc6455)
- [JWT Authentication Best Practices](https://tools.ietf.org/html/rfc8725)

