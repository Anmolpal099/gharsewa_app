import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/data/models/booking_model.dart';
import 'package:gharsewa/features/provider_panel/business_logic/skill_booking_recommendation_model.dart';

void main() {
  const model = SkillBookingRecommendationModel();

  test('ranks pending bookings that match provider skills', () {
    final bookings = [
      BookingModel(
        id: '1',
        customerId: 'c1',
        serviceId: 's1',
        providerId: 'p1',
        scheduledAt: DateTime.now(),
        status: BookingStatus.pending,
        totalPrice: 500,
        currency: 'NPR',
        serviceName: 'Pipe Leak Fix',
        serviceCategory: 'Plumbing',
        serviceTags: const ['plumbing', 'repair'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BookingModel(
        id: '2',
        customerId: 'c2',
        serviceId: 's2',
        providerId: 'p1',
        scheduledAt: DateTime.now(),
        status: BookingStatus.completed,
        totalPrice: 300,
        currency: 'NPR',
        serviceName: 'Wall Painting',
        serviceCategory: 'Painting',
        serviceTags: const ['painting'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final result = model.recommend(
      bookings: bookings,
      providerSkills: const ['Plumbing', 'Pipe Repair'],
    );

    expect(result, hasLength(1));
    expect(result.first.booking.id, '1');
    expect(result.first.matchedSkills, contains('Plumbing'));
    expect(result.first.matchScore, greaterThan(0.25));
  });

  test('returns empty when no skills on profile', () {
    final result = model.recommend(
      bookings: const [],
      providerSkills: const [],
    );
    expect(result, isEmpty);
  });
}
