/// Enums for Provider Panel feature
library;

/// Status of a booking request
enum BookingRequestStatus {
  pending,
  accepted,
  declined,
  counterOffered,
  expired;

  String get displayName {
    switch (this) {
      case BookingRequestStatus.pending:
        return 'Pending';
      case BookingRequestStatus.accepted:
        return 'Accepted';
      case BookingRequestStatus.declined:
        return 'Declined';
      case BookingRequestStatus.counterOffered:
        return 'Counter Offered';
      case BookingRequestStatus.expired:
        return 'Expired';
    }
  }
}

/// Type of suggestion provided to the provider
enum SuggestionType {
  profileImprovement,
  performanceOptimization,
  availabilityAdjustment,
  pricingStrategy;

  String get displayName {
    switch (this) {
      case SuggestionType.profileImprovement:
        return 'Profile Improvement';
      case SuggestionType.performanceOptimization:
        return 'Performance Optimization';
      case SuggestionType.availabilityAdjustment:
        return 'Availability Adjustment';
      case SuggestionType.pricingStrategy:
        return 'Pricing Strategy';
    }
  }
}

/// Priority level of a suggestion
enum SuggestionPriority {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case SuggestionPriority.high:
        return 'High';
      case SuggestionPriority.medium:
        return 'Medium';
      case SuggestionPriority.low:
        return 'Low';
    }
  }
}

/// Status of a counter offer
enum CounterOfferStatus {
  pending,
  accepted,
  rejected;

  String get displayName {
    switch (this) {
      case CounterOfferStatus.pending:
        return 'Pending';
      case CounterOfferStatus.accepted:
        return 'Accepted';
      case CounterOfferStatus.rejected:
        return 'Rejected';
    }
  }
}

/// View type for earnings display
enum EarningsViewType {
  daily,
  weekly;

  String get displayName {
    switch (this) {
      case EarningsViewType.daily:
        return 'Daily';
      case EarningsViewType.weekly:
        return 'Weekly';
    }
  }
}
