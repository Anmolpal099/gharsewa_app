/// Model representing a visual marker placed on an image during AI consultation
class DefectMarkerModel {
  /// Unique identifier for the marker
  final String id;

  /// Normalized X coordinate (0.0 to 1.0) relative to image width
  final double x;

  /// Normalized Y coordinate (0.0 to 1.0) relative to image height
  final double y;

  /// User-provided description of the issue at this marker location
  final String description;

  const DefectMarkerModel({
    required this.id,
    required this.x,
    required this.y,
    required this.description,
  });

  /// Creates a DefectMarkerModel from JSON data
  factory DefectMarkerModel.fromJson(Map<String, dynamic> json) {
    return DefectMarkerModel(
      id: json['id'] as String? ?? '',
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  /// Converts the DefectMarkerModel to JSON format
  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'description': description,
      };

  /// Creates a copy of this marker with optional field updates
  DefectMarkerModel copyWith({
    String? id,
    double? x,
    double? y,
    String? description,
  }) {
    return DefectMarkerModel(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      description: description ?? this.description,
    );
  }

  /// Checks if coordinates are within valid range (0.0 to 1.0)
  bool get hasValidCoordinates => x >= 0.0 && x <= 1.0 && y >= 0.0 && y <= 1.0;

  /// Checks if description meets minimum length requirement
  bool get hasValidDescription => description.trim().length >= 2;

  /// Checks if the marker is fully valid
  bool get isValid => hasValidCoordinates && hasValidDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DefectMarkerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          description == other.description;

  @override
  int get hashCode => Object.hash(id, x, y, description);

  @override
  String toString() =>
      'DefectMarkerModel(id: $id, x: $x, y: $y, description: $description)';
}
