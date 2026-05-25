import 'enums.dart';

/// AI-generated suggestion for provider optimization

class Suggestion {
  final String id;
  final String title;
  final String description;
  final SuggestionType type;
  final SuggestionPriority priority;
  final DateTime createdAt;
  final DateTime? dismissedAt;

  const Suggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.dismissedAt,
  });

  /// Check if suggestion has been dismissed
  bool get isDismissed => dismissedAt != null;

  /// Check if suggestion is active (not dismissed)
  bool get isActive => !isDismissed;

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: SuggestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SuggestionType.profileImprovement,
      ),
      priority: SuggestionPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => SuggestionPriority.medium,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      dismissedAt: json['dismissed_at'] != null
          ? DateTime.parse(json['dismissed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'dismissed_at': dismissedAt?.toIso8601String(),
    };
  }

  Suggestion copyWith({
    String? id,
    String? title,
    String? description,
    SuggestionType? type,
    SuggestionPriority? priority,
    DateTime? createdAt,
    DateTime? dismissedAt,
  }) {
    return Suggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Suggestion &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.priority == priority &&
        other.createdAt == createdAt &&
        other.dismissedAt == dismissedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      type,
      priority,
      createdAt,
      dismissedAt,
    );
  }
}
