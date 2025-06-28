import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_time/services/command_executor.dart';
import 'package:real_time/services/camera_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:vibration/vibration.dart';
import 'package:camera/camera.dart';
import '../models/asl_detection_state.dart';

class ASLDetectionCubit extends Cubit<ASLDetectionState> {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  String? _lastDetectedAction;
  bool _vibrationEnabled = true;

  // Camera service integration
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false;

  static const String _wsUrl = 'ws://192.168.173.153:8765';
  String _currentWsUrl = _wsUrl;

  ASLDetectionCubit() : super(ASLDetectionInitial()) {
    _initializeVibration();
  }

  // Camera-related getters
  bool get isCameraInitialized => _isCameraInitialized;
  CameraService get cameraService => _cameraService;

  Future<bool> initializeCamera(CameraDescription camera) async {
    try {
      emit(ASLDetectionLoading());

      final success = await _cameraService.initialize(camera);
      if (success) {
        _isCameraInitialized = true;
        print('✅ Camera initialized in cubit');

        // Don't emit connected state yet - wait for WebSocket
        return true;
      } else {
        emit(const ASLDetectionError(error: 'Failed to initialize camera'));
        return false;
      }
    } catch (e) {
      emit(ASLDetectionError(error: 'Camera initialization error: $e'));
      return false;
    }
  }

  Future<void> startCameraStreaming() async {
    if (!_isCameraInitialized) {
      print('❌ Camera not initialized');
      return;
    }

    if (_channel == null) {
      print('❌ WebSocket not connected');
      return;
    }

    try {
      _cameraService.connectWebSocket(_channel!);
      await _cameraService.startStreaming();
      print('🎥 Camera streaming started');
    } catch (e) {
      print('❌ Failed to start camera streaming: $e');
    }
  }

  Future<void> stopCameraStreaming() async {
    try {
      await _cameraService.stopStreaming();
      print('🛑 Camera streaming stopped');
    } catch (e) {
      print('❌ Failed to stop camera streaming: $e');
    }
  }

  Future<bool> switchCamera() async {
    if (!_isCameraInitialized) return false;

    try {
      // Stop streaming temporarily
      await _cameraService.stopStreaming();

      // Switch camera
      final success = await _cameraService.switchCamera();

      // Restart streaming if it was running
      if (success && _channel != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        await startCameraStreaming();
      }

      return success;
    } catch (e) {
      print('❌ Failed to switch camera: $e');
      return false;
    }
  }

  void updateServerUrl(String newUrl) {
    _currentWsUrl = newUrl;
    if (_channel != null) {
      disconnect();
      connect();
    }
  }

  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
  }

  bool get isVibrationEnabled => _vibrationEnabled;

  Future<void> _initializeVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        _vibrationEnabled = false;
      }
    } catch (e) {
      _vibrationEnabled = false;
    }
  }

  Future<void> _triggerVibration(String action) async {
    if (!_vibrationEnabled) return;

    try {
      final hasCustomVibrations = await Vibration.hasCustomVibrationsSupport();

      if (hasCustomVibrations == true) {
        if (action.toLowerCase().contains('call')) {
          await Vibration.vibrate(pattern: [0, 200, 100, 200], intensities: [0, 128, 0, 255]);
        } else if (action.toLowerCase().contains('open')) {
          await Vibration.vibrate(duration: 300, amplitude: 200);
        } else {
          await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100], intensities: [0, 128, 0, 128, 0, 128]);
        }
      } else {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      print('Vibration error: $e');
    }
  }

  Future<void> connect() async {
    if (_isConnecting) return;

    try {
      _isConnecting = true;
      emit(ASLDetectionLoading());

      _channel = WebSocketChannel.connect(Uri.parse(_currentWsUrl));

      // If camera is ready, connect it to WebSocket
      if (_isCameraInitialized) {
        _cameraService.connectWebSocket(_channel!);
      }

      emit(const ASLDetectionConnected(connectionStatus: 'Connected'));

      _channel!.sink.add(jsonEncode({"command": "ping"}));

      _channel!.stream.listen(
            (data) {
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          emit(ASLDetectionError(error: 'WebSocket error: $error'));
          _reconnect();
        },
        onDone: () {
          emit(const ASLDetectionError(error: 'Connection closed'));
          _reconnect();
        },
      );

      // Auto-start camera streaming if camera is ready
      if (_isCameraInitialized) {
        await startCameraStreaming();
      }

    } catch (e) {
      emit(ASLDetectionError(error: 'Failed to connect: $e'));
      _reconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleWebSocketMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);

      if (message.containsKey('status')) {
        return;
      }

      final String? currentAction = message['last_action'];
      final List<String> currentBuffer = List<String>.from(message['sequence_buffer'] ?? []);

      // Check for sign acceptance (when buffer changes)
      bool signAccepted = false;
      if (currentBuffer.length > _lastSequenceLength) {
        signAccepted = true;
        _triggerSignAcceptedVibration(); // Small vibration for sign acceptance
      }
      _lastSequenceLength = currentBuffer.length;

      // Check for action completion
      bool shouldVibrate = false;
      if (currentAction != null && currentAction != _lastDetectedAction) {
        _lastDetectedAction = currentAction;
        shouldVibrate = true;

        CommandExecutor.executeCommand(currentAction); // ✅ EXECUTE COMMAND HERE

        _triggerActionCompletedVibration(currentAction); // Longer vibration for completed action
      }

      emit(ASLDetectionUpdated(
        currentSign: message['current_sign'] ?? '00000',
        sequenceBuffer: currentBuffer,
        lastAction: currentAction,
        movement: (message['movement'] ?? 0.0).toDouble(),
        isStable: message['is_stable'] ?? false,
        connectionStatus: 'Connected',
        shouldVibrate: shouldVibrate,
      ));

    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
    }
  }

  // Add these new methods to the class:
  int _lastSequenceLength = 0;

  Future<void> _triggerSignAcceptedVibration() async {
    if (!_vibrationEnabled) return;

    try {
      // Short, gentle vibration for sign acceptance
      await Vibration.vibrate(duration: 100, amplitude: 50);
      print('📳 Sign accepted - light vibration');
    } catch (e) {
      print('❌ Sign vibration error: $e');
    }
  }

  Future<void> _triggerActionCompletedVibration(String action) async {
    if (!_vibrationEnabled) return;

    try {
      final hasCustomVibrations = await Vibration.hasCustomVibrationsSupport();

      if (hasCustomVibrations == true) {
        if (action.toLowerCase().contains('call')) {
          // Double vibration for calls
          await Vibration.vibrate(pattern: [0, 200, 100, 200], intensities: [0, 128, 0, 255]);
        } else if (action.toLowerCase().contains('open')) {
          // Single strong vibration for opening apps
          await Vibration.vibrate(duration: 300, amplitude: 200);
        } else {
          // Triple short vibration for other actions
          await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100], intensities: [0, 128, 0, 128, 0, 128]);
        }
      } else {
        await Vibration.vibrate(duration: 200);
      }

      print('📳 Action completed - full vibration pattern');
    } catch (e) {
      print('❌ Action vibration error: $e');
    }
  }

  void _reconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _cameraService.stopStreaming();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _lastDetectedAction = null;
  }

  // Get camera preview widget
  Widget getCameraPreview() {
    return _cameraService.getCameraPreview();
  }

  // Get camera stats for debugging
  Map<String, dynamic> getCameraStats() {
    return _cameraService.getStats();
  }

  @override
  Future<void> close() {
    disconnect();
    _cameraService.dispose();
    return super.close();
  }
}