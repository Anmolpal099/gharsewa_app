import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/admin_panel/presentation/widgets/ai_analytics_section.dart';
import 'package:gharsewa/services/ai/models/ai_prediction.dart';
import 'package:gharsewa/services/ai/models/ai_trend.dart';

void main() {
  group('AIAnalyticsSection Widget Tests', () {
    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AIAnalyticsSection(),
            ),
          ),
        ),
      );

      // Should show loading indicators
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays AI Analytics title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AIAnalyticsSection(),
            ),
          ),
        ),
      );

      // Should display the title
      expect(find.text('AI Analytics'), findsOneWidget);
    });

    testWidgets('displays refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AIAnalyticsSection(),
            ),
          ),
        ),
      );

      // Should display refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('PredictionsWidget Tests', () {
    testWidgets('displays predictions correctly', (WidgetTester tester) async {
      final mockPrediction = AIPrediction(
        bookingVolume: BookingVolumePrediction(
          predictions: [
            PredictionPoint(date: '2024-01-01', value: 100, confidence: 85),
            PredictionPoint(date: '2024-01-02', value: 110, confidence: 80),
          ],
          insights: 'Test insights',
          confidenceScore: 85,
          factors: ['factor1', 'factor2'],
        ),
        cached: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionsWidget(predictions: mockPrediction),
          ),
        ),
      );

      // Should display predictions title
      expect(find.text('Predictions (Next 7 Days)'), findsOneWidget);
      expect(find.text('Booking Volume Forecast'), findsOneWidget);
      expect(find.text('Test insights'), findsOneWidget);
    });
  });

  group('TrendsWidget Tests', () {
    testWidgets('displays trends correctly', (WidgetTester tester) async {
      final mockTrend = AITrend(
        trendingServices: [
          TrendingService(
            serviceName: 'Plumbing',
            category: 'Home Repair',
            growthRate: 25.5,
            currentBookings: 150,
            previousBookings: 120,
          ),
        ],
        decliningServices: [
          DecliningService(
            serviceName: 'Painting',
            category: 'Home Improvement',
            declineRate: 10.2,
            currentBookings: 80,
            previousBookings: 90,
          ),
        ],
        peakHours: [],
        insights: 'Test trend insights',
        cached: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendsWidget(trends: mockTrend),
          ),
        ),
      );

      // Should display trends title
      expect(find.text('Service Trends'), findsOneWidget);
      expect(find.text('Trending Services'), findsOneWidget);
      expect(find.text('Declining Services'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Painting'), findsOneWidget);
    });

    testWidgets('displays growth and decline indicators', (WidgetTester tester) async {
      final mockTrend = AITrend(
        trendingServices: [
          TrendingService(
            serviceName: 'Plumbing',
            category: 'Home Repair',
            growthRate: 25.5,
            currentBookings: 150,
            previousBookings: 120,
          ),
        ],
        decliningServices: [
          DecliningService(
            serviceName: 'Painting',
            category: 'Home Improvement',
            declineRate: 10.2,
            currentBookings: 80,
            previousBookings: 90,
          ),
        ],
        peakHours: [],
        insights: 'Test trend insights',
        cached: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendsWidget(trends: mockTrend),
          ),
        ),
      );

      // Should display up and down arrows
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });

  group('InsightsWidget Tests', () {
    testWidgets('displays insights correctly', (WidgetTester tester) async {
      final mockInsights = {
        'summary': 'Overall platform performance is strong',
        'insights': [
          {
            'category': 'Revenue',
            'message': 'Revenue is trending upward',
            'confidence': 90.0,
            'priority': 'high',
          },
          {
            'category': 'Operations',
            'message': 'Provider response time has improved',
            'confidence': 75.0,
            'priority': 'medium',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InsightsWidget(insights: mockInsights),
          ),
        ),
      );

      // Should display insights title
      expect(find.text('AI Insights'), findsOneWidget);
      expect(find.text('Overall platform performance is strong'), findsOneWidget);
      expect(find.text('Key Insights'), findsOneWidget);
      expect(find.text('Revenue is trending upward'), findsOneWidget);
      expect(find.text('Provider response time has improved'), findsOneWidget);
    });

    testWidgets('displays confidence indicators', (WidgetTester tester) async {
      final mockInsights = {
        'summary': 'Test summary',
        'insights': [
          {
            'category': 'Test',
            'message': 'Test message',
            'confidence': 85.0,
            'priority': 'high',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InsightsWidget(insights: mockInsights),
          ),
        ),
      );

      // Should display confidence percentage
      expect(find.text('85%'), findsOneWidget);
    });
  });
}
