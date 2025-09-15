import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  /// 카메라 초기화
  Future<CameraController> initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.medium,
    );
    await _controller!.initialize();
    return _controller!;
  }

  /// 사진 찍고 Firebase Storage에 업로드 (유저별 경로)
  Future<String> takePictureAndUpload(String userId) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception("카메라가 초기화되지 않았습니다.");
    }

    final picture = await _controller!.takePicture();
    final file = File(picture.path);

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child(
      "plogging/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    await imageRef.putFile(file);
    final downloadURL = await imageRef.getDownloadURL();

    return downloadURL;
  }

  /// 자원 해제
  void dispose() {
    _controller?.dispose();
  }
}
