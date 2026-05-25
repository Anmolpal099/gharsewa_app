# API Client Service

## Overview

The API Client service provides a robust HTTP client wrapper for communicating with the Gharsewa backend API. It includes authentication token management, automatic error handling, exponential backoff retry logic, and user-friendly error messages.

## Features

### ✅ Base URL Configuration
- Configured to use `http://localhost:8000/api` by default
- Can be overridden using environment variables
- Supports both web and mobile platforms

### ✅ Authentication Token Injection
- Automatically attaches JWT access tokens to all requests
- Skips token attachment for auth endpoints (login, register, refresh)
- Handles token refresh automatically when tokens expire (401 responses)
- Queues pending requests during token refresh to avoid race conditions

### ✅ Error Parsing
- Distinguishes between network errors, timeouts, client errors (4xx), and server errors (5xx)
- Provides user-friendly error messages for each error type
- Extracts error messages from API responses when available
- Throws structured `ApiException` with error type and status code

### ✅ Timeout Configuration
- 30-second timeout for both connection and data reception
- Configurable per request if needed

### ✅ Exponential Backoff Retry
- Automatically retries failed requests with exponential backoff
- Retry delays: 1s, 2s, 4s (max 3 retries)
- Only retries network errors and timeouts (not 4xx/5xx errors)
- Prevents overwhelming the server with rapid retries

## Usage

### Basic Usage

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/services/api/api_client.dart';
import 'package:gharsewa/services/api/api_exception.dart';

class MyService {
  final ApiClient _apiClient;

  MyService(this._apiClient);

  Future<Map<String, dynamic>> fetchData() async {
    try {
      final response = await _apiClient.get('/v1/provider/profile/123');
      return response.data;
    } on ApiException catch (e) {
      // Handle specific error types
      switch (e.type) {
        case ApiExceptionType.network:
          // Show "No internet connection" message
          print('Network error: ${e.message}');
          break;
        case ApiExceptionType.timeout:
          // Show "Request timed out" message
          print('Timeout error: ${e.message}');
          break;
        case ApiExceptionType.server:
          // Show "Server error" message
          print('Server error: ${e.message}');
          break;
        case ApiExceptionType.client:
          // Show specific error message from API
          print('Client error: ${e.message}');
          break;
        default:
          print('Unknown error: ${e.message}');
      }
      rethrow;
    }
  }
}
```

### Using with Riverpod

```dart
final myServiceProvider = Provider<MyService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MyService(apiClient);
});
```

### Making Requests

#### GET Request
```dart
final response = await apiClient.get('/v1/provider/profile/123');
final data = response.data;
```

#### GET Request with Query Parameters
```dart
final response = await apiClient.get(
  '/v1/provider/earnings',
  params: {
    'start_date': '2024-01-01',
    'end_date': '2024-01-31',
  },
);
```

#### POST Request
```dart
final response = await apiClient.post(
  '/v1/provider/skills',
  data: {
    'skill': 'Certified Electrician',
  },
);
```

#### PUT Request
```dart
final response = await apiClient.put(
  '/v1/provider/profile/123',
  data: {
    'bio': 'Experienced electrician with 10 years of expertise',
  },
);
```

#### DELETE Request
```dart
final response = await apiClient.delete('/v1/provider/skills/456');
```

## Error Handling

### Error Types

The API client throws `ApiException` with the following types:

| Type | Description | User Message |
|------|-------------|--------------|
| `network` | No internet connection | "No internet connection. Please check your network settings." |
| `timeout` | Request timed out | "Request timed out. Please try again." |
| `client` | Client error (4xx) | Specific error message from API |
| `server` | Server error (5xx) | "Server error. Our team has been notified. Please try again later." |
| `cancelled` | Request was cancelled | "Request was cancelled." |
| `unknown` | Unknown error | "An unexpected error occurred. Please try again." |

### Error Handling Best Practices

1. **Always catch ApiException**: Wrap API calls in try-catch blocks
2. **Handle specific error types**: Use switch statements to handle different error types
3. **Show user-friendly messages**: Display the error message from ApiException to users
4. **Log detailed errors**: Log the full exception for debugging purposes
5. **Provide retry options**: For network and timeout errors, offer users a retry button

### Example Error Handling

```dart
Future<void> loadProfile() async {
  try {
    final response = await _apiClient.get('/v1/provider/profile/123');
    // Process response
  } on ApiException catch (e) {
    // Log detailed error for debugging
    logger.error('Failed to load profile', error: e);
    
    // Show user-friendly message
    if (e.type == ApiExceptionType.network || e.type == ApiExceptionType.timeout) {
      // Show retry button
      showErrorDialog(
        message: e.message,
        retryAction: () => loadProfile(),
      );
    } else {
      // Show simple error message
      showErrorDialog(message: e.message);
    }
  }
}
```

## Authentication Flow

### Token Management

The API client automatically manages JWT tokens:

1. **Token Injection**: Attaches access token to every request (except auth endpoints)
2. **Token Refresh**: When a 401 response is received:
   - Automatically calls the refresh token endpoint
   - Saves new tokens to secure storage
   - Retries the original request with the new token
   - Retries all queued requests with the new token
3. **Token Expiry**: If refresh fails, clears all tokens and forces re-login

### Auth Endpoints (No Token Required)

The following endpoints do not require authentication tokens:
- `/login`
- `/register`
- `/refresh`
- `/logout`
- `/otp/*`

## Retry Logic

### Exponential Backoff

The API client implements exponential backoff for failed requests:

- **Retry 1**: Wait 1 second, then retry
- **Retry 2**: Wait 2 seconds, then retry
- **Retry 3**: Wait 4 seconds, then retry
- **After 3 retries**: Give up and throw error

### What Gets Retried

Only the following errors are retried:
- Connection timeout
- Send timeout
- Receive timeout
- Connection error (no internet)

### What Does NOT Get Retried

The following errors are NOT retried:
- Client errors (4xx) - these indicate invalid requests
- Server errors (5xx) - these indicate server issues that won't be fixed by retrying
- Cancelled requests - user intentionally cancelled

## Configuration

### Base URL

The base URL can be configured using environment variables:

```bash
# Development
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api

# Production
flutter run --dart-define=API_BASE_URL=https://api.gharsewa.com/api
```

### Timeout

The default timeout is 30 seconds. To change it, modify the `ApiClient` constructor:

```dart
ApiClient() {
  _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 60), // Change here
    receiveTimeout: const Duration(seconds: 60), // Change here
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  ));
  // ...
}
```

## Testing

### Unit Tests

Unit tests are located in `test/unit/api_client_test.dart`.

Run tests:
```bash
flutter test test/unit/api_client_test.dart
```

### Integration Tests

For integration testing with a real backend, use the `integration_test` package.

## Requirements Validation

This implementation satisfies the following requirements:

- ✅ **Requirement 25.1**: Backend API endpoints integration
- ✅ **Requirement 26.1**: User-friendly error messages for network failures
- ✅ **Requirement 26.2**: Distinguish between network errors and server errors
- ✅ **Requirement 26.3**: Timeout message with retry option
- ✅ **Requirement 26.4**: Exponential backoff for automatic retries
- ✅ **Requirement 26.6**: Detailed error logging for debugging

## Architecture

### Components

1. **ApiClient**: Main HTTP client wrapper
2. **_JwtTokenInterceptor**: Handles JWT token injection and refresh
3. **_ErrorHandlingInterceptor**: Implements exponential backoff retry
4. **ApiException**: Structured exception with error type and message
5. **ApiExceptionType**: Enum for error categorization

### Flow Diagram

```
Request → ApiClient → Interceptors → Dio → Backend
                         ↓
                   Token Injection
                         ↓
                   Error Handling
                         ↓
                   Retry Logic
                         ↓
                   Response/Error
```

## Future Enhancements

- [ ] Request caching for GET requests
- [ ] Request deduplication (prevent duplicate simultaneous requests)
- [ ] Request cancellation tokens
- [ ] Upload/download progress callbacks
- [ ] Request/response logging levels (debug, info, error)
- [ ] Custom retry strategies per endpoint
- [ ] Circuit breaker pattern for failing endpoints
