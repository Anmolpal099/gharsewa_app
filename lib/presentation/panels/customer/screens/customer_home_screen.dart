import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/repositories/service_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  return ref.read(serviceRepositoryProvider).getServices();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

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

            // ── Category Filter ──────────────────────────────────
            SliverToBoxAdapter(
              child: _CategoryFilter(
                selected: selectedCategory,
                onSelected: (cat) =>
                    ref.read(selectedCategoryProvider.notifier).state = cat,
              ),
            ),

            // ── AI Recommendations ───────────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Recommended for You'),
            ),
            SliverToBoxAdapter(
              child: _RecommendationsRow(),
            ),

            // ── All Services ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'All Services'),
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
                      (context, index) => _ServiceCard(
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
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
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

class _RecommendationsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(right: 12),
          child: SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber),
                  const SizedBox(height: 8),
                  Text('Recommended ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('AI suggested', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.blue.shade50,
                child: const Center(
                  child: Icon(Icons.home_repair_service,
                      size: 48, color: Colors.blue),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${service.currency} ${service.price.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                  Text('${service.durationMinutes} min',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
