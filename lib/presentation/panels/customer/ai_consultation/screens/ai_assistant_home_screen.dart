import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/route_constants.dart';
import '../state/ai_consultation_providers.dart';

/// AI Assistant Home Screen
/// 
/// Main entry screen for the AI Visual Assistant feature.
/// Provides navigation to:
/// - New Consultation (image capture and analysis)
/// - Consultation History (past consultations)
/// 
/// Also displays:
/// - Feature explanation card
/// - Recent consultations preview
class AIAssistantHomeScreen extends ConsumerStatefulWidget {
  const AIAssistantHomeScreen({super.key});

  @override
  ConsumerState<AIAssistantHomeScreen> createState() =>
      _AIAssistantHomeScreenState();
}

class _AIAssistantHomeScreenState
    extends ConsumerState<AIAssistantHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load recent consultations on screen init
    Future.microtask(() {
      ref.read(consultationHistoryProvider.notifier).loadConsultations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyState = ref.watch(consultationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Visual Assistant'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(consultationHistoryProvider.notifier)
              .refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Info Card ───────────────────────────────────
              _buildInfoCard(theme),
              const SizedBox(height: 24),

              // ── Action Buttons ──────────────────────────────
              _buildActionButtons(context, theme),
              const SizedBox(height: 32),

              // ── Recent Consultations Preview ────────────────
              _buildRecentConsultationsSection(context, theme, historyState),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the feature explanation info card
  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI-Powered Diagnosis',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Get instant AI-powered diagnosis for your home service issues:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              theme,
              Icons.camera_alt,
              'Capture or select images of problem areas',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              theme,
              Icons.touch_app,
              'Mark defects and add descriptions',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              theme,
              Icons.psychology,
              'Get AI diagnosis and cost estimates',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              theme,
              Icons.people,
              'View recommended service providers',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single info item with icon and text
  Widget _buildInfoItem(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the main action buttons
  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // New Consultation Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              // Reset current consultation state before starting new
              ref.read(currentConsultationProvider.notifier).reset();
              // Navigate to image capture screen
              context.push(RouteConstants.customerAIImageCapture);
            },
            icon: const Icon(Icons.add_a_photo, size: 24),
            label: const Text(
              'New Consultation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // View History Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              context.push(RouteConstants.customerAIHistory);
            },
            icon: const Icon(Icons.history, size: 24),
            label: const Text(
              'View History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the recent consultations preview section
  Widget _buildRecentConsultationsSection(
    BuildContext context,
    ThemeData theme,
    ConsultationHistoryState historyState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Consultations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (historyState.consultations.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.push(RouteConstants.customerAIHistory);
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Loading state
        if (historyState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),

        // Error state
        if (historyState.hasError && !historyState.isLoading)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    historyState.error ?? 'Failed to load consultations',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
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
          ),

        // Empty state
        if (historyState.isEmpty && !historyState.isLoading)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No consultations yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first consultation to get AI-powered diagnosis',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Recent consultations list (max 3)
        if (historyState.consultations.isNotEmpty && !historyState.isLoading)
          ...historyState.consultations
              .take(3)
              .map((consultation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildConsultationPreviewCard(
                      context,
                      theme,
                      consultation,
                    ),
                  ))
              .toList(),
      ],
    );
  }

  /// Builds a single consultation preview card
  Widget _buildConsultationPreviewCard(
    BuildContext context,
    ThemeData theme,
    consultation,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            RouteConstants.customerAIConsultationDetail
                .replaceAll(':id', consultation.id),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: consultation.imageUrl != null
                    ? Image.network(
                        consultation.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        consultation.serviceTypeDisplayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Diagnosis summary
                    Text(
                      consultation.diagnosisSummary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Date and cost
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          consultation.formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.attach_money,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        Expanded(
                          child: Text(
                            consultation.costRangeFormatted,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a placeholder image widget
  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }
}
