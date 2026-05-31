import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/models/ai_consultation_models.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../features/provider_panel/business_logic/dashboard_controller.dart';
import '../../../../features/provider_panel/business_logic/provider_bookings_providers.dart';
import '../../../../features/provider_panel/presentation/widgets/recommended_bookings_section.dart';
import '../../../../features/provider_panel/presentation/widgets/scheduling_assistant_banner.dart';
import '../../../../services/ai/ai_api_service.dart';
import '../../../../services/ai/models/ai_match_score.dart';
import '../../../../services/api/ai_consultation_api_service.dart';

/// Provider for AI consultation details by consultation ID
final aiConsultationByIdProvider = FutureProvider.family<AIConsultationModel?, String>((ref, consultationId) async {
  final apiService = ref.watch(aiConsultationApiServiceProvider);
  try {
    return await apiService.getConsultationById(consultationId);
  } catch (e) {
    return null;
  }
});

/// Widget to display AI consultation details for a booking
class AIConsultationDetailsWidget extends ConsumerWidget {
  final String consultationId;

  const AIConsultationDetailsWidget({super.key, required this.consultationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationAsync = ref.watch(aiConsultationByIdProvider(consultationId));

    return consultationAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (consultation) {
        if (consultation == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: Colors.purple[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'AI Diagnosis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[900],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  consultation.diagnosis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.plumbing, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Service: ${consultation.serviceTypeDisplayName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated Cost: ${consultation.costRangeFormatted}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (consultation.markers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Defect Markers: ${consultation.markerCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ProviderBookingsScreen extends ConsumerStatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  ConsumerState<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends ConsumerState<ProviderBookingsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _sortByMatchScore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(providerBookingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SchedulingAssistantBanner(),
        const RecommendedBookingsSection(),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Confirmed'),
                  Tab(text: 'Completed'),
                  Tab(text: 'All'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Sort by match score', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Switch(
                      value: _sortByMatchScore,
                      onChanged: (value) {
                        setState(() {
                          _sortByMatchScore = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(providerBookingsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (bookings) {
              final pending = bookings.where((b) => b.isPending).toList();
              final confirmed = bookings.where((b) => b.isConfirmed).toList();
              final completed = bookings.where((b) => b.isCompleted).toList();

              return RefreshIndicator(
                onRefresh: () => ref.refresh(providerBookingsProvider.future),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(pending, BookingListType.pending),
                    _buildBookingList(confirmed, BookingListType.confirmed),
                    _buildBookingList(completed, BookingListType.completed),
                    _buildBookingList(bookings, BookingListType.all),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, BookingListType type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${type.name} bookings',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Sort bookings by match score if enabled
    List<BookingModel> sortedBookings = List.from(bookings);
    if (_sortByMatchScore) {
      // We'll sort asynchronously using a Consumer to watch match scores
      return _SortedBookingList(
        bookings: sortedBookings,
        type: type,
        onAccept: _handleAccept,
        onReject: _handleReject,
        onComplete: _handleComplete,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        if (booking.isPending) {
          return _BookingRequestCard(
            booking: booking,
            sortByMatchScore: _sortByMatchScore,
            onAccept: () => _handleAccept(booking.id),
            onReject: () => _handleReject(booking.id),
          );
        } else {
          return _BookingHistoryCard(
            booking: booking,
            sortByMatchScore: _sortByMatchScore,
            onComplete: booking.isConfirmed 
                ? () => _handleComplete(booking.id)
                : null,
          );
        }
      },
    );
  }

  Future<void> _handleAccept(String bookingId) async {
    try {
      await ref.read(bookingRepositoryProvider).acceptBooking(bookingId);
      ref.invalidate(providerBookingsProvider);
      ref.invalidate(dashboardControllerProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(String bookingId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Not available at this time',
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonCtrl.text.isNotEmpty) {
      try {
        await ref
            .read(bookingRepositoryProvider)
            .rejectBooking(bookingId, reasonCtrl.text);
        ref.invalidate(providerBookingsProvider);
        ref.invalidate(dashboardControllerProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleComplete(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Booking'),
        content: const Text('Mark this booking as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingRepositoryProvider).completeBooking(bookingId);
        ref.invalidate(providerBookingsProvider);
        ref.invalidate(dashboardControllerProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

enum BookingListType { pending, confirmed, completed, all }

class _BookingRequestCard extends ConsumerWidget {
  final BookingModel booking;
  final bool sortByMatchScore;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BookingRequestCard({
    required this.booking,
    required this.sortByMatchScore,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchScoreAsync = ref.watch(matchScoreProvider(booking.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.pending_actions, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${booking.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'New booking request',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
            // Match Score Badge
            matchScoreAsync.when(
              data: (matchScore) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _MatchScoreBadge(
                  matchScore: matchScore,
                  onTap: () => _showMatchScoreBreakdown(context, matchScore),
                ),
              ),
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading match score...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Divider(height: 24),
            // AI Consultation Details
            if (booking.hasAIConsultation && booking.aiConsultationId != null)
              AIConsultationDetailsWidget(consultationId: booking.aiConsultationId!),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} at ${booking.scheduledAt.hour}:${booking.scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'NPR ${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMatchScoreBreakdown(BuildContext context, AIMatchScore matchScore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MatchScoreBreakdownSheet(matchScore: matchScore),
    );
  }
}

class _BookingHistoryCard extends ConsumerWidget {
  final BookingModel booking;
  final bool sortByMatchScore;
  final VoidCallback? onComplete;

  const _BookingHistoryCard({
    required this.booking,
    required this.sortByMatchScore,
    this.onComplete,
  });

  Color _getStatusColor() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchScoreAsync = ref.watch(matchScoreProvider(booking.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor().withValues(alpha: 0.2),
              child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Booking #${booking.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                // AI Consultation Indicator
                if (booking.hasAIConsultation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology, color: Colors.purple[700], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                // Match Score Badge for confirmed bookings
                if (booking.isConfirmed)
                  matchScoreAsync.when(
                    data: (matchScore) => _MatchScoreBadge(
                      matchScore: matchScore,
                      compact: true,
                      onTap: () => _showMatchScoreBreakdown(context, matchScore),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              ],
            ),
            subtitle: Text(
              '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} • NPR ${booking.totalPrice.toStringAsFixed(0)}',
            ),
            trailing: onComplete != null
                ? FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Complete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      booking.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
            onTap: booking.hasAIConsultation && booking.aiConsultationId != null
                ? () => _showAIConsultationDetails(context, booking.aiConsultationId!)
                : null,
          ),
          // AI Consultation Details (expandable)
          if (booking.hasAIConsultation && booking.aiConsultationId != null)
            AIConsultationDetailsWidget(consultationId: booking.aiConsultationId!),
        ],
      ),
    );
  }

  void _showAIConsultationDetails(BuildContext context, String consultationId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'AI Consultation Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: AIConsultationDetailsWidget(consultationId: consultationId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMatchScoreBreakdown(BuildContext context, AIMatchScore matchScore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MatchScoreBreakdownSheet(matchScore: matchScore),
    );
  }
}


// Sorted Booking List Widget
class _SortedBookingList extends ConsumerWidget {
  final List<BookingModel> bookings;
  final BookingListType type;
  final Function(String) onAccept;
  final Function(String) onReject;
  final Function(String) onComplete;

  const _SortedBookingList({
    required this.bookings,
    required this.type,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch all match scores
    final matchScoresAsync = bookings.map((b) => 
      ref.watch(matchScoreProvider(b.id))
    ).toList();

    // Check if all scores are loaded
    bool allLoaded = true;
    List<MapEntry<BookingModel, double>> bookingScores = [];

    for (int i = 0; i < bookings.length; i++) {
      final scoreAsync = matchScoresAsync[i];
      scoreAsync.when(
        data: (matchScore) {
          bookingScores.add(MapEntry(bookings[i], matchScore.matchScore));
        },
        loading: () {
          allLoaded = false;
        },
        error: (_, __) {
          // If error, add with score 0 so it appears at the bottom
          bookingScores.add(MapEntry(bookings[i], 0.0));
        },
      );
    }

    // If still loading, show loading indicator
    if (!allLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading match scores...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Sort by match score (highest first)
    bookingScores.sort((a, b) => b.value.compareTo(a.value));
    final sortedBookings = bookingScores.map((e) => e.key).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedBookings.length,
      itemBuilder: (context, index) {
        final booking = sortedBookings[index];
        if (booking.isPending) {
          return _BookingRequestCard(
            booking: booking,
            sortByMatchScore: true,
            onAccept: () => onAccept(booking.id),
            onReject: () => onReject(booking.id),
          );
        } else {
          return _BookingHistoryCard(
            booking: booking,
            sortByMatchScore: true,
            onComplete: booking.isConfirmed 
                ? () => onComplete(booking.id)
                : null,
          );
        }
      },
    );
  }
}

// Match Score Provider
final matchScoreProvider = FutureProvider.family<AIMatchScore, String>((ref, bookingId) async {
  final aiService = ref.watch(aiApiServiceProvider);
  return await aiService.getMatchScore(bookingId);
});

// Match Score Badge Widget
class _MatchScoreBadge extends StatelessWidget {
  final AIMatchScore matchScore;
  final bool compact;
  final VoidCallback onTap;

  const _MatchScoreBadge({
    required this.matchScore,
    this.compact = false,
    required this.onTap,
  });

  Color _getScoreColor() {
    final score = matchScore.matchScore;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();
    final score = matchScore.matchScore.toStringAsFixed(0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars,
              size: compact ? 14 : 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$score% Match',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: compact ? 12 : 14,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

// Match Score Breakdown Bottom Sheet
class _MatchScoreBreakdownSheet extends StatelessWidget {
  final AIMatchScore matchScore;

  const _MatchScoreBreakdownSheet({required this.matchScore});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Match Score Breakdown',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'AI-powered analysis of your compatibility with this booking',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Overall Score
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getScoreColor().withValues(alpha: 0.1),
                      _getScoreColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getScoreColor().withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getScoreColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${matchScore.matchScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Match Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getScoreLabel(),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getScoreColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Factors
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Match Factors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FactorItem(
                      icon: Icons.build,
                      label: 'Skill Alignment',
                      score: matchScore.factors.skillAlignment,
                      description: 'How well your skills match the job requirements',
                    ),
                    _FactorItem(
                      icon: Icons.location_on,
                      label: 'Location Proximity',
                      score: matchScore.factors.locationProximity,
                      description: 'Distance from the service location',
                    ),
                    _FactorItem(
                      icon: Icons.star,
                      label: 'Rating',
                      score: matchScore.factors.rating,
                      description: 'Your historical performance and reviews',
                    ),
                    _FactorItem(
                      icon: Icons.calendar_today,
                      label: 'Availability',
                      score: matchScore.factors.availability,
                      description: 'Your schedule availability for this booking',
                    ),
                    _FactorItem(
                      icon: Icons.favorite,
                      label: 'Preferences',
                      score: matchScore.factors.preferences,
                      description: 'Match with customer stated preferences',
                    ),
                    const SizedBox(height: 24),
                    // AI Reasoning
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Insights',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            matchScore.reasoning,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor() {
    final score = matchScore.matchScore;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel() {
    final score = matchScore.matchScore;
    if (score >= 80) return 'Excellent Match';
    if (score >= 60) return 'Good Match';
    return 'Fair Match';
  }
}

// Factor Item Widget
class _FactorItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double score;
  final String description;

  const _FactorItem({
    required this.icon,
    required this.label,
    required this.score,
    required this.description,
  });

  Color _getScoreColor() {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
