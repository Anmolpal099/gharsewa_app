import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/business_logic/earnings_analyzer.dart';
import 'package:gharsewa/features/provider_panel/business_logic/provider_validators.dart';
import 'package:gharsewa/features/provider_panel/data/services/provider_api_service.dart';
import 'package:gharsewa/services/api/api_client.dart';

void main() {
  group('EarningsAnalyzer (5.3)', () {
    late EarningsAnalyzer analyzer;

    setUp(() {
      analyzer = EarningsAnalyzer(ProviderApiService(ApiClient()));
    });

    test('calculatePercentageChange matches validators', () {
      expect(analyzer.calculatePercentageChange(150, 100), 50);
      expect(analyzer.calculatePercentageChange(50, 100), -50);
      expect(analyzer.calculatePercentageChange(100, 0), 0);
    });

    test('formatPercentage delegates to ProviderValidators', () {
      expect(
        analyzer.formatPercentage(12.34),
        ProviderValidators.formatPercentage(12.34),
      );
    });

    test('formatCurrency returns non-empty formatted amount', () {
      final text = analyzer.formatCurrency(1200);
      expect(text, isNotEmpty);
      expect(text.replaceAll(RegExp(r'[^0-9]'), ''), contains('1200'));
    });
  });
}
