import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/business_logic/provider_validators.dart';
import 'package:gharsewa/features/provider_panel/presentation/screens/provider_inventory_screen.dart';
import 'package:gharsewa/features/provider_panel/presentation/screens/provider_support_screen.dart';
import 'package:gharsewa/features/provider_panel/presentation/widgets/paginated_list.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Provider panel flows (11.5, 14.4)', () {
    testWidgets('support screen renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProviderSupportScreen()),
      );
      expect(find.text('How can we help?'), findsOneWidget);
    });

    testWidgets('inventory add/remove flow', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ProviderInventoryScreen()),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Safety gloves');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Safety gloves'), findsOneWidget);
    });

    testWidgets('pagination navigates pages', (tester) async {
      final items = List.generate(25, (i) => i);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView<int>(
              items: items,
              itemBuilder: (_, n) => ListTile(title: Text('Row $n')),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('Row 24'), findsOneWidget);
    });

    test('validator integration: bio + counter price', () {
      expect(ProviderValidators.validateBio('a' * 50), isTrue);
      expect(ProviderValidators.validateCounterPrice(500), isTrue);
      expect(
        ProviderValidators.percentageChange(200, 100),
        100,
      );
    });
  });
}
