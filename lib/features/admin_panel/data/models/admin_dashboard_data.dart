class AdminActivity {
  final String type;
  final String message;
  final DateTime? timestamp;

  const AdminActivity({
    required this.type,
    required this.message,
    this.timestamp,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) => AdminActivity(
        type: json['type'] as String? ?? 'activity',
        message: json['message'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
      );
}

class AdminDashboardData {
  final int totalUsers;
  final int totalCustomers;
  final int totalProviders;
  final int totalAdmins;
  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalRevenue;
  final double currentMonthRevenue;
  final int activeServices;
  final double platformRating;
  final List<AdminActivity> recentActivities;

  const AdminDashboardData({
    required this.totalUsers,
    required this.totalCustomers,
    required this.totalProviders,
    required this.totalAdmins,
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalRevenue,
    required this.currentMonthRevenue,
    required this.activeServices,
    required this.platformRating,
    required this.recentActivities,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final activities = (json['recent_activities'] as List? ?? [])
        .map((e) => AdminActivity.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminDashboardData(
      totalUsers: json['total_users'] as int? ?? 0,
      totalCustomers: json['total_customers'] as int? ?? 0,
      totalProviders: json['total_providers'] as int? ?? 0,
      totalAdmins: json['total_admins'] as int? ?? 0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      pendingBookings: json['pending_bookings'] as int? ?? 0,
      confirmedBookings: json['confirmed_bookings'] as int? ?? 0,
      completedBookings: json['completed_bookings'] as int? ?? 0,
      cancelledBookings: json['cancelled_bookings'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      currentMonthRevenue:
          (json['current_month_revenue'] as num?)?.toDouble() ?? 0,
      activeServices: json['active_services'] as int? ?? 0,
      platformRating: (json['platform_rating'] as num?)?.toDouble() ?? 0,
      recentActivities: activities,
    );
  }
}
