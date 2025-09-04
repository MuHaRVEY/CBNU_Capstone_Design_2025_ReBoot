import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapService {
  // Singleton instance
  static final GoogleMapService _instance = GoogleMapService._internal();

  factory GoogleMapService() => _instance;

  GoogleMapService._internal();

  // GoogleMapController를 저장할 변수
  GoogleMapController? _controller;

  // 현재 컨트롤러 반환
  GoogleMapController? get controller => _controller;

  // 컨트롤러 초기화
  void setController(GoogleMapController controller) {
    _controller = controller;
  }

  // 지도 이동 기능
  Future<void> moveCamera(CameraUpdate update) async {
    if (_controller != null) {
      await _controller!.moveCamera(update);
    }
  }

  // 줌 기능 등도 추가 가능
  Future<void> zoomTo(double zoom) async {
    if (_controller != null) {
      await _controller!.moveCamera(CameraUpdate.zoomTo(zoom));
    }
  }
}
