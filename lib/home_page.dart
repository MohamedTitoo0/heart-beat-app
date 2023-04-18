import 'dart:io';

import 'package:app/face_detector_page.dart';
import 'package:app/main.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';



class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState.writeAsBytesSync(true);
}


class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detector'),
      ),
      body: _body(),
    );
  }



  Widget _body() {
    return Center(
      child: SizedBox(
        width: 350,
        height: 80,
        child: OutlinedButton(
          style: ButtonStyle(
            side: MaterialStateProperty.all(
              const BorderSide(
                  color: Colors.brown, width: 1.0, style: BorderStyle.solid),
            ),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FaceDetectorPage(),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconWidget(Icons.photo_camera),
              const Text(
                'Go to Face Detect Test',
                style: TextStyle(fontSize: 24),
              ),
              _buildIconWidget(Icons.photo_camera),
            ],
          ),
        ),
      ),
    );
  }

  

    final outputImage = File('path/to/output/image.png');
  _HomePageState.writeAsBytesSync(pngBytes);

  Widget _buildIconWidget(final IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Icon(
        icon,
        size: 24,
      ),
    );
  }
  

}
