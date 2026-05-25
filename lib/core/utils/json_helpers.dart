/// Helpers for parsing API JSON on web (JS interop may yield List vs Map).
library;

/// Coerces [value] to a string-keyed map, or returns [fallback] for null/lists.
Map<String, dynamic> asJsonMap(dynamic value, {Map<String, dynamic> fallback = const {}}) {
  if (value == null) return fallback;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return fallback;
}

/// Like [asJsonMap] but throws when [value] is not a map.
Map<String, dynamic> requireJsonMap(dynamic value, {String? field}) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  final label = field != null ? ' ($field)' : '';
  throw FormatException('Expected JSON object$label, got ${value.runtimeType}');
}
