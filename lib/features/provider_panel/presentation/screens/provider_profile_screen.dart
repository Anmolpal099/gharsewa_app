import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../business_logic/ai_suggestion_engine.dart';
import '../../business_logic/performance_tracker.dart';
import '../../business_logic/profile_manager.dart';
import '../../data/models/models.dart';
import '../../data/services/dismissed_suggestions_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../utils/provider_accessibility.dart';
import '../../../../core/utils/media_url.dart';
import '../widgets/provider_async_widgets.dart';
import '../widgets/provider_widgets.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/models/platform_image.dart';

final profileSuggestionsProvider =
    FutureProvider<List<({String id, String title, String description})>>(
        (ref) async {
  final profile = ref.watch(profileManagerProvider).value;
  if (profile == null) return [];

  final engine = ref.read(aiSuggestionEngineProvider);
  final suggestions = engine.generateProfileSuggestions(profile);
  final store = ref.read(dismissedSuggestionsStoreProvider);
  final items = <({String id, String title, String description})>[];

  for (final s in suggestions) {
    if (!await store.isDismissed(s.id)) {
      items.add((id: s.id, title: s.title, description: s.description));
    }
  }
  return items;
});

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  final ImageService _imageService = ImageService();
  double _uploadProgress = 0;
  bool _isUploading = false;
  PlatformImage? _pendingCertImage;
  String? _pendingCertName;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileManagerProvider.notifier).fetchProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileManagerProvider);
    final suggestionsAsync = ref.watch(profileSuggestionsProvider);
    final metricsAsync = ref.watch(performanceTrackerProvider);
    final perf = ref.watch(performanceTrackerHelpersProvider);

    return profileAsync.when(
      loading: () => const ProviderSkeletonCard(height: 320),
      error: (e, _) => ProviderErrorPanel(
        error: e,
        onRetry: () =>
            ref.read(profileManagerProvider.notifier).fetchProfile(forceRefresh: true),
      ),
      data: (profile) {
        return RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(profileManagerProvider.notifier)
                .fetchProfile(forceRefresh: true);
            ref.invalidate(profileSuggestionsProvider);
            ref.invalidate(performanceTrackerProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text(
                    'My Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: ProviderAccessibility.minTouchButton(null),
                    onPressed: _isUploading
                        ? null
                        : () => _editProfileDetails(context, profile),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit profile'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ProfileHeader(
                name: profile.name,
                photoUrl: profile.photoUrl,
                email: profile.email,
                phone: profile.phoneNumber,
                servicesCount: profile.servicesCount,
                location: profile.location,
                category: profile.professionalCategory,
                isVerified: profile.isVerified,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _isUploading ? null : () => _pickProfilePhoto(context),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Change photo'),
                  ),
                ],
              ),
              if (_isUploading)
                LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 16),
              _CompletenessBar(completeness: profile.completeness),
              if (profile.completeness < 80) ...[
                const SizedBox(height: 8),
                _ProfilePromptBanner(
                  message:
                      'Complete your profile to get more bookings (currently ${profile.completeness.toInt()}%).',
                ),
              ],
              if (profile.isComplete) ...[
                const SizedBox(height: 8),
                const _ProfileCompleteBanner(),
              ],
              if (profile.missingItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                _MissingItemsCard(items: profile.missingItems),
              ],
              const SizedBox(height: 16),
              suggestionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  return SuggestionPager(
                    items: items,
                    onDismiss: (id) async {
                      await ref
                          .read(dismissedSuggestionsStoreProvider)
                          .dismiss(id);
                      ref.invalidate(profileSuggestionsProvider);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              metricsAsync.when(
                loading: () => const ProviderSkeletonCard(height: 100),
                error: (_, __) => const SizedBox.shrink(),
                data: (metrics) => _Section(
                  title: 'Performance',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StarRatingRow(rating: metrics.rating),
                          const SizedBox(width: 8),
                          Text(
                            metrics.formattedRating,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (metrics.isTopPerformer) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Top performer'),
                              backgroundColor:
                                  AppTheme.primaryGreen.withValues(alpha: 0.15),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              icon: Icons.reviews_outlined,
                              label: 'Reviews',
                              value: '${metrics.totalReviews}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricCard(
                              icon: Icons.work_outline,
                              label: 'Jobs done',
                              value: '${metrics.jobsCompleted}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      MetricCard(
                        icon: Icons.timer,
                        label: 'Avg response',
                        value: perf.formatResponseTime(
                          metrics.averageResponseTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_pendingCertImage != null) ...[
                Card(
                  child: ListTile(
                    title: Text('Retry upload: $_pendingCertName'),
                    trailing: FilledButton(
                      onPressed: _isUploading ? null : () => _retryCertUpload(context),
                      child: const Text('Retry'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _Section(
                title: 'Bio',
                action: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editBio(context, profile.bio ?? ''),
                ),
                child: Text(
                  profile.bio?.isNotEmpty == true
                      ? profile.bio!
                      : 'Add a bio (50–500 characters)',
                  style: TextStyle(
                    color: profile.bio?.isNotEmpty == true
                        ? null
                        : Colors.grey,
                  ),
                ),
              ),
              _Section(
                title: 'Skills',
                action: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addSkill(context),
                ),
                child: profile.skills.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.build_outlined,
                        message: 'Add your first skill',
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.skills
                            .map(
                              (s) => SkillChip(
                                label: s,
                                onRemove: () => ref
                                    .read(profileManagerProvider.notifier)
                                    .removeSkill(s),
                              ),
                            )
                            .toList(),
                      ),
              ),
              _Section(
                title: 'Certifications',
                action: IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _isUploading ? null : () => _addCertification(context),
                ),
                child: profile.certifications.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.description_outlined,
                        message: 'Upload certifications to build trust',
                      )
                    : Column(
                        children: profile.certifications
                            .map(
                              (c) => ListTile(
                                leading: const Icon(Icons.verified_user),
                                title: Text(c.name),
                                subtitle: Text(c.isVerified ? 'Verified' : 'Pending'),
                                onTap: c.documentUrl.isNotEmpty
                                    ? () => _openCert(c.documentUrl)
                                    : null,
                                trailing: !c.isVerified
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          final updated = profile.certifications
                                              .where((x) => x.id != c.id)
                                              .toList();
                                          ref
                                              .read(profileManagerProvider.notifier)
                                              .updateCertifications(updated);
                                        },
                                      )
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editProfileDetails(
    BuildContext context,
    ProviderProfile profile,
  ) async {
    final nameController = TextEditingController(text: profile.name);
    final phoneController =
        TextEditingController(text: profile.phoneNumber ?? '');
    final locationController = TextEditingController(text: profile.location);
    final categoryController =
        TextEditingController(text: profile.professionalCategory);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location / address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Professional category',
                  hintText: 'e.g. Electrician, Plumber',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    ProviderAccessibility.onSaveProfile();
    try {
      await ref.read(profileManagerProvider.notifier).updateProfileDetails(
            name: nameController.text,
            phoneNumber: phoneController.text,
            location: locationController.text,
            professionalCategory: categoryController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ProviderErrorPanel.messageFor(e))),
        );
      }
    }
  }

  Future<void> _editBio(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit bio'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            helperText: '50–500 characters required',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    ProviderAccessibility.onSaveProfile();
    try {
      await ref.read(profileManagerProvider.notifier).updateBio(controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _addSkill(BuildContext context) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add skill'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Skill name',
            helperText: '3–50 characters',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      await ref.read(profileManagerProvider.notifier).addSkill(controller.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _pickProfilePhoto(BuildContext context) async {
    final result = await _imageService.selectImage(
      source: ImageSource.gallery,
    );

    if (!mounted) return;

    if (result.wasCancelled) {
      return;
    }

    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to select image')),
      );
      return;
    }

    if (result.image == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await ref.read(profileManagerProvider.notifier).updateProfilePhoto(
            result.image!,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<void> _addCertification(BuildContext context) async {
    final nameController = TextEditingController();
    final nameOk = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Certification name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Next'),
          ),
        ],
      ),
    );
    if (nameOk != true || !mounted) return;
    // AFTER (replace with):
    final imageResult = await _imageService.selectImage(
      source: ImageSource.gallery,
    );

    if (!mounted) return;

    if (imageResult.wasCancelled) {
      return;
    }

    if (imageResult.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(imageResult.errorMessage ?? 'Failed to select image')),
      );
      return;
    }

    if (imageResult.image == null) {
      return;
    }

    // Store the PlatformImage
    final certImage = imageResult.image!;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });
    try {
      await ref.read(profileManagerProvider.notifier).uploadCertification(
            certImage,
            nameController.text.trim().isEmpty
                ? 'Certification'
                : nameController.text.trim(),
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certification uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingCertImage = certImage;
          _pendingCertName = nameController.text.trim().isEmpty
              ? 'Certification'
              : nameController.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ProviderErrorPanel.messageFor(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<void> _retryCertUpload(BuildContext context) async {
    final certImage = _pendingCertImage;
    final name = _pendingCertName;
    if (certImage == null || name == null) return;
    setState(() => _isUploading = true);
    try {
      await ref.read(profileManagerProvider.notifier).uploadCertification(
            certImage,
            name,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
      setState(() {
        _pendingCertImage = null;
        _pendingCertName = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certification uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ProviderErrorPanel.messageFor(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openCert(String url) async {
    final resolved = resolveMediaUrl(url);
    final uri = Uri.tryParse(resolved);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StarRatingRow extends StatelessWidget {
  final double rating;

  const _StarRatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = rating - i;
        IconData icon;
        if (value >= 1) {
          icon = Icons.star;
        } else if (value >= 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: Colors.amber.shade700, size: 22);
      }),
    );
  }
}

class _ProfilePromptBanner extends StatelessWidget {
  final String message;

  const _ProfilePromptBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompleteBanner extends StatelessWidget {
  const _ProfileCompleteBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.celebration, color: AppTheme.primaryGreen),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Profile 100% complete — great work! Customers trust complete profiles.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingItemsCard extends StatelessWidget {
  final List<String> items;

  const _MissingItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Still needed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletenessBar extends StatelessWidget {
  final double completeness;

  const _CompletenessBar({required this.completeness});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Profile completeness'),
            Text('${completeness.toInt()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completeness / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _Section({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
