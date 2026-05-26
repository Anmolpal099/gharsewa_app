import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/repositories/service_repository.dart';
import '../../../../services/ai/ai_api_service.dart';
import '../../../../services/ai/models/ai_recommendation.dart';
import '../../../../services/api/api_exception.dart';
import '../widgets/service_card.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  return ref.read(serviceRepositoryProvider).getServices();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// AI Recommendations provider
final aiRecommendationsProvider =
    FutureProvider.autoDispose<List<AIRecommendation>>((ref) async {
  final aiService = ref.watch(aiApiServiceProvider);
  return aiService.getRecommendations(limit: 5, refresh: false);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gharsewa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(servicesProvider.future),
        child: CustomScrollView(
          slivers: [
            // ── Search Bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBar(
                  hintText: 'Search services...',
                  leading: const Icon(Icons.search),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
            ),

            // ── AI Problem Solver Card ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _AIProblemSolverCard(
                  onTap: () => context.push(RouteConstants.customerAIAssistant),
                ),
              ),
            ),

            // ── Category Filter ──────────────────────────────────
            SliverToBoxAdapter(
              child: _CategoryFilter(
                selected: selectedCategory,
                onSelected: (cat) =>
                    ref.read(selectedCategoryProvider.notifier).state = cat,
              ),
            ),

            // ── AI Recommendations ───────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recommended for You',
                actionLabel: 'Refresh',
                onAction: () => ref.refresh(aiRecommendationsProvider),
              ),
            ),
            const SliverToBoxAdapter(
              child: _AIRecommendationsSection(),
            ),

            // ── All Services ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'All Services',
                actionLabel: 'View all',
                onAction: () => context.push(RouteConstants.customerServiceList),
              ),
            ),

            servicesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (services) {
                final filtered = services.where((s) {
                  final matchesQuery = searchQuery.isEmpty ||
                      s.name.toLowerCase().contains(searchQuery.toLowerCase());
                  final matchesCategory = selectedCategory == null ||
                      s.category == selectedCategory;
                  return matchesQuery && matchesCategory && s.isActive;
                }).toList();

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No services found')),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ServiceCard(
                        service: filtered[index],
                        onTap: () => context.push(
                          RouteConstants.customerServiceDetail
                              .replaceAll(':id', filtered[index].id),
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      );
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  static const categories = [
    'Cleaning', 'Plumbing', 'Electrical', 'Painting', 'Carpentry', 'Gardening'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: selected == cat,
                  onSelected: (_) => onSelected(cat),
                ),
              )),
        ],
      ),
    );
  }
}

class _AIRecommendationsSection extends ConsumerWidget {
  const _AIRecommendationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(aiRecommendationsProvider);

    return recommendationsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        // Handle error gracefully
        String errorMessage = 'Unable to load recommendations';
        if (error is ApiException) {
          errorMessage = error.message;
        }
        
        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => ref.refresh(aiRecommendationsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No recommendations yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Book a service to get personalized recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              return _RecommendationCard(
                recommendation: recommendation,
                onTap: () async {
                  // Record feedback when user taps
                  final aiService = ref.read(aiApiServiceProvider);
                  try {
                    await aiService.recordRecommendationFeedback(
                      recommendationId: recommendation.id,
                      action: 'clicked',
                    );
                  } catch (e) {
                    // Silently fail - don't block navigation
                    debugPrint('Failed to record feedback: $e');
                  }

                  // Navigate to service detail
                  if (context.mounted) {
                    context.push(
                      RouteConstants.customerServiceDetail
                          .replaceAll(':id', recommendation.service.id),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final AIRecommendation recommendation;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = recommendation.service;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(right: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service image or placeholder
              Container(
                height: 100,
                color: Colors.blue.shade50,
                child: service.imageUrl != null
                    ? Image.network(
                        service.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),

              // Service details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI badge and confidence score
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 12, color: Colors.amber.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  '${recommendation.confidenceScore.toStringAsFixed(0)}% match',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            service.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Service name
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Price
                      Text(
                        'NPR ${service.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // AI reasoning
                      Expanded(
                        child: Text(
                          recommendation.reasoning,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.home_repair_service,
        size: 48,
        color: Colors.blue,
      ),
    );
  }
}

class _AIProblemSolverCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AIProblemSolverCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.cyan.shade400,
                Colors.blue.shade500,
                Colors.purple.shade400,
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Background Decoration ───────────────────────
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  Icons.auto_awesome,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),

              // ── Content ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AI Problem Solver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Need a quick fix? Troubleshoot leaks, sparks, or glitches instantly with AI guidance.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text(
                        'Start DIY Help',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
