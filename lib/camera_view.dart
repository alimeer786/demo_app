import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});
  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller!);
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await _initializeControllerFuture;
              final image = await _controller!.takePicture();
              await _detectObjects(image);
            } catch (e) {
              // Replacing print with logger
              final logger = Logger();
              logger.e('Error capturing or detecting objects: $e');
            }
          },
          child: const Icon(Icons.camera_alt),
        ),
      ],
    );
  }

  Future<void> _detectObjects(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);

    // Use the new ObjectDetector with the required options
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );

    final objectDetector = ObjectDetector(options: options);

    try {
      final List<DetectedObject> objects =
          await objectDetector.processImage(inputImage);

      // Log or process the detected objects
      final logger = Logger();
      for (DetectedObject object in objects) {
        logger.d(
            'Detected object: ${object.labels.map((label) => label.text).join(', ')}');
      }
    } finally {
      // Ensure to close the detector when done
      objectDetector.close();
    }
  }
}
