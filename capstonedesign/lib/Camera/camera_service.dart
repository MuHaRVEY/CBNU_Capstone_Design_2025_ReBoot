import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  // 상태를 저장하는 변수들을 제거하여 서비스를 상태 없이(stateless) 만듭니다.
  // CameraController? _controller;
  // List<CameraDescription>? _cameras;

  /// 카메라를 찾아 초기화한 후, 생성된 CameraController를 반환합니다.
  /// 이 서비스는 컨트롤러를 소유하지 않고 생성만 담당합니다.
  Future<CameraController?> initCamera() async {
    try {
      // 1. 사용 가능한 카메라 목록을 가져옵니다.
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("🚫 사용 가능한 카메라가 없습니다.");
        return null;
      }

      // 2. 컨트롤러를 생성하고 초기화합니다.
      final controller = CameraController(
        cameras[0], // 첫 번째 카메라(후면)를 사용합니다.
        ResolutionPreset.medium,
        enableAudio: false, // 오디오는 필요 없으므로 비활성화합니다.
      );
      await controller.initialize();
      
      // 3. 초기화된 컨트롤러를 반환합니다.
      return controller;

    } catch (e) {
      debugPrint("🚨 카메라 초기화 중 오류 발생: $e");
      return null; // 오류 발생 시 null을 반환합니다.
    }
  }

}