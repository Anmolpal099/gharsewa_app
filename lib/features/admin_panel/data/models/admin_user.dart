class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> roles;
  final String? phone;
  final bool isActive;
  final int totalBookings;
  final DateTime? createdAt;
  final double? totalSpent;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;
  final List<Map<String, dynamic>> recentBookings;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roles = const [],
    this.phone,
    required this.isActive,
    this.totalBookings = 0,
    this.createdAt,
    this.totalSpent,
    this.lastLoginAt,
    this.profileImageUrl,
    this.recentBookings = const [],
  });

  factory AdminUser.fromListJson(Map<String, dynamic> json) => AdminUser(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? 'Unknown',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'customer',
        roles: (json['roles'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [json['role'] as String? ?? 'customer'],
        phone: json['phone'] as String? ?? json['phone_number'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        totalBookings: json['total_bookings'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  factory AdminUser.fromDetailJson(Map<String, dynamic> json) => AdminUser(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? 'Unknown',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'customer',
        roles: (json['roles'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [json['role'] as String? ?? 'customer'],
        phone: json['phone'] as String? ?? json['phone_number'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        totalBookings: json['total_bookings'] as int? ?? 0,
        totalSpent: (json['total_spent'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.tryParse(json['last_login_at'] as String)
            : null,
        profileImageUrl: json['profile_image_url'] as String?,
        recentBookings: (json['recent_bookings'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
      );
}
