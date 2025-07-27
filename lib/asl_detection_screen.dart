import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:real_time/configuration_screen.dart';
import 'package:vibration/vibration.dart';
import 'cubit/asl_detection_cubit.dart';
import 'models/asl_detection_state.dart';
import 'widgets/detection_overlay.dart';
import 'widgets/command_list.dart';
import 'widgets/server_connection_dialog.dart';

class ASLDetectionScreen extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> availableCameras;

  const ASLDetectionScreen({
    Key? key,
    required this.camera,
    required this.availableCameras,
  }) : super(key: key);

  @override
  State<ASLDetectionScreen> createState() => _ASLDetectionScreenState();
}

class _ASLDetectionScreenState extends State<ASLDetectionScreen> {
  bool _permissionGranted = false;
  bool _isInitializing = false;

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
      await _initializeCameraAndConnect();
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _initializeCameraAndConnect() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      final cubit = context.read<ASLDetectionCubit>();

      // Initialize camera first
      final cameraSuccess = await cubit.initializeCamera(widget.camera);

      if (cameraSuccess && mounted) {
        // Then connect to WebSocket server
        await cubit.connect();
        print('✅ Camera and WebSocket initialized successfully');
      } else {
        print('❌ Camera initialization failed');
      }
    } catch (e) {
      print('❌ Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Camera Permission Required',
          style: TextStyle(color: Colors.black87),
        ),
        content: const Text(
          'This app needs camera access to capture your hand signs for ASL detection.',
          style: TextStyle(color: Colors.black54),
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
        backgroundColor: Colors.white,
        title: const Text(
          'Vibration Settings',
          style: TextStyle(color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Enable Vibration',
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: const Text(
                'Vibrate when actions are detected',
                style: TextStyle(color: Colors.black54),
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

  void _showCameraSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Camera Settings',
          style: TextStyle(color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flip_camera_android, color: Colors.black87),
              title: const Text(
                'Switch Camera',
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: const Text(
                'Toggle between front and back camera',
                style: TextStyle(color: Colors.black54),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final success = await context.read<ASLDetectionCubit>().switchCamera();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Camera switched' : 'Failed to switch camera'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.black87),
              title: const Text(
                'Camera Stats',
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: const Text(
                'View camera performance info',
                style: TextStyle(color: Colors.black54),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showCameraStats();
              },
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

  void _showCameraStats() {
    final stats = context.read<ASLDetectionCubit>().getCameraStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Camera Statistics',
          style: TextStyle(color: Colors.black87),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: stats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Hi.PWD',style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
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
          // IconButton(
          //   onPressed: _showCameraSettings,
          //   icon: const Icon(Icons.camera_alt),
          //   tooltip: 'Camera Settings',
          // ),
          // IconButton(
          //   onPressed: _showVibrationSettings,
          //   icon: BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
          //     builder: (context, state) {
          //       final cubit = context.read<ASLDetectionCubit>();
          //       return Icon(
          //         cubit.isVibrationEnabled ? Icons.vibration : Icons.phone_android,
          //         color: cubit.isVibrationEnabled ? Colors.blue : Colors.grey,
          //       );
          //     },
          //   ),
          //   tooltip: 'Vibration Settings',
          // ),
          // IconButton(
          //   onPressed: _showServerConnectionDialog,
          //   icon: const Icon(Icons.settings),
          //   tooltip: 'Server Settings',
          // ),
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
            tooltip: 'Reconnect to Server',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "camera_switch",
            onPressed: () async {
              final success = await context.read<ASLDetectionCubit>().switchCamera();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Camera switched' : 'Failed to switch camera'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Icon(Icons.flip_camera_android),
            backgroundColor: Colors.green,
            tooltip: 'Switch Camera',
          ),
          const SizedBox(height: 8),
          // FloatingActionButton(
          //   heroTag: "settings",
          //   onPressed: _showServerConnectionDialog,
          //   child: const Icon(Icons.wifi),
          //   backgroundColor: Colors.purple,
          //   tooltip: 'Server Connection',
          // ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_permissionGranted) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Camera Permission Required',
                style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please grant camera permission to continue',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isInitializing) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing Camera & Server...',
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
      builder: (context, state) {
        if (state is ASLDetectionError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Connection Error',
                    style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error,
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ASLDetectionCubit>().connect();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            // Camera Preview (Full Screen)
            Positioned.fill(
              child: BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
                builder: (context, state) {
                  return context.read<ASLDetectionCubit>().getCameraPreview();
                },
              ),
            ),

            // Detection Overlay
            const DetectionOverlay(),

            // Command List (Draggable Bottom Sheet)
            DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.1,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: CommandList(scrollController: scrollController),
                );
              },
            ),

            // Camera Status Indicator (Top Right)
            Positioned(
              top: 20,
              right: 20,
              child: BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
                builder: (context, state) {
                  final cubit = context.read<ASLDetectionCubit>();
                  final isStreaming = cubit.cameraService.isStreaming;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isStreaming ? Colors.green : Colors.red,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isStreaming ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isStreaming ? 'LIVE' : 'OFFLINE',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up resources when screen is disposed
    context.read<ASLDetectionCubit>().stopCameraStreaming();
    super.dispose();
  }
}