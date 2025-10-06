import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  /// 이미지 파일을 Firebase Storage에 업로드하고 다운로드 URL을 반환합니다.
  Future<String> uploadImage(String imagePath, String userId) async {
    final file = File(imagePath);

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child(
      "plogging/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    await imageRef.putFile(file);
    final downloadURL = await imageRef.getDownloadURL();

    return downloadURL;
  }
}