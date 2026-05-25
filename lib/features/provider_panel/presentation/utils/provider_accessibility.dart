import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WCAG-oriented helpers: haptics, touch targets (plan 13.1, 27.x).
class ProviderAccessibility {
  ProviderAccessibility._();

  static const double minTouchTarget = 48;

  static Future<void> lightImpact() => HapticFeedback.lightImpact();

  static Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  static void onAcceptRequest() => mediumImpact();

  static void onSaveProfile() => lightImpact();

  static ButtonStyle minTouchButton(ButtonStyle? style) {
    return (style ?? const ButtonStyle()).copyWith(
      minimumSize: const WidgetStatePropertyAll(
        Size(minTouchTarget, minTouchTarget),
      ),
    );
  }
}
