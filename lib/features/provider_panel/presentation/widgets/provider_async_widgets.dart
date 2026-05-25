import 'package:flutter/material.dart';

import '../../../../services/api/api_exception.dart';

/// Network/validation error panel with retry (plan 12.1).
class ProviderErrorPanel extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String? title;

  const ProviderErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
    this.title,
  });

  static String messageFor(Object error) {
    if (error is ApiException) return error.message;
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('network')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (text.contains('timeout') || text.contains('Timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (text.contains('500') || text.contains('Server')) {
      return 'Server error. Please try again later.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            title ?? 'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            messageFor(error),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Shimmer-style loading placeholder (plan 12.3).
class ProviderSkeletonCard extends StatefulWidget {
  final double height;

  const ProviderSkeletonCard({super.key, this.height = 120});

  @override
  State<ProviderSkeletonCard> createState() => _ProviderSkeletonCardState();
}

class _ProviderSkeletonCardState extends State<ProviderSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Card(
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                  Colors.grey.shade300,
                ],
                stops: [
                  _controller.value - 0.3,
                  _controller.value,
                  _controller.value + 0.3,
                ].map((v) => v.clamp(0.0, 1.0)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
