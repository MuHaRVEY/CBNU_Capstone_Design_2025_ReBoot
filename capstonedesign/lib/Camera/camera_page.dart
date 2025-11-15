import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';
import 'trash_camera_page.dart';

class CameraPage extends StatefulWidget {
  final String userId;

  const CameraPage({super.key, required this.userId});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  CameraController? _controller;
  late final Future<void> _initCameraFuture;
  bool _isTakingPicture = false;

  // ✅ 플래시 상태 관리
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCameraFuture = _initCamera();
  }

  /// ✅ 카메라 초기화
  Future<void> _initCamera() async {
    try {
      final controller = await _cameraService.initCamera();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("카메라 초기화 실패: $e")),
        );
      }
    }
  }

  /// ✅ 플래시 토글
  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
    await _controller!.setFlashMode(newMode);
    setState(() => _isFlashOn = !_isFlashOn);
  }

  /// ✅ 사진 촬영
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;
    setState(() => _isTakingPicture = true);

    try {
      final XFile picture = await _controller!.takePicture();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrashCameraPage(
            imagePath: picture.path,
            userId: widget.userId,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initCameraFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && _controller != null) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final previewHeight = constraints.maxHeight * 0.65; // ✅ overflow 방지
                  return Column(
                    children: [
                      /// ✅ 상단 바 (닫기 + 사진 + 플래시)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text("사진",
                                style: TextStyle(color: Colors.white, fontSize: 16)),
                            IconButton(
                              icon: Icon(
                                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: _toggleFlash,
                            ),
                          ],
                        ),
                      ),

                      /// ✅ 카메라 미리보기 (아이폰 스타일 비율 + 둥근 모서리)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: previewHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),

                      /// ✅ 하단 영역 (안내문 + 촬영 버튼 + 모드 선택)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "중앙에 피사체를 맞춰주세요",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: _isTakingPicture ? null : _takePicture,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text("사진",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 20),

                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }

            /// ✅ 로딩 중
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
    _controller?.dispose();
    super.dispose();
  }
}


