import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/presentation/widgets/paginated_list.dart';

void main() {
  testWidgets('PaginatedListView pages through items (28.3)', (tester) async {
    final items = List.generate(25, (i) => 'Item $i');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginatedListView<String>(
            pageSize: 20,
            items: items,
            itemBuilder: (_, item) => Text(item),
          ),
        ),
      ),
    );

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 24'), findsNothing);
    expect(find.text('Page 1 of 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(find.text('Item 24'), findsOneWidget);
    expect(find.text('Page 2 of 2'), findsOneWidget);
  });
}
