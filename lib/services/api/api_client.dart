import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../auth/token_storage.dart';
import 'api_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _JwtTokenInterceptor(),
      _ErrorHandlingInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  /// GET request with automatic error handling
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(path, queryParameters: params);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST request with automatic error handling
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PUT request with automatic error handling
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// DELETE request with automatic error handling
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Handle DioException and convert to ApiException with user-friendly messages
  ApiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Request timed out. Please try again.',
          type: ApiExceptionType.timeout,
          statusCode: null,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network settings.',
          type: ApiExceptionType.network,
          statusCode: null,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(e);

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          type: ApiExceptionType.cancelled,
          statusCode: null,
        );

      default:
        return ApiException(
          message: 'An unexpected error occurred. Please try again.',
          type: ApiExceptionType.unknown,
          statusCode: null,
        );
    }
  }

  /// Handle bad response (4xx, 5xx) and parse error messages
  ApiException _handleBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    // Try to extract error message from response
    String message = 'An error occurred. Please try again.';
    
    if (responseData is Map<String, dynamic>) {
      // Try common error message fields
      message = responseData['message'] ?? 
                responseData['error'] ?? 
                responseData['errors']?.toString() ?? 
                message;
    }

    if (statusCode != null) {
      if (statusCode >= 500) {
        // Server errors (5xx)
        return ApiException(
          message: 'Server error. Our team has been notified. Please try again later.',
          type: ApiExceptionType.server,
          statusCode: statusCode,
        );
      } else if (statusCode >= 400) {
        // Client errors (4xx)
        return ApiException(
          message: message,
          type: ApiExceptionType.client,
          statusCode: statusCode,
        );
      }
    }

    return ApiException(
      message: message,
      type: ApiExceptionType.unknown,
      statusCode: statusCode,
    );
  }
}

/// Token Interceptor for automatic JWT token management
/// 
/// Responsibilities:
/// 1. Attaches access token to every request
/// 2. Detects 401 Unauthorized responses (token expired)
/// 3. Automatically refreshes token and retries failed request
/// 4. Clears tokens if refresh fails (forces re-login)
class _JwtTokenInterceptor extends Interceptor {
  // Dio instance for token refresh (separate from main client to avoid recursion)
  final _refreshDio = Dio();
  
  // Lock to prevent multiple simultaneous refresh attempts
  bool _isRefreshing = false;
  final List<_RequestRetry> _pendingRequests = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login, register, and refresh endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    // Add JWT token to headers
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      // Skip token refresh for auth endpoints
      if (_isAuthEndpoint(err.requestOptions.path)) {
        return handler.next(err);
      }
      
      // If already refreshing, queue this request
      if (_isRefreshing) {
        _pendingRequests.add(_RequestRetry(
          requestOptions: err.requestOptions,
          handler: handler,
        ));
        return;
      }
      
      _isRefreshing = true;
      
      try {
        // Try to refresh token
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken == null) {
          throw Exception('No refresh token available');
        }
        
        // Configure refresh dio with base URL
        _refreshDio.options.baseUrl = ApiConstants.baseUrl;
        _refreshDio.options.headers = {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        };
        
        final response = await _refreshDio.post('/v1/auth/jwt/refresh', data: {
          'refresh_token': refreshToken,
        });

        if (response.data['success'] == true) {
          final data = response.data['data'];
          
          // Save new tokens
          await TokenStorage.saveTokens(
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'],
            expiresIn: data['expires_in'],
          );

          final newAccessToken = data['access_token'];
          
          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          
          final dio = Dio(BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          ));
          
          final retryResponse = await dio.fetch(err.requestOptions);
          
          // Retry all pending requests
          for (final pending in _pendingRequests) {
            pending.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final pendingResponse = await dio.fetch(pending.requestOptions);
            pending.handler.resolve(pendingResponse);
          }
          _pendingRequests.clear();
          
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        } else {
          throw Exception('Token refresh failed');
        }
      } catch (e) {
        // Refresh failed, clear tokens and reject all pending requests
        await TokenStorage.clearAll();
        
        for (final pending in _pendingRequests) {
          pending.handler.reject(err);
        }
        _pendingRequests.clear();
        
        _isRefreshing = false;
        return handler.next(err);
      }
    }
    
    handler.next(err);
  }
  
  /// Check if endpoint is an auth endpoint (skip token attachment)
  bool _isAuthEndpoint(String path) {
    return path.contains('/login') ||
           path.contains('/register') ||
           path.contains('/refresh') ||
           path.contains('/logout') ||
           path.contains('/otp/');
  }
}

/// Error Handling Interceptor with exponential backoff retry
/// 
/// Responsibilities:
/// 1. Implements exponential backoff for failed requests
/// 2. Retries network errors and timeouts automatically
/// 3. Does not retry client errors (4xx) or server errors (5xx)
class _ErrorHandlingInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only retry on network errors and timeouts
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
      
      if (retryCount < maxRetries) {
        // Calculate exponential backoff delay: 1s, 2s, 4s
        final delay = initialDelay * (1 << retryCount);
        
        // Wait before retrying
        await Future.delayed(delay);
        
        // Increment retry count
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        
        try {
          // Retry the request
          final dio = Dio(BaseOptions(
            baseUrl: err.requestOptions.baseUrl,
            connectTimeout: err.requestOptions.connectTimeout,
            receiveTimeout: err.requestOptions.receiveTimeout,
            headers: err.requestOptions.headers,
          ));
          
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // If retry fails, continue with error handling
          if (e is DioException) {
            return handler.next(e);
          }
        }
      }
    }
    
    handler.next(err);
  }

  /// Determine if request should be retried
  bool _shouldRetry(DioException err) {
    // Retry on network errors and timeouts
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError;
  }
}

/// Helper class to queue requests during token refresh
class _RequestRetry {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  
  _RequestRetry({
    required this.requestOptions,
    required this.handler,
  });
}
