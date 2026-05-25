import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Provider panel M3 tokens (plan 14.1).
class ProviderPanelTheme {
  ProviderPanelTheme._();

  static const double cardRadius = 16;
  static const double chipRadius = 20;
  static const Duration transitionDuration = Duration(milliseconds: 300);

  static ThemeData theme(BuildContext context) {
    final base = AppTheme.providerTheme;
    return base.copyWith(
      cardTheme: base.cardTheme?.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        elevation: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }

  static List<Color> earningsGradient = [
    AppTheme.primaryGreen,
    AppTheme.primaryGreen.withValues(alpha: 0.7),
  ];

  static List<Color> suggestionGradient = const [
    Color(0xFF7B1FA2),
    Color(0xFF9C27B0),
  ];
}
