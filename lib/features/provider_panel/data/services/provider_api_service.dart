import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../services/api/api_client.dart';
import '../models/models.dart';

final providerApiServiceProvider = Provider<ProviderApiService>((ref) {
  return ProviderApiService(ref.watch(apiClientProvider));
});

/// Provider API integration aligned with Laravel `/api/v1/provider/*` routes.
class ProviderApiService {
  final ApiClient _apiClient;

  ProviderApiService(this._apiClient);

  Future<ProviderProfile> getProviderProfile() async {
    final response = await _apiClient.get('/v1/provider/profile');
    if (response.data['success'] == true) {
      return _profileFromApi(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch provider profile');
  }

  Future<ProviderProfile> updateProviderProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put('/v1/provider/profile', data: data);
    if (response.data['success'] == true) {
      return _profileFromApi(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data['message'] ?? 'Failed to update provider profile');
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.get(ApiConstants.providerDashboard);
    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch dashboard');
  }

  Future<EarningsData> getEarnings({
    DateTime? startDate,
    DateTime? endDate,
    EarningsViewType viewType = EarningsViewType.daily,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 7));
    final end = endDate ?? now;
    final groupBy = viewType == EarningsViewType.weekly ? 'week' : 'day';

    final response = await _apiClient.get(
      '/v1/provider/earnings',
      params: {
        'date_from': _formatDate(start),
        'date_to': _formatDate(end),
        'group_by': groupBy,
      },
    );

    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to fetch earnings');
    }

    return _earningsFromApi(
      response.data['data'] as Map<String, dynamic>,
      viewType: viewType,
      dateRange: DateRange(startDate: start, endDate: end),
    );
  }

  Future<List<BookingRequest>> getPendingRequests() async {
    final response = await _apiClient.get('/v1/provider/bookings/pending');
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to fetch pending requests');
    }

    final items = response.data['data'] as List<dynamic>;
    return items
        .map((e) => _bookingRequestFromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptRequest(String requestId) async {
    final response = await _apiClient.post('/v1/provider/bookings/$requestId/accept');
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to accept request');
    }
  }

  Future<void> declineRequest(String requestId, String reason) async {
    final response = await _apiClient.post(
      '/v1/provider/bookings/$requestId/reject',
      data: {'rejection_reason': reason},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to decline request');
    }
  }

  Future<PerformanceMetrics> getProviderMetrics(Map<String, dynamic> dashboard) {
    return Future.value(_metricsFromDashboard(dashboard));
  }

  /// Local AI SOP generator (no backend endpoint yet).
  Future<SafetySOP> generateSafetySOP(String jobType) async {
    await Future.delayed(const Duration(milliseconds: 800));
    const uuid = Uuid();
    final content = '''
# Safety SOP: $jobType

## Hazards
- Slip/trip hazards in work area
- Electrical exposure (if applicable)
- Chemical or dust exposure

## Required PPE
- Safety gloves
- Safety goggles
- Closed-toe footwear

## Procedures
1. Inspect work area before starting
2. Confirm tools and equipment are in safe condition
3. Follow manufacturer instructions for all products
4. Keep walkways clear during service

## Emergency Protocols
- Stop work immediately if unsafe conditions appear
- Call local emergency services (100/101/102) for serious injury
- Notify the customer and platform support
''';

    return SafetySOP(
      id: uuid.v4(),
      jobType: jobType.trim(),
      content: content,
      hazards: const [
        'Slip/trip hazards',
        'Electrical exposure',
        'Chemical or dust exposure',
      ],
      requiredPPE: const ['Safety gloves', 'Safety goggles', 'Closed-toe footwear'],
      procedures: const [
        'Inspect work area before starting',
        'Confirm tools are safe',
        'Follow manufacturer instructions',
        'Keep walkways clear',
      ],
      emergencyProtocols: const [
        'Stop work if unsafe',
        'Call emergency services for injury',
        'Notify customer and support',
      ],
      generatedAt: DateTime.now(),
      isSaved: false,
    );
  }

  ProviderProfile _profileFromApi(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final skills = (metadata['skills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final certsJson = metadata['certifications'] as List<dynamic>? ?? [];
    final certifications = certsJson
        .map((e) => Certification.fromJson(e as Map<String, dynamic>))
        .toList();

    final now = DateTime.now();
    return ProviderProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Provider',
      email: json['email'] as String? ?? '',
      photoUrl: json['profile_image_url'] as String?,
      bio: metadata['business_description'] as String? ??
          metadata['bio'] as String?,
      location: metadata['address'] as String? ?? 'Not set',
      professionalCategory:
          metadata['business_name'] as String? ?? 'Home Services',
      isVerified: json['email_verified_at'] != null,
      skills: skills,
      certifications: certifications,
      createdAt: now,
      updatedAt: now,
    );
  }

  EarningsData _earningsFromApi(
    Map<String, dynamic> json, {
    required EarningsViewType viewType,
    required DateRange dateRange,
  }) {
    final breakdown = json['breakdown'] as List<dynamic>? ?? [];
    final total = (json['total_earnings'] as num?)?.toDouble() ?? 0;

    final points = breakdown.map((item) {
      final map = item as Map<String, dynamic>;
      final period = map['period']?.toString() ?? '';
      final earnings = (map['earnings'] as num?)?.toDouble() ?? 0;
      final dateStr = map['date'] as String? ?? period;
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        date = DateTime.now();
      }
      return EarningsDataPoint(
        date: date,
        amount: earnings,
        label: _formatPeriodLabel(date, viewType),
      );
    }).toList();

    return EarningsData(
      totalEarnings: total,
      previousPeriodEarnings: 0,
      dataPoints: points,
      dateRange: dateRange,
      viewType: viewType,
    );
  }

  BookingRequest _bookingRequestFromApi(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    final scheduled = json['scheduled_at'] != null
        ? DateTime.parse(json['scheduled_at'] as String)
        : DateTime.now();
    final created = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now();

    return BookingRequest(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? '',
      customerName: customer?['name'] as String? ?? 'Customer',
      customerAvatar: customer?['profile_image_url'] as String?,
      customerLocation: customer?['metadata']?['address'] as String? ?? 'Nearby',
      serviceTitle: service?['title'] as String? ?? 'Service request',
      description: service?['description'] as String? ?? '',
      proposedPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      scheduledDateTime: scheduled,
      createdAt: created,
      status: BookingRequestStatus.pending,
    );
  }

  PerformanceMetrics _metricsFromDashboard(Map<String, dynamic> dashboard) {
    final rating = (dashboard['average_rating'] as num?)?.toDouble() ?? 0;
    final completed = dashboard['total_bookings'] as int? ?? 0;
    return PerformanceMetrics(
      rating: rating,
      totalReviews: 0,
      jobsCompleted: completed,
      averageResponseTime: const Duration(minutes: 20),
      isTopPerformer: rating >= 4.5,
      percentile: rating >= 4.5 ? 90 : 50,
    );
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _formatPeriodLabel(DateTime date, EarningsViewType type) {
    if (type == EarningsViewType.weekly) {
      return 'W${((date.day - 1) ~/ 7) + 1}';
    }
    return DateFormat('E').format(date);
  }
}
