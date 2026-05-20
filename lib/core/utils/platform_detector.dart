import 'package:flutter/foundation.dart';

/// Detects the current platform and provides platform-specific capabilities
class PlatformDetector {
  PlatformDetector._();

  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Admin panel is web-only
  static bool get supportsAdminPanel => isWeb;

  /// Customer and Provider panels are mobile-only
  static bool get supportsMobilePanel => isMobile;

  static String get platformName {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isDesktop) return 'desktop';
    return 'unknown';
  }
}
