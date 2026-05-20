/// Environment Configuration
/// This file manages environment-specific configuration
class EnvConfig {
  // Private constructor
  EnvConfig._();

  // Environment type
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30000,
  );

  // Debug Mode
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );

  static const String firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: '',
  );

  // Firebase Authentication Settings
  static const bool firebaseAuthEnabled = bool.fromEnvironment(
    'FIREBASE_AUTH_ENABLED',
    defaultValue: true,
  );

  static const int firebaseTokenRefreshInterval = int.fromEnvironment(
    'FIREBASE_TOKEN_REFRESH_INTERVAL',
    defaultValue: 3600, // 1 hour in seconds
  );

  // Stripe Configuration
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  // Pusher Configuration
  static const String pusherAppKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: '',
  );

  static const String pusherCluster = String.fromEnvironment(
    'PUSHER_CLUSTER',
    defaultValue: 'ap2',
  );

  // App Configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Gharsewa',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // Helper methods
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // Print configuration (for debugging only)
  static void printConfig() {
    assert(() {
      // ignore: avoid_print
      print('=== Environment Configuration ===');
      // ignore: avoid_print
      print('Environment: $environment');
      // ignore: avoid_print
      print('API Base URL: $apiBaseUrl');
      // ignore: avoid_print
      print('Debug Mode: $debugMode');
      // ignore: avoid_print
      print('App Name: $appName');
      // ignore: avoid_print
      print('App Version: $appVersion');
      // ignore: avoid_print
      print('================================');
      return true;
    }());
  }
}
