/// Model class for AI-generated service recommendations
class AIRecommendation {
  final String id;
  final ServiceInfo service;
  final double confidenceScore;
  final String reasoning;
  final DateTime expiresAt;

  AIRecommendation({
    required this.id,
    required this.service,
    required this.confidenceScore,
    required this.reasoning,
    required this.expiresAt,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id'] as String,
      service: ServiceInfo.fromJson(json['service'] as Map<String, dynamic>),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service.toJson(),
      'confidence_score': confidenceScore,
      'reasoning': reasoning,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

/// Service information within a recommendation
class ServiceInfo {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String? imageUrl;

  ServiceInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.imageUrl,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
  }
}
