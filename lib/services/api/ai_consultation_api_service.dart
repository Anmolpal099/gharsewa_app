import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/platform_image.dart';
import '../../core/services/image_service.dart';
import '../../data/models/ai_consultation_models.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Provider for AI Consultation API Service
final aiConsultationApiServiceProvider = Provider<AIConsultationApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIConsultationApiService(apiClient);
});

/// Service for AI Consultation API operations
/// 
/// Handles all API communication related to AI Visual Assistant consultations:
/// - Creating new consultations with image and markers
/// - Fetching consultation history with pagination
/// - Getting consultation details
/// - Deleting consultations
class AIConsultationApiService {
  final ApiClient _apiClient;
  final ImageService _imageService = ImageService();

  AIConsultationApiService(this._apiClient);

  /// Creates a new AI consultation
  /// 
  /// Parameters:
  /// - [image]: The platform-aware image to analyze
  /// - [markers]: List of markers placed on the image
  /// 
  /// Returns: The created consultation with AI analysis results
  /// 
  /// Throws: [ApiException] on error
  Future<AIConsultationModel> createConsultation({
    required PlatformImage image,
    required List<DefectMarkerModel> markers,
  }) async {
    try {
      // Convert platform image to base64
      final base64Image = await _imageService.imageToBase64(image);

      // Prepare request data
      final requestData = {
        'image': base64Image,
        'markers': markers.map((m) => m.toJson()).toList(),
      };

      // Make API request
      final response = await _apiClient.post(
        '/v1/customer/ai/consultations',
        data: requestData,
      );

      // Parse response
      if (response.data['success'] == true) {
        final consultationData = response.data['data']['consultation'];
        return AIConsultationModel.fromJson(consultationData);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to create consultation',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create consultation: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Gets consultation history with pagination
  /// 
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [perPage]: Items per page (default: 20, max: 50)
  /// - [serviceType]: Optional filter by service type
  /// 
  /// Returns: Paginated list of consultations
  /// 
  /// Throws: [ApiException] on error
  Future<ConsultationHistoryResponse> getConsultationHistory({
    int page = 1,
    int perPage = 20,
    String? serviceType,
  }) async {
    try {
      // Prepare query parameters
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (serviceType != null && serviceType.isNotEmpty) {
        params['service_type'] = serviceType;
      }

      // Make API request
      final response = await _apiClient.get(
        '/v1/customer/ai/consultations',
        params: params,
      );

      // Parse response
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final consultationsData = data['consultations'] as List;
        final consultations = consultationsData
            .map((json) => AIConsultationModel.fromJson(json))
            .toList();

        return ConsultationHistoryResponse(
          consultations: consultations,
          currentPage: data['current_page'] as int,
          lastPage: data['last_page'] as int,
          perPage: data['per_page'] as int,
          total: data['total'] as int,
        );
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to fetch consultation history',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch consultation history: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Gets a specific consultation by ID
  /// 
  /// Parameters:
  /// - [id]: Consultation ID
  /// 
  /// Returns: The consultation details
  /// 
  /// Throws: [ApiException] on error
  Future<AIConsultationModel> getConsultationById(String id) async {
    try {
      // Make API request
      final response = await _apiClient.get(
        '/v1/customer/ai/consultations/$id',
      );

      // Parse response
      if (response.data['success'] == true) {
        final consultationData = response.data['data']['consultation'];
        return AIConsultationModel.fromJson(consultationData);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to fetch consultation',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch consultation: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Deletes a consultation
  /// 
  /// Parameters:
  /// - [id]: Consultation ID
  /// 
  /// Returns: Success message
  /// 
  /// Throws: [ApiException] on error
  Future<String> deleteConsultation(String id) async {
    try {
      // Make API request
      final response = await _apiClient.delete(
        '/v1/customer/ai/consultations/$id',
      );

      // Parse response
      if (response.data['success'] == true) {
        return response.data['message'] ?? 'Consultation deleted successfully';
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to delete consultation',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete consultation: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }
}

/// Response model for paginated consultation history
class ConsultationHistoryResponse {
  final List<AIConsultationModel> consultations;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const ConsultationHistoryResponse({
    required this.consultations,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  /// Checks if there are more pages available
  bool get hasNextPage => currentPage < lastPage;

  /// Checks if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Checks if this is the last page
  bool get isLastPage => currentPage == lastPage;

  /// Gets the next page number (or null if on last page)
  int? get nextPage => hasNextPage ? currentPage + 1 : null;

  /// Gets the previous page number (or null if on first page)
  int? get previousPage => currentPage > 1 ? currentPage - 1 : null;

  /// Checks if the list is empty
  bool get isEmpty => consultations.isEmpty;

  /// Checks if the list is not empty
  bool get isNotEmpty => consultations.isNotEmpty;

  @override
  String toString() =>
      'ConsultationHistoryResponse(total: $total, page: $currentPage/$lastPage, items: ${consultations.length})';
}
