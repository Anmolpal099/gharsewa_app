import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/constants/route_constants.dart';
import '../../../../../core/utils/error_logger.dart';
import '../../../../../data/models/ai_consultation_models.dart';
import '../state/ai_consultation_providers.dart';

/// Analysis Results Screen
///
/// Displays AI analysis results including:
/// - Annotated image thumbnail with markers
/// - Diagnosis card with prominent styling
/// - Service type with icon
/// - Cost estimate in NPR range format
/// - Provider recommendations with booking options
/// - Loading state during analysis
/// - Timeout handling (30 seconds)
class AnalysisResultsScreen extends ConsumerStatefulWidget {
  const AnalysisResultsScreen({super.key});

  @override
  ConsumerState<AnalysisResultsScreen> createState() =>
      _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState
    extends ConsumerState<AnalysisResultsScreen> {
  Timer? _timeoutTimer;
  bool _showTimeoutDialog = false;

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// Start a 30-second timeout timer for analysis
  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        final state = ref.read(currentConsultationProvider);
        // Only show timeout if still submitting
        if (state.isSubmitting && !_showTimeoutDialog) {
          logWarning('AnalysisResultsScreen', 'AI analysis timeout (30 seconds)');
          _showTimeoutDialog = true;
          _showTimeoutOptionsDialog();
        }
      }
    });
  }

  /// Show timeout dialog with options to keep waiting or cancel
  void _showTimeoutOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Taking Longer'),
        content: const Text(
          'The AI analysis is taking longer than expected. Would you like to keep waiting or cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RouteConstants.customerAIAssistant);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showTimeoutDialog = false;
              // Restart timer for another 30 seconds
              _startTimeoutTimer();
            },
            child: const Text('Keep Waiting'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(currentConsultationProvider);

    // Show loading overlay if still submitting
    if (state.isSubmitting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Results'),
          centerTitle: true,
        ),
        body: _buildLoadingOverlay(theme),
      );
    }

    // Show error if analysis failed
    if (state.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Results'),
          centerTitle: true,
        ),
        body: _buildErrorState(theme, state.error!),
      );
    }

    // Show error if no consultation data
    if (state.consultation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Results'),
          centerTitle: true,
        ),
        body: _buildErrorState(theme, 'No consultation data available'),
      );
    }

    final consultation = state.consultation!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image Thumbnail with Markers ────────────────
            _buildImageThumbnail(theme, consultation),
            const SizedBox(height: 20),

            // ── Diagnosis Card ──────────────────────────────
            _buildDiagnosisCard(theme, consultation),
            const SizedBox(height: 16),

            // ── Service Type Card ───────────────────────────
            _buildServiceTypeCard(theme, consultation),
            const SizedBox(height: 16),

            // ── Cost Estimate Card ──────────────────────────
            _buildCostEstimateCard(theme, consultation),
            const SizedBox(height: 24),

            // ── Provider Recommendations ────────────────────
            _buildProviderRecommendationsSection(theme, consultation),
            const SizedBox(height: 24),

            // ── Action Buttons ──────────────────────────────
            _buildActionButtons(context, theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds loading overlay during analysis
  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              },
              onEnd: () {
                // Loop animation
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Analyzing your image...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take up to 30 seconds',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds error state
  Widget _buildErrorState(ThemeData theme, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Analysis Failed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go(RouteConstants.customerAIAssistant);
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds image thumbnail with markers overlay
  Widget _buildImageThumbnail(
    ThemeData theme,
    AIConsultationModel consultation,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (consultation.imageUrl != null)
              CachedNetworkImage(
                imageUrl: consultation.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
              )
            else
              Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),

            // Markers overlay
            CustomPaint(
              painter: _MarkerOverlayPainter(
                markers: consultation.markers,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds diagnosis card with prominent styling
  Widget _buildDiagnosisCard(
    ThemeData theme,
    AIConsultationModel consultation,
  ) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.errorContainer,
              theme.colorScheme.errorContainer.withValues(alpha: 0.7),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Diagnosis',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              consultation.diagnosis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds service type card with icon
  Widget _buildServiceTypeCard(
    ThemeData theme,
    AIConsultationModel consultation,
  ) {
    final serviceIcon = _getServiceTypeIcon(consultation.recommendedServiceType);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                serviceIcon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Type',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    consultation.serviceTypeDisplayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds cost estimate card
  Widget _buildCostEstimateCard(
    ThemeData theme,
    AIConsultationModel consultation,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.attach_money,
                color: theme.colorScheme.secondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Cost',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    consultation.costRangeFormatted,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds provider recommendations section
  Widget _buildProviderRecommendationsSection(
    ThemeData theme,
    AIConsultationModel consultation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Providers',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (consultation.recommendedProviders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No providers available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No service providers are currently available for this service type',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...consultation.recommendedProviders.map(
            (provider) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProviderRecommendationCard(
                provider: provider,
                serviceType: consultation.recommendedServiceType,
                onBookNow: () => _handleBookNow(
                  context,
                  provider.id,
                  consultation.recommendedServiceType,
                ),
                onContact: () => _handleContact(context, provider),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds action buttons at the bottom
  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // Reset consultation state and navigate to home
          ref.read(currentConsultationProvider.notifier).reset();
          context.go(RouteConstants.customerAIAssistant);
        },
        icon: const Icon(Icons.add_a_photo, size: 24),
        label: const Text(
          'Start New Consultation',
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
    );
  }

  /// Handle Book Now button press
  void _handleBookNow(
    BuildContext context,
    String providerId,
    String serviceType,
  ) {
    // Navigate to booking screen with pre-filled data
    // Format: /customer/booking/{providerId}?serviceType={serviceType}
    context.push('/customer/booking/$providerId?serviceType=$serviceType');
  }

  /// Handle Contact button press
  void _handleContact(
    BuildContext context,
    ProviderRecommendationModel provider,
  ) {
    // Show contact options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${provider.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.phone != null) ...[
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(provider.phone!),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (provider.email != null) ...[
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(provider.email!),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (provider.phone == null && provider.email == null)
              const Text('No contact information available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get icon for service type
  IconData _getServiceTypeIcon(String serviceType) {
    final type = serviceType.toLowerCase().replaceAll(' ', '_');
    switch (type) {
      case 'plumbing':
      case 'plumbing_repair':
        return Icons.plumbing;
      case 'electrical':
      case 'electrical_work':
        return Icons.electrical_services;
      case 'carpentry':
        return Icons.carpenter;
      case 'painting':
        return Icons.format_paint;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'appliance_repair':
        return Icons.build;
      case 'hvac':
        return Icons.ac_unit;
      case 'pest_control':
        return Icons.pest_control;
      case 'landscaping':
        return Icons.grass;
      case 'general_maintenance':
      default:
        return Icons.home_repair_service;
    }
  }
}

/// Custom painter for marker overlay on image thumbnail
class _MarkerOverlayPainter extends CustomPainter {
  final List<DefectMarkerModel> markers;
  final ThemeData theme;

  _MarkerOverlayPainter({
    required this.markers,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final markerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final center = Offset(marker.x * size.width, marker.y * size.height);
      const radius = 12.0;

      // Draw filled circle
      canvas.drawCircle(center, radius, fillPaint);
      // Draw circle outline
      canvas.drawCircle(center, radius, markerPaint);

      // Draw marker number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_MarkerOverlayPainter oldDelegate) {
    return oldDelegate.markers != markers;
  }
}

/// Provider Recommendation Card Widget
class _ProviderRecommendationCard extends StatelessWidget {
  final ProviderRecommendationModel provider;
  final String serviceType;
  final VoidCallback onBookNow;
  final VoidCallback onContact;

  const _ProviderRecommendationCard({
    required this.provider,
    required this.serviceType,
    required this.onBookNow,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider name and rating
            Row(
              children: [
                Expanded(
                  child: Text(
                    provider.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildRatingStars(theme, provider.rating),
              ],
            ),
            const SizedBox(height: 8),

            // Services offered
            if (provider.services.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: provider.services.take(3).map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBookNow,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Book Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
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

  /// Build rating stars display
  Widget _buildRatingStars(ThemeData theme, double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            // Full star
            return Icon(
              Icons.star,
              size: 16,
              color: Colors.amber.shade700,
            );
          } else if (index < rating) {
            // Half star
            return Icon(
              Icons.star_half,
              size: 16,
              color: Colors.amber.shade700,
            );
          } else {
            // Empty star
            return Icon(
              Icons.star_border,
              size: 16,
              color: Colors.grey.shade400,
            );
          }
        }),
        const SizedBox(width: 4),
        Text(
          provider.formattedRating,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
