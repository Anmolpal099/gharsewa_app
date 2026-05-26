# Design Document

## System Architecture

### Overview

The AI Integration system consists of three main layers:

1. **AI Infrastructure Layer**: Manages communication with Ollama and provides base AI capabilities
2. **AI Services Layer**: Implements specific AI features (recommendations, matching, analytics, notifications)
3. **API Layer**: Exposes AI features to Flutter frontend via REST endpoints

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Frontend                         │
│  (Customer Panel, Provider Panel, Admin Panel)              │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP/REST
┌─────────────────────▼───────────────────────────────────────┐
│                  Laravel Backend API                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              AI Controllers                           │  │
│  │  - RecommendationController                          │  │
│  │  - MatchingController                                │  │
│  │  - AnalyticsController                               │  │
│  │  - NotificationController                            │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │           AI Services Layer                           │  │
│  │  - RecommendationService                             │  │
│  │  - MatchingService                                   │  │
│  │  - AnalyticsService                                  │  │
│  │  - SmartNotificationService                          │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │         AI Infrastructure Layer                       │  │
│  │  - AIService (Base)                                  │  │
│  │  - PromptBuilder                                     │  │
│  │  - ResponseParser                                    │  │
│  │  - AIJobQueue                                        │  │
│  └──────────────────┬───────────────────────────────────┘  │
└─────────────────────┼───────────────────────────────────────┘
                      │ HTTP (localhost:11434)
┌─────────────────────▼───────────────────────────────────────┐
│              Ollama Container (Docker)                       │
│              Model: Qwen3-VL:4B                             │
└─────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. AI Infrastructure Layer

#### 1.1 AIService (Base Class)

**Location**: `backend/app/Services/AI/AIService.php`

**Responsibilities**:
- Manage HTTP communication with Ollama API
- Handle request/response lifecycle
- Implement retry logic and error handling
- Provide caching mechanism
- Log all AI interactions

**Key Methods**:
```php
class AIService
{
    // Send prompt to Ollama and get response
    public function generate(string $prompt, array $options = []): AIResponse
    
    // Check if Ollama is available
    public function healthCheck(): bool
    
    // Get available models from Ollama
    public function listModels(): array
    
    // Validate model is loaded
    public function validateModel(string $modelName): bool
    
    // Build structured prompt from template
    protected function buildPrompt(string $template, array $data): string
    
    // Parse and validate AI response
    protected function parseResponse(string $rawResponse): AIResponse
    
    // Cache AI response
    protected function cacheResponse(string $key, AIResponse $response): void
    
    // Get cached response
    protected function getCachedResponse(string $key): ?AIResponse
}
```

**Configuration** (`.env`):
```
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=qwen3-vl:4b
OLLAMA_TIMEOUT=30
OLLAMA_MAX_TOKENS=2048
OLLAMA_TEMPERATURE=0.7
OLLAMA_TOP_P=0.9
AI_CACHE_TTL=3600
AI_MAX_RETRIES=3
AI_RETRY_DELAY=1000
```

#### 1.2 PromptBuilder

**Location**: `backend/app/Services/AI/PromptBuilder.php`

**Responsibilities**:
- Load and manage prompt templates
- Inject data into templates
- Validate prompt structure
- Handle context window limits

**Prompt Templates** (stored in `backend/resources/prompts/`):
- `recommendation.txt`: For service recommendations
- `matching.txt`: For provider-customer matching
- `analytics.txt`: For predictive analytics
- `notification.txt`: For notification optimization

#### 1.3 ResponseParser

**Location**: `backend/app/Services/AI/ResponseParser.php`

**Responsibilities**:
- Parse JSON responses from Ollama
- Extract structured data
- Validate response format
- Sanitize output
- Handle malformed responses

#### 1.4 AIJobQueue

**Location**: `backend/app/Jobs/AI/ProcessAIRequest.php`

**Responsibilities**:
- Queue AI requests for async processing
- Retry failed jobs
- Track job status
- Notify on completion/failure

**Queue Configuration**:
- Queue name: `ai-processing`
- Max attempts: 3
- Timeout: 60 seconds
- Backoff: [10, 30, 60] seconds

### 2. AI Services Layer

#### 2.1 RecommendationService

**Location**: `backend/app/Services/AI/RecommendationService.php`

**Responsibilities**:
- Generate personalized service recommendations
- Score recommendations based on relevance
- Filter and rank results
- Cache recommendations per user

**Algorithm**:
1. Gather customer context (booking history, location, preferences)
2. Fetch available services in customer's area
3. Build prompt with customer context and service catalog
4. Send to Ollama for scoring
5. Parse scores and rank services
6. Return top 5 recommendations

**Data Model**:
```php
class Recommendation
{
    public string $serviceId;
    public string $serviceName;
    public float $score; // 0-100
    public string $reason; // AI-generated explanation
    public array $metadata;
}
```

#### 2.2 MatchingService

**Location**: `backend/app/Services/AI/MatchingService.php`

**Responsibilities**:
- Calculate provider-customer match scores
- Consider multiple matching factors
- Rank providers for bookings
- Store match scores in booking metadata

**Matching Factors**:
- Skill alignment (40% weight)
- Location proximity (25% weight)
- Provider rating (20% weight)
- Availability (10% weight)
- Customer preferences (5% weight)

**Algorithm**:
1. Extract booking requirements
2. Fetch eligible providers
3. Build prompt with booking context and provider profiles
4. Send to Ollama for scoring
5. Parse match scores
6. Store in booking metadata
7. Return ranked provider list

**Data Model**:
```php
class MatchScore
{
    public string $providerId;
    public string $providerName;
    public float $score; // 0-100
    public array $factors; // Breakdown by factor
    public string $recommendation; // AI-generated text
}
```

#### 2.3 AnalyticsService

**Location**: `backend/app/Services/AI/AnalyticsService.php`

**Responsibilities**:
- Generate predictive analytics
- Identify trends and patterns
- Forecast metrics
- Detect anomalies

**Analytics Types**:
1. **Booking Volume Prediction**: Forecast next 7 days
2. **Trending Services**: Identify growing categories
3. **Churn Risk**: Predict provider churn
4. **High-Value Customers**: Identify VIP customers
5. **Peak Demand**: Predict busy hours
6. **Revenue Forecast**: 30-day projection

**Algorithm** (Booking Volume Prediction):
1. Fetch historical booking data (last 90 days)
2. Extract features (day of week, time, season, events)
3. Build prompt with historical data and patterns
4. Send to Ollama for prediction
5. Parse predictions with confidence scores
6. Store in analytics cache
7. Return predictions

**Data Model**:
```php
class Prediction
{
    public string $type; // booking_volume, revenue, etc.
    public array $values; // Predicted values
    public array $confidence; // Confidence scores
    public string $period; // Prediction period
    public Carbon $generatedAt;
}
```

#### 2.4 SmartNotificationService

**Location**: `backend/app/Services/AI/SmartNotificationService.php`

**Responsibilities**:
- Optimize notification timing
- Personalize notification content
- Batch non-urgent notifications
- Track engagement metrics
- A/B test notification strategies

**Algorithm** (Timing Optimization):
1. Analyze customer engagement history
2. Identify active hours and response patterns
3. Build prompt with engagement data
4. Send to Ollama for optimal time prediction
5. Schedule notification at predicted time
6. Track open/click rates
7. Update model with feedback

**Data Model**:
```php
class NotificationSchedule
{
    public string $userId;
    public string $notificationType;
    public Carbon $optimalTime;
    public float $confidence;
    public array $engagementHistory;
}
```

### 3. API Layer

#### 3.1 RecommendationController

**Location**: `backend/app/Http/Controllers/API/V1/AI/RecommendationController.php`

**Endpoints**:

```php
// GET /api/v1/customer/recommendations
public function index(Request $request): JsonResponse
{
    // Returns personalized service recommendations
    // Query params: limit (default 5), refresh (force new)
}

// POST /api/v1/customer/recommendations/feedback
public function feedback(Request $request): JsonResponse
{
    // Record user feedback on recommendations
    // Body: { recommendation_id, action: 'clicked'|'booked'|'dismissed' }
}
```

#### 3.2 MatchingController

**Location**: `backend/app/Http/Controllers/API/V1/AI/MatchingController.php`

**Endpoints**:

```php
// GET /api/v1/provider/bookings/{id}/match-score
public function getMatchScore(string $bookingId): JsonResponse
{
    // Returns match score for a specific booking
}

// GET /api/v1/customer/providers/matches
public function findMatches(Request $request): JsonResponse
{
    // Find best matching providers for a service request
    // Query params: service_id, location, requirements
}
```

#### 3.3 AnalyticsController

**Location**: `backend/app/Http/Controllers/API/V1/AI/AnalyticsController.php`

**Endpoints**:

```php
// GET /api/v1/admin/analytics/predictions
public function predictions(Request $request): JsonResponse
{
    // Returns predictive analytics
    // Query params: type (booking_volume, revenue, churn)
}

// GET /api/v1/admin/analytics/trends
public function trends(Request $request): JsonResponse
{
    // Returns trending services and patterns
}

// GET /api/v1/admin/analytics/insights
public function insights(Request $request): JsonResponse
{
    // Returns AI-generated business insights
}
```

#### 3.4 AIHealthController

**Location**: `backend/app/Http/Controllers/API/V1/AI/AIHealthController.php`

**Endpoints**:

```php
// GET /api/v1/admin/ai/health
public function health(): JsonResponse
{
    // Returns Ollama health status and metrics
}

// GET /api/v1/admin/ai/metrics
public function metrics(): JsonResponse
{
    // Returns AI performance metrics
}
```

## Database Schema

### New Tables

#### ai_requests
Tracks all AI requests for monitoring and debugging.

```sql
CREATE TABLE ai_requests (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NULL,
    service_type VARCHAR(50) NOT NULL, -- recommendation, matching, analytics, notification
    prompt_hash VARCHAR(64) NOT NULL,
    response_time_ms INT NOT NULL,
    success BOOLEAN NOT NULL,
    error_message TEXT NULL,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_service (user_id, service_type),
    INDEX idx_created_at (created_at)
);
```

#### ai_recommendations
Stores generated recommendations for tracking and feedback.

```sql
CREATE TABLE ai_recommendations (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    service_id CHAR(36) NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    reason TEXT NULL,
    shown_at TIMESTAMP NULL,
    clicked_at TIMESTAMP NULL,
    booked_at TIMESTAMP NULL,
    dismissed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    INDEX idx_user_active (user_id, expires_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
);
```

#### ai_match_scores
Stores provider-customer match scores.

```sql
CREATE TABLE ai_match_scores (
    id CHAR(36) PRIMARY KEY,
    booking_id CHAR(36) NOT NULL,
    provider_id CHAR(36) NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    factors JSON NOT NULL, -- Breakdown by factor
    recommendation TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_booking (booking_id),
    INDEX idx_provider (provider_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (provider_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### ai_predictions
Stores predictive analytics results.

```sql
CREATE TABLE ai_predictions (
    id CHAR(36) PRIMARY KEY,
    prediction_type VARCHAR(50) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    predictions JSON NOT NULL,
    confidence_scores JSON NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    INDEX idx_type_period (prediction_type, period_start),
    INDEX idx_expires (expires_at)
);
```

#### notification_schedules
Stores optimized notification schedules.

```sql
CREATE TABLE notification_schedules (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    optimal_time TIME NOT NULL,
    confidence DECIMAL(5,2) NOT NULL,
    engagement_history JSON NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### Modified Tables

#### bookings
Add column for AI match score reference.

```sql
ALTER TABLE bookings ADD COLUMN ai_match_score_id CHAR(36) NULL;
ALTER TABLE bookings ADD FOREIGN KEY (ai_match_score_id) REFERENCES ai_match_scores(id) ON DELETE SET NULL;
```

## Prompt Engineering

### Recommendation Prompt Template

**File**: `backend/resources/prompts/recommendation.txt`

```
You are an AI assistant for GharSewa, a home services platform in Nepal.

TASK: Recommend the most relevant services for this customer.

CUSTOMER PROFILE:
- Location: {{customer_location}}
- Previous bookings: {{booking_history}}
- Preferences: {{preferences}}

AVAILABLE SERVICES:
{{services_list}}

INSTRUCTIONS:
1. Analyze the customer's booking history and preferences
2. Consider location proximity for each service
3. Score each service from 0-100 based on relevance
4. Provide a brief reason for each recommendation
5. Return ONLY valid JSON in this exact format:

{
  "recommendations": [
    {
      "service_id": "uuid",
      "score": 85,
      "reason": "Brief explanation"
    }
  ]
}

Return top 5 recommendations sorted by score (highest first).
```

### Matching Prompt Template

**File**: `backend/resources/prompts/matching.txt`

```
You are an AI assistant for GharSewa, a home services platform in Nepal.

TASK: Calculate match scores between providers and a booking request.

BOOKING REQUEST:
- Service: {{service_name}}
- Location: {{booking_location}}
- Requirements: {{requirements}}
- Scheduled: {{scheduled_time}}

PROVIDERS:
{{providers_list}}

SCORING FACTORS:
- Skill alignment (40%): How well provider skills match service requirements
- Location proximity (25%): Distance from booking location
- Provider rating (20%): Historical performance and reviews
- Availability (10%): Provider's schedule availability
- Customer preferences (5%): Match with customer stated preferences

INSTRUCTIONS:
1. Evaluate each provider against all factors
2. Calculate overall match score (0-100)
3. Provide factor breakdown
4. Give brief recommendation
5. Return ONLY valid JSON in this exact format:

{
  "matches": [
    {
      "provider_id": "uuid",
      "score": 92,
      "factors": {
        "skill_alignment": 95,
        "location_proximity": 88,
        "rating": 90,
        "availability": 100,
        "preferences": 85
      },
      "recommendation": "Excellent match - highly skilled and nearby"
    }
  ]
}

Return all providers sorted by score (highest first).
```

### Analytics Prompt Template

**File**: `backend/resources/prompts/analytics.txt`

```
You are an AI assistant for GharSewa, a home services platform in Nepal.

TASK: Generate predictive analytics for {{prediction_type}}.

HISTORICAL DATA:
{{historical_data}}

CONTEXT:
- Current date: {{current_date}}
- Prediction period: {{prediction_period}}
- Platform metrics: {{platform_metrics}}

INSTRUCTIONS:
1. Analyze historical patterns and trends
2. Consider seasonal factors and events
3. Generate predictions for the specified period
4. Provide confidence scores (0-100)
5. Return ONLY valid JSON in this exact format:

{
  "prediction_type": "{{prediction_type}}",
  "predictions": [
    {
      "date": "YYYY-MM-DD",
      "value": 123,
      "confidence": 85
    }
  ],
  "insights": "Brief analysis of trends and factors"
}
```

### Notification Timing Prompt Template

**File**: `backend/resources/prompts/notification.txt`

```
You are an AI assistant for GharSewa, a home services platform in Nepal.

TASK: Determine optimal notification timing for this user.

USER ENGAGEMENT HISTORY:
{{engagement_history}}

NOTIFICATION TYPE: {{notification_type}}
URGENCY: {{urgency_level}}

INSTRUCTIONS:
1. Analyze user's active hours and response patterns
2. Consider notification type and urgency
3. Recommend optimal send time
4. Provide confidence score
5. Return ONLY valid JSON in this exact format:

{
  "optimal_time": "HH:MM:SS",
  "confidence": 88,
  "reasoning": "Brief explanation"
}

If urgency is HIGH, recommend immediate send regardless of patterns.
```

## Error Handling

### Error Types

1. **Ollama Connection Error**: Ollama service unavailable
2. **Model Not Found Error**: Specified model not loaded in Ollama
3. **Timeout Error**: Request exceeded timeout limit
4. **Parse Error**: Unable to parse AI response
5. **Validation Error**: AI response failed validation
6. **Rate Limit Error**: Too many requests

### Fallback Strategies

1. **Recommendations**: Return popular services in user's location
2. **Matching**: Use rule-based scoring algorithm
3. **Analytics**: Return historical averages
4. **Notifications**: Use platform-wide optimal times

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "AI_SERVICE_UNAVAILABLE",
    "message": "AI service is temporarily unavailable",
    "fallback_used": true
  },
  "data": null
}
```

## Performance Optimization

### Caching Strategy

1. **Recommendations**: Cache per user for 1 hour
2. **Match Scores**: Cache per booking for 24 hours
3. **Analytics**: Cache predictions for 24 hours
4. **Notification Schedules**: Cache per user for 7 days

### Queue Priority

1. **High Priority**: Matching scores for active bookings
2. **Medium Priority**: Recommendations for active users
3. **Low Priority**: Analytics and batch predictions

### Rate Limiting

- Customer endpoints: 10 requests/minute
- Provider endpoints: 20 requests/minute
- Admin endpoints: 50 requests/minute

## Testing Strategy

### Unit Tests

- AIService: Test all methods with mocked Ollama responses
- PromptBuilder: Test template rendering and validation
- ResponseParser: Test parsing various response formats
- Each AI service: Test business logic independently

### Integration Tests

- Test full flow from API endpoint to Ollama and back
- Test error handling and fallback mechanisms
- Test caching behavior
- Test queue processing

### Load Tests

- Test concurrent AI requests
- Test queue performance under load
- Test cache hit rates
- Test Ollama response times

## Deployment Checklist

- [ ] Start Ollama container with docker-compose
- [ ] Pull Qwen3-VL:4B model into Ollama
- [ ] Run database migrations for new tables
- [ ] Configure environment variables
- [ ] Create prompt template files
- [ ] Set up AI job queue worker
- [ ] Configure cache driver (Redis recommended)
- [ ] Test Ollama connectivity
- [ ] Run test suite
- [ ] Monitor AI request logs
