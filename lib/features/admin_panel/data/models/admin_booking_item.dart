class AdminBookingNote {
  final String note;
  final String? adminId;
  final DateTime? createdAt;

  const AdminBookingNote({
    required this.note,
    this.adminId,
    this.createdAt,
  });

  factory AdminBookingNote.fromJson(Map<String, dynamic> json) =>
      AdminBookingNote(
        note: json['note'] as String? ?? '',
        adminId: json['admin_id']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class AdminBookingItem {
  final String id;
  final String? customerId;
  final String? providerId;
  final String? serviceId;
  final String? customerName;
  final String? customerEmail;
  final String? providerName;
  final String? serviceName;
  final DateTime? scheduledAt;
  final String status;
  final double totalPrice;
  final String currency;
  final String? cancellationReason;
  final List<AdminBookingNote> adminNotes;
  final DateTime? createdAt;

  const AdminBookingItem({
    required this.id,
    this.customerId,
    this.providerId,
    this.serviceId,
    this.customerName,
    this.customerEmail,
    this.providerName,
    this.serviceName,
    this.scheduledAt,
    required this.status,
    required this.totalPrice,
    this.currency = 'NPR',
    this.cancellationReason,
    this.adminNotes = const [],
    this.createdAt,
  });

  factory AdminBookingItem.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['admin_notes'];
    final notes = notesRaw is List
        ? notesRaw
            .map((e) => AdminBookingNote.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList()
        : <AdminBookingNote>[];

    return AdminBookingItem(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      providerId: json['provider_id']?.toString(),
      serviceId: json['service_id']?.toString(),
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      providerName: json['provider_name'] as String?,
      serviceName: json['service_name'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NPR',
      cancellationReason: json['cancellation_reason'] as String?,
      adminNotes: notes,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get canCancel => isPending || isConfirmed;
}
