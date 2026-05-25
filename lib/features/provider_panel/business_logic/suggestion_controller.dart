import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/suggestion.dart';
import '../data/services/dismissed_suggestions_store.dart';
import 'ai_suggestion_engine.dart';
import 'dashboard_controller.dart';

final dashboardSuggestionsProvider =
    FutureProvider<List<Suggestion>>((ref) async {
  final store = ref.watch(dismissedSuggestionsStoreProvider);
  await store.purgeExpired();
  final snapshot = await ref.watch(dashboardControllerProvider.future);
  final engine = ref.watch(aiSuggestionEngineProvider);
  final all = engine.generateDashboardSuggestions(snapshot.dashboard);
  final ids = await store.filterActive(all.map((s) => s.id));
  return all.where((s) => ids.contains(s.id)).toList();
});
