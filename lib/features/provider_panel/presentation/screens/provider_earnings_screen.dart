import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/earnings_analyzer.dart';
import '../widgets/earnings_chart.dart';
import '../widgets/provider_async_widgets.dart';

/// Dedicated earnings view (drawer: Earnings).
class ProviderEarningsScreen extends ConsumerStatefulWidget {
  const ProviderEarningsScreen({super.key});

  @override
  ConsumerState<ProviderEarningsScreen> createState() =>
      _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends ConsumerState<ProviderEarningsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(earningsAnalyzerProvider.notifier).fetchEarnings(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(earningsAnalyzerProvider);
    final notifier = ref.read(earningsAnalyzerProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => notifier.fetchEarnings(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Earnings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track daily and weekly income from completed jobs.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 20),
          earningsAsync.when(
            loading: () => const ProviderSkeletonCard(height: 220),
            error: (e, _) => ProviderErrorPanel(
              title: 'Could not load earnings',
              error: e,
              onRetry: () => notifier.fetchEarnings(),
            ),
            data: (earnings) => EarningsChart(
              data: earnings,
              viewType: notifier.viewType,
              onViewTypeChanged: (type) =>
                  notifier.fetchEarnings(viewType: type),
              formatCurrency: notifier.formatCurrency,
              formatPercentage: notifier.formatPercentage,
            ),
          ),
        ],
      ),
    );
  }
}
