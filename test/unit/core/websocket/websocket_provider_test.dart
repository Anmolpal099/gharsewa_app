import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gharsewa/core/websocket/websocket_provider.dart';
import 'package:gharsewa/core/websocket/models/connection_state.dart';

void main() {
  group('WebSocketConnection Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be disconnected', () {
      final state = container.read(webSocketConnectionProvider);
      expect(state, ConnectionState.disconnected);
    });

    test('should provide booking events stream', () {
      final stream = container.read(bookingEventsProvider.stream);
      expect(stream, isA<Stream>());
    });

    test('should provide notification events stream', () {
      final stream = container.read(notificationEventsProvider.stream);
      expect(stream, isA<Stream>());
    });

    test('should provide presence events stream', () {
      final stream = container.read(presenceEventsProvider.stream);
      expect(stream, isA<Stream>());
    });

    test('should provide websocket actions', () {
      final actions = container.read(webSocketActionsProvider);
      expect(actions, isA<WebSocketConnection>());
    });
  });

  group('WebSocketConnection', () {
    test('should expose event stream', () {
      final container = ProviderContainer();
      final connection = container.read(webSocketConnectionProvider.notifier);
      
      expect(connection.eventStream, isA<Stream>());
      
      container.dispose();
    });

    test('should expose state stream', () {
      final container = ProviderContainer();
      final connection = container.read(webSocketConnectionProvider.notifier);
      
      expect(connection.stateStream, isA<Stream>());
      
      container.dispose();
    });

    test('subscribe method should not throw when manager is null', () {
      final container = ProviderContainer();
      final connection = container.read(webSocketConnectionProvider.notifier);
      
      // Should not throw even when manager is not initialized
      expect(() => connection.subscribe('test-channel'), returnsNormally);
      
      container.dispose();
    });

    test('unsubscribe method should not throw when manager is null', () {
      final container = ProviderContainer();
      final connection = container.read(webSocketConnectionProvider.notifier);
      
      // Should not throw even when manager is not initialized
      expect(() => connection.unsubscribe('test-channel'), returnsNormally);
      
      container.dispose();
    });
  });
}
