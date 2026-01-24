import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Detection states for the check-in process
enum DetectionState {
  none, // No detection active
  detectingFace, // Looking for face
  detectingGesture, // Face found, looking for thumbs-up
  bothDetected, // Both face and gesture detected
  success, // Successfully held for required duration
  failed, // Detection failed or timeout
}

/// Result of gesture detection
class GestureDetectionResult {
  final bool faceDetected;
  final bool gestureDetected;
  final DetectionState state;
  final double progress; // 0.0 to 1.0
  final String message;

  GestureDetectionResult({
    required this.faceDetected,
    required this.gestureDetected,
    required this.state,
    required this.progress,
    required this.message,
  });
}

class GestureDetectionService {
  // ML Kit detectors
  late FaceDetector _faceDetector;
  late PoseDetector _poseDetector;

  // Detection state
  bool _isProcessing = false;
  bool _isInitialized = false;

  // Detection tracking
  DateTime? _bothDetectedStartTime;
  static const Duration _requiredDuration = Duration(seconds: 2);
  static const Duration _detectionTimeout = Duration(seconds: 30);
  DateTime? _detectionStartTime;

  // Callbacks
  Function(GestureDetectionResult)? onDetectionUpdate;

  bool get isInitialized => _isInitialized;

  /// Initialize the gesture detection service
  Future<void> initialize() async {
    try {
      // Initialize face detector with options
      final faceDetectorOptions = FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableLandmarks: false,
        enableTracking: true,
        minFaceSize: 0.15, // Minimum face size (15% of image)
        performanceMode: FaceDetectorMode.fast,
      );
      _faceDetector = FaceDetector(options: faceDetectorOptions);

      // Initialize pose detector with options
      final poseDetectorOptions = PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream, // Optimized for video stream
      );
      _poseDetector = PoseDetector(options: poseDetectorOptions);

      _isInitialized = true;
      debugPrint('Gesture detection service initialized');
    } catch (e) {
      debugPrint('Error initializing gesture detection: $e');
      _isInitialized = false;
    }
  }

  /// Start detection process
  void startDetection() {
    _detectionStartTime = DateTime.now();
    _bothDetectedStartTime = null;
    debugPrint('Detection started');
  }

  /// Process camera image for face and gesture detection
  Future<GestureDetectionResult> processImage(CameraImage image, CameraDescription camera) async {
    // Check if already processing or timeout
    if (_isProcessing) {
      return GestureDetectionResult(
        faceDetected: false,
        gestureDetected: false,
        state: DetectionState.none,
        progress: 0.0,
        message: 'Processing...',
      );
    }

    // Check for timeout
    if (_detectionStartTime != null) {
      final elapsed = DateTime.now().difference(_detectionStartTime!);
      if (elapsed > _detectionTimeout) {
        return GestureDetectionResult(
          faceDetected: false,
          gestureDetected: false,
          state: DetectionState.failed,
          progress: 0.0,
          message: 'Detection timeout',
        );
      }
    }

    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertToInputImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return _createErrorResult('Failed to process image');
      }

      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);
      final faceDetected = faces.isNotEmpty;

      // Detect pose for gesture recognition
      final poses = await _poseDetector.processImage(inputImage);
      final gestureDetected = _isThumbsUpGesture(poses);

      // Determine detection state and progress
      DetectionState state;
      double progress = 0.0;
      String message;

      if (faceDetected && gestureDetected) {
        // Both detected - check duration
        if (_bothDetectedStartTime == null) {
          _bothDetectedStartTime = DateTime.now();
        }

        final duration = DateTime.now().difference(_bothDetectedStartTime!);
        progress = (duration.inMilliseconds / _requiredDuration.inMilliseconds).clamp(0.0, 1.0);

        if (duration >= _requiredDuration) {
          state = DetectionState.success;
          message = 'Check-in successful!';
          progress = 1.0;
        } else {
          state = DetectionState.bothDetected;
          message = 'Hold steady... ${(_requiredDuration.inSeconds - duration.inSeconds)}s';
        }
      } else {
        // Reset timer if not both detected
        _bothDetectedStartTime = null;

        if (faceDetected && !gestureDetected) {
          state = DetectionState.detectingGesture;
          message = 'Show thumbs-up gesture';
        } else if (!faceDetected && gestureDetected) {
          state = DetectionState.detectingFace;
          message = 'Position your face in view';
        } else {
          state = DetectionState.detectingFace;
          message = 'Position your face in view';
        }
      }

      _isProcessing = false;

      final result = GestureDetectionResult(
        faceDetected: faceDetected,
        gestureDetected: gestureDetected,
        state: state,
        progress: progress,
        message: message,
      );

      // Call update callback if set
      onDetectionUpdate?.call(result);

      return result;
    } catch (e) {
      debugPrint('Error processing image: $e');
      _isProcessing = false;
      return _createErrorResult('Detection error: $e');
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertToInputImage(CameraImage image, CameraDescription camera) {
    try {
      // Get image rotation based on camera orientation
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        var rotationCompensation = sensorOrientation;
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }

      if (rotation == null) return null;

      // Get image format
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      // Get plane data
      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting image: $e');
      return null;
    }
  }

  /// Detect thumbs-up gesture from pose landmarks
  bool _isThumbsUpGesture(List<Pose> poses) {
    if (poses.isEmpty) return false;

    try {
      final pose = poses.first;

      // Get wrist and thumb landmarks for right hand
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      final rightThumb = pose.landmarks[PoseLandmarkType.rightThumb];
      final rightIndex = pose.landmarks[PoseLandmarkType.rightIndex];

      // Get wrist and thumb landmarks for left hand
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final leftThumb = pose.landmarks[PoseLandmarkType.leftThumb];
      final leftIndex = pose.landmarks[PoseLandmarkType.leftIndex];

      // Check right hand thumbs-up
      bool rightThumbsUp = false;
      if (rightWrist != null && rightThumb != null && rightIndex != null) {
        // Thumb should be higher than wrist (y-coordinate smaller)
        // and thumb should be higher than index finger
        final thumbAboveWrist = rightThumb.y < rightWrist.y;
        final thumbAboveIndex = rightThumb.y < rightIndex.y;

        // Check if landmarks have good confidence
        final goodConfidence = rightThumb.likelihood > 0.5 &&
                               rightWrist.likelihood > 0.5 &&
                               rightIndex.likelihood > 0.5;

        rightThumbsUp = thumbAboveWrist && thumbAboveIndex && goodConfidence;
      }

      // Check left hand thumbs-up
      bool leftThumbsUp = false;
      if (leftWrist != null && leftThumb != null && leftIndex != null) {
        final thumbAboveWrist = leftThumb.y < leftWrist.y;
        final thumbAboveIndex = leftThumb.y < leftIndex.y;

        final goodConfidence = leftThumb.likelihood > 0.5 &&
                               leftWrist.likelihood > 0.5 &&
                               leftIndex.likelihood > 0.5;

        leftThumbsUp = thumbAboveWrist && thumbAboveIndex && goodConfidence;
      }

      // Return true if either hand shows thumbs-up
      return rightThumbsUp || leftThumbsUp;
    } catch (e) {
      debugPrint('Error detecting thumbs-up: $e');
      return false;
    }
  }

  /// Reset detection state
  void reset() {
    _bothDetectedStartTime = null;
    _detectionStartTime = null;
    _isProcessing = false;
    debugPrint('Detection reset');
  }

  /// Create error result
  GestureDetectionResult _createErrorResult(String message) {
    return GestureDetectionResult(
      faceDetected: false,
      gestureDetected: false,
      state: DetectionState.failed,
      progress: 0.0,
      message: message,
    );
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      await _faceDetector.close();
      await _poseDetector.close();
      _isInitialized = false;
      debugPrint('Gesture detection service disposed');
    } catch (e) {
      debugPrint('Error disposing gesture detection: $e');
    }
  }

  /// Get remaining time for hold
  Duration? getRemainingHoldTime() {
    if (_bothDetectedStartTime == null) return null;

    final elapsed = DateTime.now().difference(_bothDetectedStartTime!);
    final remaining = _requiredDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if detection is successful
  bool isDetectionSuccessful() {
    if (_bothDetectedStartTime == null) return false;

    final duration = DateTime.now().difference(_bothDetectedStartTime!);
    return duration >= _requiredDuration;
  }
}
