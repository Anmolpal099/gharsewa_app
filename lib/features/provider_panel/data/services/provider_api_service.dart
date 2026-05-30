import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/json_helpers.dart';
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
      return _profileFromApi(requireJsonMap(response.data['data'], field: 'data'));
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch provider profile');
  }

  Future<ProviderProfile> updateProviderProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put('/v1/provider/profile', data: data);
    if (response.data['success'] == true) {
      return _profileFromApi(requireJsonMap(response.data['data'], field: 'data'));
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

  Future<void> sendCounterOffer(
    String requestId, {
    required double counterPrice,
    String? message,
  }) async {
    final response = await _apiClient.post(
      '/v1/provider/bookings/$requestId/counter',
      data: {
        'counter_price': counterPrice,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );

    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to send counter-offer');
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

  /// POST /api/v1/ai/safety-sop
  Future<SafetySOP> generateSafetySOP(String jobType) async {
    final response = await _apiClient.post(
      '/v1/ai/safety-sop',
      data: {'job_type': jobType.trim()},
    );

    if (response.data['success'] == true) {
      return SafetySOP.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception(response.data['message'] ?? 'Failed to generate safety SOP');
  }

  /// GET /api/v1/provider/metrics
  Future<PerformanceMetrics> getProviderMetricsFromApi() async {
    final response = await _apiClient.get('/v1/provider/metrics');
    if (response.data['success'] == true) {
      return PerformanceMetrics.fromJson(
        requireJsonMap(response.data['data'], field: 'data'),
      );
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch metrics');
  }

  /// GET /api/v1/provider/certifications/{id}
  /// Fetch a specific certification with its document data
  Future<Certification> getCertification(String certificationId) async {
    final response = await _apiClient.get('/v1/provider/certifications/$certificationId');
    if (response.data['success'] == true) {
      return Certification.fromJson(
        requireJsonMap(response.data['data'], field: 'data'),
      );
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch certification');
  }

  ProviderProfile _profileFromApi(Map<String, dynamic> json) {
    final metadata = asJsonMap(json['metadata']);
    final skills = (metadata['skills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final certsJson = metadata['certifications'];
    final certifications = certsJson is List<dynamic>
        ? certsJson
            .whereType<Map>()
            .map((e) => Certification.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Certification>[];

    final now = DateTime.now();
    return ProviderProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Provider',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      servicesCount: json['services_count'] as int? ?? 0,
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

    final metadata = json['metadata'] as Map<String, dynamic>?;
    final hasCounter = metadata?['counter_offer'] != null;
    final status = _mapBookingStatus(json['status'] as String?, hasCounter);

    var proposedPrice = (json['total_price'] as num?)?.toDouble() ?? 0;
    if (hasCounter) {
      final offer = metadata!['counter_offer'] as Map<String, dynamic>;
      proposedPrice =
          (offer['counter_price'] as num?)?.toDouble() ?? proposedPrice;
    }

    return BookingRequest(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? '',
      customerName: customer?['name'] as String? ?? 'Customer',
      customerAvatar: customer?['profile_image_url'] as String?,
      customerLocation: customer?['metadata']?['address'] as String? ?? 'Nearby',
      serviceTitle: service?['title'] as String? ?? 'Service request',
      description: service?['description'] as String? ?? '',
      proposedPrice: proposedPrice,
      scheduledDateTime: scheduled,
      createdAt: created,
      status: status,
    );
  }

  BookingRequestStatus _mapBookingStatus(String? status, bool hasCounter) {
    if (hasCounter) return BookingRequestStatus.counterOffered;
    switch (status) {
      case 'confirmed':
        return BookingRequestStatus.accepted;
      case 'rejected':
      case 'cancelled':
        return BookingRequestStatus.declined;
      case 'pending':
      default:
        return BookingRequestStatus.pending;
    }
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
