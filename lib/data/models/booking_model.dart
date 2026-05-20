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
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        serviceId: json['service_id'] as String,
        providerId: json['provider_id'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        status: BookingStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => BookingStatus.pending,
        ),
        totalPrice: (json['total_price'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'NPR',
        cancellationReason: json['cancellation_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

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
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isPending   => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;
}
