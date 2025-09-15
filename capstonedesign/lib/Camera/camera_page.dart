import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';

class CameraPage extends StatefulWidget {
  final String userId; // ✅ 유저 아이디 받기

  const CameraPage({super.key, required this.userId});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  CameraController? _controller;
  bool _isReady = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final controller = await _cameraService.initCamera();
      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (e) {
      debugPrint("카메라 초기화 실패: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final url = await _cameraService.takePictureAndUpload(widget.userId);

      if (!mounted) return;
      Navigator.pop(context, url); // 📌 업로드된 URL 반환
    } catch (e) {
      debugPrint("사진 촬영/업로드 오류: $e");
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.camera, size: 60, color: Colors.white),
              onPressed: _takePicture,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
