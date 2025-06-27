import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:real_time/configuration_screen.dart';
import 'package:vibration/vibration.dart';
import 'cubit/asl_detection_cubit.dart';
import 'models/asl_detection_state.dart';
import 'widgets/camera_view.dart';
import 'widgets/detection_overlay.dart';
import 'widgets/command_list.dart';
import 'widgets/server_connection_dialog.dart';

class ASLDetectionScreen extends StatefulWidget {
  final CameraDescription camera;

  const ASLDetectionScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<ASLDetectionScreen> createState() => _ASLDetectionScreenState();
}

class _ASLDetectionScreenState extends State<ASLDetectionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus == PermissionStatus.granted) {
      setState(() {
        _permissionGranted = true;
      });
      await _initializeCamera();
      if (mounted) {
        context.read<ASLDetectionCubit>().connect();
      }
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera access to display the live video feed while detecting hand signs.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestPermissions();
            },
            child: const Text('Grant Permission'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    if (!_permissionGranted) return;

    try {
      _cameraController = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  void _showServerConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => ServerConnectionDialog(
        onConnect: (serverUrl) {
          context.read<ASLDetectionCubit>().updateServerUrl(serverUrl);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showVibrationSettings() {
    final cubit = context.read<ASLDetectionCubit>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Vibration Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Enable Vibration',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Vibrate when actions are detected',
                style: TextStyle(color: Colors.white60),
              ),
              value: cubit.isVibrationEnabled,
              onChanged: (value) {
                cubit.toggleVibration();
                Navigator.of(context).pop();

                if (value) {
                  Vibration.vibrate(duration: 100);
                }
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ASL Detection'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigurationScreen()),
              );
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Configure Commands',
          ),
          IconButton(
            onPressed: _showVibrationSettings,
            icon: BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
              builder: (context, state) {
                final cubit = context.read<ASLDetectionCubit>();
                return Icon(
                  cubit.isVibrationEnabled ? Icons.vibration : Icons.phone_android,
                  color: cubit.isVibrationEnabled ? Colors.blue : Colors.grey,
                );
              },
            ),
            tooltip: 'Vibration Settings',
          ),

          IconButton(
            onPressed: _showServerConnectionDialog,
            icon: const Icon(Icons.settings),
            tooltip: 'Server Settings',
          ),

          BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
            builder: (context, state) {
              Color statusColor = Colors.red;
              String statusText = 'Disconnected';

              if (state is ASLDetectionConnected || state is ASLDetectionUpdated) {
                statusColor = Colors.green;
                statusText = 'Connected';
              } else if (state is ASLDetectionLoading) {
                statusColor = Colors.orange;
                statusText = 'Connecting...';
              }

              return Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "reconnect",
            onPressed: () {
              context.read<ASLDetectionCubit>().connect();
            },
            child: const Icon(Icons.refresh),
            backgroundColor: Colors.blue,
          ),
          const SizedBox(height: 8),

          FloatingActionButton(
            heroTag: "settings",
            onPressed: _showServerConnectionDialog,
            child: const Icon(Icons.wifi),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_permissionGranted) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Camera Permission Required',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Please grant camera permission to continue',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        CameraView(controller: _cameraController!),
        const DetectionOverlay(),
        DraggableScrollableSheet(
          initialChildSize: 0.2,
          minChildSize: 0.1,
          maxChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: CommandList(scrollController: scrollController),
            );
          },
        ),
      ],
    );
  }
}