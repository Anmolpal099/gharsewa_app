/// Status of a counter-offer
enum CounterOfferStatus {
  /// Counter-offer is pending customer response
  pending,
  
  /// Counter-offer has been accepted by customer
  accepted,
  
  /// Counter-offer has been rejected by customer
  rejected,
}
