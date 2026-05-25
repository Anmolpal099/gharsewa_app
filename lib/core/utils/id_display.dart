/// Safe short display for UUIDs and short legacy IDs.
String shortId(String id, [int maxLength = 8]) {
  if (id.isEmpty) return '—';
  if (id.length <= maxLength) return id;
  return id.substring(0, maxLength);
}
