import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/repositories/service_repository.dart';
import '../widgets/service_card.dart';
import 'customer_home_screen.dart';

final priceRangeProvider = StateProvider<RangeValues>((ref) {
  return const RangeValues(0, 50000);
});

/// Dedicated service listing (Task 6.2.1).
class ServiceListScreen extends ConsumerWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final priceRange = ref.watch(priceRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search services...',
              leading: const Icon(Icons.search),
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Price (NPR)'),
                Expanded(
                  child: RangeSlider(
                    values: priceRange,
                    min: 0,
                    max: 50000,
                    divisions: 50,
                    labels: RangeLabels(
                      priceRange.start.round().toString(),
                      priceRange.end.round().toString(),
                    ),
                    onChanged: (v) =>
                        ref.read(priceRangeProvider.notifier).state = v,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (services) {
                final filtered = _filter(
                  services,
                  searchQuery: searchQuery,
                  category: selectedCategory,
                  priceRange: priceRange,
                );
                if (filtered.isEmpty) {
                  return const Center(child: Text('No services match your filters'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final service = filtered[index];
                    return ServiceCard(
                      service: service,
                      onTap: () => context.push(
                        RouteConstants.customerServiceDetail
                            .replaceAll(':id', service.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ServiceModel> _filter(
    List<ServiceModel> services, {
    required String searchQuery,
    required String? category,
    required RangeValues priceRange,
  }) {
    return services.where((s) {
      if (!s.isActive) return false;
      final q = searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
      final matchesCategory = category == null || s.category == category;
      final matchesPrice =
          s.price >= priceRange.start && s.price <= priceRange.end;
      return matchesQuery && matchesCategory && matchesPrice;
    }).toList();
  }
}
