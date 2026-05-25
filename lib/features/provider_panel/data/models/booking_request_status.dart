/// Status of a booking request
enum BookingRequestStatus {
  /// Request is pending provider response
  pending,
  
  /// Request has been accepted by provider
  accepted,
  
  /// Request has been declined by provider
  declined,
  
  /// Provider has sent a counter-offer
  counterOffered,
  
  /// Request has expired without response
  expired,
}
