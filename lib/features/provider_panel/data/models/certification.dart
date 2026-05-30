/// Certification model representing a provider's certification document
library;

class Certification {
  final String id;
  final String name;
  final String? documentUrl; // Optional - fetched separately to avoid URI too long
  final String fileType; // PDF, PNG, JPG
  final bool isVerified;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;

  const Certification({
    required this.id,
    required this.name,
    this.documentUrl,
    required this.fileType,
    required this.isVerified,
    required this.uploadedAt,
    this.verifiedAt,
  });

  /// Create a Certification from JSON
  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'] as String,
      name: json['name'] as String,
      documentUrl: json['document_url'] as String?,
      fileType: json['file_type'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
    );
  }

  /// Convert Certification to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (documentUrl != null) 'document_url': documentUrl,
      'file_type': fileType,
      'is_verified': isVerified,
      'uploaded_at': uploadedAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Certification copyWith({
    String? id,
    String? name,
    String? documentUrl,
    String? fileType,
    bool? isVerified,
    DateTime? uploadedAt,
    DateTime? verifiedAt,
  }) {
    return Certification(
      id: id ?? this.id,
      name: name ?? this.name,
      documentUrl: documentUrl ?? this.documentUrl,
      fileType: fileType ?? this.fileType,
      isVerified: isVerified ?? this.isVerified,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Certification &&
        other.id == id &&
        other.name == name &&
        other.documentUrl == documentUrl &&
        other.fileType == fileType &&
        other.isVerified == isVerified &&
        other.uploadedAt == uploadedAt &&
        other.verifiedAt == verifiedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      documentUrl,
      fileType,
      isVerified,
      uploadedAt,
      verifiedAt,
    );
  }
}
