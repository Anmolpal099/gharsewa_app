# AI API Service

This directory contains the Flutter service layer for interacting with the GharSewa AI Integration backend.

## Overview

The AI API Service provides methods to interact with all 14 AI endpoints in the backend, including:

- **Personalized Service Recommendations**: AI-driven service suggestions for customers
- **Provider-Customer Matching**: Intelligent scoring to match providers with bookings
- **Predictive Analytics**: Forecasting and trend analysis for admin dashboard
- **AI System Health Monitoring**: Health checks and performance metrics
- **Safety SOP Generation**: AI-generated safety procedures for job types

## Architecture

```
lib/services/ai/
├── ai_api_service.dart          # Main service class with all API methods
├── models/                       # Data models for AI responses
│   ├── ai_recommendation.dart    # Recommendation models
│   ├── ai_match_score.dart       # Match score models
│   ├── ai_prediction.dart        # Prediction models
│   ├── ai_trend.dart             # Trend analysis models
│   ├── ai_health.dart            # Health status models
│   ├── ai_metrics.dart           # Performance metrics models
│   ├── ai_safety_sop.dart        # Safety SOP models
│   └── models.dart               # Barrel file for all models
└── README.md                     # This file
```

## Usage

### 1. Get the Service Instance

The service is provided via Riverpod:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/services/ai/ai_api_service.dart';

// In a ConsumerWidget or ConsumerStatefulWidget
final aiService = ref.watch(aiApiServiceProvider);
```

### 2. Customer Recommendations

```dart
// Get personalized recommendations
try {
  final recommendations = await aiService.getRecommendations(
    limit: 5,
    refresh: false,
  );
  
  // Display recommendations
  for (final rec in recommendations) {
    print('${rec.service.name}: ${rec.confidenceScore}%');
    print('Reason: ${rec.reasoning}');
  }
} on ApiException catch (e) {
  print('Error: ${e.message}');
}

// Record user feedback
await aiService.recordRecommendationFeedback(
  recommendationId: 'uuid',
  action: 'clicked', // or 'booked'
);

// Get recommendation statistics
final stats = await aiService.getRecommendationStats();
print('Click rate: ${stats['click_rate']}%');
```

### 3. Provider Matching

```dart
// Get match score for a booking (Provider view)
try {
  final matchScore = await aiService.getMatchScore('booking-uuid');
  
  print('Match Score: ${matchScore.matchScore}%');
  print('Skill Alignment: ${matchScore.factors.skillAlignment}');
  print('Location Proximity: ${matchScore.factors.locationProximity}');
  print('Reasoning: ${matchScore.reasoning}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}

// Find matching providers (Customer view)
final providers = await aiService.findMatchingProviders(
  serviceId: 'service-uuid',
  location: 'Kathmandu',
  limit: 5,
);

for (final provider in providers) {
  print('${provider['name']}: ${provider['match_score']}%');
}
```

### 4. Admin Analytics

```dart
// Get predictions
final prediction = await aiService.getPredictions(
  type: 'booking_volume', // or 'revenue_forecast', 'churn_risk', 'trend', 'all'
  days: 7,
  refresh: false,
);

if (prediction.bookingVolume != null) {
  print('Insights: ${prediction.bookingVolume!.insights}');
  print('Confidence: ${prediction.bookingVolume!.confidenceScore}%');
  
  for (final point in prediction.bookingVolume!.predictions) {
    print('${point.date}: ${point.value} bookings (${point.confidence}% confidence)');
  }
}

// Get trends
final trends = await aiService.getTrends(refresh: false);

print('Trending Services:');
for (final service in trends.trendingServices) {
  print('${service.serviceName}: +${service.growthRate}%');
}

print('Declining Services:');
for (final service in trends.decliningServices) {
  print('${service.serviceName}: ${service.declineRate}%');
}

// Get actionable insights
final insights = await aiService.getInsights();
print('Key Insights: ${insights['summary']['key_insights']}');

// Get prediction history
final history = await aiService.getPredictionHistory(
  type: 'booking_volume',
  limit: 10,
);
```

### 5. AI Health Monitoring

```dart
// Check AI system health
final health = await aiService.getHealth();

print('Status: ${health.status}');
print('Ollama: ${health.components.ollama.status}');
print('Redis: ${health.components.redis.status}');
print('Model: ${health.components.model.modelName}');

if (!health.isHealthy) {
  print('System is unhealthy!');
  if (!health.components.ollama.isHealthy) {
    print('Ollama error: ${health.components.ollama.error}');
  }
}

// Get performance metrics
final metrics = await aiService.getMetrics(period: '24h');

print('Total Requests: ${metrics.requests.total}');
print('Success Rate: ${metrics.requests.successRate}%');
print('Avg Response Time: ${metrics.performance.avgResponseTimeMs}ms');
print('Cache Hit Rate: ${metrics.cache.estimatedHitRate}%');

print('Requests by Type:');
metrics.requestsByType.forEach((type, count) {
  print('  $type: $count');
});

print('Top Errors:');
for (final error in metrics.topErrors) {
  print('  ${error.message}: ${error.count}');
}

// Get available models
final models = await aiService.getAvailableModels();
print('Current Model: ${models['current_model']}');
print('Available Models:');
for (final model in models['available_models']) {
  print('  ${model['name']} (${model['size']})');
}
```

### 6. Safety SOP Generation

```dart
// Generate safety SOP for a job type
try {
  final sop = await aiService.generateSafetySOP(
    jobType: 'Electrical Wiring Installation',
  );
  
  print('Job Type: ${sop.jobType}');
  print('\nHazards:');
  for (final hazard in sop.hazards) {
    print('  - $hazard');
  }
  
  print('\nRequired PPE:');
  for (final ppe in sop.requiredPpe) {
    print('  - $ppe');
  }
  
  print('\nProcedures:');
  for (final procedure in sop.procedures) {
    print('  - $procedure');
  }
  
  print('\nEmergency Protocols:');
  for (final protocol in sop.emergencyProtocols) {
    print('  - $protocol');
  }
  
  // Full markdown content
  print('\n${sop.content}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

## Error Handling

All methods throw `ApiException` on error. Always wrap calls in try-catch blocks:

```dart
try {
  final recommendations = await aiService.getRecommendations();
  // Handle success
} on ApiException catch (e) {
  // Handle API errors
  switch (e.type) {
    case ApiExceptionType.network:
      print('No internet connection');
      break;
    case ApiExceptionType.timeout:
      print('Request timed out');
      break;
    case ApiExceptionType.server:
      print('Server error: ${e.message}');
      break;
    case ApiExceptionType.client:
      print('Client error: ${e.message}');
      break;
    default:
      print('Unknown error: ${e.message}');
  }
}
```

## Authentication

All AI endpoints require JWT authentication. The `ApiClient` automatically handles:

- Attaching JWT tokens to requests
- Token refresh on 401 errors
- Automatic retry of failed requests

Ensure the user is logged in before calling AI endpoints.

## Rate Limiting

AI endpoints are rate-limited:

- Customer endpoints: 10 requests/minute
- Provider endpoints: 20 requests/minute
- Admin endpoints: 50 requests/minute

Handle 429 errors gracefully:

```dart
try {
  final recommendations = await aiService.getRecommendations();
} on ApiException catch (e) {
  if (e.statusCode == 429) {
    // Show rate limit message
    showSnackBar('Too many requests. Please try again in a moment.');
  }
}
```

## Caching

The backend caches AI responses to improve performance:

- Recommendations: 1 hour
- Match scores: 24 hours
- Analytics: 24 hours

Use the `refresh` parameter to force regeneration:

```dart
// Get fresh recommendations
final recommendations = await aiService.getRecommendations(refresh: true);

// Get fresh predictions
final predictions = await aiService.getPredictions(refresh: true);
```

## Testing

Mock the service in tests:

```dart
class MockAIApiService extends Mock implements AIApiService {}

void main() {
  late MockAIApiService mockAIService;
  
  setUp(() {
    mockAIService = MockAIApiService();
  });
  
  test('should get recommendations', () async {
    // Arrange
    when(() => mockAIService.getRecommendations())
        .thenAnswer((_) async => [
          AIRecommendation(
            id: 'test-id',
            service: ServiceInfo(
              id: 'service-id',
              name: 'Test Service',
              category: 'Cleaning',
              price: 1000,
              description: 'Test description',
            ),
            confidenceScore: 85.5,
            reasoning: 'Test reasoning',
            expiresAt: DateTime.now().add(Duration(hours: 1)),
          ),
        ]);
    
    // Act
    final recommendations = await mockAIService.getRecommendations();
    
    // Assert
    expect(recommendations.length, 1);
    expect(recommendations[0].service.name, 'Test Service');
  });
}
```

## Backend API Documentation

For detailed API documentation, see:
- `backend/AI_API_DOCUMENTATION.md`
- `backend/AI_SETUP_GUIDE.md`

## Related Files

- `lib/services/api/api_client.dart` - Base API client
- `lib/services/api/api_exception.dart` - Exception types
- `lib/core/constants/api_constants.dart` - API endpoints
