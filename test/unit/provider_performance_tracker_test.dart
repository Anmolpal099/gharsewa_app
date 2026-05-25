import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/business_logic/performance_tracker.dart';
import 'package:gharsewa/features/provider_panel/business_logic/provider_validators.dart';
import 'package:gharsewa/features/provider_panel/data/models/performance_metrics.dart';

void main() {
  group('PerformanceTracker (13.3)', () {
    const tracker = PerformanceTracker();

    test('calculateAverageResponseTime averages minutes', () {
      final avg = tracker.calculateAverageResponseTime([
        const Duration(minutes: 10),
        const Duration(minutes: 20),
      ]);
      expect(avg.inMinutes, 15);
    });

    test('formatResponseTime uses validator formatting', () {
      expect(
        tracker.formatResponseTime(const Duration(minutes: 45)),
        ProviderValidators.formatResponseTime(const Duration(minutes: 45)),
      );
    });

    test('responseTimeColor maps tokens to Material colors', () {
      expect(
        tracker.responseTimeColor(const Duration(minutes: 5)),
        Colors.green,
      );
      expect(
        tracker.responseTimeColor(const Duration(minutes: 30)),
        Colors.orange,
      );
      expect(
        tracker.responseTimeColor(const Duration(minutes: 90)),
        Colors.red,
      );
    });

    test('isTopPerformer reads metrics flag', () {
      const top = PerformanceMetrics(
        rating: 4.9,
        totalReviews: 120,
        jobsCompleted: 40,
        averageResponseTime: Duration(minutes: 10),
        isTopPerformer: true,
        percentile: 92,
      );
      const regular = PerformanceMetrics(
        rating: 4.0,
        totalReviews: 10,
        jobsCompleted: 5,
        averageResponseTime: Duration(minutes: 40),
        isTopPerformer: false,
        percentile: 50,
      );
      expect(tracker.isTopPerformer(top), isTrue);
      expect(tracker.isTopPerformer(regular), isFalse);
    });
  });
}
