import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'asl_detection_screen.dart';
import 'cubit/asl_detection_cubit.dart';
import 'services/camera_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Check if camera is available
    final bool cameraAvailable = await CameraService.isCameraAvailable();

    if (!cameraAvailable) {
      runApp(const ErrorApp(message: 'No cameras found on this device'));
      return;
    }

    // Get available cameras
    final cameras = await CameraService.getAvailableCameras();

    if (cameras.isEmpty) {
      runApp(const ErrorApp(message: 'No cameras found on this device'));
      return;
    }

    // Prefer front camera for ASL detection (user can see their hands)
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    runApp(MyApp(camera: frontCamera, availableCameras: cameras));
  } catch (e) {
    runApp(ErrorApp(message: 'Camera initialization failed: $e'));
  }
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  final List<CameraDescription> availableCameras;

  const MyApp({
    Key? key,
    required this.camera,
    required this.availableCameras,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ASL Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        // Enhanced theme for camera app
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: BlocProvider(
        create: (context) => ASLDetectionCubit(),
        child: ASLDetectionScreen(
          camera: camera,
          availableCameras: availableCameras,
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String message;

  const ErrorApp({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  'Camera Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Restart app
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Make sure camera permissions are granted',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}