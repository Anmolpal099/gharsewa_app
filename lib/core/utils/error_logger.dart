/// Error logging utility for debugging and monitoring
/// 
/// Provides centralized error logging with context information
/// including timestamp, screen name, and error details.
/// 
/// Usage:
/// ```dart
/// logError('ScreenName', 'Operation failed', error, stackTrace);
/// ```

import 'package:flutter/foundation.dart';

/// Logs an error with context information
/// 
/// Parameters:
/// - [screen]: Name of the screen or component where error occurred
/// - [message]: Human-readable error message
/// - [error]: Optional error object
/// - [stackTrace]: Optional stack trace for debugging
void logError(
  String screen,
  String message, [
  Object? error,
  StackTrace? stackTrace,
]) {
  if (!kDebugMode) return; // Only log in debug mode

  final timestamp = DateTime.now().toIso8601String();
  debugPrint('[$timestamp] [$screen] ERROR: $message');

  if (error != null) {
    debugPrint('  Error Details: $error');
  }

  if (stackTrace != null) {
    debugPrint('  Stack Trace:\n$stackTrace');
  }
}

/// Logs a warning with context information
/// 
/// Parameters:
/// - [screen]: Name of the screen or component
/// - [message]: Warning message
void logWarning(String screen, String message) {
  if (!kDebugMode) return;

  final timestamp = DateTime.now().toIso8601String();
  debugPrint('[$timestamp] [$screen] WARNING: $message');
}

/// Logs an info message with context information
/// 
/// Parameters:
/// - [screen]: Name of the screen or component
/// - [message]: Info message
void logInfo(String screen, String message) {
  if (!kDebugMode) return;

  final timestamp = DateTime.now().toIso8601String();
  debugPrint('[$timestamp] [$screen] INFO: $message');
}
