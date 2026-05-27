import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/ai_assistant_home_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/state/ai_consultation_providers.dart';

void main() {
  group('AIAssistantHomeScreen Widget Tests', () {
    testWidgets('should display app bar with correct title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('AI Visual Assistant'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display info card with feature explanation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Verify info card title
      expect(find.text('AI-Powered Diagnosis'), findsOneWidget);

      // Verify info items
      expect(
          find.text('Capture or select images of problem areas'), findsOneWidget);
      expect(find.text('Mark defects and add descriptions'), findsOneWidget);
      expect(find.text('Get AI diagnosis and cost estimates'), findsOneWidget);
      expect(find.text('View recommended service providers'), findsOneWidget);

      // Verify icons in info card
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('should display action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Verify New Consultation button
      expect(find.text('New Consultation'), findsOneWidget);
      expect(find.widgetWithIcon(ElevatedButton, Icons.add_a_photo),
          findsOneWidget);

      // Verify View History button
      expect(find.text('View History'), findsOneWidget);
      expect(
          find.widgetWithIcon(OutlinedButton, Icons.history), findsOneWidget);
    });

    testWidgets('should display recent consultations section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Verify section title
      expect(find.text('Recent Consultations'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading consultations',
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

    testWidgets('should display empty state when no consultations',
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

      // Verify empty state message
      expect(find.text('No consultations yet'), findsOneWidget);
      expect(
        find.text('Start your first consultation to get AI-powered diagnosis'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history), findsWidgets);
    });

    testWidgets('should display error state when loading fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consultationHistoryProvider.overrideWith(
              (ref) => ConsultationHistoryNotifier()
                ..state = const ConsultationHistoryState(
                  isLoading: false,
                  consultations: [],
                  error: 'Failed to load consultations',
                ),
            ),
          ],
          child: const MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Failed to load consultations'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should have scrollable content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have RefreshIndicator for pull-to-refresh',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Verify RefreshIndicator exists
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should display gradient background in info card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Find the container with gradient
      final containerFinder = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsWidgets);
    });

    testWidgets('should have proper button styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      // Find the New Consultation button
      final elevatedButtonFinder = find.ancestor(
        of: find.text('New Consultation'),
        matching: find.byType(ElevatedButton),
      );
      expect(elevatedButtonFinder, findsOneWidget);

      // Find the View History button
      final outlinedButtonFinder = find.ancestor(
        of: find.text('View History'),
        matching: find.byType(OutlinedButton),
      );
      expect(outlinedButtonFinder, findsOneWidget);
    });

    testWidgets('should display View All button when consultations exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consultationHistoryProvider.overrideWith(
              (ref) => ConsultationHistoryNotifier()
                ..state = ConsultationHistoryState(
                  isLoading: false,
                  consultations: [
                    AIConsultationModel(
                      id: '1',
                      imageUrl: 'https://example.com/image.jpg',
                      markers: const [],
                      diagnosis: 'Test diagnosis',
                      recommendedServiceType: 'Plumbing',
                      costMin: 1000,
                      costMax: 2000,
                      recommendedProviders: const [],
                      createdAt: DateTime.now(),
                    ),
                  ],
                ),
            ),
          ],
          child: const MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify View All button is displayed
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('should display placeholder image for consultations without image',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consultationHistoryProvider.overrideWith(
              (ref) => ConsultationHistoryNotifier()
                ..state = ConsultationHistoryState(
                  isLoading: false,
                  consultations: [
                    AIConsultationModel(
                      id: '1',
                      imageUrl: null,
                      markers: const [],
                      diagnosis: 'Test diagnosis',
                      recommendedServiceType: 'Plumbing',
                      costMin: 1000,
                      costMax: 2000,
                      recommendedProviders: const [],
                      createdAt: DateTime.now(),
                    ),
                  ],
                ),
            ),
          ],
          child: const MaterialApp(
            home: AIAssistantHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify placeholder icon is displayed
      expect(find.byIcon(Icons.image), findsWidgets);
    });
  });
}
