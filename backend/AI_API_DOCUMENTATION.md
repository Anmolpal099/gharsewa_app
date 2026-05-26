# AI API Documentation

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Base URL](#base-url)
4. [Rate Limiting](#rate-limiting)
5. [Error Handling](#error-handling)
6. [Endpoints](#endpoints)
   - [AI Recommendations](#ai-recommendations)
   - [AI Matching](#ai-matching)
   - [AI Analytics](#ai-analytics)
   - [AI Health & Monitoring](#ai-health--monitoring)
   - [AI Safety SOP](#ai-safety-sop)
7. [Response Formats](#response-formats)
8. [Configuration](#configuration)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The GharSewa AI Integration provides intelligent features powered by a locally-hosted Qwen3-VL model served via Ollama. The AI system offers:

- **Personalized Service Recommendations**: AI-driven service suggestions based on user history and preferences
- **Provider-Customer Matching**: Intelligent scoring to match providers with booking requests
- **Predictive Analytics**: Forecasting and trend analysis for admin decision-making
- **Smart Notification Timing**: Optimized notification delivery based on user engagement patterns
- **Safety SOP Generation**: AI-generated safety standard operating procedures for job types

All AI operations run locally at `http://localhost:11434` (or `http://gharsewa_ollama:11434` from Docker), ensuring zero API costs and complete data privacy.

---

## Authentication

All AI endpoints require JWT authentication. Include the JWT token in the `Authorization` header:

```http
Authorization: Bearer <your_jwt_token>
```

### Obtaining a JWT Token

```http
POST /api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "your_password"
}
```


**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "name": "John Doe",
      "email": "user@example.com",
      "role": "customer"
    }
  }
}
```

### Role-Based Access

- **Customer**: Access to recommendations and provider matching
- **Provider**: Access to booking match scores
- **Admin**: Full access to analytics, health monitoring, and all AI features

---

## Base URL

```
http://localhost:8000/api/v1
```

For Docker deployments:
```
http://backend:8000/api/v1
```

---

## Rate Limiting

AI endpoints are rate-limited to prevent abuse and ensure fair resource allocation:

| Endpoint Type | Rate Limit | Window |
|--------------|------------|--------|
| Customer Recommendations | 10 requests | 1 minute |
| Provider Matching | 20 requests | 1 minute |
| Admin Analytics | 50 requests | 1 minute |
| Health Check | 50 requests | 1 minute |

**Rate Limit Response (429):**
```json
{
  "success": false,
  "message": "Too many requests. Please try again in 45 seconds."
}
```


---

## Error Handling

### Standard Error Response Format

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": "Detailed error information (only in debug mode)"
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid input parameters |
| 401 | Unauthorized | Missing or invalid JWT token |
| 403 | Forbidden | Insufficient permissions for this resource |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server-side error occurred |
| 503 | Service Unavailable | AI service (Ollama) is unavailable |

### Common Error Codes

| Error Code | Description | Resolution |
|------------|-------------|------------|
| `AI_SERVICE_UNAVAILABLE` | Ollama is not responding | Check Ollama container status |
| `MODEL_NOT_FOUND` | Specified AI model not loaded | Pull the model: `docker exec gharsewa_ollama ollama pull qwen3-vl:2b` |
| `TIMEOUT_ERROR` | AI request exceeded timeout | Increase `OLLAMA_TIMEOUT` in .env |
| `PARSE_ERROR` | Unable to parse AI response | Check AI logs for malformed responses |
| `VALIDATION_ERROR` | Input validation failed | Review request parameters |
| `RATE_LIMIT_ERROR` | Too many requests | Wait before retrying |


---

## Endpoints

## AI Recommendations

### 1. Get Personalized Recommendations

Get AI-generated service recommendations tailored to the authenticated customer.

**Endpoint:** `GET /api/v1/customer/ai/recommendations`

**Authentication:** Required (Customer role)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | 5 | Number of recommendations (1-20) |
| `refresh` | boolean | No | false | Force regenerate recommendations |

**Request Example:**

```http
GET /api/v1/customer/ai/recommendations?limit=5&refresh=false
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "message": "Recommendations generated successfully",
  "data": {
    "recommendations": [
      {
        "id": "uuid",
        "service": {
          "id": "uuid",
          "name": "House Cleaning",
          "category": "Cleaning",
          "price": 2500,
          "description": "Professional house cleaning service",
          "image_url": "https://example.com/image.jpg"
        },
        "confidence_score": 92.5,
        "reasoning": "Based on your recent bookings and location preferences",
        "expires_at": "2024-01-15T10:30:00Z"
      }
    ],
    "cached": false
  }
}
```


**Error Responses:**

```json
// 400 - Invalid limit
{
  "success": false,
  "message": "Limit must be between 1 and 20"
}

// 429 - Rate limit exceeded
{
  "success": false,
  "message": "Too many requests. Please try again in 45 seconds."
}

// 500 - AI service error
{
  "success": false,
  "message": "Failed to generate recommendations",
  "error": "Ollama connection timeout"
}
```

---

### 2. Record Recommendation Feedback

Track user interactions with recommendations to improve future suggestions.

**Endpoint:** `POST /api/v1/customer/ai/recommendations/feedback`

**Authentication:** Required (Customer role)

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `recommendation_id` | string (uuid) | Yes | ID of the recommendation |
| `action` | string | Yes | User action: `clicked` or `booked` |

**Request Example:**

```http
POST /api/v1/customer/ai/recommendations/feedback
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "recommendation_id": "550e8400-e29b-41d4-a716-446655440000",
  "action": "clicked"
}
```

**Success Response (200):**

```json
{
  "success": true,
  "message": "Feedback recorded successfully",
  "data": {
    "recommendation_id": "550e8400-e29b-41d4-a716-446655440000",
    "action": "clicked",
    "recorded_at": "2024-01-15T10:30:00Z"
  }
}
```


**Error Responses:**

```json
// 403 - Unauthorized access
{
  "success": false,
  "message": "Unauthorized access to recommendation"
}

// 422 - Validation error
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "action": ["The action field must be either clicked or booked."]
  }
}
```

---

### 3. Get Recommendation Statistics

View statistics about recommendation performance for the authenticated user.

**Endpoint:** `GET /api/v1/customer/ai/recommendations/stats`

**Authentication:** Required (Customer role)

**Request Example:**

```http
GET /api/v1/customer/ai/recommendations/stats
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "data": {
    "total_recommendations": 45,
    "active_recommendations": 5,
    "clicked_recommendations": 23,
    "booked_recommendations": 12,
    "click_rate": 51.11,
    "conversion_rate": 26.67
  }
}
```

---

## AI Matching

### 4. Get Match Score for Booking (Provider View)

Get AI-calculated match score for a specific booking request.

**Endpoint:** `GET /api/v1/provider/ai/bookings/{id}/match-score`

**Authentication:** Required (Provider role)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string (uuid) | Yes | Booking ID |


**Request Example:**

```http
GET /api/v1/provider/ai/bookings/550e8400-e29b-41d4-a716-446655440000/match-score
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "data": {
    "booking_id": "550e8400-e29b-41d4-a716-446655440000",
    "match_score": 87.5,
    "factors": {
      "skill_alignment": 95,
      "location_proximity": 88,
      "rating": 90,
      "availability": 100,
      "preferences": 85
    },
    "reasoning": "Excellent match - highly skilled and nearby. Your expertise aligns perfectly with the customer's requirements.",
    "calculated_at": "2024-01-15T10:30:00Z",
    "booking_details": {
      "service": "Plumbing Repair",
      "category": "Plumbing",
      "scheduled_date": "2024-01-20",
      "location": "Kathmandu, Nepal"
    }
  }
}
```

**Error Responses:**

```json
// 404 - Booking not found
{
  "success": false,
  "message": "Booking not found"
}

// 404 - Match score not available
{
  "success": false,
  "message": "Match score not available for this booking"
}
```

---

### 5. Find Matching Providers (Customer View)

Find best matching providers for a service request.

**Endpoint:** `GET /api/v1/customer/ai/providers/matches`

**Authentication:** Required (Customer role)


**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `service_id` | string (uuid) | Yes | Service ID to find providers for |
| `location` | string | No | Service location |
| `limit` | integer | No | Number of providers (1-20, default: 10) |

**Request Example:**

```http
GET /api/v1/customer/ai/providers/matches?service_id=550e8400-e29b-41d4-a716-446655440000&location=Kathmandu&limit=5
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "message": "Matching providers retrieved successfully",
  "data": {
    "providers": [
      {
        "provider_id": "uuid",
        "name": "Ram Sharma",
        "email": "ram@example.com",
        "phone": "+977-9841234567",
        "rating": 4.8,
        "total_reviews": 156,
        "completed_bookings": 234,
        "match_score": 92.5,
        "profile": {
          "bio": "Experienced plumber with 10+ years",
          "experience_years": 10,
          "specializations": ["Plumbing", "Pipe Fitting", "Water Heater"]
        }
      }
    ],
    "total": 5
  }
}
```

**Error Responses:**

```json
// 422 - Validation error
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "service_id": ["The service id field is required."]
  }
}
```


---

### 6. Get All Match Scores for Booking (Admin View)

View all provider match scores for a specific booking.

**Endpoint:** `GET /api/v1/admin/ai/bookings/{id}/match-scores`

**Authentication:** Required (Admin role)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string (uuid) | Yes | Booking ID |

**Request Example:**

```http
GET /api/v1/admin/ai/bookings/550e8400-e29b-41d4-a716-446655440000/match-scores
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "data": {
    "booking_id": "550e8400-e29b-41d4-a716-446655440000",
    "match_scores": [
      {
        "provider_id": "uuid",
        "provider_name": "Ram Sharma",
        "match_score": 92.5,
        "factors": {
          "skill_alignment": 95,
          "location_proximity": 88,
          "rating": 90,
          "availability": 100,
          "preferences": 85
        },
        "reasoning": "Excellent match - highly skilled and nearby",
        "calculated_at": "2024-01-15T10:30:00Z"
      }
    ],
    "total": 8
  }
}
```

---

## AI Analytics

### 7. Get Predictions

Get AI-generated predictions for various metrics.

**Endpoint:** `GET /api/v1/admin/ai/analytics/predictions`

**Authentication:** Required (Admin role)


**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `type` | string | No | all | Prediction type: `booking_volume`, `revenue_forecast`, `churn_risk`, `trend` |
| `days` | integer | No | 7 | Forecast period (1-90 days) |
| `refresh` | boolean | No | false | Force refresh predictions |

**Request Example:**

```http
GET /api/v1/admin/ai/analytics/predictions?type=booking_volume&days=7&refresh=false
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "message": "Predictions generated successfully",
  "data": {
    "booking_volume": {
      "predictions": [
        {
          "date": "2024-01-16",
          "value": 45,
          "confidence": 87.5
        },
        {
          "date": "2024-01-17",
          "value": 52,
          "confidence": 85.2
        }
      ],
      "insights": "Booking volume expected to increase by 15% this week due to seasonal trends",
      "confidence_score": 86.3,
      "factors": ["seasonal_trend", "historical_pattern", "day_of_week"]
    }
  },
  "cached": false
}
```

**Error Responses:**

```json
// 400 - Invalid days parameter
{
  "success": false,
  "message": "Days must be between 1 and 90"
}
```

---

### 8. Get Trend Analysis

Get AI-identified trends and patterns.

**Endpoint:** `GET /api/v1/admin/ai/analytics/trends`

**Authentication:** Required (Admin role)


**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `refresh` | boolean | No | false | Force refresh trends |

**Request Example:**

```http
GET /api/v1/admin/ai/analytics/trends?refresh=false
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "message": "Trends identified successfully",
  "data": {
    "trending_services": [
      {
        "service_name": "House Cleaning",
        "category": "Cleaning",
        "growth_rate": 25.5,
        "current_bookings": 156,
        "previous_bookings": 124
      }
    ],
    "declining_services": [
      {
        "service_name": "Garden Maintenance",
        "category": "Gardening",
        "decline_rate": -12.3,
        "current_bookings": 45,
        "previous_bookings": 51
      }
    ],
    "peak_hours": [
      {"hour": 10, "booking_count": 45},
      {"hour": 14, "booking_count": 52}
    ],
    "insights": "House cleaning services showing strong growth. Consider promoting during peak hours (10 AM - 2 PM)."
  },
  "cached": false
}
```

---

### 9. Get Actionable Insights

Get AI-generated business insights and recommendations.

**Endpoint:** `GET /api/v1/admin/ai/analytics/insights`

**Authentication:** Required (Admin role)

**Request Example:**

```http
GET /api/v1/admin/ai/analytics/insights
Authorization: Bearer <jwt_token>
```


**Success Response (200):**

```json
{
  "success": true,
  "message": "Insights retrieved successfully",
  "data": {
    "insights": {
      "booking_volume": [
        {
          "insights": "Booking volume expected to peak on weekends",
          "confidence_score": 88.5,
          "factors": ["day_of_week", "historical_pattern"],
          "created_at": "2024-01-15T10:30:00Z"
        }
      ],
      "revenue_forecast": [],
      "churn_risk": [],
      "trend": []
    },
    "summary": {
      "total_predictions": 10,
      "average_confidence": 85.7,
      "high_confidence_count": 7,
      "key_insights": [
        "Booking volume expected to peak on weekends",
        "House cleaning services showing 25% growth",
        "Provider retention rate improving"
      ]
    },
    "total_predictions": 10
  }
}
```

---

### 10. Get Prediction History

View historical predictions for trend analysis.

**Endpoint:** `GET /api/v1/admin/ai/analytics/history`

**Authentication:** Required (Admin role)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `type` | string | No | all | Filter by prediction type |
| `limit` | integer | No | 20 | Number of records (1-100) |

**Request Example:**

```http
GET /api/v1/admin/ai/analytics/history?type=booking_volume&limit=10
Authorization: Bearer <jwt_token>
```


**Success Response (200):**

```json
{
  "success": true,
  "message": "History retrieved successfully",
  "data": {
    "predictions": [
      {
        "id": "uuid",
        "type": "booking_volume",
        "confidence_score": 87.5,
        "insights": "Booking volume expected to increase",
        "factors": ["seasonal_trend", "historical_pattern"],
        "valid_until": "2024-01-16T10:30:00Z",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "total": 10
  }
}
```

**Error Responses:**

```json
// 400 - Invalid limit
{
  "success": false,
  "message": "Limit must be between 1 and 100"
}
```

---

## AI Health & Monitoring

### 11. Get AI System Health

Check the health status of all AI system components.

**Endpoint:** `GET /api/v1/admin/ai/health`

**Authentication:** Required (Admin role)

**Request Example:**

```http
GET /api/v1/admin/ai/health
Authorization: Bearer <jwt_token>
```

**Success Response (200):**

```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-15T10:30:00Z",
    "components": {
      "ollama": {
        "status": "healthy",
        "message": "Ollama is responding"
      },
      "redis": {
        "status": "healthy",
        "message": "Redis is responding"
      },
      "database": {
        "status": "healthy",
        "message": "Database is responding"
      },
      "model": {
        "status": "healthy",
        "message": "Model is available",
        "model_name": "qwen3-vl:2b"
      },
      "queue": {
        "status": "healthy",
        "message": "Failed jobs: 0",
        "failed_jobs": 0
      }
    }
  }
}
```


**Unhealthy Response (503):**

```json
{
  "success": false,
  "data": {
    "status": "unhealthy",
    "timestamp": "2024-01-15T10:30:00Z",
    "components": {
      "ollama": {
        "status": "unhealthy",
        "message": "Ollama is not responding",
        "error": "Connection timeout"
      },
      "redis": {
        "status": "healthy",
        "message": "Redis is responding"
      },
      "database": {
        "status": "healthy",
        "message": "Database is responding"
      },
      "model": {
        "status": "unhealthy",
        "message": "Model is not available",
        "model_name": "qwen3-vl:2b"
      },
      "queue": {
        "status": "degraded",
        "message": "Failed jobs: 15",
        "failed_jobs": 15
      }
    }
  }
}
```

---

### 12. Get AI System Metrics

Get performance metrics for the AI system.

**Endpoint:** `GET /api/v1/admin/ai/metrics`

**Authentication:** Required (Admin role)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `period` | string | No | 24h | Time period: `1h`, `24h`, `7d`, `30d` |

**Request Example:**

```http
GET /api/v1/admin/ai/metrics?period=24h
Authorization: Bearer <jwt_token>
```


**Success Response (200):**

```json
{
  "success": true,
  "message": "Metrics retrieved successfully",
  "data": {
    "period": "24h",
    "since": "2024-01-14T10:30:00Z",
    "requests": {
      "total": 1245,
      "successful": 1198,
      "failed": 47,
      "success_rate": 96.23
    },
    "performance": {
      "avg_response_time_ms": 1250.5,
      "p50_response_time_ms": 1100,
      "p95_response_time_ms": 2300,
      "p99_response_time_ms": 3500
    },
    "cache": {
      "estimated_hit_rate": 45.2,
      "estimated_hits": 563
    },
    "requests_by_type": {
      "recommendation": 456,
      "matching": 234,
      "analytics": 123,
      "notification": 432
    },
    "top_errors": [
      {
        "message": "Ollama connection timeout",
        "count": 25
      },
      {
        "message": "Model response parse error",
        "count": 12
      }
    ],
    "ollama": {
      "status": "healthy",
      "estimated_uptime": 100,
      "model": "qwen3-vl:2b"
    }
  }
}
```

---

### 13. Get Available AI Models

List all available AI models in Ollama.

**Endpoint:** `GET /api/v1/admin/ai/models`

**Authentication:** Required (Admin role)

**Request Example:**

```http
GET /api/v1/admin/ai/models
Authorization: Bearer <jwt_token>
```


**Success Response (200):**

```json
{
  "success": true,
  "message": "Models retrieved successfully",
  "data": {
    "current_model": "qwen3-vl:2b",
    "available_models": [
      {
        "name": "qwen3-vl:2b",
        "size": "1.5GB",
        "modified_at": "2024-01-10T08:00:00Z"
      },
      {
        "name": "qwen3-vl:4b",
        "size": "2.8GB",
        "modified_at": "2024-01-12T10:30:00Z"
      },
      {
        "name": "qwen2.5:3b",
        "size": "2.1GB",
        "modified_at": "2024-01-08T14:20:00Z"
      }
    ],
    "total": 3
  }
}
```

---

## AI Safety SOP

### 14. Generate Safety SOP

Generate AI-powered safety standard operating procedures for a job type.

**Endpoint:** `POST /api/v1/ai/safety-sop`

**Authentication:** Required (All authenticated users)

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `job_type` | string | Yes | Job type (2-120 characters) |

**Request Example:**

```http
POST /api/v1/ai/safety-sop
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "job_type": "Electrical Wiring Installation"
}
```


**Success Response (200):**

```json
{
  "success": true,
  "message": "Safety SOP generated successfully",
  "data": {
    "id": "uuid",
    "job_type": "Electrical Wiring Installation",
    "content": "# Safety SOP: Electrical Wiring Installation\n\n## Hazards\n- Slip, trip, and fall hazards in the work area\n- Exposure to electrical components (if applicable)...",
    "hazards": [
      "Slip, trip, and fall hazards in the work area",
      "Exposure to electrical components (if applicable)",
      "Chemical, dust, or fume exposure",
      "Manual handling and ergonomic strain"
    ],
    "required_ppe": [
      "Safety gloves",
      "Safety goggles or face shield",
      "Closed-toe safety footwear",
      "Mask/respirator when dust or fumes are present"
    ],
    "procedures": [
      "Inspect the work area and remove obstacles before starting",
      "Verify tools and equipment are in safe working condition",
      "Follow manufacturer instructions for all products and equipment",
      "Keep walkways clear and cordon off the work zone if needed",
      "Communicate hazards to the customer before beginning work"
    ],
    "emergency_protocols": [
      "Stop work immediately if unsafe conditions appear",
      "Call local emergency services (100/101/102) for serious injury",
      "Notify the customer and platform support",
      "Document the incident and preserve the work area if required"
    ],
    "generated_at": "2024-01-15T10:30:00Z",
    "is_saved": false
  }
}
```

**Error Responses:**

```json
// 422 - Validation error
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "job_type": ["The job type field is required."]
  }
}

// 500 - Generation error
{
  "success": false,
  "message": "Failed to generate safety SOP. Please try again."
}
```


---

## Response Formats

### Success Response Structure

All successful responses follow this structure:

```json
{
  "success": true,
  "message": "Human-readable success message",
  "data": {
    // Response data specific to the endpoint
  }
}
```

### Error Response Structure

All error responses follow this structure:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": "Detailed error (only in debug mode)",
  "errors": {
    // Validation errors (422 responses only)
  }
}
```

### Pagination

Endpoints that return lists support pagination:

```json
{
  "success": true,
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "per_page": 20,
    "last_page": 5
  }
}
```

### Timestamps

All timestamps are in ISO 8601 format (UTC):

```
2024-01-15T10:30:00Z
```

---

## Configuration

### Environment Variables

Configure AI services in your `.env` file:

```env
# Ollama Configuration
OLLAMA_HOST=http://gharsewa_ollama:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=60
OLLAMA_MAX_TOKENS=2048
OLLAMA_TEMPERATURE=0.7
OLLAMA_TOP_P=0.9

# AI Service Configuration
AI_CACHE_TTL=3600
AI_MAX_RETRIES=3
AI_RETRY_DELAY=1000
```


### Configuration Parameters

| Parameter | Description | Default | Valid Values |
|-----------|-------------|---------|--------------|
| `OLLAMA_HOST` | Ollama API endpoint | `http://localhost:11434` | Valid HTTP URL |
| `OLLAMA_MODEL` | AI model name | `qwen3-vl:2b` | Any Ollama model |
| `OLLAMA_TIMEOUT` | Request timeout (seconds) | `60` | 10-300 |
| `OLLAMA_MAX_TOKENS` | Max tokens per request | `2048` | 512-8192 |
| `OLLAMA_TEMPERATURE` | Response randomness | `0.7` | 0.0-1.0 |
| `OLLAMA_TOP_P` | Nucleus sampling | `0.9` | 0.0-1.0 |
| `AI_CACHE_TTL` | Cache duration (seconds) | `3600` | 60-86400 |
| `AI_MAX_RETRIES` | Max retry attempts | `3` | 1-10 |
| `AI_RETRY_DELAY` | Retry delay (ms) | `1000` | 100-10000 |

### Available Models

| Model | Size | Use Case | Performance |
|-------|------|----------|-------------|
| `qwen3-vl:2b` | 1.5GB | Fast responses, lower accuracy | ~1-2s response time |
| `qwen3-vl:4b` | 2.8GB | Balanced performance | ~2-3s response time |
| `qwen2.5:3b` | 2.1GB | General purpose | ~1.5-2.5s response time |
| `tinyllama` | 637MB | Ultra-fast, basic tasks | ~0.5-1s response time |

### Switching Models

To switch AI models:

1. Pull the new model:
```bash
docker exec gharsewa_ollama ollama pull qwen3-vl:4b
```

2. Update `.env`:
```env
OLLAMA_MODEL=qwen3-vl:4b
```

3. Restart the backend:
```bash
docker-compose restart backend
```

4. Verify the change:
```http
GET /api/v1/admin/ai/health
```

---

## Troubleshooting

### Common Issues

#### 1. Ollama Connection Error

**Symptom:** `AI_SERVICE_UNAVAILABLE` error

**Causes:**
- Ollama container not running
- Network connectivity issues
- Wrong `OLLAMA_HOST` configuration

**Solutions:**

```bash
# Check Ollama container status
docker ps | grep ollama

# Start Ollama if not running
docker-compose up -d ollama

# Check Ollama logs
docker logs gharsewa_ollama

# Test Ollama directly
curl http://localhost:11434/api/tags
```


#### 2. Model Not Found Error

**Symptom:** `MODEL_NOT_FOUND` error

**Cause:** Specified model not pulled in Ollama

**Solution:**

```bash
# List available models
docker exec gharsewa_ollama ollama list

# Pull the required model
docker exec gharsewa_ollama ollama pull qwen3-vl:2b

# Verify model is available
docker exec gharsewa_ollama ollama list
```

#### 3. Timeout Errors

**Symptom:** Requests timing out after 30-60 seconds

**Causes:**
- Model too large for available resources
- High concurrent load
- Insufficient timeout configuration

**Solutions:**

```env
# Increase timeout in .env
OLLAMA_TIMEOUT=120

# Use a smaller, faster model
OLLAMA_MODEL=qwen3-vl:2b

# Reduce max tokens
OLLAMA_MAX_TOKENS=1024
```

```bash
# Restart backend to apply changes
docker-compose restart backend
```

#### 4. Parse Errors

**Symptom:** `PARSE_ERROR` - Unable to parse AI response

**Causes:**
- Model returning malformed JSON
- Temperature too high causing random output
- Prompt template issues

**Solutions:**

```env
# Lower temperature for more consistent output
OLLAMA_TEMPERATURE=0.5

# Adjust top_p
OLLAMA_TOP_P=0.8
```

Check AI request logs:
```bash
docker-compose logs backend | grep "AI request"
```


#### 5. Rate Limit Errors

**Symptom:** `429 Too Many Requests`

**Cause:** Exceeded rate limits

**Solution:**

Wait for the cooldown period (shown in error message) or implement request throttling in your client:

```javascript
// Example: Exponential backoff
async function makeAIRequest(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const response = await fetch(url, options);
    
    if (response.status === 429) {
      const retryAfter = response.headers.get('Retry-After') || Math.pow(2, i);
      await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
      continue;
    }
    
    return response;
  }
  throw new Error('Max retries exceeded');
}
```

#### 6. Cache Issues

**Symptom:** Stale recommendations or predictions

**Cause:** Cached data not refreshing

**Solutions:**

```http
# Force refresh using query parameter
GET /api/v1/customer/ai/recommendations?refresh=true
```

```bash
# Clear Redis cache
docker exec gharsewa_redis redis-cli FLUSHDB
```

#### 7. Queue Processing Issues

**Symptom:** AI jobs stuck in queue

**Causes:**
- Queue worker not running
- Failed jobs accumulating

**Solutions:**

```bash
# Check queue worker status
docker-compose ps queue-worker

# Restart queue worker
docker-compose restart queue-worker

# Check failed jobs
docker exec gharsewa_backend php artisan queue:failed

# Retry failed jobs
docker exec gharsewa_backend php artisan queue:retry all

# Clear failed jobs
docker exec gharsewa_backend php artisan queue:flush
```


### Debugging Tips

#### Enable Debug Mode

```env
APP_DEBUG=true
LOG_LEVEL=debug
```

#### View AI Request Logs

```bash
# Real-time logs
docker-compose logs -f backend | grep "AI"

# Last 100 lines
docker-compose logs --tail=100 backend | grep "AI"

# Save logs to file
docker-compose logs backend > backend_logs.txt
```

#### Check Database Records

```bash
# Connect to database
docker exec -it gharsewa_db mysql -u gharsewa_user -p gharsewa

# View AI requests
SELECT * FROM ai_requests ORDER BY created_at DESC LIMIT 10;

# View failed requests
SELECT * FROM ai_requests WHERE success = 0 ORDER BY created_at DESC LIMIT 10;

# View recommendations
SELECT * FROM ai_recommendations WHERE user_id = 'your-user-id' ORDER BY created_at DESC;
```

#### Test Ollama Directly

```bash
# Test Ollama API
curl http://localhost:11434/api/generate -d '{
  "model": "qwen3-vl:2b",
  "prompt": "Hello, how are you?",
  "stream": false
}'

# List models
curl http://localhost:11434/api/tags

# Check model info
curl http://localhost:11434/api/show -d '{
  "name": "qwen3-vl:2b"
}'
```

### Performance Optimization

#### 1. Enable Redis Caching

Ensure Redis is properly configured:

```env
CACHE_DRIVER=redis
REDIS_HOST=redis
REDIS_PORT=6379
```

#### 2. Optimize Model Selection

Choose the right model for your use case:

- **High volume, fast responses**: `qwen3-vl:2b` or `tinyllama`
- **Balanced**: `qwen2.5:3b`
- **High accuracy**: `qwen3-vl:4b`


#### 3. Queue Configuration

For high-volume deployments:

```env
QUEUE_CONNECTION=redis
REDIS_QUEUE=ai-processing
```

Run multiple queue workers:

```bash
# In docker-compose.yml
queue-worker:
  deploy:
    replicas: 3
```

#### 4. Database Indexing

Ensure proper indexes exist:

```sql
-- Check indexes
SHOW INDEX FROM ai_requests;
SHOW INDEX FROM ai_recommendations;
SHOW INDEX FROM ai_match_scores;

-- Add missing indexes if needed
CREATE INDEX idx_user_created ON ai_requests(user_id, created_at);
CREATE INDEX idx_booking_provider ON ai_match_scores(booking_id, provider_id);
```

### Monitoring Best Practices

#### 1. Set Up Health Checks

Monitor AI system health regularly:

```bash
# Cron job to check health every 5 minutes
*/5 * * * * curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8000/api/v1/admin/ai/health
```

#### 2. Track Metrics

Monitor key metrics:

- Success rate (should be > 95%)
- Average response time (should be < 3s)
- Cache hit rate (should be > 40%)
- Queue length (should be < 100)

#### 3. Set Up Alerts

Configure alerts for:

- Ollama downtime
- Success rate < 90%
- Response time > 5s
- Failed jobs > 50

### Security Considerations

#### 1. API Authentication

- Always use JWT authentication
- Rotate JWT secrets regularly
- Implement token expiration

#### 2. Rate Limiting

- Enforce rate limits on all AI endpoints
- Monitor for abuse patterns
- Implement IP-based blocking if needed


#### 3. Data Privacy

- AI processing is local (no external API calls)
- Customer data is anonymized in prompts where possible
- Sensitive information excluded from logs
- AI logs encrypted at rest

#### 4. Input Validation

All endpoints validate input:

- String length limits
- UUID format validation
- Enum value validation
- SQL injection prevention

### Integration Examples

#### JavaScript/TypeScript (Fetch API)

```javascript
// Get recommendations
async function getRecommendations(token, limit = 5) {
  const response = await fetch(
    `http://localhost:8000/api/v1/customer/ai/recommendations?limit=${limit}`,
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  
  return await response.json();
}

// Record feedback
async function recordFeedback(token, recommendationId, action) {
  const response = await fetch(
    'http://localhost:8000/api/v1/customer/ai/recommendations/feedback',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        recommendation_id: recommendationId,
        action: action
      })
    }
  );
  
  return await response.json();
}
```


#### Flutter/Dart (http package)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  final String baseUrl = 'http://localhost:8000/api/v1';
  final String token;
  
  AIService(this.token);
  
  Future<Map<String, dynamic>> getRecommendations({int limit = 5}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customer/ai/recommendations?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recommendations: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> getMatchScore(String bookingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/provider/ai/bookings/$bookingId/match-score'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load match score: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> generateSafetySOP(String jobType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/safety-sop'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'job_type': jobType}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to generate SOP: ${response.body}');
    }
  }
}
```


#### Python (requests library)

```python
import requests

class AIClient:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def get_recommendations(self, limit=5, refresh=False):
        """Get personalized recommendations"""
        url = f'{self.base_url}/customer/ai/recommendations'
        params = {'limit': limit, 'refresh': refresh}
        
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        return response.json()
    
    def get_analytics_predictions(self, pred_type=None, days=7):
        """Get AI predictions"""
        url = f'{self.base_url}/admin/ai/analytics/predictions'
        params = {'days': days}
        if pred_type:
            params['type'] = pred_type
        
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        return response.json()
    
    def check_health(self):
        """Check AI system health"""
        url = f'{self.base_url}/admin/ai/health'
        
        response = requests.get(url, headers=self.headers)
        return response.json()

# Usage
client = AIClient('http://localhost:8000/api/v1', 'your-jwt-token')
recommendations = client.get_recommendations(limit=10)
health = client.check_health()
```

### API Changelog

#### Version 1.0.0 (Current)

**Released:** January 2024

**Features:**
- AI-powered service recommendations
- Provider-customer matching with scoring
- Predictive analytics for admin dashboard
- Smart notification timing optimization
- Safety SOP generation
- Health monitoring and metrics
- Comprehensive error handling
- Rate limiting and caching

**Endpoints:** 14 total
- 3 Recommendation endpoints
- 3 Matching endpoints
- 4 Analytics endpoints
- 3 Health monitoring endpoints
- 1 Safety SOP endpoint


### Support and Resources

#### Documentation

- **API Documentation**: This document
- **Design Document**: `backend/.kiro/specs/ai-integration-ollama/design.md`
- **Requirements**: `backend/.kiro/specs/ai-integration-ollama/requirements.md`
- **Ollama Documentation**: https://ollama.ai/docs

#### Getting Help

1. **Check Health Status**: Start with `/api/v1/admin/ai/health`
2. **Review Logs**: Check Docker logs for errors
3. **Consult Troubleshooting**: See troubleshooting section above
4. **Check Configuration**: Verify `.env` settings

#### Common Questions

**Q: How do I change the AI model?**

A: Update `OLLAMA_MODEL` in `.env`, pull the new model with `docker exec gharsewa_ollama ollama pull <model>`, and restart the backend.

**Q: Why are recommendations cached?**

A: Caching improves performance and reduces load on Ollama. Use `refresh=true` to force regeneration.

**Q: Can I use external AI APIs instead of Ollama?**

A: The current implementation is designed for Ollama. Switching to external APIs would require modifying the `AIService` class.

**Q: How accurate are the predictions?**

A: Prediction accuracy depends on historical data quality and quantity. Confidence scores indicate reliability.

**Q: Is my data sent to external servers?**

A: No. All AI processing happens locally via Ollama. No data leaves your infrastructure.

**Q: How do I scale AI services for high traffic?**

A: Use Redis caching, run multiple queue workers, and consider using a faster model like `qwen3-vl:2b`.

**Q: What happens if Ollama is down?**

A: The system uses fallback strategies (e.g., popular services for recommendations, rule-based matching) and returns appropriate error messages.

---

## Summary

This documentation covers all 14 AI endpoints in the GharSewa platform:

### Customer Endpoints (4)
1. Get Recommendations
2. Record Feedback
3. Get Statistics
4. Find Matching Providers

### Provider Endpoints (1)
5. Get Match Score

### Admin Endpoints (8)
6. Get All Match Scores
7. Get Predictions
8. Get Trends
9. Get Insights
10. Get History
11. Get Health Status
12. Get Metrics
13. Get Models

### General Endpoints (1)
14. Generate Safety SOP

All endpoints require JWT authentication and follow consistent response formats. The system provides comprehensive error handling, rate limiting, caching, and monitoring capabilities.

For the latest updates and changes, refer to the API changelog section.

---

**Document Version:** 1.0.0  
**Last Updated:** January 2024  
**Maintained By:** GharSewa Development Team
