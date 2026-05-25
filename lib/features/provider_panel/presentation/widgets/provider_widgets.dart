import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/media_url.dart';

class GradientCard extends StatelessWidget {
  final List<Color>? colors;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ??
        [
          AppTheme.primaryGreen,
          AppTheme.primaryGreen.withValues(alpha: 0.75),
        ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SkillChip extends StatefulWidget {
  final String label;
  final VoidCallback? onRemove;

  const SkillChip({super.key, required this.label, this.onRemove});

  @override
  State<SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<SkillChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Semantics(
        label: 'Skill ${widget.label}',
        button: widget.onRemove != null,
        child: Chip(
          label: Text(widget.label),
          deleteIcon:
              widget.onRemove != null ? const Icon(Icons.close, size: 18) : null,
          onDeleted: widget.onRemove,
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
          side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final bool useGradient;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: useGradient ? Colors.white : AppTheme.primaryGreen),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: useGradient ? Colors.white70 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: useGradient ? Colors.white : null,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12,
              color: useGradient ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ],
    );

    if (useGradient) {
      return GradientCard(child: content);
    }

    return Card(child: Padding(padding: const EdgeInsets.all(16), child: content));
  }
}

class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppTheme.primaryGreen,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.verified, color: Colors.white, size: size * 0.65),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String? email;
  final String? phone;
  final int servicesCount;
  final String location;
  final String category;
  final bool isVerified;

  const ProfileHeader({
    super.key,
    required this.name,
    this.photoUrl,
    this.email,
    this.phone,
    this.servicesCount = 0,
    required this.location,
    required this.category,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPhoto = resolveMediaUrl(photoUrl);

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
          backgroundImage: resolvedPhoto.isNotEmpty
              ? CachedNetworkImageProvider(resolvedPhoto)
              : null,
          child: resolvedPhoto.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 8),
                    const VerifiedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (email != null && email!.isNotEmpty)
                Text(email!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              if (phone != null && phone!.isNotEmpty)
                Text(phone!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(location, style: TextStyle(color: Colors.grey[600])),
              Text(
                category,
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (servicesCount > 0)
                Text(
                  '$servicesCount active service${servicesCount == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class SuggestionCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onDismiss;

  const SuggestionCard({
    super.key,
    required this.title,
    required this.description,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI suggestion: $title',
      child: GradientCard(
        colors: const [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: onDismiss,
                tooltip: 'Dismiss suggestion',
              ),
          ],
        ),
      ),
    );
  }
}

/// Swipeable suggestion carousel (plan 4.5, 8.5).
class SuggestionPager extends StatefulWidget {
  final List<({String id, String title, String description})> items;
  final Future<void> Function(String id) onDismiss;

  const SuggestionPager({
    super.key,
    required this.items,
    required this.onDismiss,
  });

  @override
  State<SuggestionPager> createState() => _SuggestionPagerState();
}

class _SuggestionPagerState extends State<SuggestionPager> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              return SuggestionCard(
                title: item.title,
                description: item.description,
                onDismiss: () => widget.onDismiss(item.id),
              );
            },
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: 8),
          Text(
            'Swipe for more • ${_index + 1}/${widget.items.length}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}
