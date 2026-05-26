/// Model class for AI-generated safety standard operating procedures
class AISafetySOP {
  final String id;
  final String jobType;
  final String content;
  final List<String> hazards;
  final List<String> requiredPpe;
  final List<String> procedures;
  final List<String> emergencyProtocols;
  final DateTime generatedAt;
  final bool isSaved;

  AISafetySOP({
    required this.id,
    required this.jobType,
    required this.content,
    required this.hazards,
    required this.requiredPpe,
    required this.procedures,
    required this.emergencyProtocols,
    required this.generatedAt,
    required this.isSaved,
  });

  factory AISafetySOP.fromJson(Map<String, dynamic> json) {
    return AISafetySOP(
      id: json['id'] as String,
      jobType: json['job_type'] as String,
      content: json['content'] as String,
      hazards: (json['hazards'] as List).cast<String>(),
      requiredPpe: (json['required_ppe'] as List).cast<String>(),
      procedures: (json['procedures'] as List).cast<String>(),
      emergencyProtocols: (json['emergency_protocols'] as List).cast<String>(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      isSaved: json['is_saved'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_type': jobType,
      'content': content,
      'hazards': hazards,
      'required_ppe': requiredPpe,
      'procedures': procedures,
      'emergency_protocols': emergencyProtocols,
      'generated_at': generatedAt.toIso8601String(),
      'is_saved': isSaved,
    };
  }
}
