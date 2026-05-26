/// Model class for AI system performance metrics
class AIMetrics {
  final String period;
  final DateTime since;
  final RequestMetrics requests;
  final PerformanceMetrics performance;
  final CacheMetrics cache;
  final Map<String, int> requestsByType;
  final List<ErrorInfo> topErrors;
  final OllamaStatus ollama;

  AIMetrics({
    required this.period,
    required this.since,
    required this.requests,
    required this.performance,
    required this.cache,
    required this.requestsByType,
    required this.topErrors,
    required this.ollama,
  });

  factory AIMetrics.fromJson(Map<String, dynamic> json) {
    return AIMetrics(
      period: json['period'] as String,
      since: DateTime.parse(json['since'] as String),
      requests: RequestMetrics.fromJson(json['requests'] as Map<String, dynamic>),
      performance: PerformanceMetrics.fromJson(json['performance'] as Map<String, dynamic>),
      cache: CacheMetrics.fromJson(json['cache'] as Map<String, dynamic>),
      requestsByType: (json['requests_by_type'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
      topErrors: (json['top_errors'] as List)
          .map((e) => ErrorInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      ollama: OllamaStatus.fromJson(json['ollama'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'since': since.toIso8601String(),
      'requests': requests.toJson(),
      'performance': performance.toJson(),
      'cache': cache.toJson(),
      'requests_by_type': requestsByType,
      'top_errors': topErrors.map((e) => e.toJson()).toList(),
      'ollama': ollama.toJson(),
    };
  }
}

/// Request metrics
class RequestMetrics {
  final int total;
  final int successful;
  final int failed;
  final double successRate;

  RequestMetrics({
    required this.total,
    required this.successful,
    required this.failed,
    required this.successRate,
  });

  factory RequestMetrics.fromJson(Map<String, dynamic> json) {
    return RequestMetrics(
      total: json['total'] as int,
      successful: json['successful'] as int,
      failed: json['failed'] as int,
      successRate: (json['success_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'successful': successful,
      'failed': failed,
      'success_rate': successRate,
    };
  }
}

/// Performance metrics
class PerformanceMetrics {
  final double avgResponseTimeMs;
  final double p50ResponseTimeMs;
  final double p95ResponseTimeMs;
  final double p99ResponseTimeMs;

  PerformanceMetrics({
    required this.avgResponseTimeMs,
    required this.p50ResponseTimeMs,
    required this.p95ResponseTimeMs,
    required this.p99ResponseTimeMs,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      avgResponseTimeMs: (json['avg_response_time_ms'] as num).toDouble(),
      p50ResponseTimeMs: (json['p50_response_time_ms'] as num).toDouble(),
      p95ResponseTimeMs: (json['p95_response_time_ms'] as num).toDouble(),
      p99ResponseTimeMs: (json['p99_response_time_ms'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avg_response_time_ms': avgResponseTimeMs,
      'p50_response_time_ms': p50ResponseTimeMs,
      'p95_response_time_ms': p95ResponseTimeMs,
      'p99_response_time_ms': p99ResponseTimeMs,
    };
  }
}

/// Cache metrics
class CacheMetrics {
  final double estimatedHitRate;
  final int estimatedHits;

  CacheMetrics({
    required this.estimatedHitRate,
    required this.estimatedHits,
  });

  factory CacheMetrics.fromJson(Map<String, dynamic> json) {
    return CacheMetrics(
      estimatedHitRate: (json['estimated_hit_rate'] as num).toDouble(),
      estimatedHits: json['estimated_hits'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimated_hit_rate': estimatedHitRate,
      'estimated_hits': estimatedHits,
    };
  }
}

/// Error information
class ErrorInfo {
  final String message;
  final int count;

  ErrorInfo({
    required this.message,
    required this.count,
  });

  factory ErrorInfo.fromJson(Map<String, dynamic> json) {
    return ErrorInfo(
      message: json['message'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'count': count,
    };
  }
}

/// Ollama status
class OllamaStatus {
  final String status;
  final double estimatedUptime;
  final String model;

  OllamaStatus({
    required this.status,
    required this.estimatedUptime,
    required this.model,
  });

  factory OllamaStatus.fromJson(Map<String, dynamic> json) {
    return OllamaStatus(
      status: json['status'] as String,
      estimatedUptime: (json['estimated_uptime'] as num).toDouble(),
      model: json['model'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'estimated_uptime': estimatedUptime,
      'model': model,
    };
  }
}
