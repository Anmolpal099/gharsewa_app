import 'certification.dart';

/// Provider profile model with completeness calculation

class ProviderProfile {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final int servicesCount;
  final String? photoUrl;
  final String? bio;
  final String location;
  final String professionalCategory;
  final bool isVerified;
  final List<String> skills;
  final List<Certification> certifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProviderProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.servicesCount = 0,
    this.photoUrl,
    this.bio,
    required this.location,
    required this.professionalCategory,
    required this.isVerified,
    required this.skills,
    required this.certifications,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate profile completeness percentage
  /// - 25% for having a photo
  /// - 25% for having a bio with at least 50 characters
  /// - 25% for having at least 3 skills
  /// - 25% for having at least 1 certification
  double get completeness {
    int score = 0;
    if (photoUrl != null && photoUrl!.isNotEmpty) score += 25;
    if (bio != null && bio!.length >= 50) score += 25;
    if (skills.length >= 3) score += 25;
    if (certifications.isNotEmpty) score += 25;
    return score.toDouble();
  }

  /// Check if profile is complete (100%)
  bool get isComplete => completeness == 100.0;

  /// Get list of missing profile items
  List<String> get missingItems {
    final List<String> missing = [];
    if (photoUrl == null || photoUrl!.isEmpty) {
      missing.add('Profile photo');
    }
    if (bio == null || bio!.length < 50) {
      missing.add('Bio (minimum 50 characters)');
    }
    if (skills.length < 3) {
      missing.add('${3 - skills.length} more skill(s)');
    }
    if (certifications.isEmpty) {
      missing.add('At least 1 certification');
    }
    return missing;
  }

  /// Create a ProviderProfile from JSON
  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      servicesCount: json['services_count'] as int? ?? 0,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String,
      professionalCategory: json['professional_category'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => Certification.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert ProviderProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'services_count': servicesCount,
      'photo_url': photoUrl,
      'bio': bio,
      'location': location,
      'professional_category': professionalCategory,
      'is_verified': isVerified,
      'skills': skills,
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ProviderProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    int? servicesCount,
    String? photoUrl,
    String? bio,
    String? location,
    String? professionalCategory,
    bool? isVerified,
    List<String>? skills,
    List<Certification>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      servicesCount: servicesCount ?? this.servicesCount,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      professionalCategory: professionalCategory ?? this.professionalCategory,
      isVerified: isVerified ?? this.isVerified,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProviderProfile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.bio == bio &&
        other.location == location &&
        other.professionalCategory == professionalCategory &&
        other.isVerified == isVerified &&
        _listEquals(other.skills, skills) &&
        _listEquals(other.certifications, certifications) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      photoUrl,
      bio,
      location,
      professionalCategory,
      isVerified,
      Object.hashAll(skills),
      Object.hashAll(certifications),
      createdAt,
      updatedAt,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
