import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/repositories/service_repository.dart';

final serviceDetailProvider =
    FutureProvider.family<ServiceModel, String>((ref, id) async {
  return ref.read(serviceRepositoryProvider).getServiceById(id);
});

class ServiceDetailScreen extends ConsumerWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      body: serviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (service) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(service.name),
                background: Container(
                  color: Colors.blue.shade100,
                  child: const Center(
                    child: Icon(Icons.home_repair_service,
                        size: 80, color: Colors.blue),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price & Duration
                    Row(
                      children: [
                        Chip(
                          label: Text(
                              '${service.currency} ${service.price.toStringAsFixed(0)}'),
                          backgroundColor: Colors.blue.shade50,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('${service.durationMinutes} min'),
                          backgroundColor: Colors.green.shade50,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(service.category),
                          backgroundColor: Colors.orange.shade50,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text('About this service',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 8),
                    Text(service.description),
                    const SizedBox(height: 24),

                    // Tags
                    if (service.tags.isNotEmpty) ...[
                      Text('Tags',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: service.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Book Now Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          RouteConstants.customerBooking
                              .replaceAll(':serviceId', service.id),
                        ),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Book Now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
