import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/booking_repository.dart';
import '../../business_logic/dashboard_controller.dart';
import '../../business_logic/profile_manager.dart';
import '../../business_logic/provider_bookings_providers.dart';
import '../../business_logic/recommended_bookings_provider.dart';
import '../../data/models/recommended_booking.dart';

/// Horizontal list of skill-matched pending bookings (model-driven).
class RecommendedBookingsSection extends ConsumerWidget {
  const RecommendedBookingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedAsync = ref.watch(recommendedBookingsProvider);
    final profile = ref.watch(profileManagerProvider).value;
    final skills = profile?.skills ?? const [];

    if (profile != null && skills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          'Add skills in Skills & Profile to see recommended bookings.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }

    return recommendedAsync.when(
      loading: () => const SizedBox(
        height: 4,
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.recommend_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended for your skills',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _RecommendedBookingCard(
                  item: items[index],
                  onAccept: () => _acceptBooking(context, ref, items[index]),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> _acceptBooking(
    BuildContext context,
    WidgetRef ref,
    RecommendedBooking item,
  ) async {
    try {
      await ref.read(bookingRepositoryProvider).acceptBooking(item.booking.id);
      ref.invalidate(providerBookingsProvider);
      ref.invalidate(dashboardControllerProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Accepted ${item.displayServiceName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RecommendedBookingCard extends StatelessWidget {
  const _RecommendedBookingCard({
    required this.item,
    required this.onAccept,
  });

  final RecommendedBooking item;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;
    final theme = Theme.of(context);

    return SizedBox(
      width: 280,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.displayServiceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.matchLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              if (booking.customerName != null) ...[
                const SizedBox(height: 4),
                Text(
                  booking.customerName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.matchedSkills.take(3).map((skill) {
                  return Chip(
                    label: Text(skill),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 11),
                  );
                }).toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatSchedule(booking.scheduledAt),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'NPR ${booking.totalPrice.toStringAsFixed(0)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSchedule(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
