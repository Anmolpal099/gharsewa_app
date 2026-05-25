import '../constants/api_constants.dart';

/// Resolves relative Laravel storage paths to absolute URLs.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final origin = ApiConstants.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  final path = url.startsWith('/') ? url : '/$url';
  return '$origin$path';
}
