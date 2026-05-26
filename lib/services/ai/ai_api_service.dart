import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'models/ai_recommendation.dart';
import 'models/ai_match_score.dart';
import 'models/ai_prediction.dart';
import 'models/ai_trend.dart';
import 'models/ai_health.dart';
import 'models/ai_metrics.dart';
import 'models/ai_safety_sop.dart';

/// Provider for AIApiService
final aiApiServiceProvider = Provider<AIApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIApiService(apiClient);
});

/// Service class for AI-related API endpoints
/// 
/// Provides methods for:
/// - Personalized service recommendations
/// - Provider-customer matching scores
/// - Predictive analytics and trends
/// - AI system health monitoring
/// - Safety SOP generation
class AIApiService {
  final ApiClient _apiClient;

  AIApiService(this._apiClient);

  // ==================== AI Recommendations ====================

  /// Get personalized service recommendations for the authenticated customer
  /// 
  /// [limit] - Number of recommendations to return (1-20, default: 5)
  /// [refresh] - Force regenerate recommendations (default: false)
  /// 
  /// Returns list of [AIRecommendation] objects
  /// 
  /// Throws [ApiException] on error
  Future<List<AIRecommendation>> getRecommendations({
    int limit = 5,
    bool refresh = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/v1/customer/ai/recommendations',
        params: {
          'limit': limit,
          'refresh': refresh,
        },
      );

      if (response.data['success'] == true) {
        final recommendations = response.data['data']['recommendations'] as List;
        return recommendations
            .map((json) => AIRecommendation.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get recommendations',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get recommendations: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Record user feedback on a recommendation
  /// 
  /// [recommendationId] - UUID of the recommendation
  /// [action] - User action: 'clicked' or 'booked'
  /// 
  /// Throws [ApiException] on error
  Future<void> recordRecommendationFeedback({
    required String recommendationId,
    required String action,
  }) async {
    try {
      final response = await _apiClient.post(
        '/v1/customer/ai/recommendations/feedback',
        data: {
          'recommendation_id': recommendationId,
          'action': action,
        },
      );

      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to record feedback',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to record feedback: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Get recommendation statistics for the authenticated user
  /// 
  /// Returns a map with statistics:
  /// - total_recommendations
  /// - active_recommendations
  /// - clicked_recommendations
  /// - booked_recommendations
  /// - click_rate
  /// - conversion_rate
  /// 
  /// Throws [ApiException] on error
  Future<Map<String, dynamic>> getRecommendationStats() async {
    try {
      final response = await _apiClient.get(
        '/v1/customer/ai/recommendations/stats',
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get stats',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get recommendation stats: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  // ==================== AI Matching ====================

  /// Get match score for a specific booking (Provider view)
  /// 
  /// [bookingId] - UUID of the booking
  /// 
  /// Returns [AIMatchScore] object with score and factors
  /// 
  /// Throws [ApiException] on error
  Future<AIMatchScore> getMatchScore(String bookingId) async {
    try {
      final response = await _apiClient.get(
        '/v1/provider/ai/bookings/$bookingId/match-score',
      );

      if (response.data['success'] == true) {
        return AIMatchScore.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get match score',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get match score: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Find matching providers for a service request (Customer view)
  /// 
  /// [serviceId] - UUID of the service
  /// [location] - Optional service location
  /// [limit] - Number of providers to return (1-20, default: 10)
  /// 
  /// Returns list of providers with match scores
  /// 
  /// Throws [ApiException] on error
  Future<List<Map<String, dynamic>>> findMatchingProviders({
    required String serviceId,
    String? location,
    int limit = 10,
  }) async {
    try {
      final params = <String, dynamic>{
        'service_id': serviceId,
        'limit': limit,
      };
      if (location != null) {
        params['location'] = location;
      }

      final response = await _apiClient.get(
        '/v1/customer/ai/providers/matches',
        params: params,
      );

      if (response.data['success'] == true) {
        final providers = response.data['data']['providers'] as List;
        return providers.cast<Map<String, dynamic>>();
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to find matching providers',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to find matching providers: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Get all match scores for a booking (Admin view)
  /// 
  /// [bookingId] - UUID of the booking
  /// 
  /// Returns list of [AIMatchScore] objects for all providers
  /// 
  /// Throws [ApiException] on error
  Future<List<AIMatchScore>> getAllMatchScores(String bookingId) async {
    try {
      final response = await _apiClient.get(
        '/v1/admin/ai/bookings/$bookingId/match-scores',
      );

      if (response.data['success'] == true) {
        final scores = response.data['data']['match_scores'] as List;
        return scores.map((json) => AIMatchScore.fromJson(json)).toList();
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get match scores',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get all match scores: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  // ==================== AI Analytics ====================

  /// Get AI-generated predictions for various metrics
  /// 
  /// [type] - Prediction type: 'booking_volume', 'revenue_forecast', 'churn_risk', 'trend', or 'all'
  /// [days] - Forecast period (1-90 days, default: 7)
  /// [refresh] - Force refresh predictions (default: false)
  /// 
  /// Returns [AIPrediction] object with predictions and insights
  /// 
  /// Throws [ApiException] on error
  Future<AIPrediction> getPredictions({
    String type = 'all',
    int days = 7,
    bool refresh = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/v1/admin/ai/analytics/predictions',
        params: {
          'type': type,
          'days': days,
          'refresh': refresh,
        },
      );

      if (response.data['success'] == true) {
        return AIPrediction.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get predictions',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get predictions: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Get AI-identified trends and patterns
  /// 
  /// [refresh] - Force refresh trends (default: false)
  /// 
  /// Returns [AITrend] object with trending/declining services and insights
  /// 
  /// Throws [ApiException] on error
  Future<AITrend> getTrends({bool refresh = false}) async {
    try {
      final response = await _apiClient.get(
        '/v1/admin/ai/analytics/trends',
        params: {'refresh': refresh},
      );

      if (response.data['success'] == true) {
        return AITrend.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get trends',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get trends: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Get AI-generated business insights and recommendations
  /// 
  /// Returns map with insights by category and summary
  /// 
  /// Throws [ApiException] on error
  Future<Map<String, dynamic>> getInsights() async {
    try {
      final response = await _apiClient.get(
        '/v1/admin/ai/analytics/insights',
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get insights',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get insights: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Get historical predictions for trend analysis
  /// 
  /// [type] - Filter by prediction type (optional)
  /// [limit] - Number of records (1-100, default: 20)
  /// 
  /// Returns list of historical predictions
  /// 
  /// Throws [ApiException] on error
  Future<List<Map<String, dynamic>>> getPredictionHistory({
    String? type,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (type != null) {
        params['type'] = type;
      }

      final response = await _apiClient.get(
        '/v1/admin/ai/analytics/history',
        params: params,
      );

      if (response.data['success'] == true) {
        final predictions = response.data['data']['predictions'] as List;
        return predictions.cast<Map<String, dynamic>>();
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get history',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get prediction history: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  // ==================== AI Health & Monitoring ====================

  /// Check the health status of all AI system components
  /// 
  /// Returns [AIHealth] object with status of all components
  /// 
  /// Throws [ApiException] on error
  Future<AIHealth> getHealth() async {
    try {
      final response = await _apiClient.get('/v1/admin/ai/health');

      if (response.data['success'] == true || response.data['success'] == false) {
        // Health endpoint can return success: false when unhealthy
        return AIHealth.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: 'Failed to get health status',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get health status: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Get performance metrics for the AI system
  /// 
  /// [period] - Time period: '1h', '24h', '7d', '30d' (default: '24h')
  /// 
  /// Returns [AIMetrics] object with performance data
  /// 
  /// Throws [ApiException] on error
  Future<AIMetrics> getMetrics({String period = '24h'}) async {
    try {
      final response = await _apiClient.get(
        '/v1/admin/ai/metrics',
        params: {'period': period},
      );

      if (response.data['success'] == true) {
        return AIMetrics.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get metrics',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get metrics: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  /// Get list of available AI models in Ollama
  /// 
  /// Returns map with current model and list of available models
  /// 
  /// Throws [ApiException] on error
  Future<Map<String, dynamic>> getAvailableModels() async {
    try {
      final response = await _apiClient.get('/v1/admin/ai/models');

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to get models',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get available models: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }

  // ==================== AI Safety SOP ====================

  /// Generate AI-powered safety standard operating procedures for a job type
  /// 
  /// [jobType] - Job type description (2-120 characters)
  /// 
  /// Returns [AISafetySOP] object with generated safety procedures
  /// 
  /// Throws [ApiException] on error
  Future<AISafetySOP> generateSafetySOP({required String jobType}) async {
    try {
      final response = await _apiClient.post(
        '/v1/ai/safety-sop',
        data: {'job_type': jobType},
      );

      if (response.data['success'] == true) {
        return AISafetySOP.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to generate safety SOP',
          type: ApiExceptionType.server,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to generate safety SOP: ${e.toString()}',
        type: ApiExceptionType.unknown,
        statusCode: null,
      );
    }
  }
}
