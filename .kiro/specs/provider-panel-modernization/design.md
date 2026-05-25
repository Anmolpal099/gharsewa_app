# Design Document: Provider Panel Modernization

## Overview

The Provider Panel Modernization feature transforms the service provider experience in the Gharsewa Flutter application by implementing a modern Material Design 3 interface inspired by the Servicely app. This comprehensive redesign focuses on five key areas:

1. **Enhanced Profile Management**: Professional profile with photo, bio, skills, certifications, and performance metrics
2. **Modernized Dashboard**: Earnings analytics with charts, AI-powered suggestions, and quick actions
3. **Smart Request Management**: Streamlined booking request handling with counter-offer capabilities
4. **AI Safety Center**: Job-specific safety checklists and Standard Operating Procedures (SOPs)
5. **Intuitive Navigation**: Bottom navigation with four key sections for efficient workflow

The design emphasizes visual appeal through gradient cards, smooth animations, and responsive layouts while maintaining high performance and accessibility standards. The architecture separates concerns between UI components, business logic services, and data management layers to ensure maintainability and testability.

### Key Design Principles

- **Provider-Centric**: Every feature designed to help providers manage their business efficiently
- **Visual Excellence**: Material Design 3 with gradients, animations, and modern aesthetics
- **Performance First**: Fast load times, smooth animations, and efficient data handling
- **Offline Capability**: Critical features like saved SOPs work without internet
- **Accessibility**: WCAG AA compliance for inclusive user experience

## Architecture

### High-Level Architecture

The Provider Panel follows a layered architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Screens, Widgets, Navigation, Animations)             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   Business Logic Layer                   │
│  (Services, Managers, State Management)                 │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  (API Client, Local Storage, Cache)                     │
└─────────────────────────────────────────────────────────┘
```

### Architecture Components

#### Presentation Layer
- **Screens**: Dashboard, Profile, Bookings, Safety Center
- **Widgets**: Reusable UI components (cards, chips, charts, dialogs)
- **Navigation**: Bottom navigation controller with state preservation
- **Animations**: Transition controllers and animation builders

#### Business Logic Layer
- **Profile Manager**: Handles profile CRUD operations and validation
- **Skill Manager**: Manages skill additions, removals, and display
- **Certification Manager**: Handles document uploads and verification status
- **Earnings Analyzer**: Calculates earnings metrics and trends
- **Request Manager**: Manages booking requests and responses
- **AI Suggestion Engine**: Generates personalized tips and safety SOPs
- **Performance Tracker**: Tracks and calculates provider metrics
- **Safety Center**: Manages SOP generation and storage

#### Data Layer
- **API Client**: HTTP client with authentication and error handling
- **Local Storage**: Hive database for offline data (SOPs, cached profiles)
- **Cache Manager**: In-memory cache for frequently accessed data
- **Document Uploader**: Multipart file upload with progress tracking

### State Management Strategy

The application uses **Provider** (or **Riverpod**) for state management with the following patterns:

- **ChangeNotifier Providers**: For mutable state (profile data, earnings, requests)
- **FutureProvider**: For async data fetching (API calls)
- **StreamProvider**: For real-time updates (new booking requests)
- **StateNotifier**: For complex state transitions (request status changes)

### Navigation Architecture

Bottom navigation with four main sections:

```
┌──────────┬──────────┬──────────────┬──────────┐
│ Explore  │ Bookings │ Safety Center│ Profile  │
│ (Home)   │          │              │          │
└──────────┴──────────┴──────────────┴──────────┘
```

Each section maintains its own navigation stack to preserve state when switching tabs.

## Components and Interfaces

### Core Components

#### 1. Profile Manager

**Responsibility**: Manages provider profile data, updates, and validation.

**Interface**:
```dart
class ProfileManager extends ChangeNotifier {
  Future<ProviderProfile> fetchProfile(String providerId);
  Future<void> updateProfile(ProviderProfile profile);
  Future<void> updateProfilePhoto(File imageFile);
  Future<void> updateBio(String bio);
  double calculateProfileCompleteness(ProviderProfile profile);
  bool validateBio(String bio); // 50-500 characters
  bool validateProfilePhoto(File file); // JPG/PNG, <5MB
}
```

**Dependencies**: API Client, Cache Manager, Document Uploader

#### 2. Skill Manager

**Responsibility**: Manages technical skills with dynamic add/remove operations.

**Interface**:
```dart
class SkillManager extends ChangeNotifier {
  Future<List<String>> fetchSkills(String providerId);
  Future<void> addSkill(String providerId, String skill);
  Future<void> removeSkill(String providerId, String skill);
  bool validateSkill(String skill); // 3-50 characters
  bool isDuplicateSkill(String skill, List<String> existingSkills);
}
```

**Dependencies**: API Client, Cache Manager

#### 3. Certification Manager

**Responsibility**: Handles certification document uploads and verification status.

**Interface**:
```dart
class CertificationManager extends ChangeNotifier {
  Future<List<Certification>> fetchCertifications(String providerId);
  Future<Certification> uploadCertification(String providerId, File file, String name);
  Future<void> deleteCertification(String certificationId);
  bool validateCertificationFile(File file); // PDF/PNG/JPG, <10MB
}
```

**Dependencies**: Document Uploader, API Client

#### 4. Earnings Analyzer

**Responsibility**: Calculates earnings metrics, trends, and percentage changes.

**Interface**:
```dart
class EarningsAnalyzer extends ChangeNotifier {
  Future<EarningsData> fetchEarnings(String providerId, DateRange range);
  double calculatePercentageChange(double current, double previous);
  List<EarningsDataPoint> getDailyEarnings(DateTime startDate, int days);
  List<EarningsDataPoint> getWeeklyEarnings(DateTime startDate, int weeks);
  String formatCurrency(double amount, String locale);
}
```

**Dependencies**: API Client, Cache Manager

#### 5. Request Manager

**Responsibility**: Manages booking requests with accept/decline/counter operations.

**Interface**:
```dart
class RequestManager extends ChangeNotifier {
  Stream<List<BookingRequest>> watchPendingRequests(String providerId);
  Future<void> acceptRequest(String requestId);
  Future<void> declineRequest(String requestId, String reason);
  Future<void> sendCounterOffer(String requestId, double price, String message);
  List<BookingRequest> sortRequestsByDate(List<BookingRequest> requests);
  List<BookingRequest> filterUrgentRequests(List<BookingRequest> requests);
}
```

**Dependencies**: API Client, Notification Service

#### 6. AI Suggestion Engine

**Responsibility**: Generates personalized optimization tips and safety SOPs.

**Interface**:
```dart
class AISuggestionEngine {
  Future<List<Suggestion>> generateProfileSuggestions(ProviderProfile profile, PerformanceMetrics metrics);
  Future<List<Suggestion>> generateDashboardSuggestions(PerformanceMetrics metrics);
  Future<SafetySOP> generateSafetySOP(String jobType);
  List<Suggestion> prioritizeSuggestions(List<Suggestion> suggestions);
}
```

**Dependencies**: API Client (AI service endpoint)

#### 7. Performance Tracker

**Responsibility**: Tracks and calculates provider performance metrics.

**Interface**:
```dart
class PerformanceTracker extends ChangeNotifier {
  Future<PerformanceMetrics> fetchMetrics(String providerId);
  double calculateAverageResponseTime(List<BookingRequest> requests);
  bool isTopPerformer(double rating, double percentile);
  String formatResponseTime(Duration duration);
  Color getResponseTimeColor(Duration duration);
}
```

**Dependencies**: API Client, Cache Manager

#### 8. Safety Center

**Responsibility**: Manages SOP generation, storage, and offline access.

**Interface**:
```dart
class SafetyCenter extends ChangeNotifier {
  Future<SafetySOP> generateSOP(String jobType);
  Future<void> saveSOP(SafetySOP sop);
  Future<List<SafetySOP>> fetchSavedSOPs();
  Future<void> deleteSOP(String sopId);
  List<SafetySOP> searchSOPs(String query);
  Future<void> syncSOPs(); // Sync with backend when online
}
```

**Dependencies**: AI Suggestion Engine, Local Storage (Hive)

#### 9. Document Uploader

**Responsibility**: Handles file uploads with validation and progress tracking.

**Interface**:
```dart
class DocumentUploader {
  Future<String> uploadFile(File file, String endpoint, {Function(double)? onProgress});
  bool validateFileType(File file, List<String> allowedTypes);
  bool validateFileSize(File file, int maxSizeBytes);
  Future<File> compressImage(File imageFile);
}
```

**Dependencies**: HTTP Client, Image Compression Library

#### 10. Chart Renderer

**Responsibility**: Renders earnings charts with animations and interactions.

**Interface**:
```dart
class ChartRenderer extends StatelessWidget {
  Widget buildBarChart(List<EarningsDataPoint> data, ChartConfig config);
  Widget buildEmptyState();
  BarChartData createBarChartData(List<EarningsDataPoint> data);
  FlTitlesData createTitlesData(List<EarningsDataPoint> data);
}
```

**Dependencies**: fl_chart library

#### 11. Navigation Controller

**Responsibility**: Manages bottom navigation and screen routing.

**Interface**:
```dart
class NavigationController extends ChangeNotifier {
  int currentIndex;
  void navigateToTab(int index);
  void navigateToScreen(String route, {Object? arguments});
  bool canPop();
  void pop();
}
```

**Dependencies**: Flutter Navigator

### UI Components

#### Reusable Widgets

1. **GradientCard**: Card with gradient background for visual appeal
2. **SkillChip**: Chip widget for displaying skills with remove option
3. **MetricCard**: Card displaying a single metric with icon and value
4. **RequestCard**: Card displaying booking request details with action buttons
5. **SuggestionCard**: Card displaying AI suggestions with dismiss option
6. **VerifiedBadge**: Badge widget showing verification status
7. **EarningsChart**: Bar chart widget for earnings visualization
8. **QuickActionButton**: Button for quick access features
9. **ProfileHeader**: Header component with photo, name, and verification badge
10. **EmptyState**: Widget for displaying empty list states

## Data Models

### ProviderProfile

```dart
class ProviderProfile {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final String location;
  final String professionalCategory;
  final bool isVerified;
  final List<String> skills;
  final List<Certification> certifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed property
  double get completeness {
    int score = 0;
    if (photoUrl != null) score += 25;
    if (bio != null && bio!.length >= 50) score += 25;
    if (skills.length >= 3) score += 25;
    if (certifications.isNotEmpty) score += 25;
    return score.toDouble();
  }
}
```

### Certification

```dart
class Certification {
  final String id;
  final String name;
  final String documentUrl;
  final String fileType; // PDF, PNG, JPG
  final bool isVerified;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;
}
```

### EarningsData

```dart
class EarningsData {
  final double totalEarnings;
  final double previousPeriodEarnings;
  final List<EarningsDataPoint> dataPoints;
  final DateRange dateRange;
  final EarningsViewType viewType; // daily or weekly
  
  double get percentageChange {
    if (previousPeriodEarnings == 0) return 0;
    return ((totalEarnings - previousPeriodEarnings) / previousPeriodEarnings) * 100;
  }
  
  bool get isPositiveChange => percentageChange > 0;
}
```

### EarningsDataPoint

```dart
class EarningsDataPoint {
  final DateTime date;
  final double amount;
  final String label; // e.g., "Mon", "Week 1"
}
```

### BookingRequest

```dart
class BookingRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String customerLocation;
  final String serviceTitle;
  final String description;
  final double proposedPrice;
  final DateTime scheduledDateTime;
  final DateTime createdAt;
  final BookingRequestStatus status;
  final bool isUrgent; // scheduled within 24 hours
  
  Duration get timeElapsed => DateTime.now().difference(createdAt);
}
```

### BookingRequestStatus

```dart
enum BookingRequestStatus {
  pending,
  accepted,
  declined,
  counterOffered,
  expired
}
```

### PerformanceMetrics

```dart
class PerformanceMetrics {
  final double rating; // 0.0 to 5.0
  final int totalReviews;
  final int jobsCompleted;
  final Duration averageResponseTime;
  final bool isTopPerformer; // top 10%
  final double percentile;
}
```

### Suggestion

```dart
class Suggestion {
  final String id;
  final String title;
  final String description;
  final SuggestionType type;
  final SuggestionPriority priority;
  final DateTime createdAt;
  final DateTime? dismissedAt;
}
```

### SuggestionType

```dart
enum SuggestionType {
  profileImprovement,
  performanceOptimization,
  availabilityAdjustment,
  pricingStrategy
}
```

### SuggestionPriority

```dart
enum SuggestionPriority {
  high,
  medium,
  low
}
```

### SafetySOP

```dart
class SafetySOP {
  final String id;
  final String jobType;
  final String content; // Markdown formatted
  final List<String> hazards;
  final List<String> requiredPPE;
  final List<String> procedures;
  final List<String> emergencyProtocols;
  final DateTime generatedAt;
  final bool isSaved;
}
```

### CounterOffer

```dart
class CounterOffer {
  final String id;
  final String requestId;
  final double originalPrice;
  final double counterPrice;
  final String? message;
  final DateTime createdAt;
  final CounterOfferStatus status;
}
```

### CounterOfferStatus

```dart
enum CounterOfferStatus {
  pending,
  accepted,
  rejected
}
```

### ChartConfig

```dart
class ChartConfig {
  final Color barColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final double barWidth;
  final bool showGrid;
  final bool enableTouch;
  final Duration animationDuration;
}
```

### DateRange

```dart
class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  
  int get daysDifference => endDate.difference(startDate).inDays;
}
```

### EarningsViewType

```dart
enum EarningsViewType {
  daily,
  weekly
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

This feature is primarily UI-focused with Material Design 3 components, navigation, and visual interactions. However, it contains several pure business logic functions that benefit from property-based testing. The properties below focus on validation logic, calculations, formatting functions, and data transformations—areas where universal properties can verify correctness across a wide input space.

### Property 1: Bio Validation Boundary

*For any* string input, the bio validation function SHALL return true if and only if the string length is between 50 and 500 characters (inclusive).

**Validates: Requirements 1.4**

### Property 2: Skill Name Validation Boundary

*For any* string input, the skill name validation function SHALL return true if and only if the string length is between 3 and 50 characters (inclusive).

**Validates: Requirements 2.3**

### Property 3: Skill Capacity Limit

*For any* list of skills, the Skill Manager SHALL accept the addition of a new skill if and only if the current skill count is less than 20.

**Validates: Requirements 2.6**

### Property 4: Response Time Formatting Threshold

*For any* duration value, the response time formatting function SHALL return a string with "minutes" unit when the duration is less than 60 minutes, and "hours" unit when the duration is 60 minutes or greater.

**Validates: Requirements 4.6**

### Property 5: Earnings Percentage Change Calculation

*For any* pair of earnings values (current, previous) where previous is non-zero, the percentage change calculation SHALL equal ((current - previous) / previous) × 100.

**Validates: Requirements 6.5, 21.1**

### Property 6: Currency Formatting Consistency

*For any* numeric amount and locale, the currency formatting function SHALL return a string that includes the currency symbol appropriate for that locale and formats the number according to locale conventions.

**Validates: Requirements 6.7**

### Property 7: Request Sorting Invariant

*For any* list of booking requests, the sorted output SHALL maintain the property that for all adjacent pairs (request_i, request_i+1), request_i.createdAt >= request_i+1.createdAt (descending order by date).

**Validates: Requirements 8.8, 22.1**

### Property 8: Duplicate Skill Rejection

*For any* existing skill list and new skill name, the skill addition function SHALL reject the addition if and only if the new skill name already exists in the list (case-insensitive comparison).

**Validates: Requirements 16.3**

### Property 9: Response Time Calculation

*For any* pair of timestamps (created, responded) where responded >= created, the response time calculation SHALL equal the duration between the two timestamps.

**Validates: Requirements 18.2**

### Property 10: Average Response Time Calculation

*For any* non-empty list of response times, the average response time calculation SHALL equal the sum of all response times divided by the count of response times.

**Validates: Requirements 18.3**

### Property 11: Percentage Formatting Precision

*For any* numeric percentage value, the percentage formatting function SHALL return a string with exactly one decimal place.

**Validates: Requirements 21.5**

### Property 12: Urgency Detection Threshold

*For any* booking request with a scheduled date/time, the urgency detection function SHALL return true if and only if the scheduled time is within 24 hours from the current time.

**Validates: Requirements 22.2**

### Property 13: Profile Completeness Calculation

*For any* provider profile, the completeness percentage SHALL be calculated as: (25 if photo exists) + (25 if bio length >= 50) + (25 if skills count >= 3) + (25 if certifications count >= 1), resulting in a value between 0 and 100.

**Validates: Requirements 23.1**

### Property 14: Counter-Offer Price Validation

*For any* numeric input, the counter-offer price validation function SHALL return true if and only if the value is greater than zero.

**Validates: Requirements 17.3**

## Error Handling

### Network Error Handling

The application implements comprehensive error handling for network operations:

1. **Connection Errors**: When no internet connection is available, display "No internet connection. Please check your network settings." with a retry button.

2. **Timeout Errors**: When requests exceed 30 seconds, display "Request timed out. Please try again." with automatic exponential backoff retry (1s, 2s, 4s delays).

3. **Server Errors (5xx)**: Display "Server error. Our team has been notified. Please try again later." and log detailed error information for debugging.

4. **Client Errors (4xx)**: Parse error response and display specific message (e.g., "Invalid file format" for 400, "Unauthorized" for 401).

5. **Upload Failures**: Preserve selected file in memory and provide retry option without requiring file reselection.

### Validation Error Handling

1. **Bio Validation**: Display "Bio must be between 50 and 500 characters" below the text field when validation fails.

2. **Skill Validation**: Display "Skill name must be between 3 and 50 characters" in the skill input dialog.

3. **File Validation**: Display specific error messages:
   - "File must be JPG or PNG format" for invalid image types
   - "File must be PDF, PNG, or JPG format" for invalid certification types
   - "File size must be under 5MB" for oversized profile photos
   - "File size must be under 10MB" for oversized certifications

4. **Counter-Offer Validation**: Display "Price must be greater than zero" below the price input field.

### State Error Handling

1. **Empty States**: Display helpful messages and call-to-action buttons:
   - No pending requests: "No pending requests. Update your availability to receive more bookings."
   - No skills: "Add your first skill to showcase your expertise."
   - No certifications: "Upload certifications to build customer trust."
   - No earnings data: "No earnings data available for this period."

2. **Loading States**: Display skeleton screens or shimmer effects during data fetching to maintain perceived performance.

3. **Stale Data**: Display a refresh indicator when cached data is older than 5 minutes and automatically refresh in the background.

### AI Service Error Handling

1. **SOP Generation Failure**: Display "Unable to generate safety SOP. Please try again or contact support." with retry option.

2. **Suggestion Generation Failure**: Silently fail and hide suggestion card rather than displaying error (non-critical feature).

3. **Timeout**: If AI service takes longer than 10 seconds, display "This is taking longer than usual..." message while continuing to wait.

### Local Storage Error Handling

1. **Hive Initialization Failure**: Fall back to in-memory storage and display warning "Offline features unavailable."

2. **Storage Full**: Display "Device storage full. Please free up space to save SOPs offline."

3. **Corruption**: Clear corrupted data and reinitialize storage, logging error for investigation.

### Graceful Degradation

1. **Chart Rendering Failure**: Display earnings data in text format if chart library fails.

2. **Image Loading Failure**: Display placeholder avatar/icon if profile photo or customer avatar fails to load.

3. **Animation Failure**: Disable animations if performance drops below 30 FPS to maintain usability.

## Testing Strategy

### Overview

The testing strategy employs a multi-layered approach combining unit tests, property-based tests, widget tests, integration tests, and manual testing to ensure comprehensive coverage of the Provider Panel Modernization feature.

### Unit Testing

**Scope**: Pure business logic functions, validation logic, calculations, and data transformations.

**Framework**: Flutter's built-in `test` package

**Coverage Target**: 90% for business logic layer

**Key Areas**:
- Profile Manager validation functions (bio, photo)
- Skill Manager validation and duplicate detection
- Earnings Analyzer calculations (percentage change, formatting)
- Performance Tracker calculations (response time, averages)
- Request Manager sorting and filtering
- Document Uploader validation functions

**Example Unit Tests**:
```dart
test('bio validation rejects strings under 50 characters', () {
  expect(ProfileManager.validateBio('Short bio'), false);
});

test('percentage change calculation handles zero previous value', () {
  expect(EarningsAnalyzer.calculatePercentageChange(100, 0), 0);
});
```

### Property-Based Testing

**Scope**: Pure functions with universal properties (see Correctness Properties section)

**Framework**: `test` package with custom property test helpers or `fast_check` equivalent for Dart

**Configuration**: Minimum 100 iterations per property test

**Key Areas**:
- Validation boundary conditions (bio length, skill length, file size)
- Calculation correctness (percentage change, averages, response time)
- Formatting consistency (currency, percentages, time)
- Sorting and filtering invariants
- Profile completeness calculation

**Property Test Structure**:
```dart
// Feature: provider-panel-modernization, Property 1: Bio Validation Boundary
test('bio validation accepts only 50-500 character strings', () {
  final random = Random();
  for (int i = 0; i < 100; i++) {
    final length = random.nextInt(600);
    final bio = 'a' * length;
    final result = ProfileManager.validateBio(bio);
    expect(result, length >= 50 && length <= 500);
  }
});
```

**Tag Format**: Each property test includes a comment:
```dart
// Feature: provider-panel-modernization, Property {number}: {property_text}
```

### Widget Testing

**Scope**: Individual UI components and their interactions

**Framework**: Flutter's `flutter_test` package

**Coverage Target**: 80% for presentation layer

**Key Areas**:
- Profile screen widgets (header, skills, certifications)
- Dashboard widgets (earnings card, rating card, request cards)
- Safety Center widgets (SOP generator, saved SOPs list)
- Navigation controller and bottom navigation bar
- Reusable components (GradientCard, SkillChip, MetricCard)

**Example Widget Tests**:
```dart
testWidgets('skill chip displays remove icon on tap', (tester) async {
  await tester.pumpWidget(SkillChip(skill: 'Electrician'));
  await tester.tap(find.byType(SkillChip));
  await tester.pump();
  expect(find.byIcon(Icons.close), findsOneWidget);
});
```

### Integration Testing

**Scope**: End-to-end user flows and API integration

**Framework**: Flutter's `integration_test` package

**Key Flows**:
1. **Profile Update Flow**: Open profile → Edit bio → Add skill → Upload certification → Save → Verify updates
2. **Request Management Flow**: View pending requests → Accept request → Verify notification sent
3. **Counter-Offer Flow**: View request → Send counter-offer → Verify customer notified
4. **Earnings View Flow**: Open dashboard → Toggle daily/weekly → Verify chart updates
5. **SOP Generation Flow**: Open Safety Center → Enter job type → Generate SOP → Save → Verify offline access
6. **Navigation Flow**: Navigate between all tabs → Verify state preservation

**API Integration Tests**:
- Mock backend responses for all API endpoints
- Test error scenarios (network failure, timeout, 4xx/5xx errors)
- Verify request payloads and headers
- Test authentication token handling

### Performance Testing

**Scope**: Load times, animation smoothness, memory usage

**Tools**: Flutter DevTools, custom performance benchmarks

**Metrics**:
- Dashboard load time: < 2 seconds on 4G
- Screen transition animations: 60 FPS
- Chart rendering: < 500ms
- Image upload: Progress updates every 100ms
- Memory usage: < 150MB for typical session

**Benchmark Tests**:
```dart
test('earnings chart renders in under 500ms', () async {
  final stopwatch = Stopwatch()..start();
  await tester.pumpWidget(EarningsChart(data: mockData));
  await tester.pumpAndSettle();
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(500));
});
```

### Accessibility Testing

**Scope**: Screen reader support, color contrast, touch targets

**Tools**: Flutter's accessibility testing tools, manual testing with TalkBack/VoiceOver

**Checks**:
- All interactive elements have semantic labels
- Color contrast ratios meet WCAG AA (4.5:1 for text)
- Touch targets are at least 48x48 dp
- Dynamic text sizing works for all text elements
- Haptic feedback for important actions

### Manual Testing

**Scope**: Visual design, user experience, edge cases

**Test Cases**:
1. Visual design matches Servicely reference (gradients, spacing, typography)
2. Animations are smooth and feel natural
3. Error messages are clear and actionable
4. Empty states are helpful and encouraging
5. Offline mode works correctly for saved SOPs
6. Different screen sizes and orientations
7. Different locales and languages
8. Low-end device performance

### Test Data Management

**Mock Data**:
- Provider profiles with varying completeness (0%, 25%, 50%, 75%, 100%)
- Booking requests with different statuses and urgency levels
- Earnings data for daily and weekly views
- Performance metrics for top performers and average providers
- Safety SOPs for various job types

**Test Fixtures**:
- Sample images (JPG, PNG) for profile photos and certifications
- Sample PDF files for certifications
- Invalid files for validation testing (wrong format, oversized)

### Continuous Integration

**CI Pipeline**:
1. Run all unit tests and property tests
2. Run widget tests with code coverage reporting
3. Run integration tests on emulator
4. Generate coverage report (target: 85% overall)
5. Run static analysis (flutter analyze)
6. Check formatting (flutter format --set-exit-if-changed)

**Quality Gates**:
- All tests must pass
- Code coverage must be >= 85%
- No critical or high-severity static analysis issues
- No formatting violations

### Testing Best Practices

1. **Isolation**: Each test should be independent and not rely on other tests
2. **Clarity**: Test names should clearly describe what is being tested
3. **Arrange-Act-Assert**: Follow AAA pattern for test structure
4. **Mock External Dependencies**: Use mocks for API calls, file system, time
5. **Test Edge Cases**: Include boundary conditions, empty inputs, null values
6. **Avoid Flaky Tests**: Use `pumpAndSettle()` for animations, avoid hardcoded delays
7. **Keep Tests Fast**: Unit tests should run in milliseconds, widget tests in seconds

### Property-Based Testing Implementation

**Library Selection**: Use Dart's `test` package with custom property test helpers. If a mature PBT library becomes available for Dart (similar to QuickCheck or Hypothesis), migrate to it.

**Generator Strategy**:
- String generators: Random lengths (0-1000), various character sets
- Number generators: Positive, negative, zero, decimals, edge values (MAX_INT, MIN_INT)
- Date generators: Past, present, future, edge dates
- List generators: Empty, single item, many items, duplicates

**Shrinking Strategy**: When a property test fails, manually reduce the failing input to the minimal case for debugging.

**Test Organization**: Group property tests in a separate test file (`*_property_test.dart`) to distinguish them from example-based unit tests.

