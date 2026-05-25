import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/presentation/screens/provider_support_screen.dart';

void main() {
  testWidgets('ProviderSupportScreen shows help options (10.5)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderSupportScreen()),
    );

    expect(find.text('How can we help?'), findsOneWidget);
    expect(find.text('FAQs'), findsOneWidget);
    expect(find.text('Email support'), findsOneWidget);
    expect(find.text('Report an issue'), findsOneWidget);
  });
}
