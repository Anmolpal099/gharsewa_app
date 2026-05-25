import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/presentation/screens/provider_inventory_screen.dart';

void main() {
  testWidgets('ProviderInventoryScreen adds items (10.6)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProviderInventoryScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Wrench set');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Wrench set'), findsOneWidget);
  });
}
