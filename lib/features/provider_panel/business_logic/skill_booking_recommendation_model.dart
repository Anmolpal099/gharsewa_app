import '../../../../data/datasources/local/mock_data.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/models/service_model.dart';
import '../data/models/recommended_booking.dart';

/// Skill-based booking recommendation engine.
///
/// Replace or wrap this class when the ML scheduling/recommendation model is ready.
class SkillBookingRecommendationModel {
  const SkillBookingRecommendationModel({
    this.maxResults = 5,
    this.minMatchScore = 0.25,
  });

  final int maxResults;
  final double minMatchScore;

  List<RecommendedBooking> recommend({
    required List<BookingModel> bookings,
    required List<String> providerSkills,
  }) {
    if (providerSkills.isEmpty) return [];

    final trimmedSkills =
        providerSkills.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (trimmedSkills.isEmpty) return [];

    final serviceLookup = {
      for (final s in MockData.services) s.id: s,
    };

    final pending = bookings.where((b) => b.isPending).toList();
    final scored = <RecommendedBooking>[];

    for (final booking in pending) {
      final enriched = _enrichBooking(booking, serviceLookup);
      final matched = _matchedSkills(trimmedSkills, enriched);
      if (matched.isEmpty) continue;

      final score = _scoreMatch(trimmedSkills, enriched, matched);
      if (score < minMatchScore) continue;

      scored.add(
        RecommendedBooking(
          booking: enriched,
          displayServiceName: enriched.serviceName ?? 'Booking request',
          matchedSkills: matched,
          matchScore: score,
        ),
      );
    }

    scored.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return scored.take(maxResults).toList();
  }

  BookingModel _enrichBooking(
    BookingModel booking,
    Map<String, ServiceModel> serviceLookup,
  ) {
    if (booking.serviceName != null && booking.serviceName!.isNotEmpty) {
      return booking;
    }
    final svc = serviceLookup[booking.serviceId];
    if (svc == null) return booking;

    return BookingModel(
      id: booking.id,
      customerId: booking.customerId,
      serviceId: booking.serviceId,
      providerId: booking.providerId,
      scheduledAt: booking.scheduledAt,
      status: booking.status,
      totalPrice: booking.totalPrice,
      currency: booking.currency,
      cancellationReason: booking.cancellationReason,
      serviceName: svc.name,
      serviceCategory: svc.category,
      serviceTags: svc.tags,
      customerName: booking.customerName,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
    );
  }

  List<String> _matchedSkills(List<String> providerSkills, BookingModel booking) {
    final haystack = _bookingTokens(booking);
    final matched = <String>[];
    for (final original in providerSkills) {
      final skill = _normalizeToken(original);
      if (skill.isEmpty) continue;
      if (_tokenMatchesHaystack(skill, haystack)) {
        matched.add(original);
      }
    }
    return matched;
  }

  double _scoreMatch(
    List<String> providerSkills,
    BookingModel booking,
    List<String> matched,
  ) {
    final coverage = matched.length / providerSkills.length;
    final haystack = _bookingTokens(booking);
    var depth = 0;
    for (final skill in matched) {
      final n = _normalizeToken(skill);
      if (haystack.contains(n)) depth++;
      for (final token in haystack) {
        if (token.contains(n) || n.contains(token)) depth++;
      }
    }
    final depthBoost = (depth / (matched.length * 2)).clamp(0.0, 0.35);
    return (coverage * 0.65 + depthBoost).clamp(0.0, 1.0);
  }

  Set<String> _bookingTokens(BookingModel booking) {
    final tokens = <String>{};
    void addText(String? text) {
      if (text == null || text.isEmpty) return;
      for (final part in text.split(RegExp(r'[\s,/\-]+'))) {
        final t = _normalizeToken(part);
        if (t.length >= 2) tokens.add(t);
      }
    }

    addText(booking.serviceName);
    addText(booking.serviceCategory);
    for (final tag in booking.serviceTags) {
      addText(tag);
    }
    return tokens;
  }

  bool _tokenMatchesHaystack(String skill, Set<String> haystack) {
    if (haystack.contains(skill)) return true;
    for (final token in haystack) {
      if (token.contains(skill) || skill.contains(token)) return true;
    }
    return false;
  }

  String _normalizeToken(String input) =>
      input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
