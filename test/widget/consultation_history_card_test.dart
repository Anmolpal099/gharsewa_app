import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/widgets/consultation_history_card.dart';
import 'package:gharsewa/data/models/ai_consultation_models.dart';

void main() {
  group('ConsultationHistoryCard Widget Tests', () {
    late AIConsultationModel testConsultation;

    setUp(() {
      testConsultation = AIConsultationModel(
        id: 'test-id-123',
        customerId: 'customer-1',
        imagePath: '/path/to/image.jpg',
        imageUrl: 'https://example.com/image.jpg',
        markers: const [
          DefectMarkerModel(
            id: '1',
            x: 0.5,
            y: 0.5,
            description: 'Water leak',
          ),
        ],
        diagnosis: 'Plumbing issue with water leak',
        recommendedServiceType: 'Plumbing Repair',
        estimatedCostMin: 2000.0,
        estimatedCostMax: 5000.0,
        recommendedProviders: const [],
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 15, 10, 30),
      );
    });

    testWidgets('should display consultation summary information',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: testConsultation,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify card is displayed
      expect(find.byType(Card), findsOneWidget);

      // Verify InkWell for tap handling
      expect(find.byType(InkWell), findsOneWidget);

      // Verify service type badge is displayed
      expect(find.text(testConsultation.serviceTypeDisplayName), findsOneWidget);

      // Verify diagnosis summary is displayed
      expect(find.text(testConsultation.diagnosisSummary), findsOneWidget);

      // Verify chevron icon
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should display thumbnail image',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: testConsultation,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify Image.network widget exists
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should display placeholder when image is null',
        (WidgetTester tester) async {
      final consultationWithoutImage = testConsultation.copyWith(
        imageUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: consultationWithoutImage,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify placeholder icon is displayed
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('should display date and cost metadata',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: testConsultation,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify calendar icon for date
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);

      // Verify money icon for cost
      expect(find.byIcon(Icons.attach_money), findsOneWidget);

      // Verify formatted date is displayed
      expect(find.text(testConsultation.formattedDate), findsOneWidget);

      // Verify cost range is displayed
      expect(find.text(testConsultation.costRangeFormatted), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: testConsultation,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Verify onTap was called
      expect(tapped, isTrue);
    });

    testWidgets('should display service type badge with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: testConsultation,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the service type badge container
      final badgeFinder = find.ancestor(
        of: find.text(testConsultation.serviceTypeDisplayName),
        matching: find.byType(Container),
      );

      expect(badgeFinder, findsOneWidget);
    });

    testWidgets('should truncate long diagnosis text',
        (WidgetTester tester) async {
      final longDiagnosisConsultation = testConsultation.copyWith(
        diagnosis:
            'This is a very long diagnosis text that should be truncated when displayed in the card to prevent overflow and maintain a clean UI layout',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: longDiagnosisConsultation,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the diagnosis text widget
      final diagnosisTextFinder = find.ancestor(
        of: find.text(longDiagnosisConsultation.diagnosisSummary),
        matching: find.byType(Text),
      );

      expect(diagnosisTextFinder, findsOneWidget);

      // Verify text has maxLines and overflow properties
      final textWidget = tester.widget<Text>(diagnosisTextFinder);
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should have proper card elevation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: testConsultation,
              onTap: () {},
            ),
          ),
        ),
      );

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(2));
    });

    testWidgets('should have proper clip behavior',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsultationHistoryCard(
              consultation: testConsultation,
              onTap: () {},
            ),
          ),
        ),
      );

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.clipBehavior, equals(Clip.antiAlias));
    });
  });
}
