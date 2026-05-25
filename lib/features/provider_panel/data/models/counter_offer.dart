import 'enums.dart';

/// Counter offer sent by provider to customer

class CounterOffer {
  final String id;
  final String requestId;
  final double originalPrice;
  final double counterPrice;
  final String? message;
  final DateTime createdAt;
  final CounterOfferStatus status;

  const CounterOffer({
    required this.id,
    required this.requestId,
    required this.originalPrice,
    required this.counterPrice,
    required this.createdAt,
    required this.status,
    this.message,
  });

  /// Calculate price difference
  double get priceDifference => counterPrice - originalPrice;

  /// Calculate percentage difference
  double get percentageDifference {
    if (originalPrice == 0) return 0;
    return (priceDifference / originalPrice) * 100;
  }

  /// Check if counter offer is higher than original
  bool get isHigher => counterPrice > originalPrice;

  /// Check if counter offer is lower than original
  bool get isLower => counterPrice < originalPrice;

  factory CounterOffer.fromJson(Map<String, dynamic> json) {
    return CounterOffer(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      originalPrice: (json['original_price'] as num).toDouble(),
      counterPrice: (json['counter_price'] as num).toDouble(),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: CounterOfferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CounterOfferStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'original_price': originalPrice,
      'counter_price': counterPrice,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  CounterOffer copyWith({
    String? id,
    String? requestId,
    double? originalPrice,
    double? counterPrice,
    String? message,
    DateTime? createdAt,
    CounterOfferStatus? status,
  }) {
    return CounterOffer(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      originalPrice: originalPrice ?? this.originalPrice,
      counterPrice: counterPrice ?? this.counterPrice,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CounterOffer &&
        other.id == id &&
        other.requestId == requestId &&
        other.originalPrice == originalPrice &&
        other.counterPrice == counterPrice &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      requestId,
      originalPrice,
      counterPrice,
      message,
      createdAt,
      status,
    );
  }
}
