import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/route_constants.dart';
import '../../../../../core/utils/error_logger.dart';
import '../../../../../data/models/ai_consultation_models.dart';
import '../state/consultation_history_provider.dart';
import '../widgets/consultation_history_card.dart';

/// Consultation History Screen
/// 
/// Displays a paginated list of past AI consultations with:
/// - Pull-to-refresh functionality
/// - Infinite scroll pagination
/// - Service type filtering
/// - Tap to view details
/// - Delete functionality with confirmation
/// - Empty and loading states
class ConsultationHistoryScreen extends ConsumerStatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  ConsumerState<ConsultationHistoryScreen> createState() =>
      _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState
    extends ConsumerState<ConsultationHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedServiceType;

  // Available service types for filtering
  final List<String> _serviceTypes = [
    'All Services',
    'Plumbing Repair',
    'Electrical Work',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Appliance Repair',
    'HVAC',
    'Pest Control',
    'Landscaping',
    'General Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    // Load consultations on screen init
    Future.microtask(() {
      ref.read(consultationHistoryProvider.notifier).loadConsultations();
    });

    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handles scroll events for infinite scroll pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200px from bottom
      final historyState = ref.read(consultationHistoryProvider);
      if (historyState.hasMore && !historyState.isLoadingMore) {
        ref.read(consultationHistoryProvider.notifier).loadMore();
      }
    }
  }

  /// Handles pull-to-refresh
  Future<void> _onRefresh() async {
    await ref.read(consultationHistoryProvider.notifier).refresh();
  }

  /// Handles service type filter selection
  void _onFilterChanged(String? serviceType) {
    setState(() {
      _selectedServiceType =
          serviceType == 'All Services' ? null : serviceType;
    });
    ref
        .read(consultationHistoryProvider.notifier)
        .filterByServiceType(_selectedServiceType);
  }

  /// Shows filter bottom sheet
  void _showFilterBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Service Type',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _serviceTypes.length,
                itemBuilder: (context, index) {
                  final serviceType = _serviceTypes[index];
                  final isSelected = serviceType == 'All Services'
                      ? _selectedServiceType == null
                      : _selectedServiceType == serviceType;

                  return RadioListTile<String>(
                    title: Text(serviceType),
                    value: serviceType,
                    groupValue: _selectedServiceType ?? 'All Services',
                    selected: isSelected,
                    onChanged: (value) {
                      _onFilterChanged(value);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows consultation detail bottom sheet
  void _showConsultationDetail(
    BuildContext context,
    ThemeData theme,
    AIConsultationModel consultation,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _buildDetailView(
          context,
          theme,
          consultation,
          scrollController,
        ),
      ),
    );
  }

  /// Builds the detail view content
  Widget _buildDetailView(
    BuildContext context,
    ThemeData theme,
    AIConsultationModel consultation,
    ScrollController scrollController,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Consultation Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Image with markers
          if (consultation.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                consultation.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderImage(200),
              ),
            ),
          const SizedBox(height: 20),

          // Service Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              consultation.serviceTypeDisplayName,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Diagnosis
          _buildDetailSection(
            theme,
            'Diagnosis',
            Icons.medical_services,
            consultation.diagnosis,
          ),
          const SizedBox(height: 16),

          // Cost Estimate
          _buildDetailSection(
            theme,
            'Cost Estimate',
            Icons.attach_money,
            consultation.costRangeFormatted,
          ),
          const SizedBox(height: 16),

          // Markers
          if (consultation.markers.isNotEmpty) ...[
            Text(
              'Marked Defects (${consultation.markerCount})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...consultation.markers.asMap().entries.map((entry) {
              final index = entry.key;
              final marker = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Position: (${(marker.x * 100).toStringAsFixed(1)}%, ${(marker.y * 100).toStringAsFixed(1)}%)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                marker.description,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          // Recommended Providers
          if (consultation.hasRecommendedProviders) ...[
            Text(
              'Recommended Providers (${consultation.providerCount})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...consultation.recommendedProviders.map((provider) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      provider.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(provider.rating.toStringAsFixed(1)),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to booking screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking feature coming soon'),
                          ),
                        );
                      },
                      child: const Text('Book'),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          // Metadata
          Card(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildMetadataRow(
                    theme,
                    Icons.calendar_today,
                    'Date',
                    '${consultation.formattedDate} at ${consultation.formattedTime}',
                  ),
                  if (consultation.processingTimeSeconds != null) ...[
                    const Divider(height: 16),
                    _buildMetadataRow(
                      theme,
                      Icons.timer,
                      'Processing Time',
                      consultation.formattedProcessingTime,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(context, theme, consultation);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a detail section with icon and content
  Widget _buildDetailSection(
    ThemeData theme,
    String title,
    IconData icon,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  /// Builds a metadata row
  Widget _buildMetadataRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  /// Shows delete confirmation dialog
  void _confirmDelete(
    BuildContext context,
    ThemeData theme,
    AIConsultationModel consultation,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Consultation'),
        content: const Text(
          'Are you sure you want to delete this consultation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteConsultation(consultation.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Deletes a consultation
  Future<void> _deleteConsultation(String consultationId) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Deleting consultation...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Delete via provider
      await ref.read(deleteConsultationProvider(consultationId).future);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Show error message
      logError('ConsultationHistoryScreen', 'Failed to delete consultation', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete consultation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Builds a placeholder image widget
  Widget _buildPlaceholderImage(double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image,
        size: height * 0.3,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyState = ref.watch(consultationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation History'),
        centerTitle: true,
        actions: [
          // Filter button
          IconButton(
            onPressed: () => _showFilterBottomSheet(context, theme),
            icon: Badge(
              isLabelVisible: historyState.hasFilter,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(context, theme, historyState),
      ),
    );
  }

  /// Builds the main body content
  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ConsultationHistoryState historyState,
  ) {
    // Initial loading state
    if (historyState.isLoading && historyState.consultations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state (only if no data)
    if (historyState.hasError &&
        historyState.consultations.isEmpty &&
        !historyState.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Consultations',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                historyState.error ?? 'An unexpected error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(consultationHistoryProvider.notifier)
                      .loadConsultations();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (historyState.isEmpty && !historyState.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                historyState.hasFilter
                    ? 'No consultations found'
                    : 'No consultations yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                historyState.hasFilter
                    ? 'Try adjusting your filter to see more results'
                    : 'Start your first consultation to get AI-powered diagnosis for your home service issues',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              if (historyState.hasFilter)
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(consultationHistoryProvider.notifier)
                        .clearFilter();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filter'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    context.push(RouteConstants.customerAIImageCapture);
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('New Consultation'),
                ),
            ],
          ),
        ),
      );
    }

    // Consultations list
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: historyState.consultations.length +
          (historyState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == historyState.consultations.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final consultation = historyState.consultations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ConsultationHistoryCard(
            consultation: consultation,
            onTap: () => _showConsultationDetail(
              context,
              theme,
              consultation,
            ),
          ),
        );
      },
    );
  }
}
