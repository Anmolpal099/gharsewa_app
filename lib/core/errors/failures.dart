import 'app_exception.dart';

/// Domain-friendly failure mapping (Epic 1.1.2).
class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  factory Failure.fromException(Object error) {
    if (error is AppException) {
      return Failure(error.message, code: error.code);
    }
    return Failure(error.toString());
  }
}
