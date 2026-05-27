/// Model representing a recommended service provider from AI analysis
class ProviderRecommendationModel {
  /// Unique identifier for the provider
  final String id;

  /// Provider's business or personal name
  final String name;

  /// Average rating (0.0 to 5.0)
  final double rating;

  /// List of services offered by this provider
  final List<String> services;

  /// Provider's contact phone number
  final String? phone;

  /// Provider's email address
  final String? email;

  /// Provider's profile image URL
  final String? profileImage;

  /// Provider's location/address
  final String? location;

  /// Number of completed bookings
  final int? completedBookings;

  /// Whether the provider is currently active
  final bool isActive;

  const ProviderRecommendationModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.services,
    this.phone,
    this.email,
    this.profileImage,
    this.location,
    this.completedBookings,
    this.isActive = true,
  });

  /// Creates a ProviderRecommendationModel from JSON data
  factory ProviderRecommendationModel.fromJson(Map<String, dynamic> json) {
    return ProviderRecommendationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      services: _parseStringList(json['services']),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String?,
      location: json['location'] as String?,
      completedBookings: json['completed_bookings'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Parses a dynamic value into a list of strings
  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Converts the ProviderRecommendationModel to JSON format
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'services': services,
        'phone': phone,
        'email': email,
        'profile_image': profileImage,
        'location': location,
        'completed_bookings': completedBookings,
        'is_active': isActive,
      };

  /// Creates a copy of this provider with optional field updates
  ProviderRecommendationModel copyWith({
    String? id,
    String? name,
    double? rating,
    List<String>? services,
    String? phone,
    String? email,
    String? profileImage,
    String? location,
    int? completedBookings,
    bool? isActive,
  }) {
    return ProviderRecommendationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      services: services ?? this.services,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      completedBookings: completedBookings ?? this.completedBookings,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Gets a formatted rating string (e.g., "4.5")
  String get formattedRating => rating.toStringAsFixed(1);

  /// Gets a comma-separated string of services
  String get servicesText => services.join(', ');

  /// Checks if the provider has a high rating (>= 4.0)
  bool get hasHighRating => rating >= 4.0;

  /// Checks if the provider has completed bookings data
  bool get hasBookingHistory => completedBookings != null && completedBookings! > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderRecommendationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProviderRecommendationModel(id: $id, name: $name, rating: $rating, services: $services)';
}
