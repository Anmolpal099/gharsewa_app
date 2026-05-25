import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../../services/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../datasources/local/mock_data.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.read(apiClientProvider)),
);

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  Future<List<BookingModel>> getCustomerBookings() async {
    try {
      final res = await _api.get(ApiConstants.customerBookings);
      final data = res.data['data'] as List;
      return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return MockData.bookings;
    }
  }

  Future<List<BookingModel>> getProviderBookings() async {
    try {
      final res = await _api.get(ApiConstants.providerBookings);
      final data = res.data['data'] as List;
      return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return MockData.bookings;
    }
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.customerBookings, data: data);
      return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return MockData.bookings.first;
    }
  }

  Future<void> cancelBooking(String id, {String? reason}) async {
    try {
      await _api.post('${ApiConstants.customerBookings}/$id/cancel',
          data: {'reason': reason});
    } catch (_) {}
  }

  Future<void> acceptBooking(String id) async {
    try {
      await _api.post('${ApiConstants.providerBookings}/$id/accept');
    } catch (_) {}
  }

  Future<void> rejectBooking(String id, String reason) async {
    try {
      await _api.post('${ApiConstants.providerBookings}/$id/reject',
          data: {'reason': reason});
    } catch (_) {}
  }

  Future<void> completeBooking(String id) async {
    try {
      await _api.post('${ApiConstants.providerBookings}/$id/complete');
    } catch (_) {}
  }

  /// Available time slots for a service on a date (Task 6.4.2).
  Future<List<String>> checkAvailability({
    required String serviceId,
    required DateTime date,
  }) async {
    try {
      final res = await _api.get(
        ApiConstants.customerBookingsCheckAvailability,
        params: {
          'service_id': serviceId,
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return List<String>.from(data['available_slots'] as List? ?? []);
    } catch (_) {
      return ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];
    }
  }
}
