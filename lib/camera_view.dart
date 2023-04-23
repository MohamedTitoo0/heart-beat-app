import 'dart:io';
import 'package:app/main.dart';
import 'package:app/util/screen_mode.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

class CameraView extends StatefulWidget {
  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;

  const CameraView({
    Key? key,
    required this.title,
    required this.onImage,
    required this.initialDirection,
    this.customPaint,
    this.text,
  }) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  ScreenMode _mode = ScreenMode.live;
  CameraController? _controller;
  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  int _cameraIndex = 0;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  final bool _allowPicker = true;
  bool _chagingCameraLens = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 99,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) =>
              element.lensDirection == widget.initialDirection &&
              element.sensorOrientation == 99,
        ),
      );
    } else {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
            (element) => element.lensDirection == widget.initialDirection),
      );
    }

    _startLive();
  }

  Future _startLive() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMaxZoomLevel().then((value) {
        maxZoomLevel = value;
      });
      _controller?.getMinZoomLevel().then((value) {
        zoomLevel = value;
        minZoomLevel = value;
      });
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _processCameraImage(final CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;
    final planeData = image.planes.map((final Plane plane) {
      return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width);
    }).toList();
    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      inputImageData: inputImageData,
    );
    widget.onImage(inputImage);
  }

  int? faceRedColor = 0;
  int? faceGreenColor = 0;
  int? faceBlueColor = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_allowPicker)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: _switchScreenMode,
                child: Icon(
                  _mode == ScreenMode.live
                      ? Icons.photo_library_rounded
                      : (Platform.isIOS
                          ? Icons.camera_alt_rounded
                          : Icons.camera_alt),
                ),
              ),
            )
        ],
      ),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }


  // ToDo screen video

  final FaceDetector faceDetector = FirebaseVision.instance.faceDetector(
    FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
    ),
  );


  void _detectFaces() async {
    final VideoPlayerController controller = VideoPlayerController.asset('assets/video.mp4');
    await controller.initialize();
    await controller.play();

    controller.addListener(() async {
      final image = await controller.formatHint;
      final inputImageData = FirebaseVisionImage.fromImage(image);
      final List<Face> faces = await faceDetector.processImage(inputImageData);

      Future<Image> _loadImage(String assetName) async {
        final ByteData assetByteData = await rootBundle.load(assetName);
        final Uint8List imageData = assetByteData.buffer.asUint8List();
        final Completer<Image> completer = Completer();
        decodeImageFromList(imageData, (Image img) {
          return completer.complete(img);
        });
        return completer.future;
      }

      void _drawFaceRectangles(Canvas canvas, Image image, List<Face> faces) {
        final Paint paint = Paint()
          ..color = Color.fromARGB(255, 255, 0, 0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        for (final face in faces) {
          final rect = face.boundingBox;
          canvas.drawRect(rect, paint);
        }
      }

      void _detectFaces() async {
        // ...

        final Image image = await _loadImage('assets/background.png');

        controller.addListener(() async {
          // ...

          final PictureRecorder recorder = ui.PictureRecorder();
          final Canvas canvas = Canvas(recorder);

          canvas.drawImage(image, const Offset(0.0, 0.0), ui.Paint());

          _drawFaceRectangles(canvas, image, faces);

          final Picture picture = recorder.endRecording();
          final Image outputImage = await picture.toImage(image.width, image.height);

          void _detectFaces() async {
            // ...

            controller.addListener(() async {
              // ...

              final PictureRecorder recorder = PictureRecorder();
              final Canvas canvas = Canvas(recorder);

              canvas.drawImage(image, const Offset(0.0, 0.0), Paint());

              _drawFaceRectangles(canvas, image, faces);

              final Picture picture = recorder.endRecording();
              final Image outputImage = await picture.toImage(image.width, image.height);

              setState(() {
                _outputImage = outputImage;
              });
            });
          }

          @override
          Widget build(BuildContext context) {
            return Scaffold(
                body: Center(
                    child: outputImage
                ))
            ;
          }

        }

            setState(() {});
      }
    });
  }

// ......



  Widget? _floatingActionButton() {
    if (_mode == ScreenMode.gallery) return null;
    if (cameras.length == 1) return null;

    return SizedBox(
      height: 70,
      width: 70,
      child: FloatingActionButton(
        onPressed: _switchCamera,
        child: Icon(
          Platform.isIOS
              ? Icons.video_call_rounded
              : Icons.camera_alt,

          size: 40,
        ),
        
      ),
      
    );
  }


  Future _switchCamera() async {
    XFile? picture;
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        _controller!.stopImageStream();
        picture = await _controller!.takePicture();
        setState(() {
          _isLoading = true;
        });
        _convertImageToRGB(picture);
      }
      else {
        print('take picture error');
      }
    } catch (e) {
      print(e);
      Navigator.pop(context);
    }
  }

  Future<void> _convertImageToRGB(XFile xFile) async {
    // Convert the XFile to a compressed JPEG Uint8List
    final Uint8List compressedImg = await convertXFileToJpg(xFile);

    // Decode the JPEG to an RGB image
    final decoder = image.JpegDecoder();
    final decodedImg = decoder.decodeImage(compressedImg);

    // Calculate the average R, G, and B values across all pixels
    int totalR = 0, totalG = 0, totalB = 0;
    for (int y = 0; y < decodedImg!.height; y++) {
      for (int x = 0; x < decodedImg.width; x++) {
        final pixel = decodedImg.getPixel(x, y);
        totalR += image.getRed(pixel);
        totalG += image.getGreen(pixel);
        totalB += image.getBlue(pixel);
      }
    }
    final numPixels = decodedImg.width * decodedImg.height;
    final avgR = (totalR / numPixels).round();
    final avgG = (totalG / numPixels).round();
    final avgB = (totalB / numPixels).round();

    // Combine the R, G, and B values into a single integer
    final rgb = (avgR << 16) + (avgG << 8) + avgB;
    debugPrint('Red:$avgR Green:$avgG Blue:$avgB  RGB VALUES');

    setState(() {
      _isLoading = false;
      faceRedColor = avgR;
      faceGreenColor = avgG;
      faceBlueColor = avgB;
    });
    _controller?.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<Uint8List> convertXFileToJpg(XFile file) async {
    final bytes = await file.readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 90,
      format: CompressFormat.jpeg,
    );
    debugPrint('$compressedBytes <<<<<');
    return compressedBytes;
  }

  Widget _body() {
    Widget body;
    if (_mode == ScreenMode.live) {
      body = _liveBody();
    } else {
      body = _galleryBody();
    }
    return body;
  }

  Widget _galleryBody() {
    return ListView(
      shrinkWrap: true,
      children: [
        _image != null
            ? SizedBox(
                height: 400,
                width: 400,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_image!),
                    if (widget.customPaint != null) widget.customPaint!,
                  ],
                ),
              )
            : const Icon(
                Icons.image,
                size: 200,
              ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: ElevatedButton(
            onPressed: () => _getImage(ImageSource.gallery),
            child: const Text('From Gallery'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () => _getImage(ImageSource.camera),
            child: const Text('Take a Picture'),
          ),
        ),
        if (_image != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                "${_path == null ? '' : 'Image path: $_path'}\n\n${widget.text ?? ''}"),
          ),
      ],
    );
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });

    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile == null) {
      _processPickedFile(pickedFile);
    }
    setState(() {});
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }
    setState(() {
      _image = File(path);
    });
    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    widget.onImage(inputImage);
  }

  Widget _liveBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return Container(
      color: Colors.amber,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if(_isLoading) const Center(child: CircularProgressIndicator()),
          Transform.scale(
            scale: scale,
            child: Center(
              child: _chagingCameraLens
                  ? const Center(
                      child: Text("Changing camera lens"),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null && !_controller!.value.isTakingPicture)
            widget.customPaint!,
          Positioned(
            bottom: 140,
            left: 70,
            right: 50,
            child: Row(
              children: [
                Text(
                  "Red : $faceRedColor ",
                  style: const TextStyle(fontSize: 16,color: Colors.red),
                ),
                Text(
                  "Green : $faceGreenColor ",
                  style: const TextStyle(fontSize: 16,color: Colors.green),
                ),
                Text(
                  "Blue: $faceBlueColor",
                  style: const TextStyle(fontSize: 16,color: Colors.blue),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Slider(
                value: zoomLevel,
                min: minZoomLevel,
                max: maxZoomLevel,
                onChanged: (final newSliderValue) {
                  setState(() {
                    zoomLevel = newSliderValue;
                    _controller!.setZoomLevel(zoomLevel);
                  });
                },
                divisions: (maxZoomLevel - 1).toInt() < 1
                    ? null
                    : (maxZoomLevel - 1).toInt()),
          ),
        ],
      ),
    );
  }

  void _switchScreenMode() {
    _image = null;
    if (_mode == ScreenMode.live) {
      _mode = ScreenMode.gallery;
      _stopLive();
    } else {
      _mode = ScreenMode.live;
      _startLive();
    }
    setState(() {});
  }

  Future _stopLive() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
