enum ServiceStatus { active, inactive, pending }

class ServiceModel {
  final String id;
  final String providerId;
  final String name;
  final String description;
  final String category;
  final double price;
  final String currency;
  final int durationMinutes;
  final ServiceStatus status;
  final List<String> imageUrls;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.currency,
    required this.durationMinutes,
    required this.status,
    required this.imageUrls,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        providerId: json['provider_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'NPR',
        durationMinutes: json['duration_minutes'] as int,
        status: ServiceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ServiceStatus.pending,
        ),
        imageUrls: List<String>.from(json['image_urls'] as List? ?? []),
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider_id': providerId,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'currency': currency,
        'duration_minutes': durationMinutes,
        'status': status.name,
        'image_urls': imageUrls,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isActive => status == ServiceStatus.active;
}
