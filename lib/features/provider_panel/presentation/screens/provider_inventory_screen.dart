import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/provider_accessibility.dart';
import '../widgets/provider_widgets.dart';

final _inventoryProvider = StateProvider<List<String>>((ref) => []);

/// Simple inventory tracker (plan 10.6).
class ProviderInventoryScreen extends ConsumerStatefulWidget {
  const ProviderInventoryScreen({super.key});

  @override
  ConsumerState<ProviderInventoryScreen> createState() =>
      _ProviderInventoryScreenState();
}

class _ProviderInventoryScreenState extends ConsumerState<ProviderInventoryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(_inventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Item name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Add inventory item',
                  button: true,
                  child: FilledButton(
                    style: ProviderAccessibility.minTouchButton(null),
                    onPressed: () {
                      final name = _controller.text.trim();
                      if (name.isEmpty) return;
                      ProviderAccessibility.lightImpact();
                      ref.read(_inventoryProvider.notifier).state = [
                        ...items,
                        name,
                      ];
                      _controller.clear();
                    },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    message: 'Add tools and supplies you bring to jobs',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      return Semantics(
                        label: 'Inventory item ${items[i]}',
                        child: ListTile(
                          leading: const Icon(Icons.build),
                          title: Text(items[i]),
                          trailing: IconButton(
                            tooltip: 'Remove item',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              final next = [...items]..removeAt(i);
                              ref.read(_inventoryProvider.notifier).state =
                                  next;
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
