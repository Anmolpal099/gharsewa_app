import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../business_logic/scheduling_assistant_provider.dart';
import '../../data/models/scheduling_suggestion.dart';

/// Gradient CTA banner for scheduling gaps (Stitch design).
class SchedulingAssistantBanner extends ConsumerWidget {
  const SchedulingAssistantBanner({super.key});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF5B2C9E), Color(0xFF3D5AFE)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(schedulingAssistantProvider);
    if (suggestion == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Semantics(
        label:
            'Scheduling Assistant: ${suggestion.displayMessage}',
        button: true,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onFillSlot(context, suggestion),
            child: Ink(
              decoration: const BoxDecoration(gradient: _gradient),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scheduling Assistant: ${suggestion.displayMessage}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FillSlotButton(
                      onPressed: () => _onFillSlot(context, suggestion),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onFillSlot(BuildContext context, SchedulingSuggestion suggestion) {
    context.go(RouteConstants.providerSchedule);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening schedule for ${_formatSlot(suggestion)}. '
          'AI scheduling model will connect here later.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatSlot(SchedulingSuggestion s) {
    return s.displayMessage.replaceFirst('You have a ', '').replaceFirst('.', '');
  }
}

class _FillSlotButton extends StatelessWidget {
  const _FillSlotButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            'Fill\nSlot',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}
