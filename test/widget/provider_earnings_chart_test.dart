import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/data/models/earnings_data.dart';
import 'package:gharsewa/features/provider_panel/data/models/enums.dart';
import 'package:gharsewa/features/provider_panel/presentation/widgets/earnings_chart.dart';

void main() {
  EarningsData sampleData() {
    final now = DateTime.now();
    return EarningsData(
      totalEarnings: 15000,
      previousPeriodEarnings: 12000,
      dataPoints: List.generate(
        3,
        (i) => EarningsDataPoint(
          date: now.subtract(Duration(days: i)),
          amount: 1000 + i * 500,
          label: 'D$i',
        ),
      ),
      dateRange: DateRange(startDate: now.subtract(const Duration(days: 7)), endDate: now),
      viewType: EarningsViewType.daily,
    );
  }

  testWidgets('EarningsChart shows total and view toggle (5.4)', (tester) async {
    var view = EarningsViewType.daily;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarningsChart(
            data: sampleData(),
            viewType: view,
            onViewTypeChanged: (v) => view = v,
            formatCurrency: (a) => 'NPR ${a.toStringAsFixed(0)}',
            formatPercentage: (p) => '+${p.toStringAsFixed(1)}%',
          ),
        ),
      ),
    );

    expect(find.textContaining('NPR 15000'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(view, EarningsViewType.weekly);
  });
}
