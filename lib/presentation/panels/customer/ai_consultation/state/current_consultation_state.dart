import 'package:flutter/foundation.dart';
import '../../../../../../core/models/platform_image.dart';
import '../../../../../../data/models/ai_consultation_models.dart';

/// State for the current consultation being created
@immutable
class CurrentConsultationState {
  /// The selected image (platform-aware)
  final PlatformImage? image;

  /// List of markers placed on the image
  final List<DefectMarkerModel> markers;

  /// Whether the consultation is being submitted
  final bool isSubmitting;

  /// Error message if submission failed
  final String? error;

  /// The created consultation (after successful submission)
  final AIConsultationModel? consultation;

  /// Whether the consultation was successfully created
  final bool isCompleted;

  const CurrentConsultationState({
    this.image,
    this.markers = const [],
    this.isSubmitting = false,
    this.error,
    this.consultation,
    this.isCompleted = false,
  });

  /// Initial state
  factory CurrentConsultationState.initial() => const CurrentConsultationState();

  /// Copy with method for immutable updates
  CurrentConsultationState copyWith({
    PlatformImage? image,
    List<DefectMarkerModel>? markers,
    bool? isSubmitting,
    String? error,
    AIConsultationModel? consultation,
    bool? isCompleted,
    bool clearError = false,
    bool clearImage = false,
    bool clearConsultation = false,
  }) {
    return CurrentConsultationState(
      image: clearImage ? null : (image ?? this.image),
      markers: markers ?? this.markers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      consultation: clearConsultation ? null : (consultation ?? this.consultation),
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Check if image is selected
  bool get hasImage => image != null;

  /// Check if markers are added
  bool get hasMarkers => markers.isNotEmpty;

  /// Check if ready to submit (has image and at least one marker)
  bool get canSubmit => hasImage && hasMarkers && !isSubmitting;

  /// Get marker count
  int get markerCount => markers.length;

  /// Check if maximum markers reached (10)
  bool get hasMaxMarkers => markers.length >= 10;

  /// Check if has error
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentConsultationState &&
          runtimeType == other.runtimeType &&
          image == other.image &&
          listEquals(markers, other.markers) &&
          isSubmitting == other.isSubmitting &&
          error == other.error &&
          consultation == other.consultation &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        image,
        markers,
        isSubmitting,
        error,
        consultation,
        isCompleted,
      );

  @override
  String toString() =>
      'CurrentConsultationState(hasImage: $hasImage, markerCount: $markerCount, isSubmitting: $isSubmitting, hasError: $hasError, isCompleted: $isCompleted)';
}
