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

class MyApp extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> availableCameras;

  const MyApp({
    Key? key,
    required this.camera,
    required this.availableCameras,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late CameraDescription currentCamera;
  late List<CameraDescription> availableCameras;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    currentCamera = widget.camera;
    availableCameras = widget.availableCameras;

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print('🔄 App lifecycle changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
      // App is back in foreground
        if (!_isAppActive) {
          print('📱 App resumed - reinitializing camera...');
          _reinitializeApp();
        }
        _isAppActive = true;
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      // App is going to background
        _isAppActive = false;
        break;
      case AppLifecycleState.detached:
      // App is being destroyed
        break;
      case AppLifecycleState.hidden:
      // App is hidden
        _isAppActive = false;
        break;
    }
  }

  Future<void> _reinitializeApp() async {
    try {
      print('🔄 Reinitializing camera resources...');

      // Check if cameras are still available
      final bool cameraAvailable = await CameraService.isCameraAvailable();

      if (!cameraAvailable) {
        print('❌ No cameras available after resume');
        return;
      }

      // Get available cameras again
      final cameras = await CameraService.getAvailableCameras();

      if (cameras.isEmpty) {
        print('❌ No cameras found after resume');
        return;
      }

      // Update camera list
      availableCameras = cameras;

      // Keep same camera preference (front camera)
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      currentCamera = frontCamera;

      print('✅ Camera reinitialized successfully');

      // Trigger rebuild to refresh the UI
      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      print('❌ Failed to reinitialize camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ASL Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: _isAppActive
          ? BlocProvider(
        create: (context) => ASLDetectionCubit(),
        child: ASLDetectionScreen(
          camera: currentCamera,
          availableCameras: availableCameras,
        ),
      )
          : const LoadingScreen(),
    );
  }
}

// Loading screen while app is reinitializing
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing camera...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
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
                  onPressed: () async {
                    // Restart app properly
                    await _restartApp();
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

  static Future<void> _restartApp() async {
    // Properly restart the app
    main();
  }
}