import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/route_constants.dart';
import '../../../../../core/utils/error_logger.dart';
import '../../../../../core/models/platform_image.dart';
import '../../../../../data/models/ai_consultation_models.dart';
import '../state/ai_consultation_providers.dart';
import '../widgets/annotation_canvas.dart';

/// Screen for annotating images with freehand drawings
/// 
/// Features:
/// - Interactive canvas for drawing on images
/// - Drawing list showing all annotations with descriptions
/// - Bottom sheet for adding/editing drawing descriptions
/// - Validation (at least 1 drawing required)
/// - Submit action with loading state
/// - Navigation to results screen on success
class AnnotationEditorScreen extends ConsumerStatefulWidget {
  /// The image to annotate (optional - will be retrieved from state if not provided)
  final PlatformImage? image;

  const AnnotationEditorScreen({
    super.key,
    this.image,
  });

  @override
  ConsumerState<AnnotationEditorScreen> createState() =>
      _AnnotationEditorScreenState();
}

class _AnnotationEditorScreenState
    extends ConsumerState<AnnotationEditorScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set the image in the current consultation state if provided
    if (widget.image != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentConsultationProvider.notifier).setImage(widget.image!);
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Show bottom sheet for freehand path description input
  void _showDescriptionBottomSheet(FreehandPath path) {
    setState(() {
      _descriptionController.text = path.description;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Text(
              'Describe the Issue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Description text field
            TextField(
              controller: _descriptionController,
              maxLength: 500,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Describe what you marked (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '${_descriptionController.text.length}/500',
              ),
              onChanged: (value) {
                setState(() {}); // Update counter
              },
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _descriptionController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _saveDescription(path);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _descriptionController.clear();
      });
    });
  }

  /// Save freehand path description
  void _saveDescription(FreehandPath path) {
    final description = _descriptionController.text.trim();
    
    // Update path with description (can be empty - optional)
    ref.read(freehandPathsProvider.notifier).updatePathDescription(
          path.id,
          description,
        );
  }

  /// Handle freehand path deletion
  void _deletePath(String pathId) {
    ref.read(freehandPathsProvider.notifier).removePath(pathId);
    
    // Clear selection if deleted path was selected
    final selectedId = ref.read(selectedFreehandPathIdProvider);
    if (selectedId == pathId) {
      ref.read(selectedFreehandPathIdProvider.notifier).state = null;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Drawing deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Handle submit action
  Future<void> _handleSubmit() async {
    final freehandPaths = ref.read(freehandPathsProvider);

    // Validation: at least 1 freehand drawing required
    if (freehandPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw at least one marking on the image'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Convert freehand paths to markers for API compatibility
    // Each freehand path becomes a marker at its center point
    final markers = freehandPaths.asMap().entries.map((entry) {
      final index = entry.key;
      final path = entry.value;
      
      // Calculate center point of the path
      double sumX = 0;
      double sumY = 0;
      for (final point in path.points) {
        sumX += point.dx;
        sumY += point.dy;
      }
      final centerX = sumX / path.points.length;
      final centerY = sumY / path.points.length;
      
      return DefectMarkerModel(
        id: path.id,
        x: centerX,
        y: centerY,
        description: path.description.isEmpty 
            ? 'Drawing ${index + 1}' 
            : path.description,
      );
    }).toList();
    
    // Update consultation state with converted markers
    ref.read(currentConsultationProvider.notifier).clearMarkers();
    for (final marker in markers) {
      ref.read(currentConsultationProvider.notifier).addMarker(marker);
    }

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing your image...',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take up to 30 seconds',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Submit consultation
      await ref.read(currentConsultationProvider.notifier).submitConsultation();

      // Check if submission was successful
      final state = ref.read(currentConsultationProvider);
      
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (state.hasError) {
        // Show error dialog
        logError('AnnotationEditorScreen', 'Submission failed', state.error);
        _showErrorDialog(state.error!);
      } else if (state.isCompleted) {
        // Navigate to results screen
        context.push(RouteConstants.customerAIResults);
      }
    } catch (e, stackTrace) {
      logError('AnnotationEditorScreen', 'Unexpected error during submission', e, stackTrace);
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }

  /// Show error dialog with retry option
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSubmit();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final freehandPaths = ref.watch(freehandPathsProvider);
    final pathCount = freehandPaths.length;
    final canSubmit = freehandPaths.isNotEmpty;
    final consultationState = ref.watch(currentConsultationProvider);
    
    // Get image from widget or state
    final image = widget.image ?? consultationState.image;
    
    // Show error if no image available
    if (image == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Annotate Image'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'No image available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please go back and select an image',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Defective Areas'),
        actions: [
          // Submit button
          TextButton.icon(
            onPressed: canSubmit ? _handleSubmit : null,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing count indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 20,
                  color: pathCount > 0 ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '$pathCount drawing${pathCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: pathCount > 0 ? Colors.black87 : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (pathCount == 0)
                  const Text(
                    'Drag on image to mark defective areas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // Canvas section (2/3 of screen)
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: AnnotationCanvas(
                image: image,
                onPathAdded: _showDescriptionBottomSheet,
                onPathSelected: _showDescriptionBottomSheet,
              ),
            ),
          ),
          // Drawing list section (1/3 of screen)
          Expanded(
            flex: 1,
            child: Material(
              color: Colors.white,
              child: freehandPaths.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No drawings yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Drag on the image above to mark defective areas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Drawings',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: freehandPaths.length,
                            itemBuilder: (context, index) {
                              final path = freehandPaths[index];
                              final pathNumber = index + 1;
                              final hasDescription =
                                  path.description.trim().isNotEmpty;

                              return Dismissible(
                                key: Key(path.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (_) => _deletePath(path.id),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    child: Text(
                                      pathNumber.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    hasDescription
                                        ? path.description
                                        : 'Drawing $pathNumber',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontStyle: hasDescription
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: !hasDescription
                                      ? const Text(
                                          'Tap to add description (optional)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () =>
                                            _showDescriptionBottomSheet(path),
                                        tooltip: 'Edit description',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        onPressed: () =>
                                            _deletePath(path.id),
                                        tooltip: 'Delete drawing',
                                      ),
                                    ],
                                  ),
                                  onTap: () =>
                                      _showDescriptionBottomSheet(path),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
