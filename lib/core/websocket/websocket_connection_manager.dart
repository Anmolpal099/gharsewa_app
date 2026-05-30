import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

import 'models/connection_state.dart';
import 'models/websocket_event.dart';

/// Manages WebSocket connection lifecycle, authentication, and event handling
/// 
/// This class handles:
/// - Connection establishment with JWT authentication
/// - Automatic reconnection with exponential backoff
/// - Channel subscriptions
/// - Event parsing and routing
/// - Connection state management
/// 
/// **Requirements**: 6.1, 6.2, 6.3, 6.4, 6.5, 7.1, 7.2, 7.3, 7.4, 7.5, 18.1, 18.2, 18.3, 18.4, 18.5
class WebSocketConnectionManager {
  /// The WebSocket server URL (without token parameter)
  final String wsUrl;
  
  /// Function to retrieve the current JWT token
  final String Function() getToken;
  
  /// Logger instance for debugging and monitoring
  final Logger _logger;
  
  /// The active WebSocket channel
  WebSocketChannel? _channel;
  
  /// Current connection state
  ConnectionState _state = ConnectionState.disconnected;
  
  /// Timer for scheduled reconnection attempts
  Timer? _reconnectTimer;
  
  /// Number of consecutive reconnection attempts
  int _reconnectAttempts = 0;
  
  /// Maximum reconnection delay in seconds
  static const int _maxReconnectDelay = 30;
  
  /// List of subscribed channels
  final Set<String> _subscribedChannels = {};
  
  /// Stream controller for connection state changes
  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();
  
  /// Stream controller for incoming WebSocket events
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  
  /// Stream subscription for WebSocket messages
  StreamSubscription? _messageSubscription;
  
  /// Whether the connection was explicitly closed by the user
  bool _explicitlyClosed = false;
  
  /// Stream of connection state changes
  Stream<ConnectionState> get stateStream => _stateController.stream;
  
  /// Stream of incoming WebSocket events
  Stream<WebSocketEvent> get eventStream => _eventController.stream;
  
  /// Current connection state
  ConnectionState get state => _state;
  
  /// Whether currently connected
  bool get isConnected => _state == ConnectionState.connected;
  
  /// Number of reconnection attempts made
  int get reconnectAttempts => _reconnectAttempts;
  
  /// Creates a new WebSocket connection manager
  /// 
  /// [wsUrl] - The WebSocket server URL (e.g., 'ws://localhost:6001/app/app-key')
  /// [getToken] - Function that returns the current JWT token
  /// [logger] - Optional logger instance for debugging
  WebSocketConnectionManager({
    required this.wsUrl,
    required this.getToken,
    Logger? logger,
  }) : _logger = logger ?? Logger();
  
  /// Establishes a WebSocket connection with JWT authentication
  /// 
  /// If already connected or connecting, this method returns immediately.
  /// The JWT token is appended to the URL as a query parameter.
  /// 
  /// **Requirement 6.1**: Connection establishment with JWT token
  /// **Requirement 6.2**: Defer connection if token unavailable
  Future<void> connect() async {
    // Don't connect if already connected or connecting
    if (_state == ConnectionState.connected || 
        _state == ConnectionState.connecting) {
      _logger.d('Already connected or connecting, skipping connect()');
      return;
    }
    
    // Reset explicit close flag
    _explicitlyClosed = false;
    
    _updateState(ConnectionState.connecting);
    _logger.i('Attempting to connect to WebSocket: $wsUrl');
    
    try {
      // Get JWT token
      final token = getToken();
      
      // Defer connection if token is not available (Requirement 6.2)
      if (token.isEmpty) {
        _logger.w('JWT token not available, deferring connection');
        _updateState(ConnectionState.disconnected);
        return;
      }
      
      // Build WebSocket URL with JWT token authentication (Requirement 6.1)
      final uri = Uri.parse(wsUrl);
      final authenticatedUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'token': token,
        },
      );
      
      _logger.d('Connecting to: ${authenticatedUri.toString().replaceAll(token, '***')}');
      
      // Establish WebSocket connection
      _channel = WebSocketChannel.connect(authenticatedUri);
      
      // Wait for connection to be ready
      await _channel!.ready;
      
      _logger.i('WebSocket connection established successfully');
      _updateState(ConnectionState.connected);
      
      // Reset reconnection attempts on successful connection (Requirement 7.4)
      _reconnectAttempts = 0;
      
      // Listen to incoming messages
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
      
      // Re-subscribe to channels after reconnection (Requirement 7.5)
      _resubscribeToChannels();
      
    } catch (e, stackTrace) {
      _logger.e('Failed to connect to WebSocket', error: e, stackTrace: stackTrace);
      _handleError(e);
    }
  }
  
  /// Closes the WebSocket connection
  /// 
  /// This method explicitly closes the connection and prevents automatic
  /// reconnection. Use this when the user logs out or the app is closing.
  /// 
  /// **Requirement 18.3**: Close connection on logout
  /// **Requirement 18.5**: Dispose event listeners on close
  void disconnect() {
    _logger.i('Disconnecting WebSocket');
    
    // Mark as explicitly closed to prevent reconnection
    _explicitlyClosed = true;
    
    // Cancel reconnection timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    // Cancel message subscription (Requirement 18.5)
    _messageSubscription?.cancel();
    _messageSubscription = null;
    
    // Close WebSocket channel
    _channel?.sink.close();
    _channel = null;
    
    // Clear subscribed channels
    _subscribedChannels.clear();
    
    // Update state
    _updateState(ConnectionState.disconnected);
    
    _logger.i('WebSocket disconnected');
  }
  
  /// Subscribes to a WebSocket channel
  /// 
  /// Channels are used to organize events into logical groups.
  /// Examples: 'private-user.123', 'presence-providers'
  /// 
  /// **Requirement 6.3**: Subscribe to user's private channel
  /// **Requirement 6.4**: Subscribe to presence channel
  void subscribe(String channel) {
    _logger.d('Subscribing to channel: $channel');
    
    // Add to subscribed channels list
    _subscribedChannels.add(channel);
    
    // Send subscription message if connected
    if (isConnected) {
      _sendSubscription(channel);
    } else {
      _logger.w('Not connected, subscription will be sent after connection');
    }
  }
  
  /// Unsubscribes from a WebSocket channel
  /// 
  /// Removes the channel from the subscription list and sends an
  /// unsubscribe message to the server.
  void unsubscribe(String channel) {
    _logger.d('Unsubscribing from channel: $channel');
    
    // Remove from subscribed channels list
    _subscribedChannels.remove(channel);
    
    // Send unsubscription message if connected
    if (isConnected) {
      _send({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channel},
      });
    }
  }
  
  /// Handles incoming WebSocket messages
  /// 
  /// Parses JSON messages and converts them to WebSocketEvent objects.
  /// Emits parsed events to the event stream.
  /// 
  /// **Requirement 6.5**: Message handling and event parsing
  void _handleMessage(dynamic message) {
    try {
      _logger.d('Received message: $message');
      
      // Parse JSON message
      final Map<String, dynamic> data = jsonDecode(message as String);
      
      // Handle different message types
      final eventType = data['event'] as String?;
      
      if (eventType == null) {
        _logger.w('Received message without event type: $data');
        return;
      }
      
      // Handle connection events
      if (eventType == 'pusher:connection_established') {
        _logger.i('Connection established event received');
        return;
      }
      
      if (eventType == 'pusher:subscription_succeeded') {
        final channel = data['channel'] as String?;
        _logger.i('Subscription succeeded for channel: $channel');
        return;
      }
      
      if (eventType == 'pusher:subscription_error') {
        final channel = data['channel'] as String?;
        _logger.e('Subscription error for channel: $channel');
        return;
      }
      
      // Parse and emit application events
      try {
        final event = WebSocketEvent.fromJson(data);
        _eventController.add(event);
        _logger.d('Emitted event: ${event.event} on channel: ${event.channel}');
      } catch (e) {
        _logger.e('Failed to parse WebSocket event', error: e);
      }
      
    } catch (e, stackTrace) {
      _logger.e('Error handling WebSocket message', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Handles WebSocket errors
  /// 
  /// Updates connection state to error and schedules reconnection.
  /// 
  /// **Requirement 6.5**: Error handling
  /// **Requirement 7.1**: Automatic reconnection on error
  void _handleError(dynamic error) {
    _logger.e('WebSocket error occurred', error: error);
    
    _updateState(ConnectionState.error);
    
    // Schedule reconnection if not explicitly closed
    if (!_explicitlyClosed) {
      _scheduleReconnect();
    }
  }
  
  /// Handles WebSocket disconnection
  /// 
  /// Called when the WebSocket connection is closed.
  /// Schedules automatic reconnection unless explicitly closed.
  /// 
  /// **Requirement 6.5**: Disconnection handling
  /// **Requirement 7.1**: Automatic reconnection on disconnect
  void _handleDisconnect() {
    _logger.w('WebSocket connection closed');
    
    // Cancel message subscription
    _messageSubscription?.cancel();
    _messageSubscription = null;
    
    _updateState(ConnectionState.disconnected);
    
    // Schedule reconnection if not explicitly closed
    if (!_explicitlyClosed) {
      _scheduleReconnect();
    }
  }
  
  /// Schedules a reconnection attempt with exponential backoff
  /// 
  /// Implements exponential backoff strategy:
  /// - 1st attempt: 1 second
  /// - 2nd attempt: 2 seconds
  /// - 3rd attempt: 4 seconds
  /// - 4th attempt: 8 seconds
  /// - 5th attempt: 16 seconds
  /// - 6th+ attempts: 30 seconds (max)
  /// 
  /// **Requirement 7.1**: Reconnect after 1 second on first failure
  /// **Requirement 7.2**: Wait 2 seconds on second failure
  /// **Requirement 7.3**: Double wait time up to 30 seconds max
  /// **Requirement 7.5**: Continue reconnection indefinitely
  void _scheduleReconnect() {
    // Cancel any existing reconnection timer
    _reconnectTimer?.cancel();
    
    // Calculate backoff delay
    final delay = _calculateBackoff();
    
    _logger.i('Scheduling reconnection attempt ${_reconnectAttempts + 1} in ${delay.inSeconds} seconds');
    
    // Schedule reconnection
    _reconnectTimer = Timer(delay, () {
      _logger.i('Executing reconnection attempt ${_reconnectAttempts + 1}');
      connect();
    });
  }
  
  /// Calculates the exponential backoff delay for reconnection
  /// 
  /// Returns a Duration based on the number of reconnection attempts:
  /// - Attempt 0: 1 second
  /// - Attempt 1: 2 seconds
  /// - Attempt 2: 4 seconds
  /// - Attempt 3: 8 seconds
  /// - Attempt 4: 16 seconds
  /// - Attempt 5+: 30 seconds (max)
  /// 
  /// **Requirement 7.1, 7.2, 7.3**: Exponential backoff (1s, 2s, 4s, 8s, 16s, 30s max)
  Duration _calculateBackoff() {
    // Calculate exponential backoff: 2^attempts seconds
    final seconds = min(pow(2, _reconnectAttempts).toInt(), _maxReconnectDelay);
    
    // Increment attempts counter
    _reconnectAttempts++;
    
    return Duration(seconds: seconds);
  }
  
  /// Re-subscribes to all previously subscribed channels
  /// 
  /// Called after successful reconnection to restore subscriptions.
  void _resubscribeToChannels() {
    if (_subscribedChannels.isEmpty) {
      return;
    }
    
    _logger.i('Re-subscribing to ${_subscribedChannels.length} channels');
    
    for (final channel in _subscribedChannels) {
      _sendSubscription(channel);
    }
  }
  
  /// Sends a subscription message to the WebSocket server
  void _sendSubscription(String channel) {
    _send({
      'event': 'pusher:subscribe',
      'data': {'channel': channel},
    });
    
    _logger.d('Sent subscription for channel: $channel');
  }
  
  /// Sends a message to the WebSocket server
  /// 
  /// Serializes the data to JSON and sends it through the WebSocket channel.
  void _send(Map<String, dynamic> data) {
    if (_channel == null || !isConnected) {
      _logger.w('Cannot send message: not connected');
      return;
    }
    
    try {
      final message = jsonEncode(data);
      _channel!.sink.add(message);
      _logger.d('Sent message: $message');
    } catch (e) {
      _logger.e('Failed to send message', error: e);
    }
  }
  
  /// Updates the connection state and notifies listeners
  /// 
  /// **Requirement 6.5**: Expose connection state to UI layer
  void _updateState(ConnectionState newState) {
    if (_state == newState) {
      return;
    }
    
    _logger.d('Connection state changed: $_state -> $newState');
    _state = newState;
    _stateController.add(newState);
  }
  
  /// Disposes of all resources
  /// 
  /// Closes streams, cancels timers, and closes the WebSocket connection.
  /// Call this when the connection manager is no longer needed.
  /// 
  /// **Requirement 18.5**: Dispose of event listeners
  void dispose() {
    _logger.i('Disposing WebSocket connection manager');
    
    // Disconnect WebSocket
    disconnect();
    
    // Close stream controllers
    _stateController.close();
    _eventController.close();
    
    _logger.i('WebSocket connection manager disposed');
  }
}
