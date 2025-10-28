// lib/Firebase/firebase_workout_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseWorkoutService {
  static final _db = FirebaseDatabase.instance;
  static final _auth = FirebaseAuth.instance;

  /// 운동 기록 저장 (공통 함수)
  static Future<void> saveWorkout({
    required double distanceM,
    required Duration duration,
    double? avgSpeedKmh,
    bool isNavigation = false,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print('❌ Firebase 저장 실패: 로그인된 사용자 없음');
        return;
      }

      final userRef = _db.ref('users/$uid/workoutStats');
      final snapshot = await userRef.get();

      double prevDistance = 0;
      double prevTime = 0;
      double prevSpeed = 0;
      int prevSessions = 0;

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        prevDistance = (data['totalDistance'] ?? 0).toDouble();
        prevTime = (data['totalTime'] ?? 0).toDouble();
        prevSpeed = (data['averageSpeed'] ?? 0).toDouble();
        prevSessions = (data['totalSessions'] ?? 0).toInt();
      }

      final sessionSpeed = avgSpeedKmh ??
          (distanceM > 0 && duration.inSeconds > 0
              ? (distanceM / 1000) / (duration.inSeconds / 3600)
              : 0);

      final newAverageSpeed =
          ((prevSpeed * prevSessions) + sessionSpeed) / (prevSessions + 1);

      // ✅ 누적 통계 업데이트
      await userRef.update({
        'totalDistance': prevDistance + distanceM,
        'totalTime': prevTime + duration.inSeconds,
        'averageSpeed': newAverageSpeed,
        'totalSessions': prevSessions + 1,
        'lastUpdated': DateTime.now().toIso8601String(),
        'lastSession': {
          'distance': distanceM,
          'time': duration.inSeconds,
          'speed': sessionSpeed,
          'isNavigation': isNavigation,
          'date': DateTime.now().toIso8601String(),
        },
      });

      // ✅ 세션별 히스토리 추가
      final path = isNavigation ? 'navigatorHistory' : 'polylineHistory';
      final sessionRef = _db.ref('users/$uid/$path').push();

      await sessionRef.set({
        'distance': distanceM,
        'time': duration.inSeconds,
        'speed': sessionSpeed,
        'date': DateTime.now().toIso8601String(),
      });

      print(
          '✅ Firebase ${isNavigation ? "네비게이션" : "플로깅"} 데이터 저장 완료 (${(distanceM / 1000).toStringAsFixed(2)} km)');
    } catch (e, stack) {
      print('❌ Firebase 저장 중 오류: $e');
      print(stack);
    }
  }
}
