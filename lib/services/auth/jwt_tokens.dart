/// JWT authentication tokens model
class JwtTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const JwtTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory JwtTokens.fromJson(Map<String, dynamic> json) {
    return JwtTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
    };
  }

  /// Get expiration timestamp
  DateTime get expiresAt {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }

  /// Check if token is expired
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }
}

/// User data from JWT authentication
class JwtUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> roles;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? emailVerifiedAt;

  const JwtUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roles,
    this.phoneNumber,
    this.profileImageUrl,
    this.emailVerifiedAt,
  });

  factory JwtUser.fromJson(Map<String, dynamic> json) {
    // Parse roles array, fallback to single role if not present
    List<String> rolesList;
    if (json['roles'] != null) {
      rolesList = (json['roles'] as List).map((e) => e.toString()).toList();
    } else {
      rolesList = [json['role'] as String];
    }

    return JwtUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      roles: rolesList,
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'roles': roles,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
    };
  }

  /// Check if email is verified
  bool get isEmailVerified => emailVerifiedAt != null;

  /// Check if user has a specific role
  bool hasRole(String roleToCheck) {
    return roles.contains(roleToCheck);
  }

  /// Check if user has any of the given roles
  bool hasAnyRole(List<String> rolesToCheck) {
    return rolesToCheck.any((r) => roles.contains(r));
  }

  /// Check if user has multiple roles
  bool get hasMultipleRoles => roles.length > 1;

  /// Check if user is a customer
  bool get isCustomer => hasRole('customer');

  /// Check if user is a service provider
  bool get isServiceProvider => hasRole('serviceProvider');

  /// Check if user is an admin
  bool get isAdmin => hasRole('admin');
}
