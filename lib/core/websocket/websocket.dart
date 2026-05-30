/// WebSocket module
/// 
/// This module provides WebSocket connection management, real-time event handling,
/// and connection state management for the Gharsewa application.
/// 
/// Key components:
/// - [WebSocketConnectionManager]: Manages WebSocket connection lifecycle
/// - [WebSocketConnection]: Riverpod provider for WebSocket connection
/// - [WebSocketEvent]: Represents incoming WebSocket events
/// - [ConnectionState]: Enum for connection states
/// - [BookingEventData]: Data model for booking events
/// - [NotificationEventData]: Data model for notification events
/// - [PresenceMember]: Data model for presence channel members
library;

export 'models/models.dart';
export 'websocket_connection_manager.dart';
export 'websocket_provider.dart';
