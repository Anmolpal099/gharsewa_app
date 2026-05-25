import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/platform_config.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Push/local notifications facade (Task 1.1.2 / 5.x).
/// Firebase Messaging can be wired when FCM credentials are configured.
class NotificationService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!PlatformConfig.current.supportsPushNotifications) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('NotificationService: push disabled on ${PlatformConfig.current.name}');
      }
      _initialized = true;
      return;
    }
    // Placeholder for firebase_messaging when enabled in build flavors.
    _initialized = true;
  }

  Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Notification: $title — $body');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Notification subscribe: $topic');
    }
  }
}
