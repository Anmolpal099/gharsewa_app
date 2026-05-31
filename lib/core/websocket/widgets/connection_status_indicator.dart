import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../websocket_provider.dart';
import '../models/connection_state.dart';

/// Connection status indicator widget
/// 
/// Displays real-time WebSocket connection status with visual feedback.
/// - "Connecting..." indicator when connecting
/// - "Live" indicator with green status when connected
/// - "Disconnected" indicator with red status when disconnected
/// - "Reconnecting..." with attempt count during reconnection
/// - Positioned in app bar or non-intrusive location
/// - Animates transitions between states
/// 
/// **Requirements**: 13.1, 13.2, 13.3, 13.4, 13.5
class ConnectionStatusIndicator extends ConsumerWidget {
  /// Whether to show the indicator in a compact form (smaller, icon-only)
  final bool compact;
  
  /// Whether to show the indicator in the app bar style
  final bool appBarStyle;
  
  /// Custom text style for the status label
  final TextStyle? textStyle;

  const ConnectionStatusIndicator({
    super.key,
    this.compact = false,
    this.appBarStyle = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the WebSocket connection state
    final connectionState = ref.watch(webSocketConnectionProvider);
    
    // Get the connection manager to check reconnection attempts
    final connectionManager = ref.watch(webSocketActionsProvider);
    final reconnectAttempts = connectionManager.reconnectAttempts;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _buildStatusIndicator(context, connectionState, reconnectAttempts),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    ConnectionState state,
    int reconnectAttempts,
  ) {
    switch (state) {
      case ConnectionState.connecting:
        return _buildConnectingIndicator(context);
      
      case ConnectionState.connected:
        return _buildLiveIndicator(context);
      
      case ConnectionState.disconnected:
        return _buildDisconnectedIndicator(context, reconnectAttempts);
      
      case ConnectionState.error:
        return _buildErrorIndicator(context, reconnectAttempts);
    }
  }

  /// Build "Connecting..." indicator
  /// 
  /// **Requirement 13.1**: Display "Connecting..." status when connecting
  Widget _buildConnectingIndicator(BuildContext context) {
    if (compact) {
      return _buildCompactIndicator(
        context,
        color: Colors.orange,
        icon: Icons.sync,
        label: 'Connecting...',
      );
    }

    if (appBarStyle) {
      return _buildAppBarIndicator(
        context,
        color: Colors.orange,
        icon: Icons.sync,
        label: 'Connecting...',
      );
    }

    return _buildFullIndicator(
      context,
      color: Colors.orange,
      icon: Icons.sync,
      label: 'Connecting...',
      subtitle: 'Establishing WebSocket connection',
    );
  }

  /// Build "Live" indicator with green status
  /// 
  /// **Requirement 13.2**: Display "Live" status when connected
  Widget _buildLiveIndicator(BuildContext context) {
    if (compact) {
      return _buildCompactIndicator(
        context,
        color: Colors.green,
        icon: Icons.check_circle,
        label: 'Live',
      );
    }

    if (appBarStyle) {
      return _buildAppBarIndicator(
        context,
        color: Colors.green,
        icon: Icons.check_circle,
        label: 'Live',
      );
    }

    return _buildFullIndicator(
      context,
      color: Colors.green,
      icon: Icons.check_circle,
      label: 'Live',
      subtitle: 'Real-time updates active',
    );
  }

  /// Build "Disconnected" indicator with red status
  /// 
  /// **Requirement 13.3**: Display "Disconnected" status when disconnected
  Widget _buildDisconnectedIndicator(BuildContext context, int reconnectAttempts) {
    // If reconnection attempts > 0, show reconnecting status
    if (reconnectAttempts > 0) {
      return _buildReconnectingIndicator(context, reconnectAttempts);
    }

    if (compact) {
      return _buildCompactIndicator(
        context,
        color: Colors.red,
        icon: Icons.error_outline,
        label: 'Disconnected',
      );
    }

    if (appBarStyle) {
      return _buildAppBarIndicator(
        context,
        color: Colors.red,
        icon: Icons.error_outline,
        label: 'Disconnected',
      );
    }

    return _buildFullIndicator(
      context,
      color: Colors.red,
      icon: Icons.error_outline,
      label: 'Disconnected',
      subtitle: 'WebSocket connection lost',
    );
  }

  /// Build "Reconnecting..." indicator with attempt count
  /// 
  /// **Requirement 13.4**: Display "Reconnecting..." status during reconnection
  Widget _buildReconnectingIndicator(BuildContext context, int reconnectAttempts) {
    final label = 'Reconnecting... ($reconnectAttempts)';

    if (compact) {
      return _buildCompactIndicator(
        context,
        color: Colors.orange,
        icon: Icons.refresh,
        label: label,
        animateIcon: true,
      );
    }

    if (appBarStyle) {
      return _buildAppBarIndicator(
        context,
        color: Colors.orange,
        icon: Icons.refresh,
        label: label,
        animateIcon: true,
      );
    }

    return _buildFullIndicator(
      context,
      color: Colors.orange,
      icon: Icons.refresh,
      label: label,
      subtitle: 'Attempting to reconnect...',
      animateIcon: true,
    );
  }

  /// Build error indicator
  Widget _buildErrorIndicator(BuildContext context, int reconnectAttempts) {
    // If reconnection attempts > 0, show reconnecting status
    if (reconnectAttempts > 0) {
      return _buildReconnectingIndicator(context, reconnectAttempts);
    }

    if (compact) {
      return _buildCompactIndicator(
        context,
        color: Colors.red,
        icon: Icons.error,
        label: 'Error',
      );
    }

    if (appBarStyle) {
      return _buildAppBarIndicator(
        context,
        color: Colors.red,
        icon: Icons.error,
        label: 'Error',
      );
    }

    return _buildFullIndicator(
      context,
      color: Colors.red,
      icon: Icons.error,
      label: 'Connection Error',
      subtitle: 'Failed to establish connection',
    );
  }

  /// Build compact indicator (icon + label, smaller)
  Widget _buildCompactIndicator(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    bool animateIcon = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        if (animateIcon) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(
          label,
          style: textStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
        ),
      ],
    );
  }

  /// Build app bar style indicator
  Widget _buildAppBarIndicator(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    bool animateIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animateIcon)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: textStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
    );
  }

  /// Build full indicator with subtitle
  Widget _buildFullIndicator(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required String subtitle,
    bool animateIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animateIcon)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Minimal connection status badge
/// 
/// A small badge that can be placed in the app bar or other compact spaces.
/// Shows only the connection status with a colored dot.
/// 
/// **Requirements**: 13.1, 13.2, 13.3, 13.4
class ConnectionStatusBadge extends ConsumerWidget {
  final double size;
  final bool showLabel;

  const ConnectionStatusBadge({
    super.key,
    this.size = 8.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(webSocketConnectionProvider);
    final connectionManager = ref.watch(webSocketActionsProvider);
    final reconnectAttempts = connectionManager.reconnectAttempts;

    Color color;
    String? label;

    switch (connectionState) {
      case ConnectionState.connecting:
        color = Colors.orange;
        label = showLabel ? 'Connecting' : null;
        break;
      case ConnectionState.connected:
        color = Colors.green;
        label = showLabel ? 'Live' : null;
        break;
      case ConnectionState.disconnected:
        color = reconnectAttempts > 0 ? Colors.orange : Colors.red;
        label = showLabel 
            ? (reconnectAttempts > 0 ? 'Reconnecting' : 'Disconnected') 
            : null;
        break;
      case ConnectionState.error:
        color = Colors.red;
        label = showLabel ? 'Error' : null;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}
