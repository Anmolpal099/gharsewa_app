# Design Document: AI Visual Assistant

## 1. Overview

The AI Visual Assistant feature enables customers to diagnose home service issues through AI-powered image analysis. The system integrates with the existing Ollama service running Qwen 3.5 Vision model (qwen3-vl:2b) to analyze images with visual annotations and provide comprehensive recommendations including diagnosis, service type, cost estimates, and provider suggestions.

### 1.1 Architecture Principles

- **Extend Existing Patterns**: Leverage the existing AIService base class and API client architecture
- **Separation of Concerns**: Backend handles AI processing and data persistence; Flutter handles UI and image capture
- **Stateless API**: RESTful endpoints with JWT authentication
- **Async Processing**: AI analysis runs asynchronously with progress tracking
- **Data Privacy**: Customer images stored securely with access control

### 1.2 Technology Stack

**Backend:**
- Laravel 11 (PHP 8.2+)
- MySQL 8.0+ (database)
- Ollama service (qwen3-vl:2b model)
- Laravel Storage (image file management)

**Frontend:**
- Flutter 3.x
- Riverpod (state management)
- image_picker package (camera/gallery access)
- Custom annotation editor widget

## 2. Database Schema

### 2.1 New Table: `ai_consultations`

Stores customer consultation records with images, annotations, and AI responses.

```sql
CREATE TABLE ai_consultations (
    id CHAR(36) PRIMARY KEY,
    customer_id CHAR(36) NOT NULL,
    image_path VARCHAR(500) NOT NULL,
    image_size_kb INT UNSIGNED NOT NULL,
    markers JSON NOT NULL COMMENT 'Array of {x, y, description}',
    ai_diagnosis TEXT NOT NULL,
    recommended_service_type VARCHAR(100) NOT NULL,
    cost_min DECIMAL(10, 2) NOT NULL,
    cost_max DECIMAL(10, 2) NOT NULL,
    recommended_providers JSON NULL COMMENT 'Array of provider IDs',
    ai_response_raw JSON NOT NULL COMMENT 'Full AI response for reference',
    processing_time_ms INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_customer_created (customer_id, created_at DESC),
    INDEX idx_service_type (recommended_service_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```


### 2.2 Markers JSON Structure

```json
[
  {
    "x": 0.45,
    "y": 0.32,
    "description": "Water leaking from pipe joint"
  },
  {
    "x": 0.67,
    "y": 0.58,
    "description": "Rust visible on metal surface"
  }
]
```

**Notes:**
- `x` and `y` are normalized coordinates (0.0 to 1.0) relative to image dimensions
- Allows up to 10 markers per image
- Each marker has a text description (max 500 characters)

### 2.3 AI Response Raw JSON Structure

```json
{
  "diagnosis": "Plumbing leak with corrosion damage",
  "service_type": "Plumbing Repair",
  "cost_estimate": {
    "min": 2000,
    "max": 5000,
    "currency": "NPR"
  },
  "recommended_providers": [
    {
      "id": "uuid-1",
      "name": "Expert Plumbers",
      "rating": 4.8,
      "match_score": 0.95
    }
  ],
  "confidence": 0.87,
  "model": "qwen3-vl:2b",
  "processing_time_ms": 27000
}
```

## 3. Backend Architecture

### 3.1 New Service Class: `VisionAIService`

Extends the existing `AIService` base class to handle vision-specific operations.

**Location:** `backend/app/Services/AI/VisionAIService.php`

**Key Methods:**

```php
class VisionAIService extends AIService
{
    /**
     * Analyze image with markers and descriptions
     * 
     * @param string $imagePath - Path to uploaded image
     * @param array $markers - Array of marker objects with x, y, description
     * @return AIResponse - Structured response with diagnosis and recommendations
     */
    public function analyzeImage(string $imagePath, array $markers): AIResponse;
    
    /**
     * Build prompt for vision model
     * 
     * @param array $markers - Marker data
     * @return string - Formatted prompt
     */
    private function buildVisionPrompt(array $markers): string;
    
    /**
     * Parse AI response into structured format
     * 
     * @param string $rawResponse - Raw AI text response
     * @return array - Structured data with diagnosis, service_type, cost, providers
     */
    private function parseVisionResponse(string $rawResponse): array;
    
    /**
     * Find matching providers for service type
     * 
     * @param string $serviceType - Service category
     * @param int $limit - Number of providers to return
     * @return array - Top providers with ratings
     */
    private function findMatchingProviders(string $serviceType, int $limit = 3): array;
    
    /**
     * Encode image to base64 for Ollama API
     * 
     * @param string $imagePath - Path to image file
     * @return string - Base64 encoded image
     */
    private function encodeImageToBase64(string $imagePath): string;
}
```

### 3.2 New Model: `AIConsultation`

**Location:** `backend/app/Models/AIConsultation.php`

**Key Properties:**
- UUID primary key
- Relationships: `belongsTo(User::class, 'customer_id')`
- Casts: `markers` (array), `recommended_providers` (array), `ai_response_raw` (array)
- Accessors: `image_url` (generates full URL for image)
- Scopes: `forCustomer($customerId)`, `recent()`, `byServiceType($type)`


### 3.3 New Controller: `AIConsultationController`

**Location:** `backend/app/Http/Controllers/API/V1/Customer/AIConsultationController.php`

**Endpoints:**

#### POST `/api/v1/customer/ai/consultations`
Create new consultation with image analysis

**Request:**
```json
{
  "image": "<base64_encoded_image>",
  "markers": [
    {"x": 0.45, "y": 0.32, "description": "Water leak"},
    {"x": 0.67, "y": 0.58, "description": "Rust"}
  ]
}
```

**Validation:**
- `image`: required, base64 string, max 10MB decoded
- `markers`: required, array, min 1, max 10
- `markers.*.x`: required, numeric, between 0 and 1
- `markers.*.y`: required, numeric, between 0 and 1
- `markers.*.description`: required, string, min 2, max 500

**Response (201):**
```json
{
  "success": true,
  "message": "Consultation created successfully",
  "data": {
    "consultation": {
      "id": "uuid",
      "image_url": "https://...",
      "markers": [...],
      "diagnosis": "Plumbing leak with corrosion",
      "recommended_service_type": "Plumbing Repair",
      "cost_min": 2000,
      "cost_max": 5000,
      "recommended_providers": [
        {
          "id": "uuid",
          "name": "Expert Plumbers",
          "rating": 4.8,
          "services": ["Plumbing Repair"]
        }
      ],
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```


#### GET `/api/v1/customer/ai/consultations`
Get consultation history for authenticated customer

**Query Parameters:**
- `page`: integer, default 1
- `per_page`: integer, min 1, max 50, default 20
- `service_type`: string, optional filter

**Response (200):**
```json
{
  "success": true,
  "data": {
    "consultations": [
      {
        "id": "uuid",
        "image_url": "https://...",
        "diagnosis": "Brief diagnosis",
        "recommended_service_type": "Plumbing Repair",
        "cost_min": 2000,
        "cost_max": 5000,
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 45,
      "last_page": 3
    }
  }
}
```

#### GET `/api/v1/customer/ai/consultations/{id}`
Get detailed consultation by ID

**Response (200):**
```json
{
  "success": true,
  "data": {
    "consultation": {
      "id": "uuid",
      "image_url": "https://...",
      "markers": [...],
      "diagnosis": "Full diagnosis text",
      "recommended_service_type": "Plumbing Repair",
      "cost_min": 2000,
      "cost_max": 5000,
      "recommended_providers": [...],
      "processing_time_ms": 27000,
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```


#### DELETE `/api/v1/customer/ai/consultations/{id}`
Delete a consultation (soft delete)

**Response (200):**
```json
{
  "success": true,
  "message": "Consultation deleted successfully"
}
```

### 3.4 Request Validation

**Location:** `backend/app/Http/Requests/AI/CreateConsultationRequest.php`

```php
class CreateConsultationRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'image' => ['required', 'string', new Base64Image(maxSizeKb: 10240)],
            'markers' => ['required', 'array', 'min:1', 'max:10'],
            'markers.*.x' => ['required', 'numeric', 'between:0,1'],
            'markers.*.y' => ['required', 'numeric', 'between:0,1'],
            'markers.*.description' => ['required', 'string', 'min:2', 'max:500'],
        ];
    }
}
```

### 3.5 Image Storage Strategy

**Storage Path:** `storage/app/public/consultations/{customer_id}/{uuid}.jpg`

**Process:**
1. Decode base64 image
2. Validate format (JPEG, PNG, HEIC)
3. Compress if > 5MB (maintain aspect ratio)
4. Generate unique filename using UUID
5. Store in customer-specific directory
6. Save path to database
7. Return public URL

**Cleanup:** Images older than 12 months deleted via scheduled command


## 4. Frontend Architecture (Flutter)

### 4.1 Feature Structure

```
lib/features/ai_visual_assistant/
├── data/
│   ├── models/
│   │   ├── ai_consultation.dart
│   │   ├── defect_marker.dart
│   │   └── consultation_response.dart
│   ├── repositories/
│   │   └── ai_consultation_repository.dart
│   └── services/
│       └── ai_consultation_api_service.dart
├── domain/
│   └── providers/
│       ├── ai_consultation_provider.dart
│       └── consultation_history_provider.dart
└── presentation/
    ├── screens/
    │   ├── ai_assistant_home_screen.dart
    │   ├── image_capture_screen.dart
    │   ├── annotation_editor_screen.dart
    │   ├── analysis_results_screen.dart
    │   └── consultation_history_screen.dart
    └── widgets/
        ├── annotation_canvas.dart
        ├── marker_list_item.dart
        ├── provider_recommendation_card.dart
        └── consultation_history_card.dart
```

### 4.2 Data Models

#### `DefectMarker`

```dart
class DefectMarker {
  final double x;  // Normalized 0.0 to 1.0
  final double y;  // Normalized 0.0 to 1.0
  final String description;
  final String id;  // Local UUID for UI management
  
  DefectMarker({
    required this.x,
    required this.y,
    required this.description,
    String? id,
  }) : id = id ?? Uuid().v4();
  
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'description': description,
  };
  
  factory DefectMarker.fromJson(Map<String, dynamic> json) => DefectMarker(
    x: json['x'].toDouble(),
    y: json['y'].toDouble(),
    description: json['description'],
  );
}
```


#### `AIConsultation`

```dart
class AIConsultation {
  final String id;
  final String imageUrl;
  final List<DefectMarker> markers;
  final String diagnosis;
  final String recommendedServiceType;
  final double costMin;
  final double costMax;
  final List<ProviderRecommendation> recommendedProviders;
  final int? processingTimeMs;
  final DateTime createdAt;
  
  AIConsultation({
    required this.id,
    required this.imageUrl,
    required this.markers,
    required this.diagnosis,
    required this.recommendedServiceType,
    required this.costMin,
    required this.costMax,
    required this.recommendedProviders,
    this.processingTimeMs,
    required this.createdAt,
  });
  
  factory AIConsultation.fromJson(Map<String, dynamic> json) {
    return AIConsultation(
      id: json['id'],
      imageUrl: json['image_url'],
      markers: (json['markers'] as List)
          .map((m) => DefectMarker.fromJson(m))
          .toList(),
      diagnosis: json['diagnosis'],
      recommendedServiceType: json['recommended_service_type'],
      costMin: json['cost_min'].toDouble(),
      costMax: json['cost_max'].toDouble(),
      recommendedProviders: (json['recommended_providers'] as List)
          .map((p) => ProviderRecommendation.fromJson(p))
          .toList(),
      processingTimeMs: json['processing_time_ms'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```


#### `ProviderRecommendation`

```dart
class ProviderRecommendation {
  final String id;
  final String name;
  final double rating;
  final List<String> services;
  final double? matchScore;
  
  ProviderRecommendation({
    required this.id,
    required this.name,
    required this.rating,
    required this.services,
    this.matchScore,
  });
  
  factory ProviderRecommendation.fromJson(Map<String, dynamic> json) {
    return ProviderRecommendation(
      id: json['id'],
      name: json['name'],
      rating: json['rating'].toDouble(),
      services: List<String>.from(json['services'] ?? []),
      matchScore: json['match_score']?.toDouble(),
    );
  }
}
```

### 4.3 API Service

**Location:** `lib/features/ai_visual_assistant/data/services/ai_consultation_api_service.dart`

```dart
class AIConsultationApiService {
  final ApiClient _apiClient;
  
  AIConsultationApiService(this._apiClient);
  
  Future<AIConsultation> createConsultation({
    required String imageBase64,
    required List<DefectMarker> markers,
  }) async {
    final response = await _apiClient.post(
      '/v1/customer/ai/consultations',
      data: {
        'image': imageBase64,
        'markers': markers.map((m) => m.toJson()).toList(),
      },
    );
    
    return AIConsultation.fromJson(response.data['data']['consultation']);
  }
  
  Future<List<AIConsultation>> getConsultationHistory({
    int page = 1,
    int perPage = 20,
    String? serviceType,
  }) async {
    final response = await _apiClient.get(
      '/v1/customer/ai/consultations',
      params: {
        'page': page,
        'per_page': perPage,
        if (serviceType != null) 'service_type': serviceType,
      },
    );
    
    final consultations = response.data['data']['consultations'] as List;
    return consultations.map((c) => AIConsultation.fromJson(c)).toList();
  }
  
  Future<AIConsultation> getConsultationById(String id) async {
    final response = await _apiClient.get(
      '/v1/customer/ai/consultations/$id',
    );
    
    return AIConsultation.fromJson(response.data['data']['consultation']);
  }
  
  Future<void> deleteConsultation(String id) async {
    await _apiClient.delete('/v1/customer/ai/consultations/$id');
  }
}
```


### 4.4 State Management (Riverpod)

#### Providers

```dart
// API Service Provider
final aiConsultationApiServiceProvider = Provider<AIConsultationApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIConsultationApiService(apiClient);
});

// Current Consultation State Provider
final currentConsultationProvider = StateNotifierProvider<CurrentConsultationNotifier, CurrentConsultationState>((ref) {
  final apiService = ref.watch(aiConsultationApiServiceProvider);
  return CurrentConsultationNotifier(apiService);
});

// Consultation History Provider
final consultationHistoryProvider = FutureProvider.autoDispose<List<AIConsultation>>((ref) async {
  final apiService = ref.watch(aiConsultationApiServiceProvider);
  return apiService.getConsultationHistory();
});

// Markers State Provider (for annotation editor)
final markersProvider = StateNotifierProvider<MarkersNotifier, List<DefectMarker>>((ref) {
  return MarkersNotifier();
});
```

#### State Classes

```dart
class CurrentConsultationState {
  final File? imageFile;
  final String? imageBase64;
  final List<DefectMarker> markers;
  final AIConsultation? result;
  final bool isLoading;
  final String? error;
  
  CurrentConsultationState({
    this.imageFile,
    this.imageBase64,
    this.markers = const [],
    this.result,
    this.isLoading = false,
    this.error,
  });
  
  CurrentConsultationState copyWith({...}) => ...;
}
```


### 4.5 UI Screens

#### 4.5.1 AI Assistant Home Screen

**Route:** `/customer/ai-assistant`

**Layout:**
- App bar with title "AI Visual Assistant"
- Two primary action buttons:
  - "New Consultation" → Navigate to Image Capture Screen
  - "View History" → Navigate to Consultation History Screen
- Info card explaining the feature
- Recent consultations preview (last 3)

#### 4.5.2 Image Capture Screen

**Route:** `/customer/ai-assistant/capture`

**Layout:**
- App bar with back button
- Two large buttons:
  - "Take Photo" (camera icon) → Opens camera
  - "Select from Gallery" (gallery icon) → Opens gallery picker
- Uses `image_picker` package
- On image selected → Navigate to Annotation Editor Screen

**Implementation:**
```dart
Future<void> _captureImage(ImageSource source) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: source,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );
  
  if (image != null) {
    // Validate image size
    final bytes = await image.readAsBytes();
    final sizeKb = bytes.length / 1024;
    
    if (sizeKb < 100 || sizeKb > 10240) {
      // Show error
      return;
    }
    
    // Navigate to annotation editor
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AnnotationEditorScreen(imageFile: File(image.path)),
    ));
  }
}
```


#### 4.5.3 Annotation Editor Screen

**Route:** `/customer/ai-assistant/annotate`

**Layout:**
- App bar with back button and "Submit" action button
- Custom `AnnotationCanvas` widget displaying image
- Marker list below canvas showing all markers with descriptions
- Floating action button to add new marker
- Bottom sheet for entering marker description

**Key Widget: AnnotationCanvas**

```dart
class AnnotationCanvas extends StatefulWidget {
  final File imageFile;
  final List<DefectMarker> markers;
  final Function(DefectMarker) onMarkerAdded;
  final Function(String markerId) onMarkerRemoved;
  
  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  ui.Image? _image;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() => _image = frame.image);
  }
  
  void _handleTap(TapDownDetails details) {
    if (widget.markers.length >= 10) {
      // Show max markers error
      return;
    }
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;
    
    // Normalize coordinates
    final x = localPosition.dx / size.width;
    final y = localPosition.dy / size.height;
    
    // Show description dialog
    _showDescriptionDialog(x, y);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: CustomPaint(
        painter: AnnotationPainter(
          image: _image,
          markers: widget.markers,
        ),
        child: Container(),
      ),
    );
  }
}
```


**Custom Painter:**

```dart
class AnnotationPainter extends CustomPainter {
  final ui.Image? image;
  final List<DefectMarker> markers;
  
  AnnotationPainter({this.image, required this.markers});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    
    // Draw image
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
    
    // Draw markers
    final markerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final fillPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    for (final marker in markers) {
      final center = Offset(marker.x * size.width, marker.y * size.height);
      canvas.drawCircle(center, 20, fillPaint);
      canvas.drawCircle(center, 20, markerPaint);
      
      // Draw marker number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${markers.indexOf(marker) + 1}',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.markers != markers || oldDelegate.image != image;
  }
}
```


#### 4.5.4 Analysis Results Screen

**Route:** `/customer/ai-assistant/results`

**Layout:**
- App bar with "AI Diagnosis" title
- Image thumbnail with markers overlay
- Diagnosis card (prominent, colored background)
- Service type card with icon
- Cost estimate card (NPR range)
- Recommended providers section:
  - List of 3 provider cards
  - Each card shows: name, rating, "Book Now" button
- Bottom action buttons:
  - "Start New Consultation"
  - "Save to History" (auto-saved, just confirmation)

**Loading State:**
- Full-screen loading overlay
- Progress indicator
- Text: "Analyzing your image... This may take up to 30 seconds"
- Animated AI icon

#### 4.5.5 Consultation History Screen

**Route:** `/customer/ai-assistant/history`

**Layout:**
- App bar with "Consultation History" title
- Search/filter bar (by service type)
- List of consultation cards:
  - Thumbnail image
  - Diagnosis summary (truncated)
  - Service type badge
  - Date
  - Tap to view details
- Pull-to-refresh
- Pagination (load more on scroll)
- Empty state: "No consultations yet"

**Detail View:**
- Full consultation details
- Same layout as Results Screen
- Additional: "Re-analyze" button
- "Delete" button (with confirmation)


### 4.6 Navigation Flow

```
AI Assistant Home
├── New Consultation
│   ├── Image Capture
│   │   ├── Take Photo → Camera
│   │   └── Select Gallery → Gallery Picker
│   ├── Annotation Editor
│   │   ├── Add Markers (tap on image)
│   │   ├── Add Descriptions (bottom sheet)
│   │   └── Submit → Analysis
│   └── Analysis Results
│       ├── View Diagnosis
│       ├── View Providers
│       ├── Book Now → Booking Screen
│       └── Start New → Image Capture
└── View History
    ├── Consultation List
    └── Consultation Detail
        ├── Re-analyze → Annotation Editor
        └── Delete → Confirmation Dialog
```

### 4.7 Error Handling

**Error Types:**

1. **Camera/Gallery Access Denied**
   - Show dialog: "Camera permission required"
   - Button: "Open Settings"

2. **Image Validation Failed**
   - Show snackbar: "Image must be between 100KB and 10MB"
   - Allow retry

3. **Network Error**
   - Show dialog: "No internet connection"
   - Button: "Retry"

4. **AI Service Timeout**
   - Show dialog: "Analysis is taking longer than expected"
   - Buttons: "Keep Waiting" / "Cancel"

5. **AI Service Unavailable**
   - Show dialog: "AI service temporarily unavailable"
   - Button: "Try Again Later"

6. **Unexpected Error**
   - Show dialog: "Something went wrong"
   - Buttons: "Retry" / "Contact Support"


## 5. AI Prompt Engineering

### 5.1 Vision Prompt Template

```
You are an expert home service diagnostic assistant. Analyze the provided image with the following defect markers:

{markers_list}

Based on the image and marked defects, provide a structured diagnosis in the following JSON format:

{
  "diagnosis": "Brief description of the problem (50-500 characters)",
  "service_type": "One of: Plumbing Repair, Electrical Work, Carpentry, Painting, Cleaning, Appliance Repair, HVAC, Pest Control, Landscaping, General Maintenance",
  "cost_estimate": {
    "min": <minimum cost in NPR>,
    "max": <maximum cost in NPR>
  },
  "confidence": <confidence score 0.0 to 1.0>
}

Guidelines:
- Diagnosis should be clear and actionable
- Service type must match one of the listed categories
- Cost estimates should be realistic for Nepal market (NPR 500 - 50000)
- Maximum should be at least 1.5x minimum
- If uncertain, use default range NPR 1000-5000 and confidence < 0.5
```

### 5.2 Markers List Format

```
Marker 1 at position (45%, 32%): Water leaking from pipe joint
Marker 2 at position (67%, 58%): Rust visible on metal surface
```

### 5.3 Response Parsing Strategy

1. Extract JSON from AI response (handle markdown code blocks)
2. Validate required fields exist
3. Validate service_type against known categories
4. Validate cost_min and cost_max are positive numbers
5. Apply fallback values if validation fails:
   - diagnosis: "Unable to determine specific issue"
   - service_type: "General Maintenance"
   - cost_min: 1000, cost_max: 5000
   - confidence: 0.3


## 6. Security Considerations

### 6.1 Authentication & Authorization

- All endpoints require JWT authentication
- Customer can only access their own consultations
- Image URLs use signed URLs with expiration (optional enhancement)

### 6.2 Input Validation

- Image size limits enforced (100KB - 10MB)
- Base64 validation before decoding
- Marker count limit (max 10)
- Description length limit (max 500 chars)
- Coordinate validation (0.0 - 1.0 range)

### 6.3 File Storage Security

- Images stored outside public web root
- Access controlled via Laravel Storage
- Customer-specific directories prevent cross-access
- Unique filenames prevent enumeration attacks

### 6.4 Rate Limiting

- API endpoints rate limited: 10 requests per minute per user
- Prevents abuse of expensive AI operations

### 6.5 Data Privacy

- Images and consultations deleted after 12 months
- No sharing with third parties
- HTTPS required for all API calls
- Image data not logged in application logs

## 7. Performance Optimization

### 7.1 Backend

- Image compression before storage (if > 5MB)
- Database indexes on customer_id and created_at
- Pagination for history queries
- Caching of provider recommendations (5 minutes)
- Async AI processing with job queue (optional enhancement)

### 7.2 Frontend

- Image compression before upload (max 1920x1920, 85% quality)
- Lazy loading of consultation history
- Cached network images
- Optimistic UI updates
- Debounced search/filter inputs


## 8. Testing Strategy

### 8.1 Backend Tests

**Unit Tests:**
- `VisionAIService::analyzeImage()` - Mock Ollama responses
- `VisionAIService::parseVisionResponse()` - Test JSON parsing
- `VisionAIService::findMatchingProviders()` - Test provider matching logic
- `AIConsultation` model - Test relationships and accessors

**Feature Tests:**
- POST `/api/v1/customer/ai/consultations` - Test creation flow
- GET `/api/v1/customer/ai/consultations` - Test pagination and filtering
- GET `/api/v1/customer/ai/consultations/{id}` - Test authorization
- DELETE `/api/v1/customer/ai/consultations/{id}` - Test soft delete

**Integration Tests:**
- Full consultation workflow with real Ollama service
- Image upload, storage, and retrieval
- Provider recommendation accuracy

### 8.2 Frontend Tests

**Unit Tests:**
- `DefectMarker` model - Test serialization
- `AIConsultation` model - Test fromJson parsing
- Coordinate normalization logic

**Widget Tests:**
- `AnnotationCanvas` - Test marker placement
- `AnnotationPainter` - Test rendering
- `ProviderRecommendationCard` - Test UI rendering

**Integration Tests:**
- Full consultation flow from image capture to results
- History loading and pagination
- Error handling scenarios

### 8.3 Manual Testing Checklist

- [ ] Camera capture on Android/iOS
- [ ] Gallery selection on Android/iOS
- [ ] Image validation (size, format)
- [ ] Marker placement accuracy
- [ ] Description input and editing
- [ ] AI analysis with various image types
- [ ] Provider recommendations relevance
- [ ] History pagination
- [ ] Delete consultation
- [ ] Network error handling
- [ ] Permission denied scenarios


## 9. Deployment Considerations

### 9.1 Database Migration

```bash
php artisan make:migration create_ai_consultations_table
php artisan migrate
```

### 9.2 Storage Setup

```bash
php artisan storage:link
mkdir -p storage/app/public/consultations
chmod -R 775 storage/app/public/consultations
```

### 9.3 Environment Variables

```env
# Ollama Configuration (already configured)
OLLAMA_HOST=http://gharsewa_ollama:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=60

# AI Consultation Settings
AI_CONSULTATION_MAX_IMAGE_SIZE_KB=10240
AI_CONSULTATION_MAX_MARKERS=10
AI_CONSULTATION_RETENTION_DAYS=365
```

### 9.4 Scheduled Tasks

Add to `bootstrap/app.php` or scheduler:

```php
// Clean up old consultations (older than 12 months)
$schedule->command('ai:cleanup-consultations')->daily();
```

### 9.5 Flutter Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.0
  uuid: ^4.0.0
  cached_network_image: ^3.3.0
```

### 9.6 Monitoring

- Log AI request failures
- Monitor AI response times
- Track consultation creation rate
- Alert on high error rates
- Monitor storage usage for images


## 10. Future Enhancements

### 10.1 Phase 2 Features

1. **Real-time Streaming Analysis**
   - Stream AI responses as they generate
   - Show partial results during processing

2. **Multi-Image Consultations**
   - Allow multiple images per consultation
   - Compare before/after images

3. **Voice Descriptions**
   - Record audio descriptions instead of text
   - Transcribe using speech-to-text

4. **AR Marker Placement**
   - Use AR to place 3D markers in real space
   - Better spatial understanding

5. **Provider Chat Integration**
   - Direct chat with recommended providers
   - Share consultation details in chat

6. **Cost Breakdown**
   - Detailed cost breakdown by task
   - Material vs labor cost split

7. **Booking Pre-fill**
   - Auto-create booking from consultation
   - Pre-fill all details from AI analysis

8. **Analytics Dashboard**
   - Most common issues
   - Average costs by service type
   - Provider recommendation accuracy

### 10.2 Technical Improvements

1. **Async Processing**
   - Queue AI analysis jobs
   - WebSocket notifications for completion

2. **Image Optimization**
   - WebP format support
   - Progressive image loading
   - Thumbnail generation

3. **Caching Strategy**
   - Cache similar consultations
   - Reduce duplicate AI calls

4. **Model Fine-tuning**
   - Train on Gharsewa-specific data
   - Improve accuracy for local context

## 11. Success Metrics

- **Adoption Rate**: % of customers using AI Visual Assistant
- **Consultation Completion Rate**: % of started consultations that complete
- **Booking Conversion Rate**: % of consultations leading to bookings
- **AI Accuracy**: User feedback on diagnosis accuracy
- **Response Time**: Average AI processing time
- **Error Rate**: % of failed consultations
- **User Satisfaction**: Rating of AI recommendations

