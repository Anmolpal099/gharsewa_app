enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

class BookingModel {
  final String id;
  final String customerId;
  final String serviceId;
  final String providerId;
  final DateTime scheduledAt;
  final BookingStatus status;
  final double totalPrice;
  final String currency;
  final String? cancellationReason;
  final String? serviceName;
  final String? serviceCategory;
  final List<String> serviceTags;
  final String? customerName;
  final String? aiConsultationId; // Link to AI consultation if booking originated from one
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.providerId,
    required this.scheduledAt,
    required this.status,
    required this.totalPrice,
    required this.currency,
    this.cancellationReason,
    this.serviceName,
    this.serviceCategory,
    this.serviceTags = const [],
    this.customerName,
    this.aiConsultationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    final customer = json['customer'];
    Map<String, dynamic>? serviceMap;
    Map<String, dynamic>? customerMap;
    if (service is Map) {
      serviceMap = Map<String, dynamic>.from(service);
    }
    if (customer is Map) {
      customerMap = Map<String, dynamic>.from(customer);
    }

    return BookingModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ??
          customerMap?['id']?.toString() ??
          '',
      serviceId: json['service_id'] as String? ??
          serviceMap?['id']?.toString() ??
          '',
      providerId: json['provider_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      totalPrice: (json['total_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'NPR',
      cancellationReason: json['cancellation_reason'] as String?,
      serviceName: json['service_name'] as String? ?? serviceMap?['name'] as String?,
      serviceCategory:
          json['service_category'] as String? ?? serviceMap?['category'] as String?,
      serviceTags: _parseStringList(
        json['service_tags'] ?? serviceMap?['tags'],
      ),
      customerName: json['customer_name'] as String? ?? customerMap?['name'] as String?,
      aiConsultationId: json['ai_consultation_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'service_id': serviceId,
        'provider_id': providerId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status.name,
        'total_price': totalPrice,
        'currency': currency,
        'cancellation_reason': cancellationReason,
        'service_name': serviceName,
        'service_category': serviceCategory,
        'service_tags': serviceTags,
        'customer_name': customerName,
        'ai_consultation_id': aiConsultationId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isPending   => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get hasAIConsultation => aiConsultationId != null && aiConsultationId!.isNotEmpty;
}
