import 'package:flutter/material.dart';

/// Configuration for chart rendering

class ChartConfig {
  final Color barColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final double barWidth;
  final bool showGrid;
  final bool enableTouch;
  final Duration animationDuration;

  const ChartConfig({
    required this.barColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    this.barWidth = 22.0,
    this.showGrid = true,
    this.enableTouch = true,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  /// Default configuration with primary color
  factory ChartConfig.defaultConfig({Color? primaryColor}) {
    final color = primaryColor ?? Colors.blue;
    return ChartConfig(
      barColor: color,
      gradientStartColor: color.withValues(alpha: 0.8),
      gradientEndColor: color.withValues(alpha: 0.3),
    );
  }

  /// Configuration for earnings chart with green gradient
  factory ChartConfig.earnings() {
    return const ChartConfig(
      barColor: Color(0xFF4CAF50),
      gradientStartColor: Color(0xFF4CAF50),
      gradientEndColor: Color(0xFF81C784),
    );
  }

  ChartConfig copyWith({
    Color? barColor,
    Color? gradientStartColor,
    Color? gradientEndColor,
    double? barWidth,
    bool? showGrid,
    bool? enableTouch,
    Duration? animationDuration,
  }) {
    return ChartConfig(
      barColor: barColor ?? this.barColor,
      gradientStartColor: gradientStartColor ?? this.gradientStartColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      barWidth: barWidth ?? this.barWidth,
      showGrid: showGrid ?? this.showGrid,
      enableTouch: enableTouch ?? this.enableTouch,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChartConfig &&
        other.barColor == barColor &&
        other.gradientStartColor == gradientStartColor &&
        other.gradientEndColor == gradientEndColor &&
        other.barWidth == barWidth &&
        other.showGrid == showGrid &&
        other.enableTouch == enableTouch &&
        other.animationDuration == animationDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      barColor,
      gradientStartColor,
      gradientEndColor,
      barWidth,
      showGrid,
      enableTouch,
      animationDuration,
    );
  }
}
