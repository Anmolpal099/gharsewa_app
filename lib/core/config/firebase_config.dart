import 'package:firebase_core/firebase_core.dart';
import 'env_config.dart';

/// Firebase Configuration Helper
/// Uses Firebase Authentication for real-time token generation and validation.
class FirebaseConfig {
  // Private constructor — static use only
  FirebaseConfig._();

  /// Firebase options built from environment variables
  static FirebaseOptions get currentPlatformOptions => const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
        appId: String.fromEnvironment('FIREBASE_APP_ID'),
        messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
      );

  /// Initialize Firebase with environment-specific configuration
  static Future<void> initialize() async {
    if (!EnvConfig.firebaseAuthEnabled) {
      assert(() {
        // ignore: avoid_print
        print('⚠️  Firebase authentication is disabled');
        return true;
      }());
      return;
    }

    await Firebase.initializeApp(options: currentPlatformOptions);

    assert(() {
      // ignore: avoid_print
      print('✅ Firebase initialized — project: ${EnvConfig.firebaseProjectId}');
      return true;
    }());
  }

  /// Returns true when all required Firebase config values are present
  static bool get isConfigured =>
      EnvConfig.firebaseApiKey.isNotEmpty &&
      EnvConfig.firebaseAppId.isNotEmpty &&
      EnvConfig.firebaseProjectId.isNotEmpty;

  /// Token refresh interval in milliseconds (default 1 hour)
  static int get tokenRefreshIntervalMs =>
      EnvConfig.firebaseTokenRefreshInterval * 1000;
}
