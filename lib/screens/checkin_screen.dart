import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/gesture_detection_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../widgets/camera_preview_widget.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final GestureDetectionService _gestureService = GestureDetectionService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  bool _isInitializing = true;
  bool _isDetecting = false;
  bool _showSuccess = false;
  bool _showFailure = false;
  String? _errorMessage;
  GestureDetectionResult? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (!_cameraService.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeServices();
    }
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Initialize gesture detection service
      await _gestureService.initialize();

      // Initialize camera service
      final cameraInitialized = await _cameraService.initialize();

      if (!cameraInitialized) {
        setState(() {
          _errorMessage = 'Failed to initialize camera. Please check permissions.';
          _isInitializing = false;
        });
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing services: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _cleanup() async {
    await _cameraService.stopImageStream();
    await _cameraService.dispose();
    await _gestureService.dispose();
  }

  void _startCheckIn() async {
    if (!_cameraService.isInitialized || !_gestureService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Services not initialized')),
      );
      return;
    }

    setState(() {
      _isDetecting = true;
      _lastResult = null;
    });

    // Reset and start detection
    _gestureService.reset();
    _gestureService.startDetection();

    // Start image stream with detection callback
    await _cameraService.startImageStream((cameraImage) async {
      if (!_isDetecting) return;

      // Process image for gesture detection
      final result = await _gestureService.processImage(
        cameraImage,
        _cameraService.controller!.description,
      );

      // Update UI with detection result
      if (mounted) {
        setState(() {
          _lastResult = result;
        });
      }

      // Check for success
      if (result.state == DetectionState.success) {
        await _handleCheckInSuccess();
      }

      // Check for failure/timeout
      if (result.state == DetectionState.failed) {
        await _handleCheckInFailure(result.message);
      }
    });
  }

  Future<void> _handleCheckInSuccess() async {
    // Stop detection
    setState(() {
      _isDetecting = false;
    });

    await _cameraService.stopImageStream();

    // Get current location
    final location = await _locationService.getCurrentLocation();

    // Get device ID from auth (you'll need to pass this from a provider or similar)
    // For now, we'll use a placeholder - in production, get this from AuthService
    final deviceId = 'PLACEHOLDER_DEVICE_ID'; // TODO: Get from auth

    // Update check-in in Firestore
    final success = await _firestoreService.updateCheckIn(
      deviceId,
      location: location,
    );

    if (success && location != null) {
      // Optionally add to history
      await _firestoreService.addCheckInHistory(deviceId, location);
    }

    // Show success animation
    setState(() {
      _showSuccess = true;
    });

    // Wait for animation, then return to home
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCheckInFailure(String message) async {
    setState(() {
      _isDetecting = false;
    });

    await _cameraService.stopImageStream();

    // Show failure animation
    setState(() {
      _showFailure = true;
      _errorMessage = message;
    });
  }

  void _retry() {
    setState(() {
      _showFailure = false;
      _errorMessage = null;
    });
    _startCheckIn();
  }

  void _cancel() {
    setState(() {
      _isDetecting = false;
      _showFailure = false;
    });
    _cameraService.stopImageStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (!_isInitializing && _errorMessage == null)
            CameraPreviewWidget(
              controller: _cameraService.controller,
              detectionResult: _lastResult,
              showOverlay: _isDetecting,
            ),

          // Loading state
          if (_isInitializing)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Error state
          if (_errorMessage != null && !_showFailure)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeServices,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Success animation
          if (_showSuccess)
            CheckInSuccessAnimation(
              onComplete: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),

          // Failure animation
          if (_showFailure)
            CheckInFailureAnimation(
              message: _errorMessage ?? 'Detection failed',
              onRetry: _retry,
            ),

          // Top bar with close button
          if (!_isInitializing && _errorMessage == null && !_showSuccess && !_showFailure)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _cancel();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

          // Bottom action button
          if (!_isInitializing &&
              _errorMessage == null &&
              !_isDetecting &&
              !_showSuccess &&
              !_showFailure)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Check-in Instructions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.face, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Position your face in the frame',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.thumb_up, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Show a thumbs-up gesture',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.timer, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Hold both for 2 seconds',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Start button
                      ElevatedButton(
                        onPressed: _startCheckIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Start Check-in',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Cancel button during detection
          if (_isDetecting)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
