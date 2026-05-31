import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/repositories/booking_repository.dart';
import '../../core/websocket/websocket_provider.dart';
import '../../core/websocket/models/connection_state.dart';

/// Polling state
enum PollingState {
  /// Polling is disabled (WebSocket is working)
  disabled,
  
  /// Polling is active (WebSocket failed)
  active,
}

/// Polling service for graceful degradation
/// 
/// Provides HTTP polling fallback when WebSocket connection fails.
/// - Polls booking updates every 30 seconds
/// - Polls notifications every 60 seconds
/// - Enables polling when WebSocket fails after 5 connection attempts
/// - Disables polling when WebSocket connection is restored
/// 
/// **Requirements**: 14.1, 14.2, 14.3, 14.4
class PollingService extends StateNotifier<PollingState> {
  PollingService(this._ref) : super(PollingState.disabled) {
    _initialize();
  }

  final Ref _ref;
  final Logger _logger = Logger();
  
  /// Timer for booking polling (every 30 seconds)
  Timer? _bookingPollTimer;
  
  /// Timer for notification polling (every 60 seconds)
  Timer? _notificationPollTimer;
  
  /// Subscription to WebSocket connection state
  ProviderSubscription? _connectionStateSubscription;
  
  /// Number of consecutive WebSocket connection failures
  int _connectionFailures = 0;
  
  /// Maximum connection failures before enabling polling
  static const int _maxConnectionFailures = 5;
  
  /// Polling interval for bookings (30 seconds)
  static const Duration _bookingPollInterval = Duration(seconds: 30);
  
  /// Polling interval for notifications (60 seconds)
  static const Duration _notificationPollInterval = Duration(seconds: 60);

  /// Initialize the polling service
  void _initialize() {
    _logger.i('Initializing PollingService');

    // Listen to WebSocket connection state changes
    _connectionStateSubscription = _ref.listen<ConnectionState>(
      webSocketConnectionProvider,
      (previous, next) {
        _handleConnectionStateChange(previous, next);
      },
    );
  }

  /// Handle WebSocket connection state changes
  void _handleConnectionStateChange(ConnectionState? previous, ConnectionState current) {
    _logger.d('Connection state changed: $previous -> $current');

    switch (current) {
      case ConnectionState.connected:
        // WebSocket reconnected - disable polling
        _onWebSocketConnected();
        break;
      
      case ConnectionState.disconnected:
      case ConnectionState.error:
        // WebSocket disconnected or error - track failures
        _onWebSocketDisconnected();
        break;
      
      case ConnectionState.connecting:
        // Currently connecting - do nothing
        break;
    }
  }

  /// Handle WebSocket connection established
  void _onWebSocketConnected() {
    _logger.i('WebSocket connected - disabling polling');
    
    // Reset connection failure counter
    _connectionFailures = 0;
    
    // Disable polling if active
    if (state == PollingState.active) {
      _stopPolling();
      state = PollingState.disabled;
    }
  }

  /// Handle WebSocket disconnection or error
  void _onWebSocketDisconnected() {
    _connectionFailures++;
    _logger.w('WebSocket disconnected (failure $_connectionFailures/$_maxConnectionFailures)');

    // Enable polling after 5 consecutive failures
    if (_connectionFailures >= _maxConnectionFailures) {
      _logger.i('Max connection failures reached - enabling polling');
      _startPolling();
      state = PollingState.active;
    }
  }

  /// Start polling for bookings and notifications
  void _startPolling() {
    _logger.i('Starting polling service');
    
    // Start booking polling (every 30 seconds)
    _startBookingPolling();
    
    // Start notification polling (every 60 seconds)
    _startNotificationPolling();
  }

  /// Stop polling for bookings and notifications
  void _stopPolling() {
    _logger.i('Stopping polling service');
    
    // Cancel booking polling timer
    _bookingPollTimer?.cancel();
    _bookingPollTimer = null;
    
    // Cancel notification polling timer
    _notificationPollTimer?.cancel();
    _notificationPollTimer = null;
  }

  /// Start polling for booking updates
  /// 
  /// **Requirement 14.1**: Poll for booking updates every 30 seconds
  void _startBookingPolling() {
    _bookingPollTimer?.cancel();
    
    _logger.i('Starting booking polling (interval: ${_bookingPollInterval.inSeconds}s)');
    
    // Poll immediately, then on interval
    _pollBookings();
    
    _bookingPollTimer = Timer.periodic(_bookingPollInterval, (_) {
      _pollBookings();
    });
  }

  /// Poll for booking updates via HTTP
  void _pollBookings() async {
    try {
      _logger.d('Polling for booking updates');
      
      final bookingRepository = _ref.read(bookingRepositoryProvider);
      
      // Get current user role to determine which bookings to fetch
      // For now, we'll fetch both customer and provider bookings
      // In production, you'd check the user's role first
      
      // Poll customer bookings
      try {
        await bookingRepository.getCustomerBookings();
        _logger.d('Successfully polled customer bookings');
      } catch (e) {
        _logger.w('Failed to poll customer bookings', error: e);
      }
      
      // Poll provider bookings
      try {
        await bookingRepository.getProviderBookings();
        _logger.d('Successfully polled provider bookings');
      } catch (e) {
        _logger.w('Failed to poll provider bookings', error: e);
      }
      
    } catch (e, stackTrace) {
      _logger.e('Error polling bookings', error: e, stackTrace: stackTrace);
    }
  }

  /// Start polling for notification updates
  /// 
  /// **Requirement 14.2**: Poll for notifications every 60 seconds
  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    
    _logger.i('Starting notification polling (interval: ${_notificationPollInterval.inSeconds}s)');
    
    // Poll immediately, then on interval
    _pollNotifications();
    
    _notificationPollTimer = Timer.periodic(_notificationPollInterval, (_) {
      _pollNotifications();
    });
  }

  /// Poll for notification updates via HTTP
  void _pollNotifications() async {
    try {
      _logger.d('Polling for notification updates');
      
      // Note: There's no notification repository in the current codebase
      // When the notification API is implemented, this should call:
      // final notificationRepository = _ref.read(notificationRepositoryProvider);
      // await notificationRepository.getNotifications();
      
      // For now, we'll log a placeholder
      _logger.d('Notification polling placeholder - implement notification repository');
      
    } catch (e, stackTrace) {
      _logger.e('Error polling notifications', error: e, stackTrace: stackTrace);
    }
  }

  /// Manually trigger a booking poll
  /// 
  /// This can be called by the UI to refresh data on demand
  void pollBookingsNow() {
    _logger.d('Manual booking poll requested');
    _pollBookings();
  }

  /// Manually trigger a notification poll
  /// 
  /// This can be called by the UI to refresh data on demand
  void pollNotificationsNow() {
    _logger.d('Manual notification poll requested');
    _pollNotifications();
  }

  /// Get the current number of connection failures
  int get connectionFailures => _connectionFailures;

  /// Check if polling is currently active
  bool get isPolling => state == PollingState.active;

  @override
  void dispose() {
    _logger.i('Disposing PollingService');
    _connectionStateSubscription?.close();
    _stopPolling();
    super.dispose();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

/// Polling service provider
/// 
/// Manages HTTP polling fallback for WebSocket failures.
/// Automatically enables polling after 5 consecutive WebSocket connection failures.
/// 
/// **Requirements**: 14.1, 14.2, 14.3, 14.4
final pollingServiceProvider = StateNotifierProvider<PollingService, PollingState>((ref) {
  return PollingService(ref);
});

/// Provider to check if polling is currently active
final isPollingActiveProvider = Provider<bool>((ref) {
  return ref.watch(pollingServiceProvider) == PollingState.active;
});

/// Provider to get the current number of connection failures
final connectionFailuresProvider = Provider<int>((ref) {
  final pollingService = ref.watch(pollingServiceProvider.notifier);
  return pollingService.connectionFailures;
});
