# Implementation Plan: AI Integration with Ollama

## Overview

This implementation plan covers the integration of AI capabilities into the GharSewa platform using a locally-hosted Qwen3-VL:4B model served via Ollama. The implementation includes setting up the Ollama infrastructure, creating AI service layers for recommendations, matching, analytics, and smart notifications, and integrating these features into both the Laravel backend and Flutter frontend.

## Tasks

- [x] 1. Set up Ollama infrastructure and configuration
  - [x] 1.1 Start Ollama container using docker-compose.ollama.yml and verify it's running
    - Review docker-compose.ollama.yml configuration
    - Ensure gharsewa_network exists
    - Start Ollama container: `docker-compose -f docker-compose.ollama.yml up -d`
    - Verify container is running and accessible at http://localhost:11434
    - _Requirements: 1.1, 6.1, 6.6_
  
  - [x] 1.2 Load Qwen3-VL:4B model into Ollama
    - Check if model is already available: `docker exec gharsewa_ollama ollama list`
    - Pull model if not available: `docker exec gharsewa_ollama ollama pull qwen3-vl:4b`
    - Verify model is loaded and responds to test prompts
    - _Requirements: 6.3, 6.7_
  
  - [x] 1.3 Configure environment variables for Ollama in Laravel .env file
    - Add all Ollama configuration variables (OLLAMA_HOST, OLLAMA_MODEL, OLLAMA_TIMEOUT, etc.)
    - Document configuration in .env.example
    - Set appropriate values for development environment
    - _Requirements: 6.1, 6.2, 6.4, 6.5_


- [x] 2. Create AI infrastructure layer for Ollama communication
  - [x] 2.1 Create AIService base class with HTTP client for Ollama API
    - Implement `generate()` method for sending prompts
    - Implement `healthCheck()`, `listModels()`, and `validateModel()` methods
    - Implement retry logic with exponential backoff
    - Implement response caching mechanism
    - Add comprehensive error handling and logging for all operations
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.10_
  
  - [x] 2.2 Create AIResponse DTO for encapsulating AI responses
    - Define properties: content, metadata, success, error
    - Implement toArray() and toJson() methods
    - Add validation methods for response structure
    - _Requirements: 7.1, 7.3, 7.8_
  
  - [x] 2.3 Create PromptBuilder for template management and rendering
    - Create `backend/resources/prompts/` directory
    - Implement template loading from files
    - Implement variable substitution ({{variable}})
    - Implement prompt validation and context window limit handling
    - _Requirements: 1.7, 6.8, 6.9_
  
  - [x] 2.4 Create ResponseParser for AI response parsing and validation
    - Implement JSON parsing with error handling
    - Implement response validation and data sanitization
    - Add fallback logic for malformed responses
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.7, 7.8, 7.9_


- [x] 3. Create database schema for AI features
  - [x] 3.1 Create ai_requests migration and run migration
    - Run: `docker-compose exec app php artisan make:migration create_ai_requests_table`
    - Define schema with indexes for performance
    - Run migration: `docker-compose exec app php artisan migrate`
    - _Requirements: 1.4, 9.6_
  
  - [x] 3.2 Create ai_recommendations migration and run migration
    - Run: `docker-compose exec app php artisan make:migration create_ai_recommendations_table`
    - Define schema with foreign keys and indexes
    - Run migration
    - _Requirements: 2.10_
  
  - [x] 3.3 Create ai_match_scores migration and run migration
    - Run: `docker-compose exec app php artisan make:migration create_ai_match_scores_table`
    - Define schema with foreign keys to bookings and users
    - Run migration
    - _Requirements: 3.10_
  
  - [x] 3.4 Create ai_predictions and notification_schedules migrations
    - Create ai_predictions migration
    - Create notification_schedules migration
    - Modify bookings table to add ai_match_score_id column
    - Run all migrations
    - _Requirements: 4.8, 5.9_


- [x] 4. Create prompt templates for all AI features
  - [x] 4.1 Create and test recommendation prompt template
    - Create `backend/resources/prompts/recommendation.txt`
    - Write structured prompt with clear instructions and JSON output format
    - Test with sample data to ensure valid recommendations
    - _Requirements: 2.1, 2.5, 6.8_
  
  - [x] 4.2 Create and test matching prompt template
    - Create `backend/resources/prompts/matching.txt`
    - Define scoring factors and weights, specify JSON output format
    - Test with sample providers to ensure valid match scores
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_
  
  - [x] 4.3 Create and test analytics prompt template
    - Create `backend/resources/prompts/analytics.txt`
    - Define prediction types and output format with confidence scores
    - Test with historical data to ensure valid predictions
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.9_
  
  - [x] 4.4 Create and test notification timing prompt template
    - Create `backend/resources/prompts/notification.txt`
    - Define engagement pattern analysis and optimal time output format
    - Test with sample engagement data to ensure valid timing recommendations
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.8_


- [x] 5. Implement recommendation engine
  - [x] 5.1 Create RecommendationService with personalized recommendation logic
    - Create `backend/app/Services/AI/RecommendationService.php` extending AIService
    - Implement `generateRecommendations(User $user, int $limit = 5)` method
    - Gather customer context (history, location, preferences) and fetch available services
    - Build prompt using PromptBuilder, send to Ollama, parse response
    - Store recommendations in database and return Recommendation DTOs
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10_
  
  - [x] 5.2 Create RecommendationController with API endpoints
    - Create `backend/app/Http/Controllers/API/V1/AI/RecommendationController.php`
    - Implement `index()` method for GET /api/v1/customer/recommendations
    - Implement `feedback()` method for POST /api/v1/customer/recommendations/feedback
    - Add authentication middleware and rate limiting
    - _Requirements: 8.1, 8.6, 8.7, 8.8, 8.10_
  
  - [x] 5.3 Add recommendation routes in Laravel
    - Open `backend/routes/api.php`
    - Add recommendation routes under customer middleware group
    - Test routes with Postman/curl to verify accessibility
    - _Requirements: 8.1, 8.6_
  
  - [x] 5.4 Create AIRecommendation Eloquent model
    - Create `backend/app/Models/AIRecommendation.php`
    - Define relationships (user, service)
    - Add scopes for active recommendations and methods for tracking interactions
    - _Requirements: 2.10_


- [ ] 6. Implement service matching system
  - [x] 6.1 Create MatchingService with match scoring logic
    - Create `backend/app/Services/AI/MatchingService.php` extending AIService
    - Implement `calculateMatchScores(Booking $booking)` method
    - Gather booking requirements and fetch eligible providers
    - Build matching prompt, send to Ollama, parse scores
    - Store match scores in database and return MatchScore DTOs
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_
  
  - [x] 6.2 Create MatchingController with API endpoints
    - Create `backend/app/Http/Controllers/API/V1/AI/MatchingController.php`
    - Implement `getMatchScore()` for GET /api/v1/provider/bookings/{id}/match-score
    - Implement `findMatches()` for GET /api/v1/customer/providers/matches
    - Add authentication and authorization checks
    - _Requirements: 8.2, 8.6, 8.7, 8.8_
  
  - [x] 6.3 Integrate matching into booking flow
    - Open `backend/app/Http/Controllers/API/V1/Customer/BookingController.php`
    - Add match score calculation after booking creation
    - Queue match score job for async processing
    - Store match score ID in booking
    - _Requirements: 3.1, 3.10_


- [ ] 7. Implement predictive analytics for admin dashboard
  - [x] 7.1 Create AnalyticsService with predictive analytics logic
    - Create `backend/app/Services/AI/AnalyticsService.php` extending AIService
    - Implement `predictBookingVolume(int $days = 7)` method
    - Implement `identifyTrends()`, `predictChurnRisk()`, and `forecastRevenue(int $days = 30)` methods
    - Fetch historical data, build analytics prompts, parse predictions with confidence scores
    - Store in ai_predictions table
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10_
  
  - [x] 7.2 Create AnalyticsController with API endpoints
    - Create `backend/app/Http/Controllers/API/V1/AI/AnalyticsController.php`
    - Implement `predictions()` for GET /api/v1/admin/analytics/predictions
    - Implement `trends()` for GET /api/v1/admin/analytics/trends
    - Implement `insights()` for GET /api/v1/admin/analytics/insights
    - Add admin authentication and return predictions with confidence scores
    - _Requirements: 8.3, 8.4, 8.6, 8.7, 8.8_
  
  - [x] 7.3 Create analytics scheduled job for daily generation
    - Create `backend/app/Console/Commands/GenerateAIAnalytics.php`
    - Implement analytics generation logic
    - Register command in Kernel.php and schedule to run daily at midnight
    - Test command execution
    - _Requirements: 4.8_


- [ ] 8. Implement smart notification timing optimization
  - [x] 8.1 Create SmartNotificationService with timing optimization logic
    - Create `backend/app/Services/AI/SmartNotificationService.php` extending AIService
    - Implement `determineOptimalTime(User $user, string $notificationType)` method
    - Analyze user engagement history and build notification timing prompt
    - Parse optimal time from response and store in notification_schedules table
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10_
  
  - [x] 8.2 Integrate with notification system
    - Locate existing notification sending logic
    - Add AI timing optimization before scheduling
    - Fall back to default times if AI unavailable
    - Track notification engagement (opens, clicks)
    - _Requirements: 5.6, 5.7, 5.9_
  
  - [-] 8.3 Create A/B testing framework for notification strategies
    - Add A/B test tracking to notification_schedules table
    - Randomly assign users to control/test groups
    - Track performance metrics by group
    - Create report endpoint for A/B results
    - _Requirements: 5.10_

- [x] 9. Create AI job queue system for async processing
  - [x] 9.1 Create AI job classes for queue processing
    - Create `backend/app/Jobs/AI/GenerateRecommendationsJob.php`
    - Create `backend/app/Jobs/AI/CalculateMatchScoresJob.php`
    - Create `backend/app/Jobs/AI/GenerateAnalyticsJob.php`
    - Implement job logic with retry logic and error handling
    - _Requirements: 1.8, 1.9_
  
  - [x] 9.2 Configure queue worker for AI jobs
    - Configure queue connection in config/queue.php
    - Set up Redis or database queue driver
    - Create supervisor config for queue worker
    - Start queue worker: `php artisan queue:work --queue=ai-processing`
    - Test job processing
    - _Requirements: 1.8, 1.9_

- [x] 10. Create AI health monitoring system
  - [x] 10.1 Create AIHealthController with health monitoring endpoints
    - Create `backend/app/Http/Controllers/API/V1/AI/AIHealthController.php`
    - Implement `health()` method for GET /api/v1/admin/ai/health
    - Implement `metrics()` method for GET /api/v1/admin/ai/metrics
    - Check Ollama connectivity and calculate success rates and response times
    - _Requirements: 8.5, 8.6, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8_
  
  - [x] 10.2 Add AI metrics to admin dashboard
    - Add AI metrics section to admin dashboard API
    - Show total AI requests, success rate, average response time, and Ollama uptime
    - Ensure metrics update in real-time
    - _Requirements: 9.8_

- [x] 11. Implement caching strategy for AI responses
  - [x] 11.1 Configure Redis cache for AI responses
    - Ensure Redis is available in Docker
    - Configure cache driver in .env: `CACHE_DRIVER=redis`
    - Test Redis connectivity
    - Configure cache TTL for different AI operations
    - _Requirements: 1.10_
  
  - [x] 11.2 Implement cache logic in all AI services
    - Add cache checks before AI requests
    - Store AI responses in cache with keys based on input hash
    - Set appropriate TTL per operation type
    - Test cache hit/miss behavior
    - _Requirements: 1.10_


- [ ]* 12. Write comprehensive tests for AI features
  - [ ]* 12.1 Create unit tests for AI services
    - Create test file for AIService with mocked Ollama responses
    - Test all AIService methods including error handling and retry logic
    - Run tests: `docker-compose exec app php artisan test`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_
  
  - [ ]* 12.2 Create integration tests for AI endpoints
    - Create test files for each AI controller
    - Test full request/response cycle, authentication, authorization, and error responses
    - Test rate limiting functionality
    - _Requirements: 8.6, 8.7, 8.8, 8.10_

- [x] 13. Create documentation for AI integration
  - [x] 13.1 Create API documentation for all AI endpoints
    - Create `AI_API_DOCUMENTATION.md`
    - Document each endpoint with examples, request/response formats, authentication requirements
    - Include error codes and troubleshooting information
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [x] 13.2 Create setup guide for Ollama configuration
    - Create `AI_SETUP_GUIDE.md`
    - Document Ollama installation, model loading, and environment configuration
    - Include troubleshooting section for common issues
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 14. Integrate AI features into Flutter app
  - [ ] 14.1 Create AI API service in Flutter
    - Create `lib/core/services/ai_api_service.dart`
    - Implement methods for each AI endpoint with error handling and response parsing
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  
  - [~] 14.2 Add recommendations to customer home screen
    - Open customer home screen and add recommendations section
    - Fetch recommendations from API and display in horizontal scrollable list
    - Add tap handlers to view service details and refresh functionality
    - _Requirements: 2.1, 2.6_
  
  - [~] 14.3 Add match scores to provider dashboard
    - Open provider bookings screen and fetch match scores for each booking
    - Display match score badge and show factor breakdown on tap
    - Sort bookings by match score
    - _Requirements: 3.1, 3.7_
  
  - [~] 14.4 Add analytics to admin dashboard
    - Open admin dashboard screen and add analytics section
    - Fetch predictions from API and display charts for predictions
    - Show confidence scores with visualizations
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.9_

- [ ] 15. Testing and optimization
  - [~] 15.1 End-to-end testing of all AI workflows
    - Test recommendation flow (customer requests → AI generates → display)
    - Test matching flow (booking created → scores calculated → provider sees)
    - Test analytics flow (data collected → predictions generated → admin views)
    - Test notification timing (user activity tracked → optimal time determined)
    - Document any issues found
    - _Requirements: 2.1, 2.6, 3.1, 3.8, 4.1, 4.8, 5.1_
  
  - [~] 15.2 Performance optimization of AI requests
    - Measure AI response times and identify slow operations
    - Optimize prompts for faster responses
    - Increase cache usage and tune queue worker settings
    - _Requirements: 2.6, 3.8, 9.1, 9.2_
  
  - [~] 15.3 Load testing of AI system
    - Use tool like Apache Bench or k6 to send concurrent requests
    - Monitor Ollama resource usage and queue performance
    - Identify bottlenecks and ensure system handles 50 concurrent requests
    - _Requirements: 9.1, 9.2, 9.3_

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements from the requirements document for traceability
- The AI infrastructure layer (tasks 1-4) must be completed before implementing specific AI services (tasks 5-8)
- Database migrations (task 3) should be completed early to support all AI features
- Prompt templates (task 4) are critical for AI quality and should be tested thoroughly
- Queue system (task 9) enables async processing and prevents blocking the main application
- Caching strategy (task 11) significantly improves performance and reduces Ollama load
- Flutter integration (task 14) can proceed in parallel once backend APIs are stable
- End-to-end testing (task 15) validates the complete system and identifies integration issues

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "3.1", "3.2", "3.3", "3.4"] },
    { "id": 2, "tasks": ["2.1", "2.2", "2.3", "2.4", "11.1"] },
    { "id": 3, "tasks": ["4.1", "4.2", "4.3", "4.4", "9.1", "11.2"] },
    { "id": 4, "tasks": ["5.1", "6.1", "7.1", "8.1", "9.2"] },
    { "id": 5, "tasks": ["5.4", "5.2", "6.2", "7.2", "10.1"] },
    { "id": 6, "tasks": ["5.3", "6.3", "7.3", "8.2", "10.2"] },
    { "id": 7, "tasks": ["8.3", "13.1", "13.2", "14.1"] },
    { "id": 8, "tasks": ["14.2", "14.3", "14.4"] },
    { "id": 9, "tasks": ["12.1", "12.2", "15.1"] },
    { "id": 10, "tasks": ["15.2", "15.3"] }
  ]
}
```
