import '../../../../data/models/booking_model.dart';

/// A pending booking ranked by skill match (swap engine when ML model is ready).
class RecommendedBooking {
  final BookingModel booking;
  final String displayServiceName;
  final List<String> matchedSkills;
  /// Match strength from 0.0 to 1.0.
  final double matchScore;

  const RecommendedBooking({
    required this.booking,
    required this.displayServiceName,
    required this.matchedSkills,
    required this.matchScore,
  });

  int get matchPercent => (matchScore * 100).round().clamp(0, 100);

  String get matchLabel => '$matchPercent% skill match';
}
