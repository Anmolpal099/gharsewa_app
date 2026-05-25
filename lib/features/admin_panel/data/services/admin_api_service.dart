import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/json_helpers.dart';
import '../../../../services/api/api_client.dart';
import '../models/admin_analytics.dart';
import '../models/admin_booking_item.dart';
import '../models/admin_dashboard_data.dart';
import '../models/admin_user.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(apiClientProvider));
});

class AdminApiService {
  AdminApiService(this._api);

  final ApiClient _api;

  Future<AdminDashboardData> getDashboard() async {
    final res = await _api.get(ApiConstants.adminDashboard);
    if (res.data['success'] == true) {
      return AdminDashboardData.fromJson(
        requireJsonMap(res.data['data'], field: 'data'),
      );
    }
    throw Exception(res.data['message'] ?? 'Failed to load dashboard');
  }

  Future<AdminAnalytics> getAnalytics() async {
    final res = await _api.get(ApiConstants.adminAnalytics);
    if (res.data['success'] == true) {
      return AdminAnalytics.fromJson(
        requireJsonMap(res.data['data'], field: 'data'),
      );
    }
    throw Exception(res.data['message'] ?? 'Failed to load analytics');
  }

  Future<List<AdminUser>> getUsers({
    String? search,
    String? role,
    String? status,
  }) async {
    final res = await _api.get(
      ApiConstants.adminUsers,
      params: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role.isNotEmpty) 'role': role,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    if (res.data['success'] == true) {
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => AdminUser.fromListJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res.data['message'] ?? 'Failed to load users');
  }

  Future<AdminUser> getUser(String id) async {
    final res = await _api.get('${ApiConstants.adminUsers}/$id');
    if (res.data['success'] == true) {
      return AdminUser.fromDetailJson(
        requireJsonMap(res.data['data'], field: 'data'),
      );
    }
    throw Exception(res.data['message'] ?? 'Failed to load user');
  }

  Future<void> activateUser(String id) async {
    final res = await _api.post('${ApiConstants.adminUsers}/$id/activate');
    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Activate failed');
    }
  }

  Future<void> deactivateUser(String id, String reason) async {
    final res = await _api.post(
      '${ApiConstants.adminUsers}/$id/deactivate',
      data: {'reason': reason},
    );
    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Deactivate failed');
    }
  }

  Future<String> resetUserPassword(String id) async {
    final res = await _api.post(
      '${ApiConstants.adminUsers}/$id/password-reset',
    );
    if (res.data['success'] == true) {
      final data = requireJsonMap(res.data['data'], field: 'data');
      return data['temporary_password'] as String? ?? '';
    }
    throw Exception(res.data['message'] ?? 'Password reset failed');
  }

  /// Delete a user (customer or service provider)
  /// This permanently removes the user from the system
  Future<void> deleteUser(String id, String reason) async {
    final res = await _api.delete(
      '${ApiConstants.adminUsers}/$id',
      data: {'reason': reason},
    );
    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Delete failed');
    }
  }

  Future<List<AdminBookingItem>> getBookings({
    String? search,
    String? status,
  }) async {
    final res = await _api.get(
      ApiConstants.adminBookings,
      params: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    if (res.data['success'] == true) {
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => AdminBookingItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res.data['message'] ?? 'Failed to load bookings');
  }

  Future<void> cancelBooking(
    String id, {
    required String reason,
    bool refund = false,
  }) async {
    final res = await _api.post(
      '${ApiConstants.adminBookings}/$id/cancel',
      data: {'reason': reason, 'refund': refund},
    );
    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Cancel failed');
    }
  }

  Future<void> addBookingNote(String id, String note) async {
    final res = await _api.post(
      '${ApiConstants.adminBookings}/$id/note',
      data: {'note': note},
    );
    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Failed to add note');
    }
  }

  Future<Map<String, dynamic>> generateReport({
    required String type,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await _api.get(
      ApiConstants.adminReports,
      params: {
        'type': type,
        'format': format,
        'start_date': _dateParam(startDate),
        'end_date': _dateParam(endDate),
      },
    );
    if (res.data['success'] == true) {
      return requireJsonMap(res.data['data'], field: 'data');
    }
    throw Exception(res.data['message'] ?? 'Report generation failed');
  }

  String _dateParam(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
