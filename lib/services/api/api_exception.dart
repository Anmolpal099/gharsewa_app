/// Custom exception class for API errors
/// 
/// Provides structured error information with user-friendly messages
/// and error types for proper handling in the UI layer.
class ApiException implements Exception {
  /// User-friendly error message
  final String message;
  
  /// Type of error for categorization
  final ApiExceptionType type;
  
  /// HTTP status code (if available)
  final int? statusCode;

  ApiException({
    required this.message,
    required this.type,
    this.statusCode,
  });

  @override
  String toString() {
    return 'ApiException: $message (type: $type, statusCode: $statusCode)';
  }
}

/// Types of API exceptions
enum ApiExceptionType {
  /// Network connection error (no internet)
  network,
  
  /// Request timeout
  timeout,
  
  /// Client error (4xx status codes)
  client,
  
  /// Server error (5xx status codes)
  server,
  
  /// Request was cancelled
  cancelled,
  
  /// Unknown error
  unknown,
}
