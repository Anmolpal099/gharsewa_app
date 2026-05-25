import 'platform_detector.dart';

/// Platform-specific capabilities (Task 3.1.2).
class PlatformConfig {
  static PlatformConfig get current {
    if (PlatformDetector.isWeb) return PlatformConfig.web;
    if (PlatformDetector.isAndroid || PlatformDetector.isIOS) {
      return PlatformConfig.mobile;
    }
    return PlatformConfig.desktop;
  }

  static const PlatformConfig web = PlatformConfig._(
    name: 'web',
    supportsAdminPanel: true,
    supportsPushNotifications: false,
    supportsFilePicker: true,
    supportsDeepLinking: true,
    maxUploadSizeMb: 10,
  );

  static const PlatformConfig mobile = PlatformConfig._(
    name: 'mobile',
    supportsAdminPanel: false,
    supportsPushNotifications: true,
    supportsFilePicker: true,
    supportsDeepLinking: true,
    maxUploadSizeMb: 10,
  );

  static const PlatformConfig desktop = PlatformConfig._(
    name: 'desktop',
    supportsAdminPanel: true,
    supportsPushNotifications: false,
    supportsFilePicker: true,
    supportsDeepLinking: false,
    maxUploadSizeMb: 25,
  );

  const PlatformConfig._({
    required this.name,
    required this.supportsAdminPanel,
    required this.supportsPushNotifications,
    required this.supportsFilePicker,
    required this.supportsDeepLinking,
    required this.maxUploadSizeMb,
  });

  final String name;
  final bool supportsAdminPanel;
  final bool supportsPushNotifications;
  final bool supportsFilePicker;
  final bool supportsDeepLinking;
  final int maxUploadSizeMb;
}
