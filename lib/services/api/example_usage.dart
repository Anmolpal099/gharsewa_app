/// Example usage of the API Client
/// 
/// This file demonstrates how to use the ApiClient service
/// in various scenarios with proper error handling.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Example service that uses the API client
class ProviderProfileService {
  final ApiClient _apiClient;

  ProviderProfileService(this._apiClient);

  /// Fetch provider profile with error handling
  Future<Map<String, dynamic>> fetchProfile(String providerId) async {
    try {
      final response = await _apiClient.get('/v1/provider/profile/$providerId');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to fetch profile',
          type: ApiExceptionType.unknown,
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      // Log error for debugging
      print('Error fetching profile: ${e.toString()}');
      
      // Handle specific error types
      switch (e.type) {
        case ApiExceptionType.network:
          // User is offline - show offline message
          print('User is offline: ${e.message}');
          break;
        case ApiExceptionType.timeout:
          // Request timed out - suggest retry
          print('Request timed out: ${e.message}');
          break;
        case ApiExceptionType.server:
          // Server error - show generic error
          print('Server error: ${e.message}');
          break;
        case ApiExceptionType.client:
          // Client error - show specific error
          print('Client error: ${e.message}');
          break;
        default:
          print('Unknown error: ${e.message}');
      }
      
      rethrow;
    }
  }

  /// Update provider profile with validation
  Future<void> updateProfile(String providerId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '/v1/provider/profile/$providerId',
        data: data,
      );
      
      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to update profile',
          type: ApiExceptionType.unknown,
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('Error updating profile: ${e.toString()}');
      rethrow;
    }
  }

  /// Add skill to provider profile
  Future<void> addSkill(String providerId, String skill) async {
    try {
      final response = await _apiClient.post(
        '/v1/provider/skills',
        data: {
          'provider_id': providerId,
          'skill': skill,
        },
      );
      
      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to add skill',
          type: ApiExceptionType.unknown,
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('Error adding skill: ${e.toString()}');
      rethrow;
    }
  }

  /// Remove skill from provider profile
  Future<void> removeSkill(String skillId) async {
    try {
      final response = await _apiClient.delete('/v1/provider/skills/$skillId');
      
      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to remove skill',
          type: ApiExceptionType.unknown,
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('Error removing skill: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch earnings data with date range
  Future<Map<String, dynamic>> fetchEarnings(
    String providerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        '/v1/provider/earnings',
        params: {
          'provider_id': providerId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to fetch earnings',
          type: ApiExceptionType.unknown,
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('Error fetching earnings: ${e.toString()}');
      rethrow;
    }
  }
}

/// Riverpod provider for the service
final providerProfileServiceProvider = Provider<ProviderProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProviderProfileService(apiClient);
});

/// Example UI usage with error handling
class ProfileViewModel {
  final ProviderProfileService _service;
  
  ProfileViewModel(this._service);

  /// Load profile with user-friendly error handling
  Future<Map<String, dynamic>?> loadProfile(String providerId) async {
    try {
      return await _service.fetchProfile(providerId);
    } on ApiException catch (e) {
      // Return null and let UI show error message
      _showErrorToUser(e);
      return null;
    }
  }

  /// Show error message to user based on error type
  void _showErrorToUser(ApiException e) {
    // In a real app, this would show a snackbar or dialog
    String userMessage;
    bool showRetry = false;

    switch (e.type) {
      case ApiExceptionType.network:
        userMessage = e.message;
        showRetry = true;
        break;
      case ApiExceptionType.timeout:
        userMessage = e.message;
        showRetry = true;
        break;
      case ApiExceptionType.server:
        userMessage = e.message;
        showRetry = false;
        break;
      case ApiExceptionType.client:
        userMessage = e.message;
        showRetry = false;
        break;
      default:
        userMessage = e.message;
        showRetry = false;
    }

    print('Show to user: $userMessage (retry: $showRetry)');
    // In real app: showDialog(message: userMessage, showRetry: showRetry);
  }
}
