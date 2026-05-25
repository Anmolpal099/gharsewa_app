import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';

final providerBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  return ref.read(bookingRepositoryProvider).getProviderBookings();
});
