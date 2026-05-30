import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../features/presence/providers/presence_realtime_provider.dart';

/// Online presence indicator widget
/// 
/// Displays a visual indicator showing whether a user is currently online.
/// - Green dot for online users
/// - Gray dot or no indicator for offline users
/// - Shows last seen timestamp for offline users on profile pages
/// - Updates indicator within 1 second of presence change
/// 
/// **Requirements**: 12.1, 12.2, 12.3, 12.4, 12.5
class OnlineIndicator extends ConsumerWidget {
  /// The user ID to check online status for
  final String userId;
  
  /// Whether to show the indicator for offline users (gray dot)
  /// If false, no indicator is shown for offline users
  final bool showOfflineIndicator;
  
  /// Size of the indicator dot in pixels
  final double size;
  
  /// Whether to show last seen timestamp for offline users
  /// Only applicable on profile pages or detailed views
  final bool showLastSeen;
  
  /// Optional last seen timestamp for offline users
  /// If null and user is offline, no last seen info is displayed
  final DateTime? lastSeenAt;

  const OnlineIndicator({
    super.key,
    required this.userId,
    this.showOfflineIndicator = false,
    this.size = 10.0,
    this.showLastSeen = false,
    this.lastSeenAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the online status for this specific user
    // **Requirement 12.2**: Update indicator within 1 second of presence change
    final isOnline = ref.watch(isUserOnlineProvider(userId));

    // **Requirement 12.3**: Display green dot for online users
    if (isOnline) {
      return _buildOnlineIndicator();
    }

    // **Requirement 12.4**: Display gray dot or no indicator for offline users
    if (showOfflineIndicator) {
      return _buildOfflineIndicator(context);
    }

    // No indicator for offline users when showOfflineIndicator is false
    return const SizedBox.shrink();
  }

  /// Build the online indicator (green dot)
  /// 
  /// **Requirement 12.3**: Display green dot for online users
  Widget _buildOnlineIndicator() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  /// Build the offline indicator (gray dot)
  /// 
  /// **Requirement 12.4**: Display gray dot for offline users
  Widget _buildOfflineIndicator(BuildContext context) {
    // If we should show last seen timestamp, wrap in a column
    if (showLastSeen && lastSeenAt != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          _buildLastSeenText(context),
        ],
      );
    }

    // Just the gray dot
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Build the last seen timestamp text
  /// 
  /// **Requirement 12.5**: Show last seen timestamp for offline users on profile pages
  Widget _buildLastSeenText(BuildContext context) {
    if (lastSeenAt == null) {
      return const SizedBox.shrink();
    }

    final lastSeenText = timeago.format(lastSeenAt!);

    return Text(
      'Last seen $lastSeenText',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 12,
          ),
    );
  }
}

/// Online indicator with label
/// 
/// A variant that shows the online status with a text label.
/// Useful for list items or cards where you want to show "Online" or "Offline" text.
/// 
/// **Requirements**: 12.1, 12.2, 12.3, 12.4
class OnlineIndicatorWithLabel extends ConsumerWidget {
  /// The user ID to check online status for
  final String userId;
  
  /// Size of the indicator dot in pixels
  final double dotSize;
  
  /// Text style for the label
  final TextStyle? labelStyle;
  
  /// Spacing between dot and label
  final double spacing;

  const OnlineIndicatorWithLabel({
    super.key,
    required this.userId,
    this.dotSize = 8.0,
    this.labelStyle,
    this.spacing = 6.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the online status for this specific user
    // **Requirement 12.2**: Update indicator within 1 second of presence change
    final isOnline = ref.watch(isUserOnlineProvider(userId));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // **Requirement 12.3**: Display green dot for online users
        // **Requirement 12.4**: Display gray dot for offline users
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(width: spacing),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: labelStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOnline ? Colors.green : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
        ),
      ],
    );
  }
}

/// Compact online indicator badge
/// 
/// A small badge-style indicator that can be overlaid on avatars or profile pictures.
/// Positioned in the bottom-right corner by default.
/// 
/// **Requirements**: 12.1, 12.2, 12.3, 12.4
class OnlineIndicatorBadge extends ConsumerWidget {
  /// The user ID to check online status for
  final String userId;
  
  /// Size of the badge in pixels
  final double size;
  
  /// Whether to show a white border around the badge
  final bool showBorder;
  
  /// Border width if showBorder is true
  final double borderWidth;

  const OnlineIndicatorBadge({
    super.key,
    required this.userId,
    this.size = 12.0,
    this.showBorder = true,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the online status for this specific user
    // **Requirement 12.2**: Update indicator within 1 second of presence change
    final isOnline = ref.watch(isUserOnlineProvider(userId));

    // Only show badge for online users
    // **Requirement 12.1**: Show online indicator for users in presence channel
    if (!isOnline) {
      return const SizedBox.shrink();
    }

    // **Requirement 12.3**: Display green dot for online users
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Provider-specific online indicator
/// 
/// A specialized indicator for service providers that uses the provider-specific
/// online status check. This is optimized for provider lists and searches.
/// 
/// **Requirements**: 12.1, 12.2, 12.3, 12.4
class ProviderOnlineIndicator extends ConsumerWidget {
  /// The provider ID to check online status for
  final String providerId;
  
  /// Whether to show the indicator for offline providers (gray dot)
  final bool showOfflineIndicator;
  
  /// Size of the indicator dot in pixels
  final double size;

  const ProviderOnlineIndicator({
    super.key,
    required this.providerId,
    this.showOfflineIndicator = false,
    this.size = 10.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider-specific online status
    // **Requirement 12.2**: Update indicator within 1 second of presence change
    final isOnline = ref.watch(isProviderOnlineProvider(providerId));

    // **Requirement 12.3**: Display green dot for online users
    if (isOnline) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }

    // **Requirement 12.4**: Display gray dot or no indicator for offline users
    if (showOfflineIndicator) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
