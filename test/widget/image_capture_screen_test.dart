import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/presentation/panels/customer/ai_consultation/screens/image_capture_screen.dart';

void main() {
  group('ImageCaptureScreen Widget Tests', () {
    testWidgets('should display screen title and action buttons',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Capture Image'), findsOneWidget);

      // Verify header text
      expect(find.text('Choose Image Source'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Select from Gallery'), findsOneWidget);

      // Verify button icons
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('should display image requirements info',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      // Verify requirements section
      expect(find.text('Image Requirements'), findsOneWidget);
      expect(find.text('Size: 100KB - 10MB'), findsOneWidget);
      expect(find.text('Formats: JPEG, PNG, HEIC'), findsOneWidget);
      expect(find.text('Clear, well-lit images work best'), findsOneWidget);
    });

    testWidgets('should have proper button structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      // Verify both action buttons are present
      final takePhotoButton = find.ancestor(
        of: find.text('Take Photo'),
        matching: find.byType(InkWell),
      );
      expect(takePhotoButton, findsOneWidget);

      final galleryButton = find.ancestor(
        of: find.text('Select from Gallery'),
        matching: find.byType(InkWell),
      );
      expect(galleryButton, findsOneWidget);
    });

    testWidgets('should display header icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      // Verify header icon (add_a_photo)
      final headerIcons = find.byIcon(Icons.add_a_photo);
      expect(headerIcons, findsWidgets);
    });

    testWidgets('should have scrollable content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
