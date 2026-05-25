/// Safety Standard Operating Procedure (SOP) for job types
library;

class SafetySOP {
  final String id;
  final String jobType;
  final String content; // Markdown formatted
  final List<String> hazards;
  final List<String> requiredPPE;
  final List<String> procedures;
  final List<String> emergencyProtocols;
  final DateTime generatedAt;
  final bool isSaved;

  const SafetySOP({
    required this.id,
    required this.jobType,
    required this.content,
    required this.hazards,
    required this.requiredPPE,
    required this.procedures,
    required this.emergencyProtocols,
    required this.generatedAt,
    required this.isSaved,
  });

  factory SafetySOP.fromJson(Map<String, dynamic> json) {
    return SafetySOP(
      id: json['id'] as String,
      jobType: json['job_type'] as String,
      content: json['content'] as String,
      hazards: (json['hazards'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requiredPPE: (json['required_ppe'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      procedures: (json['procedures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      emergencyProtocols: (json['emergency_protocols'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      generatedAt: DateTime.parse(json['generated_at'] as String),
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_type': jobType,
      'content': content,
      'hazards': hazards,
      'required_ppe': requiredPPE,
      'procedures': procedures,
      'emergency_protocols': emergencyProtocols,
      'generated_at': generatedAt.toIso8601String(),
      'is_saved': isSaved,
    };
  }

  SafetySOP copyWith({
    String? id,
    String? jobType,
    String? content,
    List<String>? hazards,
    List<String>? requiredPPE,
    List<String>? procedures,
    List<String>? emergencyProtocols,
    DateTime? generatedAt,
    bool? isSaved,
  }) {
    return SafetySOP(
      id: id ?? this.id,
      jobType: jobType ?? this.jobType,
      content: content ?? this.content,
      hazards: hazards ?? this.hazards,
      requiredPPE: requiredPPE ?? this.requiredPPE,
      procedures: procedures ?? this.procedures,
      emergencyProtocols: emergencyProtocols ?? this.emergencyProtocols,
      generatedAt: generatedAt ?? this.generatedAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SafetySOP &&
        other.id == id &&
        other.jobType == jobType &&
        other.content == content &&
        _listEquals(other.hazards, hazards) &&
        _listEquals(other.requiredPPE, requiredPPE) &&
        _listEquals(other.procedures, procedures) &&
        _listEquals(other.emergencyProtocols, emergencyProtocols) &&
        other.generatedAt == generatedAt &&
        other.isSaved == isSaved;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      jobType,
      content,
      Object.hashAll(hazards),
      Object.hashAll(requiredPPE),
      Object.hashAll(procedures),
      Object.hashAll(emergencyProtocols),
      generatedAt,
      isSaved,
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
