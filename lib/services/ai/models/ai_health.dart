/// Model class for AI system health status
class AIHealth {
  final String status;
  final DateTime timestamp;
  final HealthComponents components;

  AIHealth({
    required this.status,
    required this.timestamp,
    required this.components,
  });

  /// Check if the system is healthy
  bool get isHealthy => status == 'healthy';

  factory AIHealth.fromJson(Map<String, dynamic> json) {
    return AIHealth(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      components: HealthComponents.fromJson(json['components'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'components': components.toJson(),
    };
  }
}

/// Health status of all system components
class HealthComponents {
  final ComponentHealth ollama;
  final ComponentHealth redis;
  final ComponentHealth database;
  final ModelHealth model;
  final QueueHealth queue;

  HealthComponents({
    required this.ollama,
    required this.redis,
    required this.database,
    required this.model,
    required this.queue,
  });

  factory HealthComponents.fromJson(Map<String, dynamic> json) {
    return HealthComponents(
      ollama: ComponentHealth.fromJson(json['ollama'] as Map<String, dynamic>),
      redis: ComponentHealth.fromJson(json['redis'] as Map<String, dynamic>),
      database: ComponentHealth.fromJson(json['database'] as Map<String, dynamic>),
      model: ModelHealth.fromJson(json['model'] as Map<String, dynamic>),
      queue: QueueHealth.fromJson(json['queue'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ollama': ollama.toJson(),
      'redis': redis.toJson(),
      'database': database.toJson(),
      'model': model.toJson(),
      'queue': queue.toJson(),
    };
  }
}

/// Health status of a single component
class ComponentHealth {
  final String status;
  final String message;
  final String? error;

  ComponentHealth({
    required this.status,
    required this.message,
    this.error,
  });

  /// Check if the component is healthy
  bool get isHealthy => status == 'healthy';

  factory ComponentHealth.fromJson(Map<String, dynamic> json) {
    return ComponentHealth(
      status: json['status'] as String,
      message: json['message'] as String,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'error': error,
    };
  }
}

/// Health status of the AI model
class ModelHealth {
  final String status;
  final String message;
  final String modelName;
  final String? error;

  ModelHealth({
    required this.status,
    required this.message,
    required this.modelName,
    this.error,
  });

  /// Check if the model is healthy
  bool get isHealthy => status == 'healthy';

  factory ModelHealth.fromJson(Map<String, dynamic> json) {
    return ModelHealth(
      status: json['status'] as String,
      message: json['message'] as String,
      modelName: json['model_name'] as String,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'model_name': modelName,
      'error': error,
    };
  }
}

/// Health status of the job queue
class QueueHealth {
  final String status;
  final String message;
  final int failedJobs;

  QueueHealth({
    required this.status,
    required this.message,
    required this.failedJobs,
  });

  /// Check if the queue is healthy
  bool get isHealthy => status == 'healthy';

  factory QueueHealth.fromJson(Map<String, dynamic> json) {
    return QueueHealth(
      status: json['status'] as String,
      message: json['message'] as String,
      failedJobs: json['failed_jobs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'failed_jobs': failedJobs,
    };
  }
}
