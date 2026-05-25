import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/models.dart';
import '../data/services/provider_api_service.dart';
import 'provider_validators.dart';

final earningsAnalyzerProvider =
    StateNotifierProvider<EarningsAnalyzer, AsyncValue<EarningsData>>((ref) {
  return EarningsAnalyzer(ref.watch(providerApiServiceProvider));
});

class EarningsAnalyzer extends StateNotifier<AsyncValue<EarningsData>> {
  EarningsAnalyzer(this._api) : super(const AsyncValue.loading());

  final ProviderApiService _api;
  EarningsViewType _viewType = EarningsViewType.daily;

  EarningsViewType get viewType => _viewType;

  Future<void> fetchEarnings({EarningsViewType? viewType}) async {
    if (viewType != null) _viewType = viewType;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      if (_viewType == EarningsViewType.weekly) {
        return _api.getEarnings(
          startDate: now.subtract(const Duration(days: 28)),
          endDate: now,
          viewType: EarningsViewType.weekly,
        );
      }
      return _api.getEarnings(
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
        viewType: EarningsViewType.daily,
      );
    });
  }

  double calculatePercentageChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  String formatCurrency(double amount, {String locale = 'en_US'}) {
    final format = NumberFormat.simpleCurrency(locale: locale, name: 'NPR');
    return format.format(amount);
  }

  String formatPercentage(double value) =>
      ProviderValidators.formatPercentage(value);

  Future<EarningsData> getDailyEarnings() => _api.getEarnings(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        viewType: EarningsViewType.daily,
      );

  Future<EarningsData> getWeeklyEarnings() => _api.getEarnings(
        startDate: DateTime.now().subtract(const Duration(days: 28)),
        endDate: DateTime.now(),
        viewType: EarningsViewType.weekly,
      );
}
