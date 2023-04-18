import 'package:app/camera_view.dart';
import 'package:app/util/face_detector_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPage extends StatefulWidget {
  const FaceDetectorPage({Key? key}) : super(key: key);

  @override
  State<FaceDetectorPage> createState() => _FaceDetectorPageState();
}

class _FaceDetectorPageState extends State<FaceDetectorPage> {
  //create face detector object
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraView(
      title: 'Face Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
        initializeCamera();
      },
      initialDirection: CameraLensDirection.front,
    ),Row(
      children: [
        Text("Red : $faceRedColor", style: const TextStyle(fontSize: 30),),
        Text("Green : $faceGreenColor",style: const TextStyle(fontSize: 30),),
        Text("Blue: $faceBlueColor",style: const TextStyle(fontSize: 30),),
      ],
    ),
      ],
    );
  }

  Future<void> processImage(final InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = "";
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'face found ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face ${face.boundingBox}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
  List<CameraDescription> cameras = [];
int? faceRedColor;
int? faceGreenColor;
int? faceBlueColor;
Future<void> initializeCamera() async {
  cameras = await availableCameras();
  final CameraController cameraController = CameraController(
    cameras[0],
    ResolutionPreset.medium,
  );

  await cameraController.initialize();
  cameraController.startImageStream((CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    for (int i = 0; i < width; i++) {
      for (int j = 0; j < height; j++) {
        final int pixel = cameraImage.planes[0].bytes[j * width + i];
        final int red = (pixel >> 16) & 0xff;
        final int green = (pixel >> 8) & 0xff;
        final int blue = pixel & 0xff;

        int totalRed = 0;
        int totalGreen = 0;
        int totalBlue = 0;
        int pixelCount = 0;

        for (int i = 0; i < width; i++) {
          for (int j = 0; j < height; j++) {
            final int pixel = cameraImage.planes[0].bytes[j * width + i];
            final int red = (pixel >> 16) & 0xff;
            final int green = (pixel >> 8) & 0xff;
            final int blue = pixel & 0xff;

            totalRed += red;
            totalGreen += green;
            totalBlue += blue;
            pixelCount++;
          }
        }

        final int averageRed = totalRed ~/ pixelCount;
        final int averageGreen = totalGreen ~/ pixelCount;
        final int averageBlue = totalBlue ~/ pixelCount;

        print('Average color: RGB($averageRed, $averageGreen, $averageBlue)');
        
      setState(() {
          faceRedColor = averageRed;
        faceGreenColor = averageGreen;
        faceBlueColor = averageBlue;
        });
    
      }
    }
  });

  Future.delayed(const Duration(seconds: 3)).then((value) {
            cameraController.dispose();
          });
  }
}
