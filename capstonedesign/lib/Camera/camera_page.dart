import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';
import 'trash_camera_page.dart'; // 촬영 후 이동할 페이지

class CameraPage extends StatefulWidget {
  final String userId;

  const CameraPage({super.key, required this.userId});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // CameraService는 상태를 가지지 않으므로 final로 선언
  final CameraService _cameraService = CameraService();

  // CameraController는 이 위젯의 생명주기를 따릅니다.
  CameraController? _controller;

  // 초기화 과정을 Future로 관리하여 build 메서드에서 활용
  late final Future<void> _initCameraFuture;

  bool _isTakingPicture = false; // 중복 촬영 방지 플래그

  @override
  void initState() {
    super.initState();
    _initCameraFuture = _initCamera();
  }

  /// ✅ 카메라 초기화
  Future<void> _initCamera() async {
    try {
      debugPrint("🔄 Initializing camera...");
      final controller = await _cameraService.initCamera();

      if (controller == null) {
        throw Exception("카메라 컨트롤러를 받아오지 못했습니다.");
      }

      // 위젯이 아직 마운트 상태일 때만 컨트롤러를 설정
      if (!mounted) return;
      setState(() {
        _controller = controller;
      });

      debugPrint("✅ Camera initialized successfully");
    } catch (e, stack) {
      debugPrint("🚨 Camera init failed: $e");
      debugPrint("$stack");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("카메라 초기화 실패: ${e.toString()}")),
        );
      }
    }
  }

  /// ✅ 사진 촬영 및 확인 페이지로 이동
  Future<void> _takePicture() async {
    // 컨트롤러가 준비되지 않았거나, 이미 촬영 중이면 아무것도 하지 않음
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      debugPrint("📸 Taking a picture...");
      final XFile picture = await _controller!.takePicture();
      debugPrint("✅ Picture taken: ${picture.path}");

      if (!mounted) return;

      // 촬영된 이미지 경로를 가지고 TrashCameraPage로 이동
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrashCameraPage(
            imagePath: picture.path,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint("🚨 Picture capture failed: $e");
      debugPrint("$stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("사진 촬영 실패: ${e.toString()}")),
        );
      }
    } finally {
      // 페이지 전환 후 돌아왔을 때 다시 촬영 가능하도록 플래그 해제
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        // FutureBuilder를 사용해 카메라 초기화 과정을 명확하게 처리
        child: FutureBuilder<void>(
          future: _initCameraFuture,
          builder: (context, snapshot) {
            // 초기화가 완료되고 컨트롤러가 준비되었을 때
            if (snapshot.connectionState == ConnectionState.done && _controller != null) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller!),
                  // 촬영 버튼
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 70, color: Colors.white),
                        // 촬영 중일 때는 버튼 비활성화
                        onPressed: _isTakingPicture ? null : _takePicture,
                      ),
                    ),
                  ),
                ],
              );
            }
            // 초기화 중일 때 로딩 인디케이터 표시
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint("🧹 Disposing camera controller...");
    // CameraPage가 소유한 컨트롤러를 여기서만 해제
    _controller?.dispose();
    debugPrint("✅ Camera controller disposed.");
    super.dispose();
  }
}