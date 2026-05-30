import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/core/websocket/models/presence_member.dart';
import 'package:gharsewa/core/websocket/models/websocket_event.dart';
import 'package:gharsewa/core/websocket/websocket_provider.dart';
import 'package:gharsewa/features/presence/providers/presence_realtime_provider.dart';

// Extension to pump the container and wait for state updates
extension ProviderContainerPump on ProviderContainer {
  Future<void> pump() async {
    await Future.delayed(Duration.zero);
  }
}

void main() {
  group('PresenceRealtime Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Override presence events provider to provide test events
          presenceEventsProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty state', () {
      final state = container.read(presenceRealtimeProvider);

      expect(state.onlineProviders, isEmpty);
      expect(state.onlineCustomers, isEmpty);
      expect(state.totalOnlineCount, 0);
    });

    test('should check if user is online', () {
      final notifier = container.read(presenceRealtimeProvider.notifier);

      // Initially no users online
      expect(notifier.isUserOnline('user-123'), isFalse);
      expect(notifier.isProviderOnline('provider-456'), isFalse);
      expect(notifier.isCustomerOnline('customer-789'), isFalse);
    });

    test('should get online provider by ID', () {
      final notifier = container.read(presenceRealtimeProvider.notifier);

      // Initially no providers online
      expect(notifier.getOnlineProvider('provider-123'), isNull);
    });

    test('should get online customer by ID', () {
      final notifier = container.read(presenceRealtimeProvider.notifier);

      // Initially no customers online
      expect(notifier.getOnlineCustomer('customer-123'), isNull);
    });

    test('isUserOnlineProvider should return false for non-existent user', () {
      final isOnline = container.read(isUserOnlineProvider('user-123'));
      expect(isOnline, isFalse);
    });

    test('isProviderOnlineProvider should return false for non-existent provider', () {
      final isOnline = container.read(isProviderOnlineProvider('provider-123'));
      expect(isOnline, isFalse);
    });

    test('isCustomerOnlineProvider should return false for non-existent customer', () {
      final isOnline = container.read(isCustomerOnlineProvider('customer-123'));
      expect(isOnline, isFalse);
    });

    test('onlineProvidersProvider should return empty list initially', () {
      final providers = container.read(onlineProvidersProvider);
      expect(providers, isEmpty);
    });

    test('onlineCustomersProvider should return empty list initially', () {
      final customers = container.read(onlineCustomersProvider);
      expect(customers, isEmpty);
    });

    test('totalOnlineCountProvider should return 0 initially', () {
      final count = container.read(totalOnlineCountProvider);
      expect(count, 0);
    });

    test('onlineProvidersCountProvider should return 0 initially', () {
      final count = container.read(onlineProvidersCountProvider);
      expect(count, 0);
    });

    test('onlineCustomersCountProvider should return 0 initially', () {
      final count = container.read(onlineCustomersCountProvider);
      expect(count, 0);
    });

    test('PresenceState copyWith should create new instance with updated values', () {
      const state = PresenceState();
      final member = const PresenceMember(
        id: 'provider-123',
        name: 'Test Provider',
      );

      final newState = state.copyWith(
        onlineProviders: [member],
      );

      expect(newState.onlineProviders, [member]);
      expect(newState.onlineCustomers, isEmpty);
      expect(newState.onlineProvidersCount, 1);
      expect(newState.totalOnlineCount, 1);
    });

    test('PresenceState should calculate counts correctly', () {
      final state = PresenceState(
        onlineProviders: const [
          PresenceMember(id: 'p1', name: 'Provider 1'),
          PresenceMember(id: 'p2', name: 'Provider 2'),
        ],
        onlineCustomers: const [
          PresenceMember(id: 'c1', name: 'Customer 1'),
        ],
      );

      expect(state.onlineProvidersCount, 2);
      expect(state.onlineCustomersCount, 1);
      expect(state.totalOnlineCount, 3);
    });
  });

  group('PresenceRealtime Event Handling Tests', () {
    test('PresenceState should be updated correctly', () {
      // Test the state management directly
      const initialState = PresenceState();
      
      final member = const PresenceMember(
        id: 'provider-123',
        name: 'Test Provider',
      );
      
      final newState = initialState.copyWith(
        onlineProviders: [member],
      );
      
      expect(newState.onlineProviders.length, 1);
      expect(newState.onlineProviders.first.id, 'provider-123');
      expect(newState.onlineProviders.first.name, 'Test Provider');
    });

    test('should check online status after state update', () {
      final container = ProviderContainer();
      
      // Manually update the state
      final notifier = container.read(presenceRealtimeProvider.notifier);
      notifier.state = const PresenceState(
        onlineProviders: [
          PresenceMember(id: 'provider-123', name: 'Test Provider'),
        ],
        onlineCustomers: [
          PresenceMember(id: 'customer-456', name: 'Test Customer'),
        ],
      );
      
      // Check online status
      expect(notifier.isUserOnline('provider-123'), isTrue);
      expect(notifier.isUserOnline('customer-456'), isTrue);
      expect(notifier.isUserOnline('unknown-user'), isFalse);
      
      expect(notifier.isProviderOnline('provider-123'), isTrue);
      expect(notifier.isProviderOnline('unknown-provider'), isFalse);
      
      expect(notifier.isCustomerOnline('customer-456'), isTrue);
      expect(notifier.isCustomerOnline('unknown-customer'), isFalse);
      
      container.dispose();
    });

    test('should get online members after state update', () {
      final container = ProviderContainer();
      
      // Manually update the state
      final notifier = container.read(presenceRealtimeProvider.notifier);
      notifier.state = const PresenceState(
        onlineProviders: [
          PresenceMember(id: 'provider-123', name: 'Test Provider'),
        ],
        onlineCustomers: [
          PresenceMember(id: 'customer-456', name: 'Test Customer'),
        ],
      );
      
      // Get online members
      final provider = notifier.getOnlineProvider('provider-123');
      expect(provider, isNotNull);
      expect(provider!.id, 'provider-123');
      expect(provider.name, 'Test Provider');
      
      final customer = notifier.getOnlineCustomer('customer-456');
      expect(customer, isNotNull);
      expect(customer!.id, 'customer-456');
      expect(customer.name, 'Test Customer');
      
      expect(notifier.getOnlineProvider('unknown'), isNull);
      expect(notifier.getOnlineCustomer('unknown'), isNull);
      
      container.dispose();
    });

    test('family providers should work with updated state', () {
      final container = ProviderContainer();
      
      // Manually update the state
      final notifier = container.read(presenceRealtimeProvider.notifier);
      notifier.state = const PresenceState(
        onlineProviders: [
          PresenceMember(id: 'provider-123', name: 'Test Provider'),
        ],
      );
      
      // Check family providers
      final isOnline = container.read(isProviderOnlineProvider('provider-123'));
      expect(isOnline, isTrue);
      
      final isOffline = container.read(isProviderOnlineProvider('provider-456'));
      expect(isOffline, isFalse);
      
      container.dispose();
    });
  });
}
