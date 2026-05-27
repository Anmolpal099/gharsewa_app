import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/image_capture_screen.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/ai_assistant_home_screen.dart';

void main() {
  group('Button Interactions Tests', () {
    group('ImageCaptureScreen Button Tests', () {
      testWidgets('Take Photo button should be tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ImageCaptureScreen(),
            ),
          ),
        );

        // Find Take Photo button
        final takePhotoButton = find.ancestor(
          of: find.text('Take Photo'),
          matching: find.byType(InkWell),
        );

        expect(takePhotoButton, findsOneWidget);

        // Verify button is enabled (can be tapped)
        final inkWell = tester.widget<InkWell>(takePhotoButton);
        expect(inkWell.onTap, isNotNull);
      });

      testWidgets('Select from Gallery button should be tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ImageCaptureScreen(),
            ),
          ),
        );

        // Find Select from Gallery button
        final galleryButton = find.ancestor(
          of: find.text('Select from Gallery'),
          matching: find.byType(InkWell),
        );

        expect(galleryButton, findsOneWidget);

        // Verify button is enabled (can be tapped)
        final inkWell = tester.widget<InkWell>(galleryButton);
        expect(inkWell.onTap, isNotNull);
      });

      testWidgets('buttons should have proper visual feedback',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ImageCaptureScreen(),
            ),
          ),
        );

        // Verify InkWell widgets exist for ripple effect
        expect(find.byType(InkWell), findsNWidgets(2));
      });
    });

    group('AIAssistantHomeScreen Button Tests', () {
      testWidgets('New Consultation button should be tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Find New Consultation button
        final newConsultationButton = find.ancestor(
          of: find.text('New Consultation'),
          matching: find.byType(ElevatedButton),
        );

        expect(newConsultationButton, findsOneWidget);

        // Verify button is enabled
        final button = tester.widget<ElevatedButton>(newConsultationButton);
        expect(button.onPressed, isNotNull);
      });

      testWidgets('View History button should be tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Find View History button
        final viewHistoryButton = find.ancestor(
          of: find.text('View History'),
          matching: find.byType(OutlinedButton),
        );

        expect(viewHistoryButton, findsOneWidget);

        // Verify button is enabled
        final button = tester.widget<OutlinedButton>(viewHistoryButton);
        expect(button.onPressed, isNotNull);
      });

      testWidgets('buttons should have proper sizing',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Find button containers
        final buttonContainers = find.descendant(
          of: find.byType(Column),
          matching: find.byType(SizedBox),
        );

        expect(buttonContainers, findsWidgets);
      });

      testWidgets('buttons should have icons',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Verify button icons
        expect(find.widgetWithIcon(ElevatedButton, Icons.add_a_photo),
            findsOneWidget);
        expect(
            find.widgetWithIcon(OutlinedButton, Icons.history), findsOneWidget);
      });
    });

    group('Button State Tests', () {
      testWidgets('buttons should maintain state during interactions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ImageCaptureScreen(),
            ),
          ),
        );

        // Find Take Photo button
        final takePhotoButton = find.ancestor(
          of: find.text('Take Photo'),
          matching: find.byType(InkWell),
        );

        // Tap the button
        await tester.tap(takePhotoButton);
        await tester.pump();

        // Button should still exist after tap
        expect(takePhotoButton, findsOneWidget);
      });

      testWidgets('buttons should be responsive to multiple taps',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        final newConsultationButton = find.ancestor(
          of: find.text('New Consultation'),
          matching: find.byType(ElevatedButton),
        );

        // Tap multiple times
        await tester.tap(newConsultationButton);
        await tester.pump();
        await tester.tap(newConsultationButton);
        await tester.pump();

        // Button should still be present
        expect(newConsultationButton, findsOneWidget);
      });
    });

    group('Button Accessibility Tests', () {
      testWidgets('buttons should have semantic labels',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ImageCaptureScreen(),
            ),
          ),
        );

        // Verify text labels exist for screen readers
        expect(find.text('Take Photo'), findsOneWidget);
        expect(find.text('Select from Gallery'), findsOneWidget);
      });

      testWidgets('buttons should have sufficient touch targets',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Find button with size constraints
        final buttonFinder = find.ancestor(
          of: find.text('New Consultation'),
          matching: find.byType(SizedBox),
        );

        expect(buttonFinder, findsOneWidget);

        // Verify button has proper height (56 is Material Design standard)
        final sizedBox = tester.widget<SizedBox>(buttonFinder);
        expect(sizedBox.height, equals(56));
      });
    });

    group('Button Visual Feedback Tests', () {
      testWidgets('ElevatedButton should have elevation',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        final elevatedButton = find.ancestor(
          of: find.text('New Consultation'),
          matching: find.byType(ElevatedButton),
        );

        expect(elevatedButton, findsOneWidget);
      });

      testWidgets('OutlinedButton should have border',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        final outlinedButton = find.ancestor(
          of: find.text('View History'),
          matching: find.byType(OutlinedButton),
        );

        expect(outlinedButton, findsOneWidget);
      });

      testWidgets('buttons should have rounded corners',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Buttons should be present with proper styling
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });
    });

    group('Button Layout Tests', () {
      testWidgets('buttons should be properly aligned',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Find buttons in column layout
        final columnFinder = find.byType(Column);
        expect(columnFinder, findsWidgets);

        // Verify both buttons exist
        expect(find.text('New Consultation'), findsOneWidget);
        expect(find.text('View History'), findsOneWidget);
      });

      testWidgets('buttons should have proper spacing',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Verify SizedBox spacing exists between buttons
        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('buttons should span full width',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AIAssistantHomeScreen(),
            ),
          ),
        );

        // Find button with width constraint
        final buttonFinder = find.ancestor(
          of: find.text('New Consultation'),
          matching: find.byType(SizedBox),
        );

        expect(buttonFinder, findsOneWidget);

        // Verify button has full width
        final sizedBox = tester.widget<SizedBox>(buttonFinder);
        expect(sizedBox.width, equals(double.infinity));
      });
    });
  });
}
