import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../widgets/provider_async_widgets.dart';

final providerScheduleBookingsProvider =
    FutureProvider<List<BookingModel>>((ref) async {
  return ref.read(bookingRepositoryProvider).getProviderBookings();
});

/// Provider schedule — upcoming bookings (plan 10.3).
class ProviderScheduleScreen extends ConsumerWidget {
  const ProviderScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(providerScheduleBookingsProvider);

    return bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ProviderErrorPanel(
          error: e,
          onRetry: () => ref.invalidate(providerScheduleBookingsProvider),
        ),
        data: (bookings) {
          final upcoming = bookings
              .where((b) => !b.isCancelled && !b.isCompleted)
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          if (upcoming.isEmpty) {
            return const Center(child: Text('No upcoming bookings scheduled'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: upcoming.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = upcoming[i];
              return Semantics(
                label: 'Booking ${b.status.name} on ${b.scheduledAt}',
                child: ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text('Booking #${b.id.substring(0, 8)}'),
                  subtitle: Text(
                    '${b.scheduledAt.toLocal()} • ${b.status.name} • NPR ${b.totalPrice.toStringAsFixed(0)}',
                  ),
                  leading: const Icon(Icons.event),
                ),
              );
            },
          );
        },
    );
  }
}
