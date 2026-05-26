# Requirements Document

## Introduction

This document specifies the requirements for integrating AI capabilities into the GharSewa platform using a locally-hosted Qwen3-VL:4B model served via Ollama. The AI integration will provide personalized service recommendations, intelligent provider-customer matching, predictive analytics for the admin dashboard, and smart notification timing optimization. The system will leverage the existing Laravel backend infrastructure and communicate with Ollama running in Docker at http://localhost:11434, ensuring zero API costs while maintaining data privacy.

## Glossary

- **AI_Service**: The Laravel service class that manages all communication with the Ollama API
- **Ollama**: The local AI model serving platform running the Qwen3-VL:4B model in Docker
- **Recommendation_Engine**: The service that generates personalized service recommendations for customers
- **Matching_Service**: The service that scores and ranks provider-customer compatibility
- **Analytics_Service**: The service that generates predictive insights for admin dashboard
- **Smart_Notification_Service**: The service that optimizes notification timing and content
- **AI_Job_Queue**: Laravel queue system for processing AI requests asynchronously
- **Customer**: A user seeking home services on the platform
- **Provider**: A service provider offering home services
- **Admin**: Platform administrator monitoring operations
- **Match_Score**: A numerical value (0-100) indicating provider-customer compatibility
- **Recommendation_Score**: A numerical value (0-100) indicating service relevance to a customer
- **Model_Response**: The JSON response returned by the Ollama API
- **Prompt_Template**: A structured text template used to format AI model inputs
- **Context_Window**: The maximum token limit for AI model input

## Requirements

### Requirement 1: AI Service Infrastructure Setup

**User Story:** As a developer, I want a robust AI service infrastructure, so that all AI operations are centralized, maintainable, and reliable.

#### Acceptance Criteria

1. THE AI_Service SHALL communicate with Ollama at http://localhost:11434
2. WHEN Ollama is unavailable, THE AI_Service SHALL return a descriptive error message
3. THE AI_Service SHALL validate all prompts before sending to Ollama
4. THE AI_Service SHALL log all AI requests and responses with timestamps
5. THE AI_Service SHALL implement retry logic with exponential backoff for failed requests
6. THE AI_Service SHALL enforce a maximum timeout of 30 seconds per request
7. WHEN a prompt exceeds the Context_Window, THE AI_Service SHALL truncate or summarize the input
8. THE AI_Job_Queue SHALL process AI requests asynchronously to prevent blocking
9. THE AI_Job_Queue SHALL retry failed jobs up to 3 times before marking as failed
10. THE AI_Service SHALL cache frequently requested AI responses for 1 hour

### Requirement 2: Service Recommendation Engine

**User Story:** As a Customer, I want personalized service recommendations, so that I can discover relevant services quickly.

#### Acceptance Criteria

1. WHEN a Customer views the home screen, THE Recommendation_Engine SHALL generate up to 5 personalized service recommendations
2. THE Recommendation_Engine SHALL consider Customer booking history when generating recommendations
3. THE Recommendation_Engine SHALL consider Customer location when generating recommendations
4. THE Recommendation_Engine SHALL consider service popularity when generating recommendations
5. THE Recommendation_Engine SHALL assign a Recommendation_Score to each suggested service
6. THE Recommendation_Engine SHALL return recommendations within 2 seconds
7. WHEN a Customer has no booking history, THE Recommendation_Engine SHALL recommend popular services in their location
8. THE Recommendation_Engine SHALL exclude services the Customer has booked in the last 30 days
9. THE Recommendation_Engine SHALL update recommendations when Customer preferences change
10. THE Recommendation_Engine SHALL log all recommendation requests with Customer ID and results

### Requirement 3: Provider-Customer Matching

**User Story:** As a Provider, I want to see match scores for booking requests, so that I can prioritize bookings where I am a good fit.

#### Acceptance Criteria

1. WHEN a booking is created, THE Matching_Service SHALL calculate a Match_Score for each eligible Provider
2. THE Matching_Service SHALL consider Provider skills when calculating Match_Score
3. THE Matching_Service SHALL consider Provider location proximity when calculating Match_Score
4. THE Matching_Service SHALL consider Provider rating and review history when calculating Match_Score
5. THE Matching_Service SHALL consider Provider availability when calculating Match_Score
6. THE Matching_Service SHALL consider Customer preferences when calculating Match_Score
7. THE Matching_Service SHALL return Match_Score values between 0 and 100
8. THE Matching_Service SHALL complete scoring within 3 seconds
9. WHEN multiple Providers have similar Match_Score values, THE Matching_Service SHALL rank by Provider rating
10. THE Matching_Service SHALL store Match_Score in the booking metadata for audit purposes

### Requirement 4: Predictive Analytics for Admin Dashboard

**User Story:** As an Admin, I want predictive analytics insights, so that I can make data-driven decisions about platform operations.

#### Acceptance Criteria

1. THE Analytics_Service SHALL predict booking volume for the next 7 days
2. THE Analytics_Service SHALL identify trending service categories
3. THE Analytics_Service SHALL predict Provider churn risk based on activity patterns
4. THE Analytics_Service SHALL identify high-value Customers based on booking patterns
5. THE Analytics_Service SHALL predict peak demand hours for each service category
6. THE Analytics_Service SHALL generate revenue forecasts for the next 30 days
7. THE Analytics_Service SHALL identify underperforming service categories
8. THE Analytics_Service SHALL update predictions daily at midnight
9. THE Analytics_Service SHALL provide confidence scores for all predictions
10. THE Analytics_Service SHALL store prediction history for trend analysis

### Requirement 5: Smart Notification Timing Optimization

**User Story:** As a Customer, I want to receive notifications at optimal times, so that I am more likely to engage with them.

#### Acceptance Criteria

1. THE Smart_Notification_Service SHALL analyze Customer engagement patterns to determine optimal notification times
2. THE Smart_Notification_Service SHALL avoid sending notifications during Customer inactive hours
3. THE Smart_Notification_Service SHALL prioritize urgent notifications regardless of timing
4. THE Smart_Notification_Service SHALL batch non-urgent notifications to reduce notification fatigue
5. THE Smart_Notification_Service SHALL personalize notification content based on Customer preferences
6. THE Smart_Notification_Service SHALL track notification open rates and click-through rates
7. THE Smart_Notification_Service SHALL adjust timing strategies based on engagement metrics
8. WHEN a Customer has no engagement history, THE Smart_Notification_Service SHALL use platform-wide optimal times
9. THE Smart_Notification_Service SHALL respect Customer notification preferences and quiet hours
10. THE Smart_Notification_Service SHALL implement A/B testing for notification strategies

### Requirement 6: AI Model Configuration and Management

**User Story:** As a developer, I want flexible AI model configuration, so that I can optimize performance and switch models if needed.

#### Acceptance Criteria

1. THE AI_Service SHALL read Ollama connection settings from environment variables
2. THE AI_Service SHALL support configurable model names via environment variables
3. THE AI_Service SHALL validate that the specified model is available in Ollama before making requests
4. THE AI_Service SHALL support configurable temperature and top_p parameters for model responses
5. THE AI_Service SHALL support configurable maximum token limits per request
6. THE AI_Service SHALL provide a health check endpoint to verify Ollama connectivity
7. WHEN the configured model is unavailable, THE AI_Service SHALL log an error and return a fallback response
8. THE AI_Service SHALL support multiple Prompt_Templates for different use cases
9. THE AI_Service SHALL validate Prompt_Template syntax before execution
10. THE AI_Service SHALL allow administrators to update Prompt_Templates without code changes

### Requirement 7: AI Response Parsing and Validation

**User Story:** As a developer, I want robust response parsing, so that AI outputs are reliable and safe to use.

#### Acceptance Criteria

1. THE AI_Service SHALL parse Model_Response as JSON
2. WHEN Model_Response is not valid JSON, THE AI_Service SHALL attempt to extract structured data
3. THE AI_Service SHALL validate that Model_Response contains expected fields
4. THE AI_Service SHALL sanitize Model_Response to remove potentially harmful content
5. THE AI_Service SHALL validate numerical scores are within expected ranges
6. THE AI_Service SHALL validate that recommendations reference valid service IDs
7. WHEN Model_Response is incomplete, THE AI_Service SHALL return a partial result with a warning
8. THE AI_Service SHALL log all parsing errors with the original Model_Response
9. THE AI_Service SHALL implement fallback logic when AI responses are unusable
10. THE AI_Service SHALL track AI response quality metrics for monitoring

### Requirement 8: AI Feature API Endpoints

**User Story:** As a Flutter developer, I want REST API endpoints for AI features, so that I can integrate them into the mobile app.

#### Acceptance Criteria

1. THE Backend SHALL provide GET /api/v1/customer/recommendations endpoint
2. THE Backend SHALL provide GET /api/v1/provider/bookings/{id}/match-score endpoint
3. THE Backend SHALL provide GET /api/v1/admin/analytics/predictions endpoint
4. THE Backend SHALL provide GET /api/v1/admin/analytics/trends endpoint
5. THE Backend SHALL provide POST /api/v1/admin/ai/health-check endpoint
6. THE Backend SHALL require authentication for all AI endpoints
7. THE Backend SHALL return AI responses in consistent JSON format
8. WHEN an AI operation fails, THE Backend SHALL return appropriate HTTP status codes
9. THE Backend SHALL include response time metadata in all AI endpoint responses
10. THE Backend SHALL rate-limit AI endpoints to prevent abuse

### Requirement 9: AI Performance Monitoring

**User Story:** As an Admin, I want to monitor AI system performance, so that I can identify and resolve issues quickly.

#### Acceptance Criteria

1. THE AI_Service SHALL track average response time for each AI operation type
2. THE AI_Service SHALL track success rate for each AI operation type
3. THE AI_Service SHALL track Ollama availability percentage
4. THE AI_Service SHALL alert when AI response time exceeds 5 seconds
5. THE AI_Service SHALL alert when AI success rate falls below 95%
6. THE AI_Service SHALL track daily AI request volume
7. THE AI_Service SHALL track AI job queue length and processing time
8. THE AI_Service SHALL provide a dashboard endpoint for AI metrics
9. THE AI_Service SHALL store performance metrics for 90 days
10. THE AI_Service SHALL generate weekly performance reports

### Requirement 10: AI Data Privacy and Security

**User Story:** As a Customer, I want my data to be handled securely, so that my privacy is protected when using AI features.

#### Acceptance Criteria

1. THE AI_Service SHALL process all data locally without sending to external APIs
2. THE AI_Service SHALL anonymize Customer data in AI prompts where possible
3. THE AI_Service SHALL not include sensitive personal information in AI logs
4. THE AI_Service SHALL encrypt AI request logs at rest
5. THE AI_Service SHALL implement access controls for AI-generated insights
6. THE AI_Service SHALL allow Customers to opt out of AI-powered recommendations
7. THE AI_Service SHALL delete Customer AI interaction history upon account deletion
8. THE AI_Service SHALL comply with data retention policies for AI-generated data
9. THE AI_Service SHALL audit all access to AI-generated Customer insights
10. THE AI_Service SHALL provide Customers with transparency about AI data usage

