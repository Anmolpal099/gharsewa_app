import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api/api_client.dart';
import '../models/models.dart';

/// Provider for the ProviderApiService
final providerApiServiceProvider = Provider<ProviderApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProviderApiService(apiClient);
});

/// Service layer for provider-specific API endpoints
/// 
/// This service wraps the ApiClient with provider-specific endpoint methods
/// and returns properly typed responses using the data models.
class ProviderApiService {
  final ApiClient _apiClient;

  ProviderApiService(this._apiClient);

  /// GET /api/provider/profile/:id
  /// 
  /// Fetches provider profile data including skills and certifications
  /// 
  /// **Validates: Requirements 25.1**
  Future<ProviderProfile> getProviderProfile(String providerId) async {
    final response = await _apiClient.get('/api/provider/profile/$providerId');
    
    if (response.data['success'] == true) {
      return ProviderProfile.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch provider profile');
    }
  }

  /// PUT /api/provider/profile/:id
  /// 
  /// Updates provider profile information
  /// 
  /// **Validates: Requirements 25.2**
  Future<ProviderProfile> updateProviderProfile(
    String providerId,
    Map<String, dynamic> profileData,
  ) async {
    final response = await _apiClient.put(
      '/api/provider/profile/$providerId',
      data: profileData,
    );
    
    if (response.data['success'] == true) {
      return ProviderProfile.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to update provider profile');
    }
  }

  /// POST /api/provider/skills
  /// 
  /// Adds a skill to a provider profile
  /// 
  /// **Validates: Requirements 25.3**
  Future<List<String>> addSkill(String providerId, String skill) async {
    final response = await _apiClient.post(
      '/api/provider/skills',
      data: {
        'provider_id': providerId,
        'skill': skill,
      },
    );
    
    if (response.data['success'] == true) {
      return (response.data['data']['skills'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to add skill');
    }
  }

  /// DELETE /api/provider/skills/:id
  /// 
  /// Removes a skill from a provider profile
  /// 
  /// **Validates: Requirements 25.4**
  Future<List<String>> removeSkill(String providerId, String skillId) async {
    final response = await _apiClient.delete('/api/provider/skills/$skillId');
    
    if (response.data['success'] == true) {
      return (response.data['data']['skills'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to remove skill');
    }
  }

  /// POST /api/provider/certifications
  /// 
  /// Uploads a certification document with multipart/form-data support
  /// 
  /// **Validates: Requirements 25.5**
  Future<Certification> uploadCertification(
    String providerId,
    String certificationName,
    String documentUrl,
  ) async {
    final response = await _apiClient.post(
      '/api/provider/certifications',
      data: {
        'provider_id': providerId,
        'name': certificationName,
        'document_url': documentUrl,
      },
    );
    
    if (response.data['success'] == true) {
      return Certification.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to upload certification');
    }
  }

  /// GET /api/provider/earnings
  /// 
  /// Fetches earnings data with date range parameters
  /// 
  /// **Validates: Requirements 25.6**
  Future<EarningsData> getEarnings(
    String providerId, {
    required DateTime startDate,
    required DateTime endDate,
    required EarningsViewType viewType,
  }) async {
    final response = await _apiClient.get(
      '/api/provider/earnings',
      params: {
        'provider_id': providerId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'view_type': viewType.name,
      },
    );
    
    if (response.data['success'] == true) {
      return EarningsData.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch earnings');
    }
  }

  /// GET /api/provider/requests/pending
  /// 
  /// Fetches pending booking requests
  /// 
  /// **Validates: Requirements 25.7**
  Future<List<BookingRequest>> getPendingRequests(String providerId) async {
    final response = await _apiClient.get(
      '/api/provider/requests/pending',
      params: {'provider_id': providerId},
    );
    
    if (response.data['success'] == true) {
      return (response.data['data'] as List<dynamic>)
          .map((e) => BookingRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch pending requests');
    }
  }

  /// POST /api/provider/requests/:id/respond
  /// 
  /// Responds to a booking request (accept, decline, counter)
  /// 
  /// **Validates: Requirements 25.8**
  Future<BookingRequest> respondToRequest(
    String requestId, {
    required String action, // 'accept', 'decline', 'counter'
    String? declineReason,
    double? counterPrice,
    String? counterMessage,
  }) async {
    final data = <String, dynamic>{
      'action': action,
    };
    
    if (declineReason != null) {
      data['decline_reason'] = declineReason;
    }
    
    if (counterPrice != null) {
      data['counter_price'] = counterPrice;
    }
    
    if (counterMessage != null) {
      data['counter_message'] = counterMessage;
    }
    
    final response = await _apiClient.post(
      '/api/provider/requests/$requestId/respond',
      data: data,
    );
    
    if (response.data['success'] == true) {
      return BookingRequest.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to respond to request');
    }
  }

  /// POST /api/ai/safety-sop
  /// 
  /// Generates AI safety SOP with job type parameter
  /// 
  /// **Validates: Requirements 25.9**
  Future<SafetySOP> generateSafetySOP(String jobType) async {
    final response = await _apiClient.post(
      '/api/ai/safety-sop',
      data: {'job_type': jobType},
    );
    
    if (response.data['success'] == true) {
      return SafetySOP.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to generate safety SOP');
    }
  }

  /// GET /api/provider/metrics
  /// 
  /// Fetches provider performance metrics
  /// 
  /// **Validates: Requirements 25.10**
  Future<PerformanceMetrics> getProviderMetrics(String providerId) async {
    final response = await _apiClient.get(
      '/api/provider/metrics',
      params: {'provider_id': providerId},
    );
    
    if (response.data['success'] == true) {
      return PerformanceMetrics.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch provider metrics');
    }
  }
}
