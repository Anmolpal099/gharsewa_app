import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/safety_center_manager.dart';
import '../../data/models/safety_sop.dart';
import '../utils/provider_accessibility.dart';
import '../widgets/paginated_list.dart';
import '../widgets/provider_widgets.dart';

class SafetyCenterScreen extends ConsumerStatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  ConsumerState<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends ConsumerState<SafetyCenterScreen> {
  final _jobTypeController = TextEditingController();

  @override
  void dispose() {
    _jobTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(safetyCenterManagerProvider);
    final notifier = ref.read(safetyCenterManagerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.shield, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Safety Center',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (state.isOffline)
              Chip(
                avatar: const Icon(Icons.cloud_off, size: 16),
                label: const Text('Offline'),
                backgroundColor: Colors.orange.shade100,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Generate and save SOPs for offline access',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _jobTypeController,
          decoration: const InputDecoration(
            labelText: 'Job type',
            hintText: 'e.g. Electrical repair, Plumbing',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Generate safety SOP',
          button: true,
          child: FilledButton.icon(
            style: ProviderAccessibility.minTouchButton(null),
            onPressed: state.isGenerating
                ? null
                : () => notifier.generateSOP(_jobTypeController.text),
          icon: state.isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
            label: Text(state.isGenerating ? 'Generating...' : 'Generate SOP'),
          ),
        ),
        if (state.isGenerating && state.showSlowMessage)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Taking longer than usual…'),
          ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(state.error!, style: const TextStyle(color: Colors.red)),
          TextButton(
            onPressed: () => notifier.generateSOP(_jobTypeController.text),
            child: const Text('Retry'),
          ),
        ],
        if (state.generatedSop != null) ...[
          const SizedBox(height: 16),
          _SopView(sop: state.generatedSop!),
          const SizedBox(height: 8),
          FilledButton(
            style: ProviderAccessibility.minTouchButton(null),
            onPressed: () {
              ProviderAccessibility.onSaveProfile();
              notifier.saveSOP(state.generatedSop!);
            },
            child: const Text('Save SOP'),
          ),
        ],
        const SizedBox(height: 32),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search saved SOPs',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setSearchQuery,
        ),
        const SizedBox(height: 16),
        Text(
          'Saved SOPs',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (state.filteredSops.isEmpty)
          const EmptyStateWidget(
            icon: Icons.library_books_outlined,
            message: 'No saved SOPs yet',
          )
        else
          PaginatedListView<SafetySOP>(
            items: state.filteredSops,
            itemBuilder: (context, sop) => Semantics(
              label: 'Saved SOP for ${sop.jobType}',
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(sop.jobType),
                  subtitle: Text(
                    'Generated ${_formatDate(sop.generatedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete SOP',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.deleteSOP(sop.id),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SopView(sop: sop, compact: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _SopView extends StatelessWidget {
  final SafetySOP sop;
  final bool compact;

  const _SopView({required this.sop, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          _SectionList(title: 'Hazards', items: sop.hazards),
          _SectionList(title: 'Required PPE', items: sop.requiredPPE),
          _SectionList(title: 'Procedures', items: sop.procedures),
          _SectionList(
            title: 'Emergency protocols',
            items: sop.emergencyProtocols,
          ),
        ],
        Text(
          sop.content,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<String> items;

  const _SectionList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(i)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
