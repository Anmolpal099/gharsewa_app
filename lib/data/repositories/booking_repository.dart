import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../../services/api/api_client.dart';
import '../../core/constants/api_constants.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.read(apiClientProvider)),
);

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  Future<List<BookingModel>> getCustomerBookings() async {
    final res = await _api.get(ApiConstants.customerBookings);
    final data = res.data['data'] as List;
    return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BookingModel>> getProviderBookings() async {
    final res = await _api.get(ApiConstants.providerBookings);
    final data = res.data['data'] as List;
    return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConstants.customerBookings, data: data);
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> cancelBooking(String id, {String? reason}) async {
    await _api.post('${ApiConstants.customerBookings}/$id/cancel',
        data: {'reason': reason});
  }

  Future<void> acceptBooking(String id) async {
    await _api.post('${ApiConstants.providerBookings}/$id/accept');
  }

  Future<void> rejectBooking(String id, String reason) async {
    await _api.post('${ApiConstants.providerBookings}/$id/reject',
        data: {'reason': reason});
  }

  Future<void> completeBooking(String id) async {
    await _api.post('${ApiConstants.providerBookings}/$id/complete');
  }
}
