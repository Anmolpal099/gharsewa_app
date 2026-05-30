import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_event_data.freezed.dart';
part 'booking_event_data.g.dart';

/// Represents the data payload for a booking status change event
@freezed
class BookingEventData with _$BookingEventData {
  const factory BookingEventData({
    /// The unique identifier of the booking
    required String bookingId,
    
    /// The previous status of the booking
    required String oldStatus,
    
    /// The new status of the booking
    required String newStatus,
    
    /// When the status change occurred
    required DateTime timestamp,
  }) = _BookingEventData;

  factory BookingEventData.fromJson(Map<String, dynamic> json) =>
      _$BookingEventDataFromJson(json);
}
