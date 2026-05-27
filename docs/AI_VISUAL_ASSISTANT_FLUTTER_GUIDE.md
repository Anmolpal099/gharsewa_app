# AI Visual Assistant - Flutter Integration Guide

## Overview

This guide provides comprehensive documentation for the Flutter implementation of the AI Visual Assistant feature in the Gharsewa mobile app.

## Architecture

### Design Pattern

The implementation follows **Clean Architecture** principles with:
- **Presentation Layer**: UI screens and widgets
- **State Management**: Riverpod providers and notifiers
- **Data Layer**: Models, API services, and repositories
- **Domain Layer**: Business logic and use cases

### Directory Structure

```
lib/
├── data/
│   └── models/
│       ├── ai_consultation_model.dart
│       ├── defect_marker_model.dart
│       └── provider_recommendation_model.dart
├── services/
│   └── api/
│       └── ai_consultation_api_service.dart
└── presentation/
    └── panels/
        └── customer/
            └── ai_consultation/
                ├── screens/
                │   ├── ai_assistant_home_screen.dart
                │   ├── image_capture_screen.dart
                │   ├── annotation_editor_screen.dart
                │   ├── analysis_results_screen.dart
                │   └── consultation_history_screen.dart
                ├── widgets/
                │   ├── annotation_canvas.dart
                │   └── consultation_history_card.dart
                └── state/
                    ├── ai_consultation_providers.dart
                    ├── current_consultation_notifier.dart
                    ├── current_consultation_state.dart
                    ├── consultation_history_provider.dart
                    └── markers_notifier.dart
```

## Data Models

### DefectMarkerModel

Represents a visual marker placed on an image.

```dart
class DefectMarkerModel {
  final String id;              // Unique identifier (UUID)
  final double x;               // Normalized X coordinate (0.0-1.0)
  final double y;               // Normalized Y coordinate (0.0-1.0)
  final String description;     // Text description (2-500 chars)

  DefectMarkerModel({
    required this.id,
    required this.x,
    required this.y,
    required this.description,
  });

  // Factory constructor from JSON
  factory DefectMarkerModel.fromJson(Map<String, dynamic> json);
  
  // Convert to JSON for API requests
  Map<String, dynamic> toJson();
  
  // Create a copy with modified fields
  DefectMarkerModel copyWith({...});
}
```

**Key Points**:
- Coordinates are normalized (0.0 = left/top, 1.0 = right/bottom)
- ID is generated client-side using UUID
- Description validated for length (2-500 characters)

### AIConsultationModel

Represents a complete consultation with AI analysis results.

```dart
class AIConsultationModel {
  final String id;                                    // Server-generated UUID
  final String? imageUrl;                             // Full URL to image
  final List<DefectMarkerModel> markers;              // Defect markers
  final String diagnosis;                             // AI diagnosis text
  final String recommendedServiceType;                // Service category
  final double costMin;                               // Minimum cost (NPR)
  final double costMax;                               // Maximum cost (NPR)
  final List<ProviderRecommendationModel> providers;  // Recommended providers
  final int? processingTimeMs;                        // AI processing time
  final DateTime createdAt;                           // Creation timestamp

  AIConsultationModel({...});

  factory AIConsultationModel.fromJson(Map<String, dynamic> json);
}
```


### ProviderRecommendationModel

Represents a service provider recommendation.

```dart
class ProviderRecommendationModel {
  final String id;                  // Provider UUID
  final String name;                // Provider name
  final double rating;              // Average rating (0.0-5.0)
  final List<String> services;      // Services offered

  ProviderRecommendationModel({...});

  factory ProviderRecommendationModel.fromJson(Map<String, dynamic> json);
}
```

## API Service

### AIConsultationApiService

Handles all HTTP communication with the backend API.

**Location**: `lib/services/api/ai_consultation_api_service.dart`

#### Methods

##### createConsultation

Creates a new consultation with AI analysis.

```dart
Future<AIConsultationModel> createConsultation({
  required String imageBase64,
  required List<DefectMarkerModel> markers,
})
```

**Parameters**:
- `imageBase64`: Base64-encoded image string
- `markers`: List of 1-10 defect markers

**Returns**: `AIConsultationModel` with AI analysis results

**Throws**: `ApiException` on errors

**Example**:
```dart
final service = ref.read(aiConsultationApiServiceProvider);
final consultation = await service.createConsultation(
  imageBase64: base64Image,
  markers: markers,
);
```

##### getConsultationHistory

Retrieves paginated consultation history.

```dart
Future<ConsultationHistoryResponse> getConsultationHistory({
  int page = 1,
  int perPage = 20,
  String? serviceType,
})
```

**Parameters**:
- `page`: Page number (default: 1)
- `perPage`: Items per page (default: 20, max: 50)
- `serviceType`: Optional filter by service type

**Returns**: `ConsultationHistoryResponse` with consultations and pagination

##### getConsultationById

Retrieves a specific consultation by ID.

```dart
Future<AIConsultationModel> getConsultationById(String id)
```

**Parameters**:
- `id`: Consultation UUID

**Returns**: `AIConsultationModel` with full details

**Throws**: `ApiException` (404 if not found, 403 if unauthorized)

##### deleteConsultation

Soft deletes a consultation.

```dart
Future<void> deleteConsultation(String id)
```

**Parameters**:
- `id`: Consultation UUID

**Throws**: `ApiException` on errors

## State Management

### Riverpod Providers

#### aiConsultationApiServiceProvider

Provides the API service instance.

```dart
final aiConsultationApiServiceProvider = Provider<AIConsultationApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIConsultationApiService(apiClient);
});
```

#### currentConsultationProvider

Manages the current consultation workflow state.

```dart
final currentConsultationProvider = 
  StateNotifierProvider<CurrentConsultationNotifier, CurrentConsultationState>((ref) {
    final apiService = ref.watch(aiConsultationApiServiceProvider);
    return CurrentConsultationNotifier(apiService);
  });
```

**State**: `CurrentConsultationState`
- `imageFile`: Selected image file
- `imageBase64`: Base64-encoded image
- `markers`: List of defect markers
- `consultation`: AI analysis result
- `isSubmitting`: Loading state
- `error`: Error message

**Methods**:
- `setImage(File image)`: Set the selected image
- `addMarker(DefectMarkerModel marker)`: Add a defect marker
- `removeMarker(String markerId)`: Remove a marker
- `updateMarker(DefectMarkerModel marker)`: Update marker description
- `submitConsultation()`: Submit for AI analysis
- `reset()`: Clear all state


#### consultationHistoryProvider

Manages consultation history with pagination.

```dart
final consultationHistoryProvider = 
  StateNotifierProvider<ConsultationHistoryNotifier, ConsultationHistoryState>((ref) {
    final apiService = ref.watch(aiConsultationApiServiceProvider);
    return ConsultationHistoryNotifier(apiService);
  });
```

**State**: `ConsultationHistoryState`
- `consultations`: List of consultations
- `isLoading`: Loading state
- `error`: Error message
- `currentPage`: Current page number
- `hasMore`: Whether more pages exist

**Methods**:
- `loadHistory({String? serviceType})`: Load first page
- `loadMore()`: Load next page
- `refresh()`: Reload from first page
- `filterByServiceType(String? type)`: Apply filter

#### markersProvider

Manages markers during annotation.

```dart
final markersProvider = 
  StateNotifierProvider<MarkersNotifier, List<DefectMarkerModel>>((ref) {
    return MarkersNotifier();
  });
```

**Methods**:
- `addMarker(DefectMarkerModel marker)`: Add marker
- `removeMarker(String id)`: Remove marker
- `updateMarker(DefectMarkerModel marker)`: Update marker
- `clear()`: Remove all markers

## Screens

### 1. AIAssistantHomeScreen

**Route**: `/customer/ai-assistant`

**Purpose**: Entry point for AI Visual Assistant feature

**Features**:
- "New Consultation" button → Navigate to ImageCaptureScreen
- "View History" button → Navigate to ConsultationHistoryScreen
- Recent consultations preview (last 3)
- Feature explanation card

**State Dependencies**:
- `consultationHistoryProvider` (for recent consultations)

**Example Usage**:
```dart
Navigator.pushNamed(context, '/customer/ai-assistant');
```

### 2. ImageCaptureScreen

**Route**: `/customer/ai-assistant/capture`

**Purpose**: Capture or select images for analysis

**Features**:
- "Take Photo" button (opens camera)
- "Select from Gallery" button (opens gallery)
- Image validation (size, format)
- Permission handling

**Dependencies**:
- `image_picker` package
- Camera and photo library permissions

**Flow**:
1. User selects capture method
2. Image selected/captured
3. Validation performed
4. Navigate to AnnotationEditorScreen with image

**Example**:
```dart
final picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.camera,
  maxWidth: 1920,
  maxHeight: 1920,
  imageQuality: 85,
);
```

### 3. AnnotationEditorScreen

**Route**: `/customer/ai-assistant/annotate`

**Purpose**: Add markers and descriptions to image

**Features**:
- Interactive annotation canvas
- Tap to add markers (max 10)
- Marker list with descriptions
- Edit/delete markers
- Submit button

**State Dependencies**:
- `currentConsultationProvider`
- `markersProvider`

**Key Widgets**:
- `AnnotationCanvas`: Custom painter for image and markers
- Marker list view
- Description input dialog

**Flow**:
1. Display image in canvas
2. User taps to add markers
3. Description dialog appears
4. Markers shown in list
5. Submit triggers AI analysis
6. Navigate to AnalysisResultsScreen

### 4. AnalysisResultsScreen

**Route**: `/customer/ai-assistant/results`

**Purpose**: Display AI analysis results

**Features**:
- Image thumbnail with markers
- Diagnosis card (prominent)
- Service type card with icon
- Cost estimate (NPR range)
- Provider recommendations (top 3)
- "Book Now" buttons
- "Start New Consultation" button

**State Dependencies**:
- `currentConsultationProvider`

**Loading State**:
- Full-screen overlay
- Progress indicator
- "Analyzing your image..." message
- Timeout handling (30 seconds)

**Flow**:
1. Show loading during AI analysis
2. Display results when complete
3. User can book provider or start new consultation


### 5. ConsultationHistoryScreen

**Route**: `/customer/ai-assistant/history`

**Purpose**: View past consultations

**Features**:
- Paginated list of consultations
- Service type filter
- Pull-to-refresh
- Infinite scroll
- Tap to view details
- Delete consultation

**State Dependencies**:
- `consultationHistoryProvider`

**List Item**: `ConsultationHistoryCard`
- Thumbnail image
- Diagnosis summary (truncated)
- Service type badge
- Date
- Tap gesture

**Detail View**:
- Full consultation data
- "Re-analyze" button
- "Delete" button with confirmation

## Custom Widgets

### AnnotationCanvas

**Purpose**: Interactive canvas for image annotation

**Location**: `lib/presentation/panels/customer/ai_consultation/widgets/annotation_canvas.dart`

**Features**:
- Displays image scaled to fit
- Handles tap gestures
- Draws markers as red circles
- Shows marker numbers
- Converts tap coordinates to normalized values

**Key Implementation**:

```dart
class AnnotationCanvas extends StatefulWidget {
  final File imageFile;
  final List<DefectMarkerModel> markers;
  final Function(double x, double y) onTap;
  final Function(String markerId) onMarkerTap;

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
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;
    
    // Normalize coordinates
    final x = localPosition.dx / size.width;
    final y = localPosition.dy / size.height;
    
    widget.onTap(x, y);
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

**AnnotationPainter**:

```dart
class AnnotationPainter extends CustomPainter {
  final ui.Image? image;
  final List<DefectMarkerModel> markers;

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

    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final center = Offset(
        marker.x * size.width,
        marker.y * size.height,
      );

      // Draw circle
      canvas.drawCircle(center, 20, fillPaint);
      canvas.drawCircle(center, 20, markerPaint);

      // Draw number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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


### ConsultationHistoryCard

**Purpose**: Display consultation summary in list

**Location**: `lib/presentation/panels/customer/ai_consultation/widgets/consultation_history_card.dart`

**Features**:
- Thumbnail image with placeholder
- Diagnosis text (truncated to 2 lines)
- Service type badge
- Date formatted
- Tap gesture

**Example**:
```dart
ConsultationHistoryCard(
  consultation: consultation,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationDetailScreen(
          consultationId: consultation.id,
        ),
      ),
    );
  },
)
```

## Navigation Flow

```
AIAssistantHomeScreen
├── New Consultation
│   ├── ImageCaptureScreen
│   │   ├── Camera → Image
│   │   └── Gallery → Image
│   ├── AnnotationEditorScreen
│   │   ├── Add Markers
│   │   ├── Add Descriptions
│   │   └── Submit
│   └── AnalysisResultsScreen
│       ├── View Results
│       ├── Book Provider → BookingScreen
│       └── New Consultation → ImageCaptureScreen
└── View History
    └── ConsultationHistoryScreen
        ├── List View
        └── Detail View
            ├── Re-analyze → AnnotationEditorScreen
            └── Delete → Confirmation
```

## Error Handling

### Error Types

1. **Camera/Gallery Permission Denied**
   - Show dialog with "Open Settings" button
   - Use `permission_handler` package

2. **Image Validation Failed**
   - Show snackbar with specific error
   - Allow user to select different image

3. **Network Error**
   - Show dialog with "Retry" button
   - Check connectivity before retry

4. **AI Service Timeout**
   - Show dialog after 30 seconds
   - Options: "Keep Waiting" / "Cancel"

5. **AI Service Unavailable**
   - Show error message
   - Suggest trying again later

6. **Unauthorized Access**
   - Redirect to login
   - Show session expired message

### Error Handling Pattern

```dart
try {
  final consultation = await ref
      .read(currentConsultationProvider.notifier)
      .submitConsultation();
  
  // Navigate to results
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AnalysisResultsScreen(),
    ),
  );
} on ApiException catch (e) {
  // Handle API errors
  if (e.statusCode == 401) {
    // Unauthorized - redirect to login
    Navigator.pushReplacementNamed(context, '/login');
  } else if (e.statusCode == 429) {
    // Rate limit exceeded
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Too many requests. Please wait.')),
    );
  } else {
    // Generic error
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(e.message ?? 'An error occurred'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
} catch (e) {
  // Unexpected error
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Unexpected Error'),
      content: Text('Something went wrong. Please try again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

## Image Processing

### Compression

Images are compressed before upload to reduce bandwidth and processing time.

```dart
Future<String> _compressAndEncodeImage(File imageFile) async {
  // Read image
  final bytes = await imageFile.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    throw Exception('Failed to decode image');
  }
  
  // Resize if needed (max 1920x1920)
  img.Image resized = image;
  if (image.width > 1920 || image.height > 1920) {
    resized = img.copyResize(
      image,
      width: image.width > image.height ? 1920 : null,
      height: image.height > image.width ? 1920 : null,
    );
  }
  
  // Encode as JPEG with 85% quality
  final compressed = img.encodeJpg(resized, quality: 85);
  
  // Convert to base64
  return base64Encode(compressed);
}
```

### Format Conversion

HEIC images are converted to JPEG for compatibility.

```dart
Future<File> _convertHeicToJpeg(File heicFile) async {
  // Use image package to decode and re-encode
  final bytes = await heicFile.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    throw Exception('Failed to decode HEIC image');
  }
  
  final jpeg = img.encodeJpg(image, quality: 85);
  
  // Save to temporary file
  final tempDir = await getTemporaryDirectory();
  final jpegFile = File('${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await jpegFile.writeAsBytes(jpeg);
  
  return jpegFile;
}
```


## Testing

### Widget Tests

Test individual widgets in isolation.

**Example: AnnotationCanvas Test**

```dart
testWidgets('AnnotationCanvas displays markers correctly', (tester) async {
  final markers = [
    DefectMarkerModel(
      id: '1',
      x: 0.5,
      y: 0.5,
      description: 'Test marker',
    ),
  ];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AnnotationCanvas(
          imageFile: File('test_image.jpg'),
          markers: markers,
          onTap: (x, y) {},
          onMarkerTap: (id) {},
        ),
      ),
    ),
  );

  // Verify canvas is rendered
  expect(find.byType(CustomPaint), findsOneWidget);
});
```

### Integration Tests

Test complete workflows end-to-end.

**Example: Consultation Creation Flow**

```dart
testWidgets('Complete consultation creation flow', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: AIAssistantHomeScreen(),
      ),
    ),
  );

  // Tap New Consultation
  await tester.tap(find.text('New Consultation'));
  await tester.pumpAndSettle();

  // Verify navigation to ImageCaptureScreen
  expect(find.byType(ImageCaptureScreen), findsOneWidget);

  // Mock image selection
  // ... (mock image picker)

  // Verify navigation to AnnotationEditorScreen
  expect(find.byType(AnnotationEditorScreen), findsOneWidget);

  // Add marker
  await tester.tapAt(Offset(100, 100));
  await tester.pumpAndSettle();

  // Enter description
  await tester.enterText(find.byType(TextField), 'Test defect');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Submit consultation
  await tester.tap(find.text('Submit'));
  await tester.pumpAndSettle();

  // Verify navigation to results
  expect(find.byType(AnalysisResultsScreen), findsOneWidget);
});
```

### Unit Tests

Test business logic and state management.

**Example: CurrentConsultationNotifier Test**

```dart
test('addMarker adds marker to state', () {
  final notifier = CurrentConsultationNotifier(mockApiService);
  
  final marker = DefectMarkerModel(
    id: '1',
    x: 0.5,
    y: 0.5,
    description: 'Test',
  );

  notifier.addMarker(marker);

  expect(notifier.state.markers.length, 1);
  expect(notifier.state.markers.first, marker);
});

test('submitConsultation calls API and updates state', () async {
  final notifier = CurrentConsultationNotifier(mockApiService);
  
  // Set up state
  notifier.setImage(File('test.jpg'));
  notifier.addMarker(testMarker);

  // Mock API response
  when(mockApiService.createConsultation(any, any))
      .thenAnswer((_) async => mockConsultation);

  // Submit
  await notifier.submitConsultation();

  // Verify
  expect(notifier.state.consultation, mockConsultation);
  expect(notifier.state.isSubmitting, false);
  verify(mockApiService.createConsultation(any, any)).called(1);
});
```

## Performance Optimization

### Image Caching

Use `cached_network_image` for consultation history images.

```dart
CachedNetworkImage(
  imageUrl: consultation.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 200,
  memCacheHeight: 200,
)
```

### Lazy Loading

Implement pagination for consultation history.

```dart
ListView.builder(
  itemCount: consultations.length + (hasMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == consultations.length) {
      // Load more indicator
      return Center(child: CircularProgressIndicator());
    }
    return ConsultationHistoryCard(consultation: consultations[index]);
  },
  controller: _scrollController,
)

// In initState
_scrollController.addListener(() {
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent * 0.9) {
    ref.read(consultationHistoryProvider.notifier).loadMore();
  }
});
```

### Memory Management

Dispose of resources properly.

```dart
@override
void dispose() {
  _scrollController.dispose();
  _imageFile?.delete(); // Clean up temporary files
  super.dispose();
}
```

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  uuid: ^4.1.0
  image: ^4.1.3
  path_provider: ^2.1.1
  permission_handler: ^11.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
```

## Best Practices

### 1. State Management

- Use Riverpod for dependency injection
- Keep state immutable
- Use `copyWith` for state updates
- Dispose providers when not needed

### 2. Error Handling

- Always wrap API calls in try-catch
- Provide user-friendly error messages
- Log errors for debugging
- Handle network connectivity

### 3. Performance

- Compress images before upload
- Cache network images
- Implement pagination
- Dispose resources properly

### 4. Code Organization

- Follow feature-first structure
- Separate concerns (UI, state, data)
- Use meaningful names
- Document complex logic

### 5. Testing

- Write widget tests for UI
- Write unit tests for logic
- Write integration tests for flows
- Mock external dependencies

## Troubleshooting

### Issue: Markers not appearing on canvas

**Cause**: Coordinates not normalized or image not loaded

**Solution**:
- Ensure coordinates are between 0.0 and 1.0
- Wait for image to load before drawing
- Check `_image` is not null in painter

### Issue: Image too large error

**Cause**: Image exceeds 10MB limit

**Solution**:
- Implement compression before upload
- Reduce image quality or resolution
- Show error message to user

### Issue: State not updating

**Cause**: Not using `copyWith` or not notifying listeners

**Solution**:
```dart
// Wrong
state.markers.add(marker);

// Correct
state = state.copyWith(
  markers: [...state.markers, marker],
);
```

### Issue: Memory leaks

**Cause**: Not disposing controllers or providers

**Solution**:
- Dispose controllers in `dispose()`
- Use `autoDispose` for providers
- Clean up temporary files

---

**Version**: 1.0  
**Last Updated**: January 2024  
**For**: Gharsewa Mobile App - AI Visual Assistant Feature
