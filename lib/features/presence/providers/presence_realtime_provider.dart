import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/websocket/models/presence_member.dart';
import '../../../core/websocket/models/websocket_event.dart';
import '../../../core/websocket/websocket_provider.dart';

/// PresenceRealtime provider
/// 
/// Subscribes to presence channels (providers, customers) and maintains
/// a list of online users. Handles presence join and leave events.
/// Exposes online status for specific user IDs.
/// 
/// **Requirements**: 5.1, 5.2, 5.3, 5.4, 5.5, 8.3, 12.1, 12.2
class PresenceRealtime extends StateNotifier<PresenceState> {
  PresenceRealtime(this._ref) : super(const PresenceState()) {
    _initialize();
  }

  final Ref _ref;
  final Logger _logger = Logger();

  /// Initialize the presence realtime listener
  /// 
  /// **Requirement 8.3**: Subscribe to presence events stream
  /// **Requirement 5.3**: Handle presence join events
  /// **Requirement 5.4**: Handle presence leave events
  void _initialize() {
    _logger.i('Initializing PresenceRealtime provider');

    // Listen to presence events using ref.listen
    // This is the recommended approach for Riverpod 2.x+
    _ref.listen<AsyncValue<WebSocketEvent>>(
      presenceEventsProvider,
      (previous, next) {
        next.whenData(_handlePresenceEvent);
      },
    );
  }

  /// Handle incoming presence events (member added/removed)
  /// 
  /// **Requirement 5.3**: Handle presence join events
  /// **Requirement 5.4**: Handle presence leave events
  /// **Requirement 12.2**: Update online indicators within 1 second
  void _handlePresenceEvent(WebSocketEvent event) {
    try {
      _logger.d('Received presence event: ${event.event} on channel: ${event.channel}');

      // Determine which channel this event is for
      final isProviderChannel = event.channel.contains('providers');
      final isCustomerChannel = event.channel.contains('customers');

      if (!isProviderChannel && !isCustomerChannel) {
        _logger.w('Unknown presence channel: ${event.channel}');
        return;
      }

      // Handle member added event
      if (event.event == 'pusher:member_added') {
        _handleMemberAdded(event, isProviderChannel);
      }
      // Handle member removed event
      else if (event.event == 'pusher:member_removed') {
        _handleMemberRemoved(event, isProviderChannel);
      }
      // Handle subscription succeeded (initial member list)
      else if (event.event == 'pusher:subscription_succeeded') {
        _handleSubscriptionSucceeded(event, isProviderChannel);
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling presence event', error: e, stackTrace: stackTrace);
    }
  }

  /// Handle member added to presence channel
  /// 
  /// **Requirement 5.3**: Broadcast presence update when user joins
  /// **Requirement 5.5**: Maintain list of currently connected user identifiers
  void _handleMemberAdded(WebSocketEvent event, bool isProviderChannel) {
    try {
      // Extract member info from event data
      final memberData = event.data['user_info'] as Map<String, dynamic>?;
      
      if (memberData == null) {
        _logger.w('Member added event missing user_info');
        return;
      }

      final member = PresenceMember.fromJson(memberData);
      _logger.i('Member joined ${isProviderChannel ? "providers" : "customers"} channel: ${member.name} (${member.id})');

      // Add member to appropriate list
      if (isProviderChannel) {
        final updatedProviders = [...state.onlineProviders];
        // Avoid duplicates
        if (!updatedProviders.any((m) => m.id == member.id)) {
          updatedProviders.add(member);
          state = state.copyWith(onlineProviders: updatedProviders);
        }
      } else {
        final updatedCustomers = [...state.onlineCustomers];
        // Avoid duplicates
        if (!updatedCustomers.any((m) => m.id == member.id)) {
          updatedCustomers.add(member);
          state = state.copyWith(onlineCustomers: updatedCustomers);
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling member added', error: e, stackTrace: stackTrace);
    }
  }

  /// Handle member removed from presence channel
  /// 
  /// **Requirement 5.2**: Remove user from presence channel within 5 seconds
  /// **Requirement 5.4**: Broadcast presence update when user leaves
  /// **Requirement 5.5**: Maintain list of currently connected user identifiers
  void _handleMemberRemoved(WebSocketEvent event, bool isProviderChannel) {
    try {
      // Extract member ID from event data
      final userId = event.data['user_id'] as String?;
      
      if (userId == null) {
        _logger.w('Member removed event missing user_id');
        return;
      }

      _logger.i('Member left ${isProviderChannel ? "providers" : "customers"} channel: $userId');

      // Remove member from appropriate list
      if (isProviderChannel) {
        final updatedProviders = state.onlineProviders
            .where((m) => m.id != userId)
            .toList();
        state = state.copyWith(onlineProviders: updatedProviders);
      } else {
        final updatedCustomers = state.onlineCustomers
            .where((m) => m.id != userId)
            .toList();
        state = state.copyWith(onlineCustomers: updatedCustomers);
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling member removed', error: e, stackTrace: stackTrace);
    }
  }

  /// Handle subscription succeeded event (initial member list)
  /// 
  /// **Requirement 5.5**: Maintain list of currently connected user identifiers
  void _handleSubscriptionSucceeded(WebSocketEvent event, bool isProviderChannel) {
    try {
      // Extract members list from event data
      final membersData = event.data['members'] as Map<String, dynamic>?;
      
      if (membersData == null) {
        _logger.i('Subscription succeeded with no initial members');
        return;
      }

      // Parse members list
      final members = <PresenceMember>[];
      membersData.forEach((userId, userData) {
        try {
          final member = PresenceMember.fromJson(userData as Map<String, dynamic>);
          members.add(member);
        } catch (e) {
          _logger.w('Failed to parse member data for user $userId', error: e);
        }
      });

      _logger.i('Subscription succeeded with ${members.length} initial members on ${isProviderChannel ? "providers" : "customers"} channel');

      // Update state with initial member list
      if (isProviderChannel) {
        state = state.copyWith(onlineProviders: members);
      } else {
        state = state.copyWith(onlineCustomers: members);
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling subscription succeeded', error: e, stackTrace: stackTrace);
    }
  }

  /// Check if a specific user is online
  /// 
  /// **Requirement 12.1**: Show online indicator for users in presence channel
  bool isUserOnline(String userId) {
    return state.onlineProviders.any((m) => m.id == userId) ||
           state.onlineCustomers.any((m) => m.id == userId);
  }

  /// Check if a specific provider is online
  /// 
  /// **Requirement 12.1**: Show online indicator for service providers
  bool isProviderOnline(String providerId) {
    return state.onlineProviders.any((m) => m.id == providerId);
  }

  /// Check if a specific customer is online
  bool isCustomerOnline(String customerId) {
    return state.onlineCustomers.any((m) => m.id == customerId);
  }

  /// Get online provider by ID
  PresenceMember? getOnlineProvider(String providerId) {
    try {
      return state.onlineProviders.firstWhere((m) => m.id == providerId);
    } catch (e) {
      return null;
    }
  }

  /// Get online customer by ID
  PresenceMember? getOnlineCustomer(String customerId) {
    try {
      return state.onlineCustomers.firstWhere((m) => m.id == customerId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _logger.i('Disposing PresenceRealtime provider');
    super.dispose();
  }
}

// ── State Classes ─────────────────────────────────────────────────────────────

/// Presence state
/// 
/// Maintains lists of online providers and customers.
/// 
/// **Requirement 5.5**: Maintain list of currently connected user identifiers
class PresenceState {
  final List<PresenceMember> onlineProviders;
  final List<PresenceMember> onlineCustomers;

  const PresenceState({
    this.onlineProviders = const [],
    this.onlineCustomers = const [],
  });

  /// Get total count of online users
  int get totalOnlineCount => onlineProviders.length + onlineCustomers.length;

  /// Get count of online providers
  int get onlineProvidersCount => onlineProviders.length;

  /// Get count of online customers
  int get onlineCustomersCount => onlineCustomers.length;

  /// Copy with method for immutable updates
  PresenceState copyWith({
    List<PresenceMember>? onlineProviders,
    List<PresenceMember>? onlineCustomers,
  }) {
    return PresenceState(
      onlineProviders: onlineProviders ?? this.onlineProviders,
      onlineCustomers: onlineCustomers ?? this.onlineCustomers,
    );
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

/// PresenceRealtime provider
/// 
/// Manages real-time presence updates via WebSocket events.
/// Automatically subscribes to presence events and maintains online user lists.
/// 
/// **Requirements**: 5.1, 5.2, 5.3, 5.4, 5.5, 8.3, 12.1, 12.2
final presenceRealtimeProvider =
    StateNotifierProvider<PresenceRealtime, PresenceState>((ref) {
  return PresenceRealtime(ref);
});

/// Provider to check if a specific user is online
/// 
/// **Requirement 12.1**: Show online indicator for users in presence channel
final isUserOnlineProvider = Provider.family<bool, String>((ref, userId) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.onlineProviders.any((m) => m.id == userId) ||
         presenceState.onlineCustomers.any((m) => m.id == userId);
});

/// Provider to check if a specific provider is online
/// 
/// **Requirement 12.1**: Show online indicator for service providers
final isProviderOnlineProvider = Provider.family<bool, String>((ref, providerId) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.onlineProviders.any((m) => m.id == providerId);
});

/// Provider to check if a specific customer is online
final isCustomerOnlineProvider = Provider.family<bool, String>((ref, customerId) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.onlineCustomers.any((m) => m.id == customerId);
});

/// Provider to get list of online providers
/// 
/// **Requirement 5.5**: Maintain list of currently connected user identifiers
final onlineProvidersProvider = Provider<List<PresenceMember>>((ref) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.onlineProviders;
});

/// Provider to get list of online customers
/// 
/// **Requirement 5.5**: Maintain list of currently connected user identifiers
final onlineCustomersProvider = Provider<List<PresenceMember>>((ref) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.onlineCustomers;
});

/// Provider to get total online user count
final totalOnlineCountProvider = Provider<int>((ref) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.totalOnlineCount;
});

/// Provider to get online providers count
final onlineProvidersCountProvider = Provider<int>((ref) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.onlineProvidersCount;
});

/// Provider to get online customers count
final onlineCustomersCountProvider = Provider<int>((ref) {
  final presenceState = ref.watch(presenceRealtimeProvider);
  return presenceState.onlineCustomersCount;
});
