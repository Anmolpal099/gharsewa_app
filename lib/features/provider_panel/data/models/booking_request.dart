import 'enums.dart';

/// Booking request from a customer
class BookingRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String customerLocation;
  final String serviceTitle;
  final String description;
  final double proposedPrice;
  final DateTime scheduledDateTime;
  final DateTime createdAt;
  final BookingRequestStatus status;

  const BookingRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.customerLocation,
    required this.serviceTitle,
    required this.description,
    required this.proposedPrice,
    required this.scheduledDateTime,
    required this.createdAt,
    required this.status,
  });

  /// Check if request is urgent (scheduled within 24 hours)
  bool get isUrgent {
    final now = DateTime.now();
    final difference = scheduledDateTime.difference(now);
    return difference.inHours <= 24 && difference.inHours >= 0;
  }

  /// Calculate time elapsed since request was created
  Duration get timeElapsed => DateTime.now().difference(createdAt);

  /// Format time elapsed as human-readable string
  String get timeElapsedString {
    final elapsed = timeElapsed;
    if (elapsed.inMinutes < 60) {
      return '${elapsed.inMinutes} minutes ago';
    } else if (elapsed.inHours < 24) {
      return '${elapsed.inHours} hours ago';
    } else {
      return '${elapsed.inDays} days ago';
    }
  }

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      customerAvatar: json['customer_avatar'] as String?,
      customerLocation: json['customer_location'] as String,
      serviceTitle: json['service_title'] as String,
      description: json['description'] as String,
      proposedPrice: (json['proposed_price'] as num).toDouble(),
      scheduledDateTime: DateTime.parse(json['scheduled_date_time'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: BookingRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingRequestStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_avatar': customerAvatar,
      'customer_location': customerLocation,
      'service_title': serviceTitle,
      'description': description,
      'proposed_price': proposedPrice,
      'scheduled_date_time': scheduledDateTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  BookingRequest copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerAvatar,
    String? customerLocation,
    String? serviceTitle,
    String? description,
    double? proposedPrice,
    DateTime? scheduledDateTime,
    DateTime? createdAt,
    BookingRequestStatus? status,
  }) {
    return BookingRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      customerLocation: customerLocation ?? this.customerLocation,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      description: description ?? this.description,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BookingRequest &&
        other.id == id &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.customerAvatar == customerAvatar &&
        other.customerLocation == customerLocation &&
        other.serviceTitle == serviceTitle &&
        other.description == description &&
        other.proposedPrice == proposedPrice &&
        other.scheduledDateTime == scheduledDateTime &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      customerName,
      customerAvatar,
      customerLocation,
      serviceTitle,
      description,
      proposedPrice,
      scheduledDateTime,
      createdAt,
      status,
    );
  }
}
