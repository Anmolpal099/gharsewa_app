import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../business_logic/dashboard_controller.dart';
import '../../business_logic/earnings_analyzer.dart';
import '../../business_logic/request_manager.dart';
import '../../business_logic/suggestion_controller.dart';
import '../../data/models/enums.dart';
import '../../data/services/dismissed_suggestions_store.dart';
import '../widgets/earnings_chart.dart';
import '../widgets/provider_async_widgets.dart';
import '../widgets/provider_widgets.dart';
import '../utils/provider_accessibility.dart';
import '../widgets/paginated_list.dart';
import '../widgets/request_card.dart';

class ModernDashboardScreen extends ConsumerStatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  ConsumerState<ModernDashboardScreen> createState() =>
      _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends ConsumerState<ModernDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(earningsAnalyzerProvider.notifier).fetchEarnings();
      ref.read(pendingRequestsStreamProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final earningsAsync = ref.watch(earningsAnalyzerProvider);
    final requestsAsync = ref.watch(pendingRequestsStreamProvider);
    final suggestionsAsync = ref.watch(dashboardSuggestionsProvider);
    final earningsNotifier = ref.read(earningsAnalyzerProvider.notifier);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardControllerProvider);
        await earningsNotifier.fetchEarnings();
        ref.invalidate(pendingRequestsStreamProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Explore',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          earningsAsync.when(
            loading: () => const ProviderSkeletonCard(height: 200),
            error: (e, _) => ProviderErrorPanel(
              error: e,
              title: 'Earnings unavailable',
              onRetry: () => earningsNotifier.fetchEarnings(),
            ),
            data: (earnings) => EarningsChart(
              data: earnings,
              viewType: earningsNotifier.viewType,
              onViewTypeChanged: (type) =>
                  earningsNotifier.fetchEarnings(viewType: type),
              formatCurrency: earningsNotifier.formatCurrency,
              formatPercentage: earningsNotifier.formatPercentage,
            ),
          ),
          const SizedBox(height: 16),
          dashboardAsync.when(
            loading: () => const ProviderSkeletonCard(height: 100),
            error: (_, __) => const SizedBox.shrink(),
            data: (snapshot) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        icon: Icons.star,
                        label: 'Rating',
                        value: snapshot.metrics.formattedRating,
                        subtitle: snapshot.metrics.isTopPerformer
                            ? 'Top performer'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        icon: Icons.work,
                        label: 'Jobs',
                        value: '${snapshot.metrics.jobsCompleted}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          suggestionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (suggestions) {
              if (suggestions.isEmpty) return const SizedBox.shrink();
              return SuggestionPager(
                items: suggestions
                    .map(
                      (s) => (
                        id: s.id,
                        title: s.title,
                        description: s.description,
                      ),
                    )
                    .toList(),
                onDismiss: (id) async {
                  await ref
                      .read(dismissedSuggestionsStoreProvider)
                      .dismiss(id);
                  ref.invalidate(dashboardSuggestionsProvider);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Quick actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _QuickAction(
                icon: Icons.calendar_month,
                label: 'Schedule',
                onTap: () => context.go(RouteConstants.providerSchedule),
              ),
              _QuickAction(
                icon: Icons.receipt_long,
                label: 'Invoices',
                onTap: () => context.go(RouteConstants.providerInvoices),
              ),
              _QuickAction(
                icon: Icons.support_agent,
                label: 'Support',
                onTap: () => context.go(RouteConstants.providerSupport),
              ),
              _QuickAction(
                icon: Icons.inventory_2,
                label: 'Inventory',
                onTap: () => context.go(RouteConstants.providerInventory),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Pending requests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          requestsAsync.when(
            loading: () => const ProviderSkeletonCard(height: 160),
            error: (e, _) => ProviderErrorPanel(
              error: e,
              title: 'Requests unavailable',
              onRetry: () => ref.invalidate(pendingRequestsStreamProvider),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.inbox_outlined,
                  message: 'No pending requests — update your availability',
                );
              }
              return PaginatedListView(
                items: requests,
                itemBuilder: (context, request) => RequestCard(
                  request: request,
                  onAccept: () => _accept(context, request.id),
                  onCounter: () => _showCounterDialog(context, request),
                  onDecline: () => _decline(context, request.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept request?'),
        content: const Text('Confirm you can fulfill this booking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ProviderAccessibility.onAcceptRequest();
    try {
      await ref.read(requestManagerProvider.notifier).acceptRequest(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _decline(BuildContext context, String id) async {
    const reasons = ['Unavailable', 'Too far', 'Schedule conflict', 'Other'];
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Decline reason'),
        children: reasons
            .map(
              (r) => SimpleDialogOption(
                child: Text(r),
                onPressed: () => Navigator.pop(ctx, r),
              ),
            )
            .toList(),
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(requestManagerProvider.notifier).declineRequest(id, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showCounterDialog(
    BuildContext context,
    dynamic request,
  ) async {
    final priceController = TextEditingController(
      text: request.proposedPrice.toStringAsFixed(0),
    );
    final messageController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Counter offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your price (NPR)',
                helperText: 'Must be greater than zero',
              ),
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (submitted != true || !context.mounted) return;

    final price = double.tryParse(priceController.text) ?? 0;
    try {
      await ref.read(requestManagerProvider.notifier).sendCounterOffer(
            request.id,
            price: price,
            message: messageController.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Counter-offer sent')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
