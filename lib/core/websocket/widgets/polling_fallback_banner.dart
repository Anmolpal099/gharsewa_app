import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/polling_service.dart';

/// Polling fallback banner widget
/// 
/// Displays a message when the app is using HTTP polling fallback
/// instead of WebSocket real-time updates.
/// 
/// Shows "Real-time updates temporarily unavailable" when polling is active.
/// Automatically dismisses when WebSocket connection is restored.
/// 
/// **Requirements**: 14.5
class PollingFallbackBanner extends ConsumerWidget {
  /// Whether to show the banner in a compact form (smaller, icon-only)
  final bool compact;
  
  /// Whether to show the banner in the app bar style
  final bool appBarStyle;
  
  /// Custom text style for the message
  final TextStyle? textStyle;
  
  /// Custom action button to dismiss the banner
  final VoidCallback? onDismiss;
  
  /// Whether to allow manual dismissal
  final bool dismissible;

  const PollingFallbackBanner({
    super.key,
    this.compact = false,
    this.appBarStyle = false,
    this.textStyle,
    this.onDismiss,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the polling state
    final isPolling = ref.watch(isPollingActiveProvider);

    // Don't show anything if not polling
    if (!isPolling) {
      return const SizedBox.shrink();
    }

    // Show the banner
    if (compact) {
      return _buildCompactBanner(context);
    }

    if (appBarStyle) {
      return _buildAppBarBanner(context);
    }

    return _buildFullBanner(context);
  }

  /// Build compact banner (small, icon + text)
  Widget _buildCompactBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_alt,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            'Polling mode',
            style: textStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
          ),
        ],
      ),
    );
  }

  /// Build app bar style banner
  Widget _buildAppBarBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_alt,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            'Real-time updates unavailable',
            style: textStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
    );
  }

  /// Build full banner with dismiss button
  Widget _buildFullBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sync_alt,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time updates temporarily unavailable',
                  style: textStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Using polling mode for updates. Reconnecting...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          if (dismissible && onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              color: Colors.orange,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Polling status indicator
/// 
/// A small indicator that can be placed in the app bar or other compact spaces.
/// Shows a small orange dot when polling is active.
/// 
/// **Requirements**: 14.5
class PollingStatusIndicator extends ConsumerWidget {
  final double size;
  final bool showLabel;

  const PollingStatusIndicator({
    super.key,
    this.size = 8.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPolling = ref.watch(isPollingActiveProvider);

    // Don't show anything if not polling
    if (!isPolling) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            'Polling',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}

/// Polling status banner with action
/// 
/// A banner that shows polling status and provides a manual refresh button.
/// 
/// **Requirements**: 14.5
class PollingStatusBanner extends ConsumerWidget {
  final VoidCallback? onManualRefresh;

  const PollingStatusBanner({
    super.key,
    this.onManualRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPolling = ref.watch(isPollingActiveProvider);

    // Don't show anything if not polling
    if (!isPolling) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sync_alt,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time updates temporarily unavailable',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Using polling mode. Updates will refresh every 30-60 seconds.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          if (onManualRefresh != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onManualRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
