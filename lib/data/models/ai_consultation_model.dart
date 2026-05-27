import 'defect_marker_model.dart';
import 'provider_recommendation_model.dart';

/// Model representing an AI consultation session
class AIConsultationModel {
  /// Unique identifier for the consultation
  final String id;

  /// Customer ID who created the consultation
  final String customerId;

  /// Path to the stored image
  final String imagePath;

  /// Full URL to access the image
  final String? imageUrl;

  /// List of markers placed on the image
  final List<DefectMarkerModel> markers;

  /// AI-generated diagnosis of the issue
  final String diagnosis;

  /// Recommended service type (e.g., 'plumbing', 'electrical', 'carpentry')
  final String recommendedServiceType;

  /// Estimated minimum cost in NPR
  final double estimatedCostMin;

  /// Estimated maximum cost in NPR
  final double estimatedCostMax;

  /// List of recommended service providers
  final List<ProviderRecommendationModel> recommendedProviders;

  /// Raw AI response for debugging/reference
  final Map<String, dynamic>? aiResponseRaw;

  /// Time taken for AI processing in seconds
  final double? processingTimeSeconds;

  /// When the consultation was created
  final DateTime createdAt;

  /// When the consultation was last updated
  final DateTime updatedAt;

  /// When the consultation was soft deleted (if applicable)
  final DateTime? deletedAt;

  const AIConsultationModel({
    required this.id,
    required this.customerId,
    required this.imagePath,
    this.imageUrl,
    required this.markers,
    required this.diagnosis,
    required this.recommendedServiceType,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.recommendedProviders,
    this.aiResponseRaw,
    this.processingTimeSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Creates an AIConsultationModel from JSON data
  factory AIConsultationModel.fromJson(Map<String, dynamic> json) {
    return AIConsultationModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      imagePath: json['image_path'] as String,
      imageUrl: json['image_url'] as String?,
      markers: _parseMarkers(json['markers']),
      diagnosis: json['diagnosis'] as String,
      recommendedServiceType: json['recommended_service_type'] as String,
      estimatedCostMin: (json['estimated_cost_min'] as num).toDouble(),
      estimatedCostMax: (json['estimated_cost_max'] as num).toDouble(),
      recommendedProviders: _parseProviders(json['recommended_providers']),
      aiResponseRaw: json['ai_response_raw'] as Map<String, dynamic>?,
      processingTimeSeconds: (json['processing_time_seconds'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
    );
  }

  /// Parses markers from JSON array
  static List<DefectMarkerModel> _parseMarkers(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => DefectMarkerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Parses provider recommendations from JSON array
  static List<ProviderRecommendationModel> _parseProviders(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => ProviderRecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Converts the AIConsultationModel to JSON format
  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'image_path': imagePath,
        'image_url': imageUrl,
        'markers': markers.map((m) => m.toJson()).toList(),
        'diagnosis': diagnosis,
        'recommended_service_type': recommendedServiceType,
        'estimated_cost_min': estimatedCostMin,
        'estimated_cost_max': estimatedCostMax,
        'recommended_providers': recommendedProviders.map((p) => p.toJson()).toList(),
        'ai_response_raw': aiResponseRaw,
        'processing_time_seconds': processingTimeSeconds,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  /// Creates a copy of this consultation with optional field updates
  AIConsultationModel copyWith({
    String? id,
    String? customerId,
    String? imagePath,
    String? imageUrl,
    List<DefectMarkerModel>? markers,
    String? diagnosis,
    String? recommendedServiceType,
    double? estimatedCostMin,
    double? estimatedCostMax,
    List<ProviderRecommendationModel>? recommendedProviders,
    Map<String, dynamic>? aiResponseRaw,
    double? processingTimeSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AIConsultationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      markers: markers ?? this.markers,
      diagnosis: diagnosis ?? this.diagnosis,
      recommendedServiceType: recommendedServiceType ?? this.recommendedServiceType,
      estimatedCostMin: estimatedCostMin ?? this.estimatedCostMin,
      estimatedCostMax: estimatedCostMax ?? this.estimatedCostMax,
      recommendedProviders: recommendedProviders ?? this.recommendedProviders,
      aiResponseRaw: aiResponseRaw ?? this.aiResponseRaw,
      processingTimeSeconds: processingTimeSeconds ?? this.processingTimeSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Gets the cost range as a formatted string (e.g., "NPR 5,000 - 10,000")
  String get costRangeFormatted {
    final minFormatted = estimatedCostMin.toStringAsFixed(0);
    final maxFormatted = estimatedCostMax.toStringAsFixed(0);
    return 'NPR $minFormatted - $maxFormatted';
  }

  /// Gets the number of markers
  int get markerCount => markers.length;

  /// Checks if there are recommended providers
  bool get hasRecommendedProviders => recommendedProviders.isNotEmpty;

  /// Gets the number of recommended providers
  int get providerCount => recommendedProviders.length;

  /// Checks if the consultation has been soft deleted
  bool get isDeleted => deletedAt != null;

  /// Gets a short diagnosis summary (first 100 characters)
  String get diagnosisSummary {
    if (diagnosis.length <= 100) return diagnosis;
    return '${diagnosis.substring(0, 97)}...';
  }

  /// Gets a formatted date string (e.g., "May 26, 2024")
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  /// Gets a formatted time string (e.g., "2:30 PM")
  String get formattedTime {
    final hour = createdAt.hour > 12 ? createdAt.hour - 12 : createdAt.hour;
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Gets processing time as a formatted string
  String get formattedProcessingTime {
    if (processingTimeSeconds == null) return 'N/A';
    if (processingTimeSeconds! < 60) {
      return '${processingTimeSeconds!.toStringAsFixed(1)}s';
    }
    final minutes = (processingTimeSeconds! / 60).floor();
    final seconds = (processingTimeSeconds! % 60).toStringAsFixed(0);
    return '${minutes}m ${seconds}s';
  }

  /// Gets a user-friendly service type name
  String get serviceTypeDisplayName {
    // Convert snake_case or kebab-case to Title Case
    return recommendedServiceType
        .split(RegExp(r'[_-]'))
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIConsultationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AIConsultationModel(id: $id, diagnosis: $diagnosisSummary, serviceType: $recommendedServiceType)';
}
