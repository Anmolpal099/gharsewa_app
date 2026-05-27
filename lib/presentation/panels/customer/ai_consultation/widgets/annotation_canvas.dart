import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/platform_image.dart';
import '../../../../../core/widgets/image_display_widget.dart';
import '../../../../../core/utils/error_logger.dart';
import '../../../../../data/models/ai_consultation_models.dart';
import '../state/markers_notifier.dart';

/// Drawing mode for annotation canvas (simplified to freehand only)
enum DrawingMode {
  freehand, // Freehand drawing (default and only mode)
}

/// Provider for current drawing mode (always freehand)
final drawingModeProvider = StateProvider<DrawingMode>((ref) => DrawingMode.freehand);

/// Model for freehand drawing paths
class FreehandPath {
  final String id;
  final List<Offset> points; // Normalized coordinates (0-1 range)
  final String description;

  FreehandPath({
    required this.id,
    required this.points,
    this.description = '',
  });

  FreehandPath copyWith({
    String? id,
    List<Offset>? points,
    String? description,
  }) {
    return FreehandPath(
      id: id ?? this.id,
      points: points ?? this.points,
      description: description ?? this.description,
    );
  }
}

/// Provider for freehand paths
final freehandPathsProvider = StateNotifierProvider<FreehandPathsNotifier, List<FreehandPath>>((ref) {
  return FreehandPathsNotifier();
});

/// Notifier for managing freehand paths
class FreehandPathsNotifier extends StateNotifier<List<FreehandPath>> {
  FreehandPathsNotifier() : super([]);

  void addPath(FreehandPath path) {
    state = [...state, path];
  }

  void removePath(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void updatePathDescription(String id, String description) {
    state = [
      for (final path in state)
        if (path.id == id)
          path.copyWith(description: description)
        else
          path,
    ];
  }

  void clear() {
    state = [];
  }
}

/// Provider for selected freehand path ID
final selectedFreehandPathIdProvider = StateProvider<String?>((ref) => null);

/// Custom widget for image annotation with freehand drawing
/// 
/// Displays an image and allows users to:
/// - Draw freehand paths to mark defective areas
/// - Add optional descriptions to drawings
/// 
/// Uses normalized coordinates (0-1 range) for path positions
class AnnotationCanvas extends ConsumerStatefulWidget {
  /// The image to display and annotate (platform-aware)
  final PlatformImage image;

  /// Callback when a freehand path is added (for showing description dialog)
  final void Function(FreehandPath path)? onPathAdded;

  /// Callback when a freehand path is selected
  final void Function(FreehandPath path)? onPathSelected;

  const AnnotationCanvas({
    super.key,
    required this.image,
    this.onPathAdded,
    this.onPathSelected,
  });

  @override
  ConsumerState<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends ConsumerState<AnnotationCanvas> {
  final GlobalKey _imageKey = GlobalKey();
  
  // Freehand drawing state
  List<Offset> _currentFreehandPoints = [];
  bool _isDrawingFreehand = false;

  /// Handle pan start (for freehand drawing)
  void _handlePanStart(DragStartDetails details) {
    final RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;
    
    // Start freehand drawing
    final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / size.height).clamp(0.0, 1.0);
    
    setState(() {
      _currentFreehandPoints = [Offset(normalizedX, normalizedY)];
      _isDrawingFreehand = true;
    });
  }

  /// Handle pan update (for freehand drawing)
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDrawingFreehand) return;
    
    final RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;
    
    // Add point to freehand path
    final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / size.height).clamp(0.0, 1.0);
    
    setState(() {
      _currentFreehandPoints.add(Offset(normalizedX, normalizedY));
    });
  }

  /// Handle pan end (for freehand drawing)
  void _handlePanEnd(DragEndDetails details) {
    if (!_isDrawingFreehand) return;
    _finishFreehandDrawing();
  }
  
  /// Finish freehand drawing
  void _finishFreehandDrawing() {
    if (_currentFreehandPoints.length < 2) {
      setState(() {
        _isDrawingFreehand = false;
        _currentFreehandPoints = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drawing too short. Draw a longer path.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Create freehand path
    final path = FreehandPath(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: List.from(_currentFreehandPoints),
    );
    
    // Add to state
    ref.read(freehandPathsProvider.notifier).addPath(path);
    
    // Select the newly added path
    ref.read(selectedFreehandPathIdProvider.notifier).state = path.id;
    
    // Notify parent to show description dialog
    widget.onPathAdded?.call(path);
    
    setState(() {
      _isDrawingFreehand = false;
      _currentFreehandPoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch freehand paths
    final freehandPaths = ref.watch(freehandPathsProvider);

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image layer - uses ImageDisplayWidget for platform-aware rendering
          ImageDisplayWidget(
            key: _imageKey,
            image: widget.image,
            fit: BoxFit.contain,
          ),
          // Freehand paths layer
          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: _FreehandPainter(
                  freehandPaths: freehandPaths,
                  canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                  currentFreehandPoints: _currentFreehandPoints,
                  isDrawingFreehand: _isDrawingFreehand,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing freehand paths
class _FreehandPainter extends CustomPainter {
  final List<FreehandPath> freehandPaths;
  final Size canvasSize;
  final List<Offset> currentFreehandPoints;
  final bool isDrawingFreehand;

  _FreehandPainter({
    required this.freehandPaths,
    required this.canvasSize,
    this.currentFreehandPoints = const [],
    this.isDrawingFreehand = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final freehandPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw saved freehand paths
    for (final path in freehandPaths) {
      if (path.points.length < 2) continue;
      
      final drawPath = Path();
      final firstPoint = Offset(
        path.points[0].dx * canvasSize.width,
        path.points[0].dy * canvasSize.height,
      );
      drawPath.moveTo(firstPoint.dx, firstPoint.dy);
      
      for (int i = 1; i < path.points.length; i++) {
        final point = Offset(
          path.points[i].dx * canvasSize.width,
          path.points[i].dy * canvasSize.height,
        );
        drawPath.lineTo(point.dx, point.dy);
      }
      
      canvas.drawPath(drawPath, freehandPaint);
    }

    // Draw current freehand path being drawn
    if (isDrawingFreehand && currentFreehandPoints.length >= 2) {
      final drawPath = Path();
      final firstPoint = Offset(
        currentFreehandPoints[0].dx * canvasSize.width,
        currentFreehandPoints[0].dy * canvasSize.height,
      );
      drawPath.moveTo(firstPoint.dx, firstPoint.dy);
      
      for (int i = 1; i < currentFreehandPoints.length; i++) {
        final point = Offset(
          currentFreehandPoints[i].dx * canvasSize.width,
          currentFreehandPoints[i].dy * canvasSize.height,
        );
        drawPath.lineTo(point.dx, point.dy);
      }
      
      canvas.drawPath(drawPath, freehandPaint..color = const Color(0xFFE53935).withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(_FreehandPainter oldDelegate) {
    return freehandPaths != oldDelegate.freehandPaths ||
        currentFreehandPoints != oldDelegate.currentFreehandPoints ||
        isDrawingFreehand != oldDelegate.isDrawingFreehand;
  }
}
