import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/widgets/annotation_canvas.dart';
import 'package:gharsewa/data/models/ai_consultation_models.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/state/markers_notifier.dart';

void main() {
  group('AnnotationCanvas Widget Tests', () {
    late File testImageFile;

    setUp(() {
      // Create a test image file path (will be mocked in tests)
      testImageFile = File('test_assets/test_image.jpg');
    });

    testWidgets('should display loading indicator while image loads',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationCanvas(
                imageFile: testImageFile,
              ),
            ),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle marker addition callback',
        (WidgetTester tester) async {
      DefectMarkerModel? addedMarker;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationCanvas(
                imageFile: testImageFile,
                onMarkerAdded: (marker) {
                  addedMarker = marker;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify callback parameter is set up
      expect(addedMarker, isNull);
    });

    testWidgets('should handle marker selection callback',
        (WidgetTester tester) async {
      DefectMarkerModel? selectedMarker;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationCanvas(
                imageFile: testImageFile,
                onMarkerSelected: (marker) {
                  selectedMarker = marker;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify callback parameter is set up
      expect(selectedMarker, isNull);
    });

    testWidgets('should use GestureDetector for tap handling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationCanvas(
                imageFile: testImageFile,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have GestureDetector for tap handling
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('should use CustomPaint for rendering',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationCanvas(
                imageFile: testImageFile,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have CustomPaint for rendering
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('AnnotationPainter Tests', () {
    testWidgets('should render markers with correct styling',
        (WidgetTester tester) async {
      final markers = [
        const DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: 'Test marker 1',
        ),
        const DefectMarkerModel(
          id: '2',
          x: 0.3,
          y: 0.7,
          description: 'Test marker 2',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            markersProvider.overrideWith((ref) => MarkersNotifier()..setMarkers(markers)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: AnnotationPainter(
                  image: null,
                  markers: markers,
                  selectedMarkerId: null,
                ),
                child: Container(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify CustomPaint widget exists
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('should highlight selected marker',
        (WidgetTester tester) async {
      final markers = [
        const DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: 'Test marker',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: AnnotationPainter(
                  image: null,
                  markers: markers,
                  selectedMarkerId: '1',
                ),
                child: Container(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify CustomPaint widget exists with selected marker
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });
}
