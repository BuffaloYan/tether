import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  /// Initialize the camera service and get available cameras
  Future<bool> initialize() async {
    try {
      // Request camera permission
      final permissionStatus = await requestCameraPermission();
      if (!permissionStatus) {
        debugPrint('Camera permission denied');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Find front-facing camera
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Fallback to first available camera if no front camera found
      frontCamera ??= _cameras!.first;

      // Initialize camera controller
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Required for ML processing
      );

      await _controller!.initialize();
      _isInitialized = true;
      debugPrint('Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Check camera permission status
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Start image streaming for real-time processing
  /// [onImage] callback receives camera images for ML processing
  Future<void> startImageStream(Function(CameraImage image) onImage) async {
    if (_controller == null || !_isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    if (!_controller!.value.isStreamingImages) {
      try {
        await _controller!.startImageStream(onImage);
        debugPrint('Image stream started');
      } catch (e) {
        debugPrint('Error starting image stream: $e');
      }
    }
  }

  /// Stop image streaming
  Future<void> stopImageStream() async {
    if (_controller == null || !_isInitialized) {
      return;
    }

    if (_controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
        debugPrint('Image stream stopped');
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
  }

  /// Take a picture (optional feature for future use)
  Future<XFile?> takePicture() async {
    if (_controller == null || !_isInitialized) {
      debugPrint('Camera not initialized');
      return null;
    }

    try {
      final XFile picture = await _controller!.takePicture();
      debugPrint('Picture taken: ${picture.path}');
      return picture;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  /// Dispose of camera resources
  Future<void> dispose() async {
    try {
      await stopImageStream();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      debugPrint('Camera disposed');
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
  }

  /// Get front camera description
  CameraDescription? getFrontCamera() {
    if (_cameras == null) return null;
    for (var camera in _cameras!) {
      if (camera.lensDirection == CameraLensDirection.front) {
        return camera;
      }
    }
    return null;
  }

  /// Get back camera description (for future use)
  CameraDescription? getBackCamera() {
    if (_cameras == null) return null;
    for (var camera in _cameras!) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    return null;
  }

  /// Switch between front and back camera
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      debugPrint('Cannot switch camera: not enough cameras');
      return false;
    }

    try {
      // Determine which camera to switch to
      final currentLens = _controller?.description.lensDirection;
      CameraDescription? newCamera;

      if (currentLens == CameraLensDirection.front) {
        newCamera = getBackCamera();
      } else {
        newCamera = getFrontCamera();
      }

      if (newCamera == null) {
        debugPrint('Cannot find camera to switch to');
        return false;
      }

      // Dispose current controller
      await dispose();

      // Initialize new camera
      _controller = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
      debugPrint('Camera switched successfully');
      return true;
    } catch (e) {
      debugPrint('Error switching camera: $e');
      return false;
    }
  }

  /// Get camera aspect ratio
  double? getAspectRatio() {
    return _controller?.value.aspectRatio;
  }

  /// Check if camera is currently recording/streaming
  bool isStreaming() {
    return _controller?.value.isStreamingImages ?? false;
  }
}
