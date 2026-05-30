import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_event.freezed.dart';
part 'websocket_event.g.dart';

/// Represents a WebSocket event received from the server
@freezed
class WebSocketEvent with _$WebSocketEvent {
  const factory WebSocketEvent({
    /// The event type/name (e.g., 'booking.status.changed', 'notification.created')
    required String event,
    
    /// The channel this event was received on
    required String channel,
    
    /// The event payload data
    required Map<String, dynamic> data,
    
    /// Optional timestamp of when the event occurred
    String? timestamp,
  }) = _WebSocketEvent;

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) =>
      _$WebSocketEventFromJson(json);
}
