import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/ai_assistant_home_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/analysis_results_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/state/ai_consultation_providers.dart';
import 'package:gharsewa/data/models/ai_consultation_models.dart';

void main() {
  group('Error State Display Tests', () {
    group('AIAssistantHomeScreen Error States', () {
      testWidgets('should display error icon when loading fails',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: false,
                    consultations: [],
                    error: 'Network error',
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error icon is displayed
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should display error message text',
          (WidgetTester tester) async {
        const errorMessage = 'Failed to load consultations';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: false,
                    consultations: [],
                    error: errorMessage,
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.text(errorMessage), findsOneWidget);
      });

      testWidgets('should display retry button on error',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: false,
                    consultations: [],
                    error: 'Network error',
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify retry button is displayed
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should display error card with proper styling',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: false,
                    consultations: [],
                    error: 'Error occurred',
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error is displayed in a Card
        expect(find.byType(Card), findsWidgets);
      });
    });

    group('AnalysisResultsScreen Error States', () {
      testWidgets('should display analysis failed error',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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
      });

      testWidgets('should display back to home button on error',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
                  ..state = const CurrentConsultationState(
                    isSubmitting: false,
                    error: 'Error occurred',
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AnalysisResultsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify back button
        expect(find.text('Back to Home'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
      });

      testWidgets('should display no consultation data error',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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

        // Verify error message
        expect(find.text('No consultation data available'), findsOneWidget);
      });

      testWidgets('should display error with proper icon size',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
                  ..state = const CurrentConsultationState(
                    isSubmitting: false,
                    error: 'Error',
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AnalysisResultsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find error icon
        final iconFinder = find.byIcon(Icons.error_outline);
        expect(iconFinder, findsOneWidget);

        // Verify icon size
        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.size, equals(80));
      });
    });

    group('Empty State Display Tests', () {
      testWidgets('should display empty state icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: false,
                    consultations: [],
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify empty state icon
        expect(find.byIcon(Icons.history), findsWidgets);
      });

      testWidgets('should display empty state message',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: false,
                    consultations: [],
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify empty state messages
        expect(find.text('No consultations yet'), findsOneWidget);
        expect(
          find.text('Start your first consultation to get AI-powered diagnosis'),
          findsOneWidget,
        );
      });

      testWidgets('should display empty providers message',
          (WidgetTester tester) async {
        final consultation = AIConsultationModel(
          id: '1',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: 'Test diagnosis',
          recommendedServiceType: 'Plumbing',
          costMin: 2000.0,
          costMax: 5000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
                  ..state = CurrentConsultationState(
                    consultation: consultation,
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
        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      });
    });
  });

  group('Loading State Display Tests', () {
    group('AIAssistantHomeScreen Loading States', () {
      testWidgets('should display loading indicator',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: true,
                    consultations: [],
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pump();

        // Verify loading indicator is displayed
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should center loading indicator',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              consultationHistoryProvider.overrideWith(
                (ref) => ConsultationHistoryNotifier()
                  ..state = const ConsultationHistoryState(
                    isLoading: true,
                    consultations: [],
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        await tester.pump();

        // Verify loading indicator is centered
        final centerFinder = find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(Center),
        );
        expect(centerFinder, findsOneWidget);
      });
    });

    group('AnalysisResultsScreen Loading States', () {
      testWidgets('should display loading overlay during analysis',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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

        // Verify loading elements
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Analyzing your image...'), findsOneWidget);
        expect(find.text('This may take up to 30 seconds'), findsOneWidget);
      });

      testWidgets('should display animated AI icon during loading',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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

        // Verify AI icon is displayed
        expect(find.byIcon(Icons.psychology), findsOneWidget);
      });

      testWidgets('should display loading message',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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

        // Verify loading messages
        expect(find.text('Analyzing your image...'), findsOneWidget);
        expect(find.text('This may take up to 30 seconds'), findsOneWidget);
      });

      testWidgets('should use TweenAnimationBuilder for animation',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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

        // Verify animation widget exists
        expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      });
    });

    group('Loading State Transitions', () {
      testWidgets('should transition from loading to content',
          (WidgetTester tester) async {
        final consultation = AIConsultationModel(
          id: '1',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: 'Test diagnosis',
          recommendedServiceType: 'Plumbing',
          costMin: 2000.0,
          costMax: 5000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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

        // Verify loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Update to loaded state
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
                  ..state = CurrentConsultationState(
                    consultation: consultation,
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

        // Verify content is displayed
        expect(find.text('AI Diagnosis'), findsOneWidget);
        expect(find.text(consultation.diagnosis), findsOneWidget);
      });

      testWidgets('should transition from loading to error',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
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

        // Verify loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Update to error state
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentConsultationProvider.overrideWith(
                (ref) => CurrentConsultationNotifier()
                  ..state = const CurrentConsultationState(
                    isSubmitting: false,
                    error: 'Analysis failed',
                  ),
              ),
            ],
            child: const MaterialApp(
              home: AnalysisResultsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error is displayed
        expect(find.text('Analysis Failed'), findsOneWidget);
        expect(find.text('Analysis failed'), findsOneWidget);
      });
    });
  });
}
