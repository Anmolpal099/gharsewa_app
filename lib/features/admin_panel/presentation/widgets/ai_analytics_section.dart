import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/ai/ai_api_service.dart';
import '../../../../services/ai/models/ai_prediction.dart';
import '../../../../services/ai/models/ai_trend.dart';
import '../../../../services/api/ai_consultation_api_service.dart';

/// Provider for AI predictions
final aiPredictionsProvider = FutureProvider.autoDispose<AIPrediction>((ref) async {
  final aiService = ref.watch(aiApiServiceProvider);
  return await aiService.getPredictions(type: 'all', days: 7);
});

/// Provider for AI trends
final aiTrendsProvider = FutureProvider.autoDispose<AITrend>((ref) async {
  final aiService = ref.watch(aiApiServiceProvider);
  return await aiService.getTrends();
});

/// Provider for AI insights
final aiInsightsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final aiService = ref.watch(aiApiServiceProvider);
  return await aiService.getInsights();
});

/// Main AI Analytics Section Widget
class AIAnalyticsSection extends ConsumerWidget {
  const AIAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(aiPredictionsProvider);
    final trendsAsync = ref.watch(aiTrendsProvider);
    final insightsAsync = ref.watch(aiInsightsProvider);
    final consultationAnalyticsAsync = ref.watch(aiConsultationAnalyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Analytics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(aiPredictionsProvider);
                ref.invalidate(aiTrendsProvider);
                ref.invalidate(aiInsightsProvider);
                ref.invalidate(aiConsultationAnalyticsProvider);
              },
              tooltip: 'Refresh Analytics',
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // AI Consultation Analytics Section
        consultationAnalyticsAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading consultation analytics: $error'),
            ),
          ),
          data: (analytics) => AIConsultationAnalyticsWidget(analytics: analytics),
        ),
        
        const SizedBox(height: 16),
        
        // Predictions Section
        predictionsAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading predictions: $error'),
            ),
          ),
          data: (predictions) => PredictionsWidget(predictions: predictions),
        ),
        
        const SizedBox(height: 16),
        
        // Trends Section
        trendsAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading trends: $error'),
            ),
          ),
          data: (trends) => TrendsWidget(trends: trends),
        ),
        
        const SizedBox(height: 16),
        
        // Insights Section
        insightsAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading insights: $error'),
            ),
          ),
          data: (insights) => InsightsWidget(insights: insights),
        ),
      ],
    );
  }
}

/// Widget to display AI consultation analytics
class AIConsultationAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const AIConsultationAnalyticsWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final totalConsultations = analytics['total_consultations'] as int? ?? 0;
    final successfulConsultations = analytics['successful_consultations'] as int? ?? 0;
    final failedConsultations = analytics['failed_consultations'] as int? ?? 0;
    final avgProcessingTime = analytics['avg_processing_time'] as double? ?? 0.0;
    final topServiceTypes = analytics['top_service_types'] as List<dynamic>? ?? [];
    final conversionRate = analytics['conversion_rate'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'AI Consultation Analytics (Last 30 Days)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Statistics Grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  context,
                  'Total Consultations',
                  '$totalConsultations',
                  Icons.analytics,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Successful',
                  '$successfulConsultations',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Failed',
                  '$failedConsultations',
                  Icons.error,
                  Colors.red,
                ),
                _buildStatCard(
                  context,
                  'Avg Processing Time',
                  '${avgProcessingTime.toStringAsFixed(1)}s',
                  Icons.timer,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Conversion Rate
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.purple[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Conversion Rate',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${conversionRate.toStringAsFixed(1)}% of AI consultations resulted in bookings',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Top Service Types
            if (topServiceTypes.isNotEmpty) ...[
              Text(
                'Top Service Types',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ...topServiceTypes.take(5).map((service) {
                final serviceMap = service as Map<String, dynamic>;
                final serviceName = serviceMap['service_name'] as String? ?? 'Unknown';
                final count = serviceMap['count'] as int? ?? 0;
                final percentage = serviceMap['percentage'] as double? ?? 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(serviceName),
                      ),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display predictions (booking volume and revenue forecast)
class PredictionsWidget extends StatelessWidget {
  const PredictionsWidget({super.key, required this.predictions});

  final AIPrediction predictions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Predictions (Next 7 Days)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Booking Volume Prediction
            if (predictions.bookingVolume != null) ...[
              _buildPredictionSection(
                context,
                title: 'Booking Volume Forecast',
                icon: Icons.book_online,
                color: Colors.deepPurple,
                prediction: predictions.bookingVolume!,
              ),
              const SizedBox(height: 20),
            ],
            
            // Revenue Forecast
            if (predictions.revenueForecast != null) ...[
              _buildPredictionSection(
                context,
                title: 'Revenue Forecast',
                icon: Icons.payments,
                color: Colors.orange,
                prediction: predictions.revenueForecast!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required dynamic prediction,
  }) {
    final predictions = prediction.predictions as List<PredictionPoint>;
    final insights = prediction.insights as String;
    final confidenceScore = prediction.confidenceScore as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            _buildConfidenceBadge(context, confidenceScore),
          ],
        ),
        const SizedBox(height: 12),
        
        // Simple bar chart visualization
        ...predictions.take(7).map((point) {
          final maxValue = predictions.map((p) => p.value).reduce((a, b) => a > b ? a : b);
          final percentage = (point.value / maxValue).clamp(0.0, 1.0);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    _formatDate(point.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              point.value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${point.confidence.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insights,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, double confidence) {
    final color = confidence >= 80
        ? Colors.green
        : confidence >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '${confidence.toStringAsFixed(0)}% confidence',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
      return '$weekday ${dt.day}/${dt.month}';
    } catch (e) {
      return date;
    }
  }
}

/// Widget to display trending and declining services
class TrendsWidget extends StatelessWidget {
  const TrendsWidget({super.key, required this.trends});

  final AITrend trends;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Service Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Trending Services
            if (trends.trendingServices.isNotEmpty) ...[
              Text(
                'Trending Services',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
              ),
              const SizedBox(height: 12),
              ...trends.trendingServices.take(5).map((service) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.serviceName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              service.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${service.growthRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${service.currentBookings} bookings',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            
            // Declining Services
            if (trends.decliningServices.isNotEmpty) ...[
              Text(
                'Declining Services',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
              ),
              const SizedBox(height: 12),
              ...trends.decliningServices.take(5).map((service) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_downward,
                          color: Colors.red[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.serviceName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              service.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '-${service.declineRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${service.currentBookings} bookings',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget to display AI-generated insights
class InsightsWidget extends StatelessWidget {
  const InsightsWidget({super.key, required this.insights});

  final Map<String, dynamic> insights;

  @override
  Widget build(BuildContext context) {
    final insightsList = insights['insights'] as List<dynamic>? ?? [];
    final summary = insights['summary'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Summary
            if (summary.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Individual Insights
            if (insightsList.isNotEmpty) ...[
              Text(
                'Key Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ...insightsList.map((insight) {
                final insightMap = insight as Map<String, dynamic>;
                final category = insightMap['category'] as String? ?? 'General';
                final message = insightMap['message'] as String? ?? '';
                final confidence = (insightMap['confidence'] as num?)?.toDouble() ?? 0.0;
                final priority = insightMap['priority'] as String? ?? 'medium';

                final priorityColor = priority == 'high'
                    ? Colors.red
                    : priority == 'medium'
                        ? Colors.orange
                        : Colors.blue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  color: priorityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _buildConfidenceIndicator(context, confidence),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context, double confidence) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence >= 80
                    ? Colors.green
                    : confidence >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${confidence.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
