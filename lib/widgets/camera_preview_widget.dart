import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/gesture_detection_service.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final GestureDetectionResult? detectionResult;
  final bool showOverlay;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.detectionResult,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Center(
          child: AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: CameraPreview(controller!),
          ),
        ),

        // Detection overlay
        if (showOverlay && detectionResult != null)
          _buildDetectionOverlay(context),
      ],
    );
  }

  Widget _buildDetectionOverlay(BuildContext context) {
    final result = detectionResult!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _getBorderColor(result.state),
          width: 4,
        ),
      ),
      child: Column(
        children: [
          // Top status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Status message
                  Text(
                    result.message,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Detection indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIndicator(
                        icon: Icons.face,
                        label: 'Face',
                        isDetected: result.faceDetected,
                      ),
                      const SizedBox(width: 24),
                      _buildIndicator(
                        icon: Icons.thumb_up,
                        label: 'Thumbs-up',
                        isDetected: result.gestureDetected,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bottom progress bar
          if (result.state == DetectionState.bothDetected)
            Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: result.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(result.progress),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Progress text
                  Text(
                    '${(result.progress * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Instruction text
          if (result.state == DetectionState.detectingFace ||
              result.state == DetectionState.detectingGesture)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getInstructionText(result.state),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required String label,
    required bool isDetected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDetected
            ? Colors.green.withOpacity(0.8)
            : Colors.grey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            isDetected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(DetectionState state) {
    switch (state) {
      case DetectionState.success:
        return Colors.green;
      case DetectionState.bothDetected:
        return Colors.amber;
      case DetectionState.detectingFace:
      case DetectionState.detectingGesture:
        return Colors.blue;
      case DetectionState.failed:
        return Colors.red;
      case DetectionState.none:
        return Colors.transparent;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) {
      return Colors.amber;
    } else if (progress < 0.8) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getInstructionText(DetectionState state) {
    switch (state) {
      case DetectionState.detectingFace:
        return 'Position your face in the center of the frame';
      case DetectionState.detectingGesture:
        return 'Show a thumbs-up gesture with one hand';
      case DetectionState.bothDetected:
        return 'Hold steady for 2 seconds...';
      case DetectionState.success:
        return 'Check-in successful!';
      case DetectionState.failed:
        return 'Detection failed. Please try again.';
      case DetectionState.none:
        return '';
    }
  }
}

/// Success animation widget
class CheckInSuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const CheckInSuccessAnimation({
    super.key,
    this.onComplete,
  });

  @override
  State<CheckInSuccessAnimation> createState() => _CheckInSuccessAnimationState();
}

class _CheckInSuccessAnimationState extends State<CheckInSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete?.call();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Check-in Successful!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay safe!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Failure animation widget
class CheckInFailureAnimation extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;

  const CheckInFailureAnimation({
    super.key,
    this.onRetry,
    this.message = 'Detection failed',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
