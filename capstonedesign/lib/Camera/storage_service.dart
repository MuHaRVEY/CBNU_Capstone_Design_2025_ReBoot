import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  /// 이미지 파일을 Firebase Storage에 업로드하고 다운로드 URL을 반환합니다.
  Future<String> uploadImage(String imagePath, String userId) async {
    final file = File(imagePath);

    // Storage 참조 설정
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child(
      "plogging/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    try {
      print("🚀 [StorageService] Upload start: $imagePath");

      // Firebase Storage에 파일 업로드
      final uploadTask = await imageRef.putFile(file);

      // 업로드 상태 로그 출력
      print("✅ [StorageService] Upload success: ${uploadTask.state}");

      // 다운로드 URL 가져오기
      final downloadURL = await imageRef.getDownloadURL();
      print("🌐 [StorageService] Download URL: $downloadURL");

      return downloadURL;
    } on FirebaseException catch (e) {
      // Firebase Storage 관련 오류
      print("🚨 [StorageService] FirebaseException: ${e.code} → ${e.message}");

      // App Check 미설정, 권한, 네트워크 등 다양한 케이스 처리
      if (e.code == 'unauthorized') {
        print("⚠️ Firebase Storage: 권한 문제 — App Check 또는 Rules 확인 필요");
      } else if (e.code == 'canceled') {
        print("⚠️ 업로드가 사용자 또는 네트워크 오류로 취소됨");
      } else if (e.code == 'object-not-found') {
        print("⚠️ 업로드 대상 경로를 찾을 수 없습니다");
      }

      rethrow; // 상위 함수로 예외 전달
    } catch (e) {
      // 일반 예외 (네트워크, 파일 접근 등)
      print("🚨 [StorageService] Unexpected error: $e");
      rethrow;
    }
  }
}
