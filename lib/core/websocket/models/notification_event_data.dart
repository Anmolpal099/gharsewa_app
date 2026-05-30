import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_event_data.freezed.dart';
part 'notification_event_data.g.dart';

/// Represents the data payload for a notification created event
@freezed
class NotificationEventData with _$NotificationEventData {
  const factory NotificationEventData({
    /// The unique identifier of the notification
    required String id,
    
    /// The notification title
    required String title,
    
    /// The notification message content
    required String message,
    
    /// The type of notification (for UI rendering)
    required String type,
    
    /// When the notification was created
    required DateTime timestamp,
  }) = _NotificationEventData;

  factory NotificationEventData.fromJson(Map<String, dynamic> json) =>
      _$NotificationEventDataFromJson(json);
}
