/// Model class for AI-calculated provider-customer match scores
class AIMatchScore {
  final String bookingId;
  final String? providerId;
  final String? providerName;
  final double matchScore;
  final MatchFactors factors;
  final String reasoning;
  final DateTime calculatedAt;
  final BookingDetails? bookingDetails;

  AIMatchScore({
    required this.bookingId,
    this.providerId,
    this.providerName,
    required this.matchScore,
    required this.factors,
    required this.reasoning,
    required this.calculatedAt,
    this.bookingDetails,
  });

  factory AIMatchScore.fromJson(Map<String, dynamic> json) {
    return AIMatchScore(
      bookingId: json['booking_id'] as String,
      providerId: json['provider_id'] as String?,
      providerName: json['provider_name'] as String?,
      matchScore: (json['match_score'] as num).toDouble(),
      factors: MatchFactors.fromJson(json['factors'] as Map<String, dynamic>),
      reasoning: json['reasoning'] as String,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
      bookingDetails: json['booking_details'] != null
          ? BookingDetails.fromJson(json['booking_details'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'provider_id': providerId,
      'provider_name': providerName,
      'match_score': matchScore,
      'factors': factors.toJson(),
      'reasoning': reasoning,
      'calculated_at': calculatedAt.toIso8601String(),
      'booking_details': bookingDetails?.toJson(),
    };
  }
}

/// Match score factors breakdown
class MatchFactors {
  final double skillAlignment;
  final double locationProximity;
  final double rating;
  final double availability;
  final double preferences;

  MatchFactors({
    required this.skillAlignment,
    required this.locationProximity,
    required this.rating,
    required this.availability,
    required this.preferences,
  });

  factory MatchFactors.fromJson(Map<String, dynamic> json) {
    return MatchFactors(
      skillAlignment: (json['skill_alignment'] as num).toDouble(),
      locationProximity: (json['location_proximity'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      availability: (json['availability'] as num).toDouble(),
      preferences: (json['preferences'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill_alignment': skillAlignment,
      'location_proximity': locationProximity,
      'rating': rating,
      'availability': availability,
      'preferences': preferences,
    };
  }
}

/// Booking details within match score
class BookingDetails {
  final String service;
  final String category;
  final String scheduledDate;
  final String location;

  BookingDetails({
    required this.service,
    required this.category,
    required this.scheduledDate,
    required this.location,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    return BookingDetails(
      service: json['service'] as String,
      category: json['category'] as String,
      scheduledDate: json['scheduled_date'] as String,
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'category': category,
      'scheduled_date': scheduledDate,
      'location': location,
    };
  }
}
