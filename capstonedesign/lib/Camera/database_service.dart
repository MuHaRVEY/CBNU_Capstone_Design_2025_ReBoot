import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// 플로깅 데이터를 Realtime Database에 저장합니다.
  Future<void> saveData({
    required String userId,
    required String imageUrl,
    required String category,
  }) async {
    // 변경된 부분: 저장 경로를 'users/유저ID/ploggingRecords'로 수정
    final ref = _database.ref("users/$userId/ploggingRecords").push();

    await ref.set({
      'imageUrl': imageUrl,
      'category': category,
      'timestamp': ServerValue.timestamp, // 서버의 시간 기준으로 저장
    });
  }
}