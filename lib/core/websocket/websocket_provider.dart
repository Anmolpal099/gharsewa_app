import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../services/auth/auth_state.dart';
import '../../services/auth/jwt_auth_service.dart';
import '../../services/auth/token_storage.dart';
import '../../core/config/env_config.dart';
import 'models/connection_state.dart';
import 'models/websocket_event.dart';
import 'websocket_connection_manager.dart';

/// WebSocket connection provider
/// 
/// Manages WebSocket connection lifecycle based on authentication state.
/// Automatically connects when user is authenticated and disconnects on logout.
/// 
/// **Requirements**: 6.1, 6.2, 6.3, 6.4, 6.5, 8.1, 8.2, 8.3, 18.1, 18.2, 18.3, 18.4
class WebSocketConnection extends StateNotifier<ConnectionState> {
  WebSocketConnection(this._ref) : super(ConnectionState.disconnected) {
    _initialize();
  }

  final Ref _ref;
  WebSocketConnectionManager? _manager;
  StreamSubscription<ConnectionState>? _stateSubscription;
  final Logger _logger = Logger();

  /// Initialize the WebSocket connection based on auth state
  /// 
  /// **Requirement 6.1**: Initialize connection when user is authenticated
  /// **Requirement 18.4**: Establish connection on login
  void _initialize() {
    // Listen to authentication state changes
    _ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenData((authState) {
        _logger.d('Auth state changed: ${authState.status}');
        
        if (authState.isAuthenticated) {
          // User is authenticated, initialize connection
          _initializeConnection();
        } else {
          // User is not authenticated, disconnect
          _disconnectConnection();
        }
      });
    });
  }

  /// Initialize WebSocket connection manager
  /// 
  /// **Requirement 6.1**: Establish connection with JWT token
  /// **Requirement 6.2**: Defer connection if token unavailable
  Future<void> _initializeConnection() async {
    if (_manager != null) {
      _logger.d('WebSocket manager already initialized');
      return;
    }

    _logger.i('Initializing WebSocket connection');

    // Load JWT token from storage
    await _loadToken();

    // Build WebSocket URL from API base URL
    final wsUrl = _buildWebSocketUrl();

    // Create connection manager
    _manager = WebSocketConnectionManager(
      wsUrl: wsUrl,
      getToken: _getToken,
      logger: _logger,
    );

    // Listen to connection state changes
    _stateSubscription = _manager!.stateStream.listen((newState) {
      _logger.d('Connection state changed: $newState');
      state = newState;
    });

    // Connect to WebSocket server
    await _manager!.connect();

    // Subscribe to user's private channel after connection
    // Note: Actual subscription happens after connection is established
    await _subscribeToUserChannels();
  }

  /// Disconnect WebSocket connection
  /// 
  /// **Requirement 18.3**: Close connection on logout
  void _disconnectConnection() {
    _logger.i('Disconnecting WebSocket connection');

    _stateSubscription?.cancel();
    _stateSubscription = null;

    _manager?.disconnect();
    _manager?.dispose();
    _manager = null;

    state = ConnectionState.disconnected;
  }

  /// Build WebSocket URL from environment configuration
  /// 
  /// Uses EnvConfig to get WebSocket URL and Reverb app key.
  /// Supports both secure (WSS) and non-secure (WS) connections.
  /// 
  /// **Requirement 9.1**: Use environment variable for WebSocket URL
  /// **Requirement 9.2**: Use environment variable for Reverb app key
  /// **Requirement 9.3**: Support secure WebSocket (WSS) in production
  String _buildWebSocketUrl() {
    // Get base WebSocket URL from environment
    String wsUrl = EnvConfig.wsUrl;
    
    // Apply secure WebSocket flag if enabled
    if (EnvConfig.useSecureWebSocket && wsUrl.startsWith('ws://')) {
      wsUrl = wsUrl.replaceFirst('ws://', 'wss://');
    }
    
    // Append Reverb app key to URL path if configured
    if (EnvConfig.reverbAppKey.isNotEmpty) {
      // Remove trailing slash if present
      wsUrl = wsUrl.replaceAll(RegExp(r'/$'), '');
      // Append app key path
      wsUrl = '$wsUrl/app/${EnvConfig.reverbAppKey}';
    }
    
    _logger.d('WebSocket URL: $wsUrl');
    return wsUrl;
  }

  /// Current cached JWT token
  String _cachedToken = '';

  /// Get current JWT token
  /// 
  /// **Requirement 6.1**: Provide JWT token for authentication
  String _getToken() {
    return _cachedToken;
  }

  /// Load JWT token from storage
  Future<void> _loadToken() async {
    try {
      final token = await TokenStorage.getAccessToken();
      _cachedToken = token ?? '';
      _logger.d('Token loaded: ${_cachedToken.isNotEmpty ? "present" : "absent"}');
    } catch (e) {
      _logger.e('Error loading token', error: e);
      _cachedToken = '';
    }
  }

  /// Subscribe to user-specific channels
  /// 
  /// **Requirement 6.3**: Subscribe to user's private channel
  /// **Requirement 6.4**: Subscribe to presence channel
  Future<void> _subscribeToUserChannels() async {
    // Wait for connection to be established
    await Future.delayed(const Duration(milliseconds: 500));

    if (_manager == null || !_manager!.isConnected) {
      _logger.w('Cannot subscribe to channels: not connected');
      return;
    }

    try {
      // Get current user
      final authService = _ref.read(jwtAuthServiceProvider);
      final user = await authService.getCurrentUser();

      if (user == null) {
        _logger.w('Cannot subscribe to channels: user not found');
        return;
      }

      // Subscribe to user's private channel
      final userChannel = 'private-user.${user.id}';
      _logger.i('Subscribing to channel: $userChannel');
      _manager!.subscribe(userChannel);

      // Subscribe to presence channel based on user role
      if (user.role == 'serviceProvider' || user.role == 'provider') {
        _logger.i('Subscribing to presence-providers channel');
        _manager!.subscribe('presence-providers');
      } else {
        _logger.i('Subscribing to presence-customers channel');
        _manager!.subscribe('presence-customers');
      }
    } catch (e) {
      _logger.e('Error subscribing to channels', error: e);
    }
  }

  /// Subscribe to a specific channel
  /// 
  /// **Requirement 8.1**: Provide method to subscribe to channels
  void subscribe(String channel) {
    if (_manager == null) {
      _logger.w('Cannot subscribe: WebSocket manager not initialized');
      return;
    }

    _logger.i('Subscribing to channel: $channel');
    _manager!.subscribe(channel);
  }

  /// Unsubscribe from a specific channel
  void unsubscribe(String channel) {
    if (_manager == null) {
      _logger.w('Cannot unsubscribe: WebSocket manager not initialized');
      return;
    }

    _logger.i('Unsubscribing from channel: $channel');
    _manager!.unsubscribe(channel);
  }

  /// Get event stream
  /// 
  /// **Requirement 8.2**: Expose event stream for filtering
  Stream<WebSocketEvent> get eventStream {
    if (_manager == null) {
      return const Stream.empty();
    }
    return _manager!.eventStream;
  }

  /// Get connection state stream
  Stream<ConnectionState> get stateStream {
    if (_manager == null) {
      return Stream.value(ConnectionState.disconnected);
    }
    return _manager!.stateStream;
  }

  @override
  void dispose() {
    _logger.i('Disposing WebSocket connection provider');
    _stateSubscription?.cancel();
    _disconnectConnection();
    super.dispose();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

/// WebSocket connection state provider
/// 
/// Provides the current WebSocket connection state.
/// Automatically manages connection based on authentication state.
/// 
/// **Requirement 6.5**: Expose connection state to UI layer
final webSocketConnectionProvider =
    StateNotifierProvider<WebSocketConnection, ConnectionState>((ref) {
  return WebSocketConnection(ref);
});

/// Stream provider for booking events
/// 
/// Filters WebSocket events to only include booking-related events.
/// 
/// **Requirement 8.1**: Register listeners for booking events
/// **Requirement 8.3**: Provide method to register listeners for specific event types
final bookingEventsProvider = StreamProvider<WebSocketEvent>((ref) {
  final connection = ref.watch(webSocketConnectionProvider.notifier);
  return connection.eventStream
      .where((event) => event.event == 'booking.status.changed');
});

/// Stream provider for notification events
/// 
/// Filters WebSocket events to only include notification events.
/// 
/// **Requirement 8.2**: Register listeners for notification events
/// **Requirement 8.3**: Provide method to register listeners for specific event types
final notificationEventsProvider = StreamProvider<WebSocketEvent>((ref) {
  final connection = ref.watch(webSocketConnectionProvider.notifier);
  return connection.eventStream
      .where((event) => event.event == 'notification.created');
});

/// Stream provider for presence events
/// 
/// Filters WebSocket events to only include presence-related events.
/// 
/// **Requirement 8.3**: Register listeners for presence updates
final presenceEventsProvider = StreamProvider<WebSocketEvent>((ref) {
  final connection = ref.watch(webSocketConnectionProvider.notifier);
  return connection.eventStream.where((event) =>
      event.event == 'pusher:member_added' ||
      event.event == 'pusher:member_removed');
});

/// Provider to access WebSocket connection methods
/// 
/// Use this to subscribe/unsubscribe to channels programmatically.
final webSocketActionsProvider = Provider<WebSocketConnection>((ref) {
  return ref.watch(webSocketConnectionProvider.notifier);
});
