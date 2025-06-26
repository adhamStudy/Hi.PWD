import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Checking for cameras...');

  try {
    final cameras = await availableCameras();
    print('Found ${cameras.length} cameras');

    for (int i = 0; i < cameras.length; i++) {
      print('Camera $i: ${cameras[i].name} - ${cameras[i].lensDirection}');
    }

    if (cameras.isNotEmpty) {
      runApp(CameraTestApp(camera: cameras.first));
    } else {
      runApp(const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('No cameras found')),
        ),
      ));
    }
  } catch (e) {
    print('Camera error: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    ));
  }
}

class CameraTestApp extends StatelessWidget {
  final CameraDescription camera;

  const CameraTestApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Camera found: ${camera.name}'),
        ),
      ),
    );
  }
}