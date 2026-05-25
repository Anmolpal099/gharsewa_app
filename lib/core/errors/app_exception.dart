/// Application-level exceptions (Epic 1.1.2 / 5.2).
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed']);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.field});

  final String? field;
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error']);
}
