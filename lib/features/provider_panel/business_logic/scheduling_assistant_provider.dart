import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/scheduling_suggestion.dart';

/// Placeholder scheduling assistant data until the real model/API is wired.
final schedulingAssistantProvider = Provider<SchedulingSuggestion?>((ref) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 11);
  return SchedulingSuggestion(
    gapDuration: const Duration(hours: 2),
    gapStart: tomorrow,
  );
});
