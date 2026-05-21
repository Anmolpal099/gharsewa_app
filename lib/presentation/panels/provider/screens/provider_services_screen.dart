import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/repositories/service_repository.dart';

final providerServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  return ref.read(serviceRepositoryProvider).getServices();
});

class ProviderServicesScreen extends ConsumerWidget {
  const ProviderServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(providerServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServiceDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (services) {
          if (services.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.design_services, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No services yet. Add your first service!'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(providerServicesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) =>
                  _ServiceManageCard(service: services[index], ref: ref),
            ),
          );
        },
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedCategory = 'Cleaning';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add New Service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Service Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (NPR)', border: OutlineInputBorder()))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: durationCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (min)', border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref.read(serviceRepositoryProvider).createService({
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'category': selectedCategory,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'duration_minutes': int.tryParse(durationCtrl.text) ?? 60,
                  'currency': 'NPR',
                });
                ref.invalidate(providerServicesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Service'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ServiceManageCard extends ConsumerWidget {
  final ServiceModel service;
  final WidgetRef ref;
  const _ServiceManageCard({required this.service, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: const Icon(Icons.design_services, color: Colors.green),
          ),
          title: Text(service.name),
          subtitle: Text('NPR ${service.price.toStringAsFixed(0)} • ${service.durationMinutes} min'),
          trailing: Switch(
            value: service.isActive,
            onChanged: (_) async {
              await ref.read(serviceRepositoryProvider).updateService(
                service.id, {'status': service.isActive ? 'inactive' : 'active'},
              );
              ref.invalidate(providerServicesProvider);
            },
          ),
        ),
      );
}
