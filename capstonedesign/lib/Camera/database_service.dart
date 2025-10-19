import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// 플로깅 데이터를 Realtime Database에 저장합니다.
  Future<void> saveData({
    required String userId,
    required String imageUrl,
    required List<String> categories, // CHANGED: String category -> List<String> categories
  }) async {
    // 저장 경로는 'users/유저ID/ploggingRecords'를 그대로 사용
    final ref = _database.ref("users/$userId/ploggingRecords").push();

    await ref.set({
      'imageUrl': imageUrl,
      'categories': categories, // CHANGED: 'category': category -> 'categories': categories
      'timestamp': ServerValue.timestamp, // 서버의 시간 기준으로 저장
    });
  }
}