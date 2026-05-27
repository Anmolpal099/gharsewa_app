# Tasks

## Task 1: Database Schema and Migration
**Requirements:** REQ-9 (Data Persistence)

Create database migration for `ai_consultations` table with proper schema, indexes, and foreign keys.

**Subtasks:**
- Create migration file for `ai_consultations` table
- Define table schema with UUID primary key, customer_id foreign key, image_path, markers JSON, AI response fields
- Add indexes on customer_id and created_at for query performance
- Add index on recommended_service_type for filtering
- Test migration up and down

**Acceptance Criteria:**
- Migration creates table with all required columns
- Foreign key constraint on customer_id references users table
- Indexes created for performance optimization
- Migration can be rolled back cleanly

---

## Task 2: AIConsultation Model
**Requirements:** REQ-9 (Data Persistence)

Create Eloquent model for AI consultations with relationships, casts, and accessors.

**Subtasks:**
- Create `AIConsultation` model class
- Define UUID primary key configuration
- Add `belongsTo` relationship to User model
- Add JSON casts for markers, recommended_providers, ai_response_raw
- Create `image_url` accessor to generate full URL
- Add scopes: `forCustomer()`, `recent()`, `byServiceType()`
- Add soft deletes support

**Acceptance Criteria:**
- Model properly handles UUID primary keys
- JSON fields automatically cast to arrays
- Relationships work correctly
- Scopes filter data as expected
- Soft deletes enabled

---

## Task 3: VisionAIService Class
**Requirements:** REQ-3 (AI Image Analysis), REQ-8 (Ollama Service Integration)

Create service class extending AIService to handle vision-specific AI operations.

**Subtasks:**
- Create `VisionAIService` class extending `AIService`
- Implement `analyzeImage()` method with image encoding and API call
- Implement `buildVisionPrompt()` to format markers into prompt
- Implement `parseVisionResponse()` to extract structured data from AI response
- Implement `findMatchingProviders()` to query providers by service type
- Implement `encodeImageToBase64()` for image encoding
- Add retry logic with exponential backoff (3 attempts)
- Add comprehensive error handling and logging

**Acceptance Criteria:**
- Service extends AIService base class
- Images encoded to base64 correctly
- Prompt includes all marker information
- AI response parsed into structured format
- Provider matching returns top 3 by rating
- Retry logic handles transient failures
- All errors logged appropriately


---

## Task 4: Request Validation Classes
**Requirements:** REQ-1 (Image Acquisition), REQ-2 (Visual Annotation)

Create form request classes for API endpoint validation.

**Subtasks:**
- Create `CreateConsultationRequest` class
- Add validation rules for image (base64, max 10MB)
- Add validation rules for markers array (min 1, max 10)
- Add validation rules for marker coordinates (x, y between 0 and 1)
- Add validation rules for marker descriptions (min 2, max 500 chars)
- Create custom `Base64Image` validation rule
- Add custom error messages

**Acceptance Criteria:**
- All validation rules enforce requirements
- Base64 image validation works correctly
- Marker count limits enforced
- Coordinate ranges validated
- Description length limits enforced
- Clear error messages returned

---

## Task 5: AIConsultationController - Create Endpoint
**Requirements:** REQ-1, REQ-2, REQ-3, REQ-4, REQ-5, REQ-6

Implement POST endpoint to create new consultation with AI analysis.

**Subtasks:**
- Create `AIConsultationController` class
- Implement `store()` method for POST `/api/v1/customer/ai/consultations`
- Decode base64 image and validate format
- Compress image if > 5MB
- Store image in customer-specific directory
- Call `VisionAIService::analyzeImage()`
- Query matching providers based on service type
- Create `AIConsultation` record in database
- Return structured response with consultation data
- Add comprehensive error handling
- Add rate limiting (10 requests per minute)

**Acceptance Criteria:**
- Endpoint accepts valid requests
- Image stored securely with unique filename
- AI analysis completes successfully
- Provider recommendations included
- Consultation saved to database
- Response matches API specification
- Rate limiting prevents abuse
- Errors handled gracefully


---

## Task 6: AIConsultationController - History Endpoints
**Requirements:** REQ-7 (Consultation History)

Implement GET endpoints for consultation history and details.

**Subtasks:**
- Implement `index()` method for GET `/api/v1/customer/ai/consultations`
- Add pagination support (default 20 per page, max 50)
- Add service_type filter parameter
- Implement `show()` method for GET `/api/v1/customer/ai/consultations/{id}`
- Add authorization check (customer can only view own consultations)
- Implement `destroy()` method for DELETE `/api/v1/customer/ai/consultations/{id}`
- Add soft delete functionality
- Return proper error responses for not found / unauthorized

**Acceptance Criteria:**
- History endpoint returns paginated results
- Filtering by service type works
- Detail endpoint returns full consultation data
- Authorization prevents cross-customer access
- Delete endpoint soft deletes consultation
- Proper HTTP status codes returned
- Response format matches specification

---

## Task 7: API Routes Registration
**Requirements:** All backend requirements

Register all AI consultation routes with proper middleware.

**Subtasks:**
- Add routes to `routes/api.php`
- Apply `auth:api` middleware for authentication
- Apply `throttle:10,1` rate limiting
- Group routes under `/v1/customer/ai/consultations` prefix
- Add route names for reference

**Acceptance Criteria:**
- All routes registered correctly
- Authentication middleware applied
- Rate limiting configured
- Routes accessible at correct URLs
- Route names follow convention

---

## Task 8: Image Storage Service
**Requirements:** REQ-9 (Data Persistence), REQ-14 (Security and Privacy)

Create service for secure image storage and retrieval.

**Subtasks:**
- Create `ConsultationImageService` class
- Implement `storeImage()` method with compression
- Implement `deleteImage()` method
- Implement `getImageUrl()` method
- Add image format validation (JPEG, PNG, HEIC)
- Add size validation and compression logic
- Generate unique filenames using UUID
- Create customer-specific directories
- Add error handling for storage failures

**Acceptance Criteria:**
- Images stored in secure location
- Compression works for images > 5MB
- Unique filenames prevent collisions
- Customer directories created automatically
- Image URLs generated correctly
- Old images can be deleted
- Storage errors handled gracefully


---

## Task 9: Cleanup Command
**Requirements:** REQ-7 (Consultation History - 12 month retention)

Create artisan command to clean up old consultations and images.

**Subtasks:**
- Create `CleanupOldConsultations` command
- Query consultations older than 12 months
- Delete associated image files
- Soft delete consultation records
- Add progress output
- Add dry-run option for testing
- Schedule command to run daily

**Acceptance Criteria:**
- Command deletes consultations older than 12 months
- Associated images removed from storage
- Progress displayed during execution
- Dry-run mode works correctly
- Command scheduled in bootstrap/app.php
- No errors when no old consultations exist

---

## Task 10: Backend Unit Tests
**Requirements:** All backend requirements

Create comprehensive unit tests for backend services and models.

**Subtasks:**
- Test `VisionAIService::analyzeImage()` with mocked Ollama
- Test `VisionAIService::parseVisionResponse()` with various inputs
- Test `VisionAIService::findMatchingProviders()` logic
- Test `AIConsultation` model relationships
- Test `AIConsultation` model scopes
- Test `ConsultationImageService` methods
- Test validation rules in `CreateConsultationRequest`
- Achieve >80% code coverage

**Acceptance Criteria:**
- All service methods tested
- Model relationships verified
- Validation rules tested
- Edge cases covered
- Mocking used appropriately
- Tests pass consistently
- Code coverage >80%

---

## Task 11: Backend Feature Tests
**Requirements:** All backend requirements

Create feature tests for API endpoints.

**Subtasks:**
- Test POST `/api/v1/customer/ai/consultations` success case
- Test POST with invalid image data
- Test POST with invalid markers
- Test POST without authentication
- Test GET `/api/v1/customer/ai/consultations` with pagination
- Test GET with service_type filter
- Test GET `/api/v1/customer/ai/consultations/{id}` success
- Test GET with unauthorized access
- Test DELETE `/api/v1/customer/ai/consultations/{id}`
- Test rate limiting enforcement

**Acceptance Criteria:**
- All endpoints tested
- Success and error cases covered
- Authentication tested
- Authorization tested
- Validation tested
- Rate limiting verified
- Tests use database transactions
- All tests pass


---

## Task 12: Flutter Data Models
**Requirements:** All Flutter requirements

Create data models for consultations and markers.

**Subtasks:**
- Create `DefectMarker` model class
- Add x, y, description, id properties
- Implement `toJson()` and `fromJson()` methods
- Create `AIConsultation` model class
- Add all required properties
- Implement `fromJson()` method
- Create `ProviderRecommendation` model class
- Add serialization methods
- Add proper null safety annotations

**Acceptance Criteria:**
- All models created with proper structure
- JSON serialization works correctly
- Null safety properly implemented
- Models match API response format
- Coordinate normalization handled

---

## Task 13: AI Consultation API Service
**Requirements:** REQ-3, REQ-7

Create Flutter service for API communication.

**Subtasks:**
- Create `AIConsultationApiService` class
- Implement `createConsultation()` method
- Implement `getConsultationHistory()` method with pagination
- Implement `getConsultationById()` method
- Implement `deleteConsultation()` method
- Add proper error handling with ApiException
- Add request/response logging
- Create Riverpod provider

**Acceptance Criteria:**
- All API methods implemented
- Base64 encoding handled correctly
- Pagination parameters passed correctly
- Errors converted to ApiException
- Provider created for dependency injection
- Methods return proper model types

---

## Task 14: State Management Providers
**Requirements:** All Flutter requirements

Create Riverpod providers for state management.

**Subtasks:**
- Create `CurrentConsultationState` class
- Create `CurrentConsultationNotifier` class
- Implement state methods: setImage, addMarker, removeMarker, submitConsultation
- Create `consultationHistoryProvider` FutureProvider
- Create `markersProvider` StateNotifierProvider
- Create `MarkersNotifier` class
- Add loading and error states
- Implement state persistence logic

**Acceptance Criteria:**
- All providers created
- State updates work correctly
- Loading states managed properly
- Error states handled
- Providers properly scoped
- State changes trigger UI updates


---

## Task 15: AI Assistant Home Screen
**Requirements:** REQ-10 (User Interface Navigation)

Create main entry screen for AI Visual Assistant feature.

**Subtasks:**
- Create `AIAssistantHomeScreen` widget
- Add app bar with title
- Create "New Consultation" button
- Create "View History" button
- Add info card explaining feature
- Add recent consultations preview section
- Implement navigation to capture and history screens
- Add loading state for recent consultations
- Style according to app theme

**Acceptance Criteria:**
- Screen displays correctly
- Navigation buttons work
- Recent consultations load and display
- Info card provides clear explanation
- UI matches design specifications
- Responsive layout

---

## Task 16: Image Capture Screen
**Requirements:** REQ-1 (Image Acquisition)

Create screen for capturing or selecting images.

**Subtasks:**
- Create `ImageCaptureScreen` widget
- Add "Take Photo" button with camera icon
- Add "Select from Gallery" button with gallery icon
- Integrate `image_picker` package
- Implement camera capture with quality settings
- Implement gallery selection
- Add image size validation (100KB - 10MB)
- Add format validation (JPEG, PNG, HEIC)
- Show error messages for validation failures
- Navigate to annotation editor on success
- Add permission handling for camera/gallery

**Acceptance Criteria:**
- Camera opens correctly
- Gallery picker works
- Image validation enforced
- Error messages clear
- Navigation works
- Permissions requested properly
- Works on Android and iOS

---

## Task 17: Annotation Canvas Widget
**Requirements:** REQ-2 (Visual Annotation)

Create custom widget for image annotation with markers.

**Subtasks:**
- Create `AnnotationCanvas` StatefulWidget
- Load and display image using dart:ui
- Implement `GestureDetector` for tap handling
- Calculate normalized coordinates from tap position
- Create `AnnotationPainter` CustomPainter
- Draw image scaled to canvas size
- Draw red circular markers at marker positions
- Draw marker numbers
- Add marker limit check (max 10)
- Implement marker selection on tap
- Add visual feedback for selected marker

**Acceptance Criteria:**
- Image displays correctly
- Tap adds marker at correct position
- Markers drawn as red circles
- Marker numbers visible
- Max 10 markers enforced
- Coordinates normalized correctly
- Canvas responsive to size changes
- Performance smooth with 10 markers


---

## Task 18: Annotation Editor Screen
**Requirements:** REQ-2 (Visual Annotation), REQ-10 (User Interface Navigation)

Create screen for annotating images with markers and descriptions.

**Subtasks:**
- Create `AnnotationEditorScreen` widget
- Add app bar with back button and submit button
- Integrate `AnnotationCanvas` widget
- Create marker list view below canvas
- Implement bottom sheet for marker description input
- Add description text field with 500 char limit
- Implement marker editing (tap existing marker)
- Implement marker deletion (swipe or button)
- Add validation (at least 1 marker required)
- Show marker count indicator
- Implement submit action with loading state
- Navigate to results screen on success

**Acceptance Criteria:**
- Canvas displays and works correctly
- Marker list shows all markers
- Description input works
- Marker editing functional
- Marker deletion works
- Validation prevents submission without markers
- Submit button triggers API call
- Loading state displayed during submission
- Navigation to results on success
- Error handling for API failures

---

## Task 19: Analysis Results Screen
**Requirements:** REQ-4 (Diagnosis and Recommendations), REQ-5 (Service Provider Matching), REQ-6 (Booking Integration)

Create screen to display AI analysis results.

**Subtasks:**
- Create `AnalysisResultsScreen` widget
- Add app bar with title
- Display image thumbnail with markers overlay
- Create diagnosis card with prominent styling
- Create service type card with icon
- Create cost estimate card (NPR range format)
- Create provider recommendation section
- Create `ProviderRecommendationCard` widget
- Add "Book Now" button for each provider
- Implement navigation to booking screen with pre-filled data
- Add "Start New Consultation" button
- Add loading overlay during analysis
- Show progress indicator with message
- Add timeout handling (30 seconds)

**Acceptance Criteria:**
- All result sections display correctly
- Diagnosis prominently shown
- Service type with appropriate icon
- Cost displayed as NPR range
- Provider cards show name, rating, services
- Book Now navigation works with pre-filled data
- Loading state shows during analysis
- Timeout handled gracefully
- UI matches design specifications
- Responsive layout


---

## Task 20: Consultation History Screen
**Requirements:** REQ-7 (Consultation History)

Create screen to view past consultations.

**Subtasks:**
- Create `ConsultationHistoryScreen` widget
- Add app bar with title
- Implement consultation list with pagination
- Create `ConsultationHistoryCard` widget
- Display thumbnail, diagnosis summary, service type, date
- Add pull-to-refresh functionality
- Add infinite scroll for pagination
- Implement service type filter
- Add search functionality (optional)
- Implement tap to view details
- Create detail view screen
- Add "Re-analyze" button in detail view
- Add "Delete" button with confirmation dialog
- Show empty state when no consultations

**Acceptance Criteria:**
- History list displays correctly
- Pagination loads more items on scroll
- Pull-to-refresh works
- Filter by service type functional
- Tap opens detail view
- Detail view shows full consultation data
- Re-analyze creates new consultation with same image
- Delete removes consultation after confirmation
- Empty state displayed appropriately
- Loading states handled

---

## Task 21: Error Handling and User Feedback
**Requirements:** REQ-11 (Error Handling and User Feedback)

Implement comprehensive error handling across all screens.

**Subtasks:**
- Create error dialog widgets for each error type
- Implement camera/gallery permission error handling
- Add "Open Settings" button for permission errors
- Implement image validation error messages
- Implement network error handling with retry
- Implement AI timeout error handling
- Add "Keep Waiting" / "Cancel" options for timeout
- Implement AI service unavailable error
- Implement generic error fallback
- Add error logging for debugging
- Create snackbar utility for non-critical errors
- Add error recovery flows

**Acceptance Criteria:**
- All error types handled
- Error messages clear and actionable
- Permission errors show settings option
- Network errors allow retry
- Timeout errors provide options
- Generic errors don't crash app
- Errors logged for debugging
- User can recover from errors
- Error UI consistent across app


---

## Task 22: Navigation Integration
**Requirements:** REQ-10 (User Interface Navigation)

Integrate AI Visual Assistant into app navigation.

**Subtasks:**
- Add route definitions for all screens
- Update customer panel navigation to include AI Assistant
- Add AI Assistant icon/button in customer home
- Implement deep linking for consultation details
- Add navigation guards for authentication
- Implement back button handling
- Add navigation transitions
- Update app routing configuration

**Acceptance Criteria:**
- All screens accessible via routes
- AI Assistant accessible from customer panel
- Deep links work correctly
- Authentication required for all screens
- Back button behavior correct
- Transitions smooth
- Navigation state preserved

---

## Task 23: Image Compression and Optimization
**Requirements:** REQ-12 (Performance and Responsiveness), REQ-13 (Image Quality and Format Handling)

Implement image compression and optimization.

**Subtasks:**
- Add image compression before upload
- Set max resolution to 1920x1920
- Set quality to 85%
- Maintain aspect ratio
- Convert HEIC to JPEG if needed
- Add base64 encoding
- Implement progress indicator during compression
- Add compression error handling
- Optimize memory usage during compression

**Acceptance Criteria:**
- Images compressed before upload
- Resolution limited to 1920x1920
- Quality set to 85%
- Aspect ratio maintained
- HEIC converted to JPEG
- Base64 encoding works
- Progress shown during compression
- Memory usage optimized
- No crashes with large images

---

## Task 24: Flutter Widget Tests
**Requirements:** All Flutter requirements

Create widget tests for UI components.

**Subtasks:**
- Test `AnnotationCanvas` marker placement
- Test `AnnotationPainter` rendering
- Test `ProviderRecommendationCard` display
- Test `ConsultationHistoryCard` display
- Test `AIAssistantHomeScreen` layout
- Test button interactions
- Test form validation
- Test error state displays
- Test loading state displays

**Acceptance Criteria:**
- All widgets tested
- Marker placement logic verified
- Rendering tested
- Interactions tested
- Validation tested
- States tested
- Tests pass consistently
- Good test coverage


---

## Task 25: Flutter Integration Tests
**Requirements:** All Flutter requirements

Create integration tests for complete workflows.

**Subtasks:**
- Test full consultation creation flow
- Test image capture to results
- Test annotation workflow
- Test history loading and viewing
- Test consultation deletion
- Test error scenarios
- Test network failure handling
- Test permission denial handling
- Mock API responses
- Mock image picker

**Acceptance Criteria:**
- Full workflows tested end-to-end
- Image capture flow tested
- Annotation flow tested
- History flow tested
- Error scenarios covered
- API responses mocked
- Tests run reliably
- All tests pass

---

## Task 26: Documentation
**Requirements:** All requirements

Create comprehensive documentation for the feature.

**Subtasks:**
- Write API documentation for new endpoints
- Document request/response formats
- Document error codes and messages
- Write Flutter integration guide
- Document state management architecture
- Create user guide for AI Visual Assistant
- Document deployment steps
- Create troubleshooting guide
- Add code comments
- Update main README

**Acceptance Criteria:**
- API fully documented
- Flutter architecture documented
- User guide clear and complete
- Deployment steps documented
- Troubleshooting guide helpful
- Code well-commented
- README updated
- Documentation accessible

---

## Task 27: Manual Testing and QA
**Requirements:** All requirements

Perform comprehensive manual testing across platforms.

**Subtasks:**
- Test on Android devices (multiple versions)
- Test on iOS devices (multiple versions)
- Test camera capture on both platforms
- Test gallery selection on both platforms
- Test with various image sizes and formats
- Test marker placement accuracy
- Test AI analysis with different image types
- Test provider recommendations
- Test history pagination
- Test all error scenarios
- Test permission flows
- Test network conditions (slow, offline)
- Test with real Ollama service
- Verify cost estimates are reasonable
- Test booking integration

**Acceptance Criteria:**
- All features work on Android
- All features work on iOS
- Camera and gallery work correctly
- Image validation works
- Marker placement accurate
- AI analysis produces good results
- Provider recommendations relevant
- History works correctly
- All errors handled properly
- Permissions work correctly
- Works in various network conditions
- Booking integration functional
- No critical bugs found

