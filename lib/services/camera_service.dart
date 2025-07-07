import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;


class CameraService {
  CameraController? _controller;
  Timer? _frameTimer;
  WebSocketChannel? _webSocketChannel;
  bool _isStreaming = false;
  bool _isInitialized = false;

  // High-speed frame rate control for 5G-like performance
  static const int targetFPS = 30; // Maximum FPS for ultra-responsive detection
  static const Duration frameDuration = Duration(milliseconds: 33); // 30 FPS = ~33ms intervals

  // Optimized image settings for speed vs quality balance
  static const int imageWidth = 360;  // Smaller for faster transmission
  static const int imageHeight = 360;
  static const int imageQuality = 70; // Lower quality for faster encoding/transmission

  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;

  Future<bool> initialize(CameraDescription camera) async {
    try {
      print('📹 Initializing camera service...');

      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // Use medium resolution for balance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Better for processing
      );

      await _controller!.initialize();
      _isInitialized = true;

      print('✅ Camera service initialized successfully');
      return true;
    } catch (e) {
      print('❌ Camera initialization failed: $e');
      return false;
    }
  }

  void connectWebSocket(WebSocketChannel channel) {
    _webSocketChannel = channel;
    print('🔗 Camera service connected to WebSocket');
  }

  Future<void> startStreaming() async {
    if (!_isInitialized || _controller == null || _webSocketChannel == null) {
      print('❌ Cannot start streaming: Not properly initialized');
      return;
    }

    if (_isStreaming) {
      print('⚠️  Already streaming');
      return;
    }

    try {
      _isStreaming = true;
      print('🎥 Starting HIGH-SPEED camera frame streaming...');

      // Start high-frequency frame capture
      _frameTimer = Timer.periodic(frameDuration, (timer) {
        _captureAndSendFrame();
      });

      print('✅ HIGH-SPEED streaming started at ${targetFPS} FPS');
    } catch (e) {
      print('❌ Failed to start streaming: $e');
      _isStreaming = false;
    }
  }

  Future<void> stopStreaming() async {
    if (!_isStreaming) return;

    _frameTimer?.cancel();
    _frameTimer = null;
    _isStreaming = false;

    print('🛑 Camera streaming stopped');
  }

  Future<void> _captureAndSendFrame() async {
    if (!_isStreaming || _controller == null || _webSocketChannel == null) {
      return;
    }

    try {
      // Capture image from camera
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Process and compress image
      final String base64Image = await _processImage(imageBytes);

      // Send to server
      final message = json.encode({
        'type': 'frame',
        'data': base64Image,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _webSocketChannel!.sink.add(message);

    } catch (e) {
      print('⚠️  Frame capture error: $e');
      // Don't stop streaming for occasional errors
    }
  }

  Future<String> _processImage(Uint8List imageBytes) async {
    try {
      // ULTRA-FAST image processing
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Fast resize with nearest neighbor (fastest interpolation)
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: imageWidth,
        height: imageHeight,
        interpolation: img.Interpolation.nearest, // Fastest method
      );

      // Fast JPEG encoding with lower quality for speed
      List<int> jpegBytes = img.encodeJpg(resizedImage, quality: imageQuality);

      // Direct base64 conversion
      String base64String = base64Encode(jpegBytes);

      return base64String;
    } catch (e) {
      print('❌ Image processing error: $e');
      // Emergency fallback: return original as base64 (no processing)
      return base64Encode(imageBytes);
    }
  }

  // Alternative method for faster capture (if needed)
  Future<void> _captureAndSendFrameFast() async {
    if (!_isStreaming || _controller == null || _webSocketChannel == null) {
      return;
    }

    try {
      // Use image stream for faster capture (more advanced)
      await _controller!.startImageStream((CameraImage cameraImage) async {
        if (_isStreaming) {
          final String base64Image = await _processCameraImage(cameraImage);

          final message = json.encode({
            'type': 'frame',
            'data': base64Image,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          _webSocketChannel!.sink.add(message);
        }
      });
    } catch (e) {
      print('⚠️  Fast frame capture error: $e');
    }
  }

  Future<String> _processCameraImage(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to RGB
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      // Create image from camera data
      final img.Image image = img.Image(width: width, height: height);

      // Convert YUV420 to RGB (simplified conversion)
      final Plane yPlane = cameraImage.planes[0];
      final Plane uPlane = cameraImage.planes[1];
      final Plane vPlane = cameraImage.planes[2];

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yPlane.bytesPerRow + x;
          final int uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

          if (yIndex < yPlane.bytes.length && uvIndex < uPlane.bytes.length) {
            final int yValue = yPlane.bytes[yIndex];
            final int uValue = uPlane.bytes[uvIndex];
            final int vValue = vPlane.bytes[uvIndex];

            // YUV to RGB conversion
            final int r = (yValue + 1.13983 * (vValue - 128)).round().clamp(0, 255);
            final int g = (yValue - 0.39465 * (uValue - 128) - 0.58060 * (vValue - 128)).round().clamp(0, 255);
            final int b = (yValue + 2.03211 * (uValue - 128)).round().clamp(0, 255);

            image.setPixelRgb(x, y, r, g, b);
          }
        }
      }

      // Resize and compress
      final img.Image resizedImage = img.copyResize(
        image,
        width: imageWidth ~/ 2, // Smaller for faster processing
        height: imageHeight ~/ 2,
      );

      final List<int> jpegBytes = img.encodeJpg(resizedImage, quality: 70);
      return base64Encode(jpegBytes);

    } catch (e) {
      print('❌ Camera image processing error: $e');
      return '';
    }
  }

  // Get camera preview widget
  Widget getCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CameraPreview(_controller!);
  }

  // Get camera resolution info
  Size? getCameraResolution() {
    if (!_isInitialized || _controller == null) return null;
    return _controller!.value.previewSize;
  }

  // Check if camera is available
  static Future<bool> isCameraAvailable() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get available cameras
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      print('❌ Failed to get available cameras: $e');
      return [];
    }
  }

  // Switch between front and back camera
  Future<bool> switchCamera() async {
    if (!_isInitialized) return false;

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return false;

      final currentCamera = _controller!.description;
      CameraDescription newCamera;

      if (currentCamera.lensDirection == CameraLensDirection.back) {
        newCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      } else {
        newCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      // Dispose current controller
      await _controller!.dispose();

      // Initialize new controller
      return await initialize(newCamera);
    } catch (e) {
      print('❌ Failed to switch camera: $e');
      return false;
    }
  }

  // Adjust frame rate for performance
  void setFrameRate(int fps) {
    if (fps < 1 || fps > 30) return;

    _frameTimer?.cancel();

    if (_isStreaming) {
      final newDuration = Duration(milliseconds: (1000 / fps).round());
      _frameTimer = Timer.periodic(newDuration, (timer) {
        _captureAndSendFrame();
      });
      print('📊 Frame rate adjusted to $fps FPS');
    }
  }

  // Get streaming statistics
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'isStreaming': _isStreaming,
      'targetFPS': targetFPS,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'imageQuality': imageQuality,
      'cameraResolution': getCameraResolution()?.toString() ?? 'Unknown',
    };
  }

  Future<void> dispose() async {
    print('🗑️ Disposing camera service...');

    try {
      // Stop streaming first
      await stopStreaming();

      // Dispose camera controller
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      // Clear WebSocket reference
      _webSocketChannel = null;

      // Reset state
      _isInitialized = false;
      _isStreaming = false;

      print('✅ Camera service disposed successfully');
    } catch (e) {
      print('❌ Error disposing camera service: $e');
    }
  }
}