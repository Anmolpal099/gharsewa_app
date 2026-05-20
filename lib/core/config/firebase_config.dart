import 'package:firebase_core/firebase_core.dart';
import 'env_config.dart';

/// Firebase Configuration Helper
/// Uses Firebase Authentication for real-time token generation and validation.
class FirebaseConfig {
  // Private constructor — static use only
  FirebaseConfig._();

  /// Firebase options built from environment variables
  static FirebaseOptions get currentPlatformOptions => const FirebaseOptions(
        apiKey: 'AIzaSyAld-M6F5glVaVYDaCoUQ8OsJLNdmc4BX8',
        appId: '1:968565700465:web:7d66f1eab7fb98f44e68d0',
        messagingSenderId: '968565700465',
        projectId: 'homeservice-bf77e',
        storageBucket: 'homeservice-bf77e.firebasestorage.app',
        authDomain: 'homeservice-bf77e.firebaseapp.com',
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
