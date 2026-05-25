import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/performance_metrics.dart';
import '../data/services/provider_api_service.dart';
import 'dashboard_controller.dart';
import 'provider_validators.dart';

final performanceTrackerProvider =
    FutureProvider<PerformanceMetrics>((ref) async {
  final api = ref.watch(providerApiServiceProvider);
  try {
    return await api.getProviderMetricsFromApi();
  } catch (_) {
    final dashboard = await ref.watch(dashboardControllerProvider.future);
    return api.getProviderMetrics(dashboard.dashboard);
  }
});

/// Performance metrics helpers (plan task 3.10).
class PerformanceTracker {
  const PerformanceTracker();

  Duration calculateAverageResponseTime(List<Duration> times) {
    if (times.isEmpty) return Duration.zero;
    final totalMinutes =
        times.fold<int>(0, (sum, d) => sum + d.inMinutes) / times.length;
    return Duration(minutes: totalMinutes.round());
  }

  bool isTopPerformer(PerformanceMetrics metrics) => metrics.isTopPerformer;

  String formatResponseTime(Duration duration) =>
      ProviderValidators.formatResponseTime(duration);

  Color responseTimeColor(Duration duration) {
    switch (ProviderValidators.responseTimeColor(duration)) {
      case ColorToken.green:
        return Colors.green;
      case ColorToken.yellow:
        return Colors.orange;
      case ColorToken.red:
        return Colors.red;
    }
  }
}

final performanceTrackerHelpersProvider =
    Provider<PerformanceTracker>((ref) => const PerformanceTracker());
