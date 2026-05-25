import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── AI Assistant Screen ───────────────────────────────────────────────────────

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  bool _isScanning = false;
  String? _detectedIssue;
  List<String> _aiTips = [];

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _detectedIssue = null;
      _aiTips = [];
    });

    // Simulate scanning process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _detectedIssue = 'Leaking pipe detected';
          _aiTips = [
            'Ensure the lighting is bright so I can detect moisture and micro-cracks.',
            'Turn off the water supply to prevent further damage.',
            'Check if the leak is from a joint or the pipe itself.',
            'Consider calling a professional plumber if the leak is severe.',
          ];
        });
      }
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
      _detectedIssue = null;
      _aiTips = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera Preview (Simulated) ──────────────────────
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                  ],
                ),
              ),
              child: _isScanning
                  ? _buildScanningOverlay()
                  : _buildIdleState(),
            ),
          ),

          // ── AI Tips (Bottom Sheet) ──────────────────────────
          if (_aiTips.isNotEmpty) _buildAITipsSheet(),

          // ── Camera Controls ─────────────────────────────────
          if (!_isScanning && _detectedIssue == null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildCameraControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Point your camera at the problem area',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Stack(
      children: [
        // ── Scanning Frame ──────────────────────────────────
        Center(
          child: Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.purple,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // ── Corner Brackets ─────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildCornerBracket(
                    topLeft: true,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildCornerBracket(
                    topRight: true,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildCornerBracket(
                    bottomLeft: true,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildCornerBracket(
                    bottomRight: true,
                  ),
                ),

                // ── Scanning Animation ──────────────────────────
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Positioned(
                      top: value * 400,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.purple.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    if (_isScanning) {
                      setState(() {});
                    }
                  },
                ),

                // ── Detection Points ────────────────────────────
                Positioned(
                  top: 150,
                  left: 100,
                  child: _buildDetectionPoint(),
                ),
                Positioned(
                  top: 250,
                  right: 80,
                  child: _buildDetectionPoint(),
                ),
              ],
            ),
          ),
        ),

        // ── Scanning Status ─────────────────────────────────
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Scanning for issues...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Instruction ─────────────────────────────────────
        Positioned(
          bottom: 150,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Point your camera at the problem area',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerBracket({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight
              ? const BorderSide(color: Colors.purple, width: 4)
              : BorderSide.none,
          left: topLeft || bottomLeft
              ? const BorderSide(color: Colors.purple, width: 4)
              : BorderSide.none,
          right: topRight || bottomRight
              ? const BorderSide(color: Colors.purple, width: 4)
              : BorderSide.none,
          bottom: bottomLeft || bottomRight
              ? const BorderSide(color: Colors.purple, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDetectionPoint() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        if (_isScanning) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildAITipsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // ── Handle ──────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: Colors.purple.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Pro-Tip',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_detectedIssue != null)
                          Text(
                            _detectedIssue!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Tips ────────────────────────────────────────
              ..._aiTips.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ── Actions ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _stopScanning,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Again'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Navigate to service booking
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Finding plumbers near you...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Find Expert'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraControls() {
    return Column(
      children: [
        // ── Capture Button ──────────────────────────────────
        GestureDetector(
          onTap: _startScanning,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to scan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
