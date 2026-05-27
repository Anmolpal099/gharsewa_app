# Tasks 12 & 13: Flutter Data Models and API Service - COMPLETE ✅

## Overview
Created comprehensive Flutter data models and API service layer for AI Visual Assistant feature.

---

## Task 12: Flutter Data Models - COMPLETE ✅

### Files Created

#### 1. DefectMarkerModel
**File:** `lib/data/models/defect_marker_model.dart`

**Features:**
- Represents visual markers placed on images
- Normalized coordinates (0.0 to 1.0) for responsive rendering
- Validation methods for coordinates and descriptions
- Full JSON serialization support
- copyWith method for immutability
- Equality and hashCode overrides

**Properties:**
- `id`: Unique identifier
- `x`: Normalized X coordinate (0.0-1.0)
- `y`: Normalized Y coordinate (0.0-1.0)
- `description`: User-provided issue description

**Helper Methods:**
- `hasValidCoordinates`: Validates coordinate range
- `hasValidDescription`: Validates description length
- `isValid`: Overall validation check

#### 2. ProviderRecommendationModel
**File:** `lib/data/models/provider_recommendation_model.dart`

**Features:**
- Represents recommended service providers from AI analysis
- Rating and service information
- Contact details (phone, email)
- Profile image and location
- Booking history data
- Full JSON serialization support

**Properties:**
- `id`: Provider unique identifier
- `name`: Provider name
- `rating`: Average rating (0.0-5.0)
- `services`: List of offered services
- `phone`, `email`: Contact information
- `profileImage`: Profile image URL
- `location`: Provider address
- `completedBookings`: Number of completed jobs
- `isActive`: Provider availability status

**Helper Methods:**
- `formattedRating`: Rating as string (e.g., "4.5")
- `servicesText`: Comma-separated services
- `hasHighRating`: Check if rating >= 4.0
- `hasBookingHistory`: Check if has completed bookings

#### 3. AIConsultationModel
**File:** `lib/data/models/ai_consultation_model.dart`

**Features:**
- Main consultation model with complete AI analysis data
- Embedded markers and provider recommendations
- Cost estimation range
- Processing time tracking
- Soft delete support
- Comprehensive helper methods
- Full JSON serialization support

**Properties:**
- `id`: Consultation unique identifier
- `customerId`: Customer who created consultation
- `imagePath`: Stored image path
- `imageUrl`: Full URL to access image
- `markers`: List of DefectMarkerModel
- `diagnosis`: AI-generated diagnosis
- `recommendedServiceType`: Service category
- `estimatedCostMin/Max`: Cost range in NPR
- `recommendedProviders`: List of ProviderRecommendationModel
- `aiResponseRaw`: Raw AI response for debugging
- `processingTimeSeconds`: AI processing duration
- `createdAt`, `updatedAt`, `deletedAt`: Timestamps

**Helper Methods:**
- `costRangeFormatted`: "NPR 5,000 - 10,000"
- `markerCount`: Number of markers
- `hasRecommendedProviders`: Check if has providers
- `providerCount`: Number of providers
- `isDeleted`: Check if soft deleted
- `diagnosisSummary`: First 100 characters
- `formattedDate`: "May 26, 2024"
- `formattedTime`: "2:30 PM"
- `formattedProcessingTime`: "27.5s" or "1m 30s"
- `serviceTypeDisplayName`: "Plumbing" (Title Case)

#### 4. Barrel Export File
**File:** `lib/data/models/ai_consultation_models.dart`

Exports all AI consultation models for easy importing:
```dart
export 'ai_consultation_model.dart';
export 'defect_marker_model.dart';
export 'provider_recommendation_model.dart';
```

### Model Architecture

```
AIConsultationModel
├── markers: List<DefectMarkerModel>
│   ├── id, x, y, description
│   └── Validation methods
└── recommendedProviders: List<ProviderRecommendationModel>
    ├── id, name, rating, services
    ├── phone, email, profileImage
    └── location, completedBookings
```

### Usage Example

```dart
import 'package:gharsewa/data/models/ai_consultation_models.dart';

// Create a marker
final marker = DefectMarkerModel(
  id: '1',
  x: 0.5,
  y: 0.3,
  description: 'Water leak visible here',
);

// Parse consultation from API response
final consultation = AIConsultationModel.fromJson(jsonData);

// Access data
print(consultation.diagnosis);
print(consultation.costRangeFormatted); // "NPR 5,000 - 10,000"
print(consultation.formattedDate); // "May 26, 2024"

// Check providers
if (consultation.hasRecommendedProviders) {
  for (final provider in consultation.recommendedProviders) {
    print('${provider.name} - ${provider.formattedRating}');
  }
}
```

---

## Task 13: AI Consultation API Service - COMPLETE ✅

### Files Created

#### AIConsultationApiService
**File:** `lib/services/api/ai_consultation_api_service.dart`

**Features:**
- Complete API integration for AI consultations
- Base64 image encoding for uploads
- Pagination support for history
- Service type filtering
- Comprehensive error handling
- Riverpod provider for dependency injection

### API Methods

#### 1. createConsultation()
Creates a new AI consultation with image analysis.

**Parameters:**
- `imageFile`: File - The image to analyze
- `markers`: List<DefectMarkerModel> - Markers placed on image

**Returns:** `AIConsultationModel` - Created consultation with AI results

**Process:**
1. Reads image file bytes
2. Converts to base64 encoding
3. Sends POST request to `/v1/customer/ai/consultations`
4. Parses response and returns consultation model

**Error Handling:**
- Network errors
- Timeout errors
- Validation errors
- Server errors

**Example:**
```dart
final service = ref.read(aiConsultationApiServiceProvider);

try {
  final consultation = await service.createConsultation(
    imageFile: imageFile,
    markers: markers,
  );
  
  print('Diagnosis: ${consultation.diagnosis}');
  print('Cost: ${consultation.costRangeFormatted}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### 2. getConsultationHistory()
Fetches paginated consultation history.

**Parameters:**
- `page`: int - Page number (default: 1)
- `perPage`: int - Items per page (default: 20, max: 50)
- `serviceType`: String? - Optional filter by service type

**Returns:** `ConsultationHistoryResponse` - Paginated results

**Response includes:**
- `consultations`: List of consultations
- `currentPage`: Current page number
- `lastPage`: Total pages
- `perPage`: Items per page
- `total`: Total consultations
- Helper methods: `hasNextPage`, `isFirstPage`, `nextPage`, etc.

**Example:**
```dart
final response = await service.getConsultationHistory(
  page: 1,
  perPage: 20,
  serviceType: 'plumbing',
);

print('Total: ${response.total}');
print('Page: ${response.currentPage}/${response.lastPage}');

for (final consultation in response.consultations) {
  print(consultation.diagnosisSummary);
}

if (response.hasNextPage) {
  // Load next page
  final nextResponse = await service.getConsultationHistory(
    page: response.nextPage!,
  );
}
```

#### 3. getConsultationById()
Fetches a specific consultation by ID.

**Parameters:**
- `id`: String - Consultation ID

**Returns:** `AIConsultationModel` - Full consultation details

**Example:**
```dart
final consultation = await service.getConsultationById('consultation-id');
print('Diagnosis: ${consultation.diagnosis}');
print('Providers: ${consultation.providerCount}');
```

#### 4. deleteConsultation()
Soft deletes a consultation.

**Parameters:**
- `id`: String - Consultation ID

**Returns:** `String` - Success message

**Example:**
```dart
final message = await service.deleteConsultation('consultation-id');
print(message); // "Consultation deleted successfully"
```

### ConsultationHistoryResponse

Helper class for paginated responses with useful methods:

**Properties:**
- `consultations`: List<AIConsultationModel>
- `currentPage`: int
- `lastPage`: int
- `perPage`: int
- `total`: int

**Helper Methods:**
- `hasNextPage`: bool - Check if more pages available
- `isFirstPage`: bool - Check if on first page
- `isLastPage`: bool - Check if on last page
- `nextPage`: int? - Get next page number
- `previousPage`: int? - Get previous page number
- `isEmpty`: bool - Check if no consultations
- `isNotEmpty`: bool - Check if has consultations

### Riverpod Integration

**Provider:**
```dart
final aiConsultationApiServiceProvider = Provider<AIConsultationApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIConsultationApiService(apiClient);
});
```

**Usage in Widgets:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(aiConsultationApiServiceProvider);
    
    // Use service methods
    return FutureBuilder(
      future: service.getConsultationHistory(),
      builder: (context, snapshot) {
        // Build UI
      },
    );
  }
}
```

### Error Handling

All methods throw `ApiException` with:
- `message`: User-friendly error message
- `type`: ApiExceptionType (network, timeout, client, server, etc.)
- `statusCode`: HTTP status code (if available)

**Error Types:**
- `network`: No internet connection
- `timeout`: Request timed out
- `client`: Client error (4xx)
- `server`: Server error (5xx)
- `cancelled`: Request cancelled
- `unknown`: Unknown error

**Example Error Handling:**
```dart
try {
  final consultation = await service.createConsultation(
    imageFile: file,
    markers: markers,
  );
} on ApiException catch (e) {
  switch (e.type) {
    case ApiExceptionType.network:
      showSnackbar('No internet connection');
      break;
    case ApiExceptionType.timeout:
      showSnackbar('Request timed out. Please try again.');
      break;
    case ApiExceptionType.client:
      showSnackbar(e.message); // Show validation errors
      break;
    case ApiExceptionType.server:
      showSnackbar('Server error. Please try again later.');
      break;
    default:
      showSnackbar('An error occurred');
  }
}
```

### Integration with Backend

**API Endpoints:**
- POST `/v1/customer/ai/consultations` - Create consultation
- GET `/v1/customer/ai/consultations` - Get history
- GET `/v1/customer/ai/consultations/{id}` - Get details
- DELETE `/v1/customer/ai/consultations/{id}` - Delete consultation

**Authentication:**
- All requests require JWT authentication
- Automatic token refresh on 401 errors
- Customer role required

**Rate Limiting:**
- 10 requests per minute for create endpoint
- Standard rate limits for other endpoints

### Testing Considerations

**Unit Tests:**
- Test JSON serialization/deserialization
- Test model validation methods
- Test helper methods
- Mock API responses

**Integration Tests:**
- Test API service methods with mocked HTTP client
- Test error handling scenarios
- Test pagination logic
- Test base64 encoding

**Widget Tests:**
- Test UI components with mock data
- Test loading states
- Test error states
- Test empty states

---

## Acceptance Criteria - All Met ✅

### Task 12: Flutter Data Models
- ✅ DefectMarker model created with x, y, description, id
- ✅ toJson() and fromJson() methods implemented
- ✅ AIConsultation model created with all properties
- ✅ fromJson() method implemented
- ✅ ProviderRecommendation model created
- ✅ Serialization methods added
- ✅ Null safety properly implemented
- ✅ Models match API response format
- ✅ Coordinate normalization handled
- ✅ Helper methods for formatting and validation

### Task 13: AI Consultation API Service
- ✅ AIConsultationApiService class created
- ✅ createConsultation() method implemented
- ✅ getConsultationHistory() method with pagination
- ✅ getConsultationById() method implemented
- ✅ deleteConsultation() method implemented
- ✅ Error handling with ApiException
- ✅ Request/response logging (via ApiClient)
- ✅ Riverpod provider created
- ✅ Base64 encoding handled correctly
- ✅ Pagination parameters passed correctly
- ✅ Methods return proper model types

---

## Status: COMPLETE ✅

**Completion Date:** May 26, 2024
**Files Created:** 5 files
**Lines of Code:** ~800 lines
**Test Coverage:** Ready for testing

---

## Next Steps

### Task 14: State Management Providers
- Create CurrentConsultationState and Notifier
- Create consultation history provider
- Create markers provider
- Implement state persistence

### Task 15-20: UI Screens
- AI Assistant Home Screen
- Image Capture Screen
- Annotation Canvas Widget
- Annotation Editor Screen
- Analysis Results Screen
- Consultation History Screen

### Task 21-23: Additional Features
- Error handling and user feedback
- Navigation integration
- Image compression and optimization

### Task 24-25: Testing
- Flutter widget tests
- Flutter integration tests

### Task 26-27: Documentation and QA
- Documentation
- Manual testing and QA

---

**Progress Update:**
- Backend: 7/11 tasks complete (63.6%)
- Flutter: 2/16 tasks complete (12.5%)
- Overall: 9/27 tasks complete (33.3%)
