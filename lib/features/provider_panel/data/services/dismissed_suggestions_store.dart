import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final dismissedSuggestionsStoreProvider =
    Provider<DismissedSuggestionsStore>((ref) {
  return DismissedSuggestionsStore();
});

/// Persists dismissed AI suggestion IDs for 7 days (plan 8.5, 9.5).
class DismissedSuggestionsStore {
  static const _boxName = 'dismissed_suggestions';
  static const _ttl = Duration(days: 7);

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<bool> isDismissed(String suggestionId) async {
    final box = await _box();
    final raw = box.get(suggestionId);
    if (raw == null) return false;
    final dismissedAt = DateTime.parse(raw as String);
    if (DateTime.now().difference(dismissedAt) > _ttl) {
      await box.delete(suggestionId);
      return false;
    }
    return true;
  }

  Future<void> dismiss(String suggestionId) async {
    final box = await _box();
    await box.put(suggestionId, DateTime.now().toIso8601String());
  }

  Future<List<String>> filterActive(Iterable<String> ids) async {
    final active = <String>[];
    for (final id in ids) {
      if (!await isDismissed(id)) active.add(id);
    }
    return active;
  }

  Future<void> purgeExpired() async {
    final box = await _box();
    final keys = box.keys.toList();
    for (final key in keys) {
      await isDismissed(key.toString());
    }
  }
}
