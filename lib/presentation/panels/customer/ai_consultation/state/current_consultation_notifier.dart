import '../../../../../../core/services/image_service.dart';
import '../../../../../../core/models/platform_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../data/models/ai_consultation_models.dart';
import '../../../../../../services/api/ai_consultation_api_service.dart';
import '../../../../../../services/api/api_exception.dart';
import 'current_consultation_state.dart';

/// Notifier for managing current consultation state
class CurrentConsultationNotifier extends StateNotifier<CurrentConsultationState> {
  final AIConsultationApiService _apiService;
  final ImageService _imageService = ImageService();
  CurrentConsultationNotifier(this._apiService)
      : super(CurrentConsultationState.initial());

  /// Set the selected image
  void setImage(PlatformImage image) {
  state = state.copyWith(
    image: image,
    clearError: true,
  );
}

  /// Clear the selected image
  void clearImage() {
    state = state.copyWith(
      clearImage: true,
      markers: [], // Clear markers when image is cleared
      clearError: true,
    );
  }

  /// Add a marker to the image
  void addMarker(DefectMarkerModel marker) {
    if (state.hasMaxMarkers) {
      state = state.copyWith(
        error: 'Maximum 10 markers allowed',
      );
      return;
    }

    final updatedMarkers = [...state.markers, marker];
    state = state.copyWith(
      markers: updatedMarkers,
      clearError: true,
    );
  }

  /// Update an existing marker
  void updateMarker(String markerId, DefectMarkerModel updatedMarker) {
    final updatedMarkers = state.markers.map((marker) {
      return marker.id == markerId ? updatedMarker : marker;
    }).toList();

    state = state.copyWith(
      markers: updatedMarkers,
      clearError: true,
    );
  }

  /// Remove a marker
  void removeMarker(String markerId) {
    final updatedMarkers = state.markers.where((m) => m.id != markerId).toList();
    state = state.copyWith(
      markers: updatedMarkers,
      clearError: true,
    );
  }

  /// Clear all markers
  void clearMarkers() {
    state = state.copyWith(
      markers: [],
      clearError: true,
    );
  }

  /// Submit the consultation for AI analysis
  Future<void> submitConsultation() async {
    if (!state.canSubmit) {
      state = state.copyWith(
        error: 'Please select an image and add at least one marker',
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final consultation = await _apiService.createConsultation(
        image: state.image!,
        markers: state.markers,
      );

      state = state.copyWith(
        isSubmitting: false,
        consultation: consultation,
        isCompleted: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Reset the consultation state
  void reset() {
    state = CurrentConsultationState.initial();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for current consultation state
final currentConsultationProvider =
    StateNotifierProvider<CurrentConsultationNotifier, CurrentConsultationState>(
  (ref) {
    final apiService = ref.watch(aiConsultationApiServiceProvider);
    return CurrentConsultationNotifier(apiService);
  },
);
