import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../widgets/provider_async_widgets.dart';

final providerInvoicesBookingsProvider =
    FutureProvider<List<BookingModel>>((ref) async {
  return ref.read(bookingRepositoryProvider).getProviderBookings();
});

/// Completed bookings as invoices (plan 10.4).
class ProviderInvoicesScreen extends ConsumerWidget {
  const ProviderInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(providerInvoicesBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ProviderErrorPanel(
          error: e,
          onRetry: () => ref.invalidate(providerInvoicesBookingsProvider),
        ),
        data: (bookings) {
          final completed = bookings.where((b) => b.isCompleted).toList();
          final total = completed.fold(0.0, (s, b) => s + b.totalPrice);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text('Total invoiced: NPR ${total.toStringAsFixed(0)}'),
                  subtitle: Text('${completed.length} completed jobs'),
                ),
              ),
              const SizedBox(height: 12),
              ...completed.map(
                (b) => Semantics(
                  label: 'Invoice ${b.totalPrice} NPR',
                  child: ListTile(
                    title: Text('Invoice #${b.id.substring(0, 8)}'),
                    subtitle: Text(b.scheduledAt.toLocal().toString()),
                    trailing: Text(
                      'NPR ${b.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
