import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/services/provider_api_service.dart';
import 'ai_suggestion_engine.dart';

final dashboardControllerProvider =
    FutureProvider<DashboardSnapshot>((ref) async {
  final api = ref.watch(providerApiServiceProvider);
  final engine = ref.watch(aiSuggestionEngineProvider);

  final dashboard = await api.getDashboard();
  final metrics = await api.getProviderMetrics(dashboard);
  final suggestions = engine.generateDashboardSuggestions(dashboard);

  return DashboardSnapshot(
    dashboard: dashboard,
    metrics: metrics,
    suggestions: suggestions,
  );
});

class DashboardSnapshot {
  final Map<String, dynamic> dashboard;
  final PerformanceMetrics metrics;
  final List<Suggestion> suggestions;

  const DashboardSnapshot({
    required this.dashboard,
    required this.metrics,
    required this.suggestions,
  });
}
