import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(CNICLiveApp(cameras: cameras));
}

class CNICLiveApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  CNICLiveApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNIC Real-Time Detection',
      home: CNICLivePage(cameras: cameras),
    );
  }
}

class CNICLivePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  CNICLivePage({required this.cameras});

  @override
  _CNICLivePageState createState() => _CNICLivePageState();
}

class _CNICLivePageState extends State<CNICLivePage> {
  late CameraController _controller;
  IO.Socket? socket;
  bool _isStreaming = false;
  List<Map<String, dynamic>> _boxes = [];
  Size? _previewSize;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io(
      'http://192.168.18.115:5001',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      print('✅ Connected to server');
    });

    socket!.onDisconnect((_) {
      print('❌ Disconnected from server');
    });

    socket!.on('bboxes', (data) {
      setState(() {
        _boxes = List<Map<String, dynamic>>.from(data['boxes']);
      });
    });

    socket!.on('error', (data) {
      print('🔥 Server error: ${data['message']}');
    });
  }

  Future<void> _initCamera() async {
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    await _controller.initialize();
    _previewSize = _controller.value.previewSize;
    setState(() {});
  }

  void _startStream() async {
    _isStreaming = true;

    while (_isStreaming) {
      try {
        final file = await _controller.takePicture();
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        socket?.emit('frame', {'image': base64Image});
      } catch (e) {
        print("❌ Snapshot error: $e");
      }

      await Future.delayed(Duration(milliseconds: 1000));
    }
  }

  void _stopStream() {
    _isStreaming = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("CNIC Real-Time Detection")),
      body: Stack(
        children: [
          CameraPreview(_controller),
          if (_previewSize != null)
            Positioned.fill(
              child: CustomPaint(
                painter: BoxesPainter(
                  boxes: _boxes,
                  previewSize: _previewSize!,
                  screenSize: MediaQuery.of(context).size,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _startStream,
            child: Text('▶ Start Stream'),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: _stopStream,
            child: Text('⏹ Stop'),
          ),
        ],
      ),
    );
  }
}

class BoxesPainter extends CustomPainter {
  final List<Map<String, dynamic>> boxes;
  final Size previewSize;
  final Size screenSize;

  BoxesPainter({
    required this.boxes,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;

    final previewAspectRatio = previewSize.width / previewSize.height;
    final screenAspectRatio = screenSize.width / screenSize.height;

    double displayWidth;
    double displayHeight;
    double offsetX = 0;
    double offsetY = 0;

    if (previewAspectRatio > screenAspectRatio) {
      displayWidth = screenSize.width;
      displayHeight = displayWidth / previewAspectRatio;
      offsetY = (screenSize.height - displayHeight) / 2;
    } else {
      displayHeight = screenSize.height;
      displayWidth = displayHeight * previewAspectRatio;
      offsetX = (screenSize.width - displayWidth) / 2;
    }

    double yoloWidth = 640;
    double yoloHeight = 448;

    if (boxes.any((box) => (box['bbox'] as List)[2] > 640)) {
      yoloWidth = 480;
      yoloHeight = 720;
    }

    final scaleX = displayWidth / yoloWidth;
    final scaleY = displayHeight / yoloHeight;

    final boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final backgroundPaint = Paint()
      ..color = Colors.red.withOpacity(0.7);

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    for (final box in boxes) {
      final bbox = box['bbox'] as List;
      final className = box['class'] as String;
      final confidence = (box['confidence'] as double).toStringAsFixed(2);

      final left = (bbox[0] * scaleX + offsetX + 10).clamp(0.0, screenSize.width);
      final top = (bbox[1] * scaleY + offsetY - 200).clamp(0.0, screenSize.height);
      final right = (bbox[2] * scaleX + offsetX + 80).clamp(0.0, screenSize.width);
      final bottom = (bbox[3] * scaleY + offsetY -160).clamp(0.0, screenSize.height);

      final width = right - left;
      final height = bottom - top;

      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, boxPaint);

      final textSpan = TextSpan(text: '$className ($confidence)', style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        left,
        top - textPainter.height - 4,
        textPainter.width + 6,
        textPainter.height + 4,
      );
      canvas.drawRect(labelRect, backgroundPaint);

      final labelX = left + 3;
      final labelY = (top - textPainter.height - 2).clamp(0.0, screenSize.height);
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
