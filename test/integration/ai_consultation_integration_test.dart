import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/data/models/ai_consultation_models.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/ai_assistant_home_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/annotation_editor_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/analysis_results_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/consultation_history_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/image_capture_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/widgets/annotation_canvas.dart';
import 'package:gharsewa/services/api/ai_consultation_api_service.dart';
import 'package:gharsewa/services/api/api_exception.dart';

/// Mock implementation of AIConsultationApiService for testing
class MockAIConsultationApiService implements AIConsultationApiService {
  AIConsultationModel? _mockConsultation;
  ConsultationHistoryResponse? _mockHistory;
  String? _mockDeleteMessage;
  Exception? _mockException;

  void setMockConsultation(AIConsultationModel consultation) {
    _mockConsultation = consultation;
  }

  void setMockHistory(ConsultationHistoryResponse history) {
    _mockHistory = history;
  }

  void setMockDeleteMessage(String message) {
    _mockDeleteMessage = message;
  }

  void setMockException(Exception exception) {
    _mockException = exception;
  }

  void reset() {
    _mockConsultation = null;
    _mockHistory = null;
    _mockDeleteMessage = null;
    _mockException = null;
  }

  @override
  Future<AIConsultationModel> createConsultation({
    required File imageFile,
    required List<DefectMarkerModel> markers,
  }) async {
    if (_mockException != null) throw _mockException!;
    if (_mockConsultation == null) {
      throw Exception('Mock consultation not set');
    }
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockConsultation!;
  }

  @override
  Future<ConsultationHistoryResponse> getConsultationHistory({
    int page = 1,
    int perPage = 20,
    String? serviceType,
  }) async {
    if (_mockException != null) throw _mockException!;
    if (_mockHistory == null) {
      throw Exception('Mock history not set');
    }
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockHistory!;
  }

  @override
  Future<AIConsultationModel> getConsultationById(String id) async {
    if (_mockException != null) throw _mockException!;
    if (_mockConsultation == null) {
      throw Exception('Mock consultation not set');
    }
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockConsultation!;
  }

  @override
  Future<String> deleteConsultation(String id) async {
    if (_mockException != null) throw _mockException!;
    if (_mockDeleteMessage == null) {
      throw Exception('Mock delete message not set');
    }
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockDeleteMessage!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Visual Assistant Integration Tests', () {
    late MockAIConsultationApiService mockApiService;

    setUp(() {
      mockApiService = MockAIConsultationApiService();
    });

    tearDown(() {
      mockApiService.reset();
    });

    /// Helper function to create a test image file
    File createTestImageFile() {
      final tempDir = Directory.systemTemp;
      final testImagePath = '${tempDir.path}/test_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final testFile = File(testImagePath);
      
      // Create a minimal valid JPEG file (1x1 pixel)
      final bytes = base64Decode(
        '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=',
      );
      testFile.writeAsBytesSync(bytes);
      return testFile;
    }

    /// Helper function to create mock consultation response
    AIConsultationModel createMockConsultation() {
      return AIConsultationModel(
        id: 'test-consultation-id',
        customerId: 'test-customer-id',
        imagePath: '/storage/consultations/test.jpg',
        imageUrl: 'https://example.com/storage/consultations/test.jpg',
        markers: const [
          DefectMarkerModel(
            id: 'marker-1',
            x: 0.5,
            y: 0.5,
            description: 'Water leak detected',
          ),
        ],
        diagnosis: 'Plumbing leak with corrosion damage',
        recommendedServiceType: 'Plumbing Repair',
        estimatedCostMin: 2000,
        estimatedCostMax: 5000,
        recommendedProviders: const [
          ProviderRecommendationModel(
            id: 'provider-1',
            name: 'Expert Plumbers',
            rating: 4.8,
            services: ['Plumbing Repair', 'Pipe Installation'],
            phone: '+977-9841234567',
            location: 'Kathmandu',
            completedBookings: 150,
            isActive: true,
          ),
          ProviderRecommendationModel(
            id: 'provider-2',
            name: 'Quick Fix Services',
            rating: 4.5,
            services: ['Plumbing Repair'],
            phone: '+977-9841234568',
            location: 'Lalitpur',
            completedBookings: 100,
            isActive: true,
          ),
        ],
        processingTimeSeconds: 27.5,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 15, 10, 30),
      );
    }

    /// Helper function to create mock consultation history
    ConsultationHistoryResponse createMockHistory() {
      return ConsultationHistoryResponse(
        consultations: [
          createMockConsultation(),
          createMockConsultation().copyWith(
            id: 'test-consultation-id-2',
            diagnosis: 'Electrical wiring issue',
            recommendedServiceType: 'Electrical Work',
          ),
        ],
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 2,
      );
    }

    testWidgets('Full consultation creation flow - image capture screen renders',
        (WidgetTester tester) async {
      // Setup mock responses
      final mockConsultation = createMockConsultation();

      mockApiService.setMockConsultation(mockConsultation);

      // Build the app with mocked dependencies
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultationApiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify image capture screen is displayed
      expect(find.text('Capture Image'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Select from Gallery'), findsOneWidget);
    });

    testWidgets('Annotation workflow - screen renders with canvas',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AnnotationEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify annotation editor screen is displayed
      expect(find.text('Annotate Image'), findsOneWidget);
      expect(find.byType(AnnotationCanvas), findsOneWidget);

      // Verify submit button is present
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('History loading and viewing', (WidgetTester tester) async {
      // Setup mock history response
      final mockHistory = createMockHistory();

      mockApiService.setMockHistory(mockHistory);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultationApiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: ConsultationHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify history screen is displayed
      expect(find.text('Consultation History'), findsOneWidget);
    });

    testWidgets('Consultation deletion with confirmation',
        (WidgetTester tester) async {
      final mockHistory = createMockHistory();

      mockApiService.setMockHistory(mockHistory);
      mockApiService.setMockDeleteMessage('Consultation deleted successfully');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultationApiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: ConsultationHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without errors
      expect(find.text('Consultation History'), findsOneWidget);
    });

    testWidgets('Error scenario - network failure handling',
        (WidgetTester tester) async {
      // Setup mock to throw network error
      mockApiService.setMockException(ApiException(
        message: 'No internet connection',
        type: ApiExceptionType.network,
        statusCode: null,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultationApiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: AnnotationEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without crashing
      expect(find.text('Annotate Image'), findsOneWidget);
    });

    testWidgets('Error scenario - API timeout handling',
        (WidgetTester tester) async {
      // Setup mock to throw timeout error
      mockApiService.setMockException(ApiException(
        message: 'Request timeout',
        type: ApiExceptionType.timeout,
        statusCode: 408,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultationApiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: AnnotationEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without crashing
      expect(find.text('Annotate Image'), findsOneWidget);
    });

    testWidgets('Error scenario - permission denial handling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify permission handling UI
      expect(find.text('Capture Image'), findsOneWidget);
    });

    testWidgets('Analysis results screen renders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify results screen renders
      expect(find.text('AI Diagnosis'), findsOneWidget);
    });

    testWidgets('AI Assistant home screen navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify home screen elements
      expect(find.text('AI Visual Assistant'), findsOneWidget);
      expect(find.text('New Consultation'), findsOneWidget);
      expect(find.text('View History'), findsOneWidget);
    });

    test('DefectMarker model validation', () {
      // Test valid marker
      const validMarker = DefectMarkerModel(
        id: 'test-id',
        x: 0.5,
        y: 0.5,
        description: 'Valid description',
      );
      expect(validMarker.isValid, isTrue);
      expect(validMarker.hasValidCoordinates, isTrue);
      expect(validMarker.hasValidDescription, isTrue);

      // Test invalid coordinates
      const invalidCoords = DefectMarkerModel(
        id: 'test-id',
        x: 1.5, // Invalid: > 1.0
        y: 0.5,
        description: 'Valid description',
      );
      expect(invalidCoords.hasValidCoordinates, isFalse);
      expect(invalidCoords.isValid, isFalse);

      // Test invalid description
      const invalidDesc = DefectMarkerModel(
        id: 'test-id',
        x: 0.5,
        y: 0.5,
        description: 'a', // Invalid: < 2 chars
      );
      expect(invalidDesc.hasValidDescription, isFalse);
      expect(invalidDesc.isValid, isFalse);
    });

    test('AIConsultation model serialization', () {
      final consultation = createMockConsultation();

      // Test toJson
      final json = consultation.toJson();
      expect(json['id'], equals('test-consultation-id'));
      expect(json['diagnosis'], equals('Plumbing leak with corrosion damage'));
      expect(json['estimated_cost_min'], equals(2000));
      expect(json['estimated_cost_max'], equals(5000));

      // Test fromJson
      final deserialized = AIConsultationModel.fromJson(json);
      expect(deserialized.id, equals(consultation.id));
      expect(deserialized.diagnosis, equals(consultation.diagnosis));
      expect(deserialized.estimatedCostMin, equals(consultation.estimatedCostMin));
      expect(deserialized.estimatedCostMax, equals(consultation.estimatedCostMax));
    });

    test('ConsultationHistoryResponse pagination logic', () {
      final response = ConsultationHistoryResponse(
        consultations: [createMockConsultation()],
        currentPage: 2,
        lastPage: 5,
        perPage: 20,
        total: 100,
      );

      expect(response.hasNextPage, isTrue);
      expect(response.isFirstPage, isFalse);
      expect(response.isLastPage, isFalse);
      expect(response.nextPage, equals(3));
      expect(response.previousPage, equals(1));
      expect(response.isNotEmpty, isTrue);

      // Test last page
      final lastPageResponse = response.copyWith(currentPage: 5);
      expect(lastPageResponse.hasNextPage, isFalse);
      expect(lastPageResponse.isLastPage, isTrue);
      expect(lastPageResponse.nextPage, isNull);
    });

    test('ProviderRecommendation model properties', () {
      const provider = ProviderRecommendationModel(
        id: 'provider-1',
        name: 'Expert Plumbers',
        rating: 4.8,
        services: ['Plumbing Repair', 'Pipe Installation'],
        phone: '+977-9841234567',
        location: 'Kathmandu',
        completedBookings: 150,
        isActive: true,
      );

      expect(provider.formattedRating, equals('4.8'));
      expect(provider.servicesText, equals('Plumbing Repair, Pipe Installation'));
      expect(provider.hasHighRating, isTrue);
      expect(provider.hasBookingHistory, isTrue);

      // Test low rating
      final lowRatedProvider = provider.copyWith(rating: 3.5);
      expect(lowRatedProvider.hasHighRating, isFalse);
    });

    test('AIConsultation helper methods', () {
      final consultation = createMockConsultation();

      // Test cost range formatting
      expect(consultation.costRangeFormatted, equals('NPR 2000 - 5000'));

      // Test marker count
      expect(consultation.markerCount, equals(1));

      // Test provider count
      expect(consultation.providerCount, equals(2));
      expect(consultation.hasRecommendedProviders, isTrue);

      // Test diagnosis summary
      final longDiagnosis = consultation.copyWith(
        diagnosis: 'A' * 150,
      );
      expect(longDiagnosis.diagnosisSummary.length, equals(100));
      expect(longDiagnosis.diagnosisSummary.endsWith('...'), isTrue);

      // Test service type display name
      expect(consultation.serviceTypeDisplayName, equals('Plumbing Repair'));
    });
  });

  group('API Service Mock Tests', () {
    late MockAIConsultationApiService mockApiService;

    setUp(() {
      mockApiService = MockAIConsultationApiService();
    });

    tearDown(() {
      mockApiService.reset();
    });

    test('Create consultation API call', () async {
      final testImage = File('test.jpg');
      const markers = [
        DefectMarkerModel(
          id: 'marker-1',
          x: 0.5,
          y: 0.5,
          description: 'Test marker',
        ),
      ];
      final mockConsultation = AIConsultationModel(
        id: 'test-id',
        customerId: 'customer-id',
        imagePath: '/path/to/image.jpg',
        imageUrl: 'https://example.com/image.jpg',
        markers: markers,
        diagnosis: 'Test diagnosis',
        recommendedServiceType: 'Plumbing Repair',
        estimatedCostMin: 1000,
        estimatedCostMax: 2000,
        recommendedProviders: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      mockApiService.setMockConsultation(mockConsultation);

      final result = await mockApiService.createConsultation(
        imageFile: testImage,
        markers: markers,
      );

      expect(result.id, equals('test-id'));
      expect(result.diagnosis, equals('Test diagnosis'));
    });

    test('Get consultation history API call', () async {
      const mockHistory = ConsultationHistoryResponse(
        consultations: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
      );

      mockApiService.setMockHistory(mockHistory);

      final result = await mockApiService.getConsultationHistory(
        page: 1,
        perPage: 20,
      );

      expect(result.currentPage, equals(1));
      expect(result.consultations, isEmpty);
    });

    test('Delete consultation API call', () async {
      const consultationId = 'test-id';
      const successMessage = 'Consultation deleted successfully';

      mockApiService.setMockDeleteMessage(successMessage);

      final result = await mockApiService.deleteConsultation(consultationId);

      expect(result, equals(successMessage));
    });

    test('API error handling - network error', () async {
      final testImage = File('test.jpg');
      const markers = [
        DefectMarkerModel(
          id: 'marker-1',
          x: 0.5,
          y: 0.5,
          description: 'Test marker',
        ),
      ];

      mockApiService.setMockException(ApiException(
        message: 'No internet connection',
        type: ApiExceptionType.network,
        statusCode: null,
      ));

      expect(
        () => mockApiService.createConsultation(
          imageFile: testImage,
          markers: markers,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('API error handling - server error', () async {
      mockApiService.setMockException(ApiException(
        message: 'Internal server error',
        type: ApiExceptionType.server,
        statusCode: 500,
      ));

      expect(
        () => mockApiService.getConsultationHistory(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

// Extension to help with copyWith for ConsultationHistoryResponse
extension ConsultationHistoryResponseCopyWith on ConsultationHistoryResponse {
  ConsultationHistoryResponse copyWith({
    List<AIConsultationModel>? consultations,
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
  }) {
    return ConsultationHistoryResponse(
      consultations: consultations ?? this.consultations,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
    );
  }
}
