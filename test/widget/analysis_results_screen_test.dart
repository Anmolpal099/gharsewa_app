import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/analysis_results_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/state/ai_consultation_providers.dart';
import 'package:gharsewa/data/models/ai_consultation_models.dart';
import 'package:gharsewa/services/api/ai_consultation_api_service.dart';

void main() {
  group('AnalysisResultsScreen Widget Tests', () {
    late AIConsultationModel testConsultation;

    setUp(() {
      testConsultation = AIConsultationModel(
        id: 'test-id-123',
        customerId: 'customer-1',
        imagePath: '/path/to/image.jpg',
        markers: const [
          DefectMarkerModel(
            id: '1',
            x: 0.5,
            y: 0.5,
            description: 'Water leak at pipe joint',
          ),
          DefectMarkerModel(
            id: '2',
            x: 0.7,
            y: 0.3,
            description: 'Rust on metal surface',
          ),
        ],
        diagnosis: 'Plumbing leak with corrosion damage requiring immediate attention',
        recommendedServiceType: 'Plumbing Repair',
        estimatedCostMin: 2000.0,
        estimatedCostMax: 5000.0,
        recommendedProviders: [
          const ProviderRecommendationModel(
            id: 'provider-1',
            name: 'Expert Plumbers',
            rating: 4.8,
            services: ['Plumbing Repair', 'Pipe Installation'],
            phone: '+977-1234567890',
            email: 'expert@plumbers.com',
          ),
          const ProviderRecommendationModel(
            id: 'provider-2',
            name: 'Quick Fix Services',
            rating: 4.5,
            services: ['Plumbing Repair'],
          ),
        ],
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 15, 10, 30),
      );
    });

    testWidgets('should display app bar with correct title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Analysis Results'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display loading overlay when submitting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = const CurrentConsultationState(
                  isSubmitting: true,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Analyzing your image...'), findsOneWidget);
      expect(find.text('This may take up to 30 seconds'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('should display error state when analysis fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = const CurrentConsultationState(
                  isSubmitting: false,
                  error: 'AI service unavailable',
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('Analysis Failed'), findsOneWidget);
      expect(find.text('AI service unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('should display error when no consultation data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = const CurrentConsultationState(
                  isSubmitting: false,
                  consultation: null,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('Analysis Failed'), findsOneWidget);
      expect(find.text('No consultation data available'), findsOneWidget);
    });

    testWidgets('should display diagnosis card with prominent styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify diagnosis card
      expect(find.text('AI Diagnosis'), findsOneWidget);
      expect(find.text(testConsultation.diagnosis), findsOneWidget);
      expect(find.byIcon(Icons.medical_services), findsOneWidget);
    });

    testWidgets('should display service type card with icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify service type card
      expect(find.text('Service Type'), findsOneWidget);
      expect(find.text(testConsultation.serviceTypeDisplayName), findsOneWidget);
      expect(find.byIcon(Icons.plumbing), findsOneWidget);
    });

    testWidgets('should display cost estimate card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify cost estimate card
      expect(find.text('Estimated Cost'), findsOneWidget);
      expect(find.text(testConsultation.costRangeFormatted), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsWidgets);
    });

    testWidgets('should display provider recommendations section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify section title
      expect(find.text('Recommended Providers'), findsOneWidget);

      // Verify provider cards are displayed
      expect(find.text('Expert Plumbers'), findsOneWidget);
      expect(find.text('Quick Fix Services'), findsOneWidget);
    });

    testWidgets('should display no providers message when list is empty',
        (WidgetTester tester) async {
      final consultationWithoutProviders = testConsultation.copyWith(
        recommendedProviders: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: consultationWithoutProviders,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no providers message
      expect(find.text('No providers available'), findsOneWidget);
      expect(
        find.text(
            'No service providers are currently available for this service type'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('should display Start New Consultation button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify button
      expect(find.text('Start New Consultation'), findsOneWidget);
      expect(find.widgetWithIcon(ElevatedButton, Icons.add_a_photo),
          findsOneWidget);
    });

    testWidgets('should have scrollable content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should display image thumbnail with markers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Card with image exists
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(AspectRatio), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('should display provider recommendation cards with actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Contact buttons
      expect(find.text('Contact'), findsNWidgets(2));
      expect(find.widgetWithIcon(OutlinedButton, Icons.phone), findsNWidgets(2));

      // Verify Book Now buttons
      expect(find.text('Book Now'), findsNWidgets(2));
      expect(find.widgetWithIcon(ElevatedButton, Icons.calendar_today),
          findsNWidgets(2));
    });

    testWidgets('should display provider ratings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify rating stars are displayed
      expect(find.byIcon(Icons.star), findsWidgets);
      expect(find.byIcon(Icons.star_half), findsWidgets);
    });

    testWidgets('should display provider services',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentConsultationProvider.overrideWith(
              (ref) => CurrentConsultationNotifier(ref.watch(aiConsultationApiServiceProvider))
                ..state = CurrentConsultationState(
                  consultation: testConsultation,
                  isSubmitting: false,
                ),
            ),
          ],
          child: const MaterialApp(
            home: AnalysisResultsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify services are displayed
      expect(find.text('Plumbing Repair'), findsWidgets);
      expect(find.text('Pipe Installation'), findsOneWidget);
    });
  });
}
