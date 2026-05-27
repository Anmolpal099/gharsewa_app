import 'package:flutter/material.dart';
import '../../../../../data/models/ai_consultation_models.dart';

/// Consultation History Card Widget
/// 
/// Displays a consultation summary in a card format with:
/// - Thumbnail image
/// - Service type badge
/// - Diagnosis summary (truncated)
/// - Date and cost information
/// - Tap gesture to view details
class ConsultationHistoryCard extends StatelessWidget {
  final AIConsultationModel consultation;
  final VoidCallback onTap;

  const ConsultationHistoryCard({
    super.key,
    required this.consultation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Image
              _buildThumbnail(),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Type Badge
                    _buildServiceTypeBadge(theme),
                    const SizedBox(height: 8),

                    // Diagnosis Summary
                    Text(
                      consultation.diagnosisSummary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date and Cost
                    _buildMetadata(theme),
                  ],
                ),
              ),

              // Arrow Icon
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

  /// Builds the thumbnail image
  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: consultation.imageUrl != null
          ? Image.network(
              consultation.imageUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderImage(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingImage();
              },
            )
          : _buildPlaceholderImage(),
    );
  }

  /// Builds a placeholder image when image fails to load or is null
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

  /// Builds a loading indicator for image
  Widget _buildLoadingImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// Builds the service type badge
  Widget _buildServiceTypeBadge(ThemeData theme) {
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
        consultation.serviceTypeDisplayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the metadata row (date and cost)
  Widget _buildMetadata(ThemeData theme) {
    return Row(
      children: [
        // Date
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

        // Cost Range
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
    );
  }
}
