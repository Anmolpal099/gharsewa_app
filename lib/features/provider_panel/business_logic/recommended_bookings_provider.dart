import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/recommended_booking.dart';
import 'provider_bookings_providers.dart';
import 'profile_manager.dart';
import 'skill_booking_recommendation_model.dart';

final skillBookingRecommendationModelProvider =
    Provider<SkillBookingRecommendationModel>(
  (ref) => const SkillBookingRecommendationModel(),
);

/// Pending bookings ranked by provider profile skills.
final recommendedBookingsProvider =
    Provider<AsyncValue<List<RecommendedBooking>>>((ref) {
  final bookingsAsync = ref.watch(providerBookingsProvider);
  final profileAsync = ref.watch(profileManagerProvider);

  return bookingsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (bookings) {
      final skills = profileAsync.value?.skills ?? const [];
      if (skills.isEmpty) {
        return const AsyncValue.data([]);
      }
      final model = ref.watch(skillBookingRecommendationModelProvider);
      return AsyncValue.data(
        model.recommend(bookings: bookings, providerSkills: skills),
      );
    },
  );
});
