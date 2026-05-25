import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';

final aiSuggestionEngineProvider = Provider<AiSuggestionEngine>((ref) {
  return const AiSuggestionEngine();
});

class AiSuggestionEngine {
  const AiSuggestionEngine();

  List<Suggestion> generateProfileSuggestions(ProviderProfile profile) {
    final suggestions = <Suggestion>[];
    if (profile.completeness < 100) {
      suggestions.add(
        Suggestion(
          id: 'profile-complete',
          title: 'Complete your profile',
          description:
              'You are at ${profile.completeness.toInt()}%. ${profile.missingItems.join(', ')}.',
          type: SuggestionType.profileImprovement,
          priority: SuggestionPriority.high,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (profile.skills.length < 3) {
      suggestions.add(
        Suggestion(
          id: 'add-skills',
          title: 'Add more skills',
          description: 'Providers with 3+ skills get more booking requests.',
          type: SuggestionType.profileImprovement,
          priority: SuggestionPriority.medium,
          createdAt: DateTime.now(),
        ),
      );
    }
    return prioritizeSuggestions(suggestions);
  }

  List<Suggestion> generateDashboardSuggestions(Map<String, dynamic> dashboard) {
    final pending = dashboard['pending_bookings'] as int? ?? 0;
    final suggestions = <Suggestion>[];
    if (pending > 0) {
      suggestions.add(
        Suggestion(
          id: 'pending-requests',
          title: '$pending pending request${pending == 1 ? '' : 's'}',
          description: 'Respond quickly to improve your response-time score.',
          type: SuggestionType.availabilityAdjustment,
          priority: SuggestionPriority.high,
          createdAt: DateTime.now(),
        ),
      );
    }
    final rating = (dashboard['average_rating'] as num?)?.toDouble() ?? 0;
    if (rating < 4) {
      suggestions.add(
        Suggestion(
          id: 'improve-rating',
          title: 'Boost your rating',
          description: 'Ask satisfied customers to leave reviews after jobs.',
          type: SuggestionType.performanceOptimization,
          priority: SuggestionPriority.medium,
          createdAt: DateTime.now(),
        ),
      );
    }
    return prioritizeSuggestions(suggestions);
  }

  List<Suggestion> prioritizeSuggestions(List<Suggestion> items) {
    final order = {
      SuggestionPriority.high: 0,
      SuggestionPriority.medium: 1,
      SuggestionPriority.low: 2,
    };
    final sorted = List<Suggestion>.from(items);
    sorted.sort(
      (a, b) => (order[a.priority] ?? 3).compareTo(order[b.priority] ?? 3),
    );
    return sorted;
  }
}
