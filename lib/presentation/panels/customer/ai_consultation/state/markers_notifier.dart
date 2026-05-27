import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../../data/models/ai_consultation_models.dart';

/// Notifier for managing markers independently
/// 
/// This provides a focused state management for markers that can be used
/// across different screens in the annotation workflow.
class MarkersNotifier extends StateNotifier<List<DefectMarkerModel>> {
  MarkersNotifier() : super([]);

  final _uuid = const Uuid();

  /// Add a new marker at the specified coordinates
  DefectMarkerModel addMarker({
    required double x,
    required double y,
    String description = '',
  }) {
    if (state.length >= 10) {
      throw Exception('Maximum 10 markers allowed');
    }

    final marker = DefectMarkerModel(
      id: _uuid.v4(),
      x: x,
      y: y,
      description: description,
    );

    state = [...state, marker];
    return marker;
  }

  /// Update an existing marker
  void updateMarker(String markerId, {
    double? x,
    double? y,
    String? description,
  }) {
    state = state.map((marker) {
      if (marker.id == markerId) {
        return marker.copyWith(
          x: x,
          y: y,
          description: description,
        );
      }
      return marker;
    }).toList();
  }

  /// Update marker description
  void updateMarkerDescription(String markerId, String description) {
    updateMarker(markerId, description: description);
  }

  /// Update marker position
  void updateMarkerPosition(String markerId, double x, double y) {
    updateMarker(markerId, x: x, y: y);
  }

  /// Remove a marker by ID
  void removeMarker(String markerId) {
    state = state.where((marker) => marker.id != markerId).toList();
  }

  /// Remove marker at index
  void removeMarkerAt(int index) {
    if (index >= 0 && index < state.length) {
      state = [...state]..removeAt(index);
    }
  }

  /// Clear all markers
  void clearAll() {
    state = [];
  }

  /// Get marker by ID
  DefectMarkerModel? getMarkerById(String markerId) {
    try {
      return state.firstWhere((marker) => marker.id == markerId);
    } catch (e) {
      return null;
    }
  }

  /// Get marker at index
  DefectMarkerModel? getMarkerAt(int index) {
    if (index >= 0 && index < state.length) {
      return state[index];
    }
    return null;
  }

  /// Check if maximum markers reached
  bool get hasMaxMarkers => state.length >= 10;

  /// Check if any markers exist
  bool get hasMarkers => state.isNotEmpty;

  /// Get marker count
  int get markerCount => state.length;

  /// Check if all markers have descriptions
  bool get allMarkersHaveDescriptions {
    return state.every((marker) => marker.description.trim().isNotEmpty);
  }

  /// Get markers without descriptions
  List<DefectMarkerModel> get markersWithoutDescriptions {
    return state.where((marker) => marker.description.trim().isEmpty).toList();
  }

  /// Validate all markers
  bool validateAll() {
    return state.every((marker) => marker.isValid);
  }

  /// Set markers from existing list (useful for editing)
  void setMarkers(List<DefectMarkerModel> markers) {
    if (markers.length > 10) {
      throw Exception('Cannot set more than 10 markers');
    }
    state = [...markers];
  }

  /// Reorder markers
  void reorderMarkers(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length ||
        newIndex < 0 || newIndex >= state.length) {
      return;
    }

    final markers = [...state];
    final marker = markers.removeAt(oldIndex);
    markers.insert(newIndex, marker);
    state = markers;
  }
}

/// Provider for markers state
final markersProvider =
    StateNotifierProvider<MarkersNotifier, List<DefectMarkerModel>>((ref) {
  return MarkersNotifier();
});

/// Provider for selected marker ID
final selectedMarkerIdProvider = StateProvider<String?>((ref) => null);

/// Provider for checking if a marker is selected
final isMarkerSelectedProvider = Provider.family<bool, String>((ref, markerId) {
  final selectedId = ref.watch(selectedMarkerIdProvider);
  return selectedId == markerId;
});

/// Provider for the currently selected marker
final selectedMarkerProvider = Provider<DefectMarkerModel?>((ref) {
  final selectedId = ref.watch(selectedMarkerIdProvider);
  if (selectedId == null) return null;

  final markers = ref.watch(markersProvider);
  try {
    return markers.firstWhere((marker) => marker.id == selectedId);
  } catch (e) {
    return null;
  }
});

/// Provider for marker count
final markerCountProvider = Provider<int>((ref) {
  final markers = ref.watch(markersProvider);
  return markers.length;
});

/// Provider for checking if max markers reached
final hasMaxMarkersProvider = Provider<bool>((ref) {
  final count = ref.watch(markerCountProvider);
  return count >= 10;
});

/// Provider for checking if markers can be submitted
final canSubmitMarkersProvider = Provider<bool>((ref) {
  final markers = ref.watch(markersProvider);
  return markers.isNotEmpty && markers.every((m) => m.isValid);
});
