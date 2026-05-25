import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/admin_analytics.dart';
import '../data/models/admin_booking_item.dart';
import '../data/models/admin_dashboard_data.dart';
import '../data/models/admin_user.dart';
import '../data/services/admin_api_service.dart';

final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) async {
  return ref.read(adminApiServiceProvider).getDashboard();
});

final adminAnalyticsProvider = FutureProvider<AdminAnalytics>((ref) async {
  return ref.read(adminApiServiceProvider).getAnalytics();
});

final adminUserSearchProvider = StateProvider<String>((ref) => '');
final adminUserRoleFilterProvider = StateProvider<String?>((ref) => null);
final adminUserStatusFilterProvider = StateProvider<String?>((ref) => null);

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  final search = ref.watch(adminUserSearchProvider);
  final role = ref.watch(adminUserRoleFilterProvider);
  final status = ref.watch(adminUserStatusFilterProvider);
  return ref.read(adminApiServiceProvider).getUsers(
        search: search,
        role: role,
        status: status,
      );
});

final adminUserDetailProvider =
    FutureProvider.family<AdminUser, String>((ref, id) async {
  return ref.read(adminApiServiceProvider).getUser(id);
});

final adminBookingSearchProvider = StateProvider<String>((ref) => '');
final adminBookingStatusFilterProvider = StateProvider<String?>((ref) => null);

final adminBookingsProvider = FutureProvider<List<AdminBookingItem>>((ref) async {
  final search = ref.watch(adminBookingSearchProvider);
  final status = ref.watch(adminBookingStatusFilterProvider);
  return ref.read(adminApiServiceProvider).getBookings(
        search: search,
        status: status,
      );
});
