// lib/Firebase/firebase_workout_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseWorkoutService {
  static final _db = FirebaseDatabase.instance;
  static final _auth = FirebaseAuth.instance;

  /// 운동 기록 저장 (공통 함수)
  // ✅ encodedRoute와 pointCount를 옵셔널 인자로 추가
  static Future<void> saveWorkout({
    required double distanceM,
    required Duration duration,
    double? avgSpeedKmh,
    bool isNavigation = false,
    String? encodedRoute, // 👈 옵셔널 경로
    int? pointCount,     // 👈 옵셔널 좌표 개수
    String? nameRoute,   // 👈 옵셔널 경로 이름
    int? ploggingPoints, // 👈 옵셔널 플로깅 포인트
    String? address,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print('❌ Firebase 저장 실패: 로그인된 사용자 없음');
        return;
      }

      // ✅ 경로 저장 여부를 플래그로 관리
      final bool savedRoute = encodedRoute != null;

      final userRef = _db.ref('users/$uid/workoutStats');
      final plogRef = _db.ref('users/$uid');
      final snapshotPlog = await plogRef.get();
      final snapshot = await userRef.get();

      double prevDistance = 0;
      double prevTime = 0;
      double prevSpeed = 0;
      int prevSessions = 0;
      int currentPloggingPoints = 0;

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        prevDistance = (data['totalDistance'] ?? 0).toDouble();
        prevTime = (data['totalTime'] ?? 0).toDouble();
        prevSpeed = (data['averageSpeed'] ?? 0).toDouble();
        prevSessions = (data['totalSessions'] ?? 0).toInt();
      }

      if (snapshotPlog.exists) {
        final dataPlog = Map<String, dynamic>.from(snapshotPlog.value as Map);
        currentPloggingPoints = (dataPlog['ploggingPoints'] ?? 0).toInt();
      }

      final sessionSpeed = avgSpeedKmh ??
          (distanceM > 0 && duration.inSeconds > 0
              ? (distanceM / 1000) / (duration.inSeconds / 3600)
              : 0);

      // ✅ 첫 세션일 경우 분모 0 오류 방지
      final newAverageSpeed = (prevSessions > 0)
          ? ((prevSpeed * prevSessions) + sessionSpeed) / (prevSessions + 1)
          : sessionSpeed;

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
          'savedRoute': savedRoute, // 경로 저장 여부 플래그 추가
          'address': address ?? '주소 없음',
          'date': DateTime.now().toIso8601String(),
        },
      });

      await plogRef.update({
        'ploggingPoints': currentPloggingPoints + (ploggingPoints ?? 0),
      });

      // --- 세션별 히스토리 추가 ---
      final path = isNavigation ? 'navigatorHistory' : 'polylineHistory';
      final sessionRef = _db.ref('users/$uid/$path').push();

      // ✅ 기본 세션 데이터 생성
      final Map<String, dynamic> sessionData = {
        'distance': distanceM,
        'time': duration.inSeconds,
        'speed': sessionSpeed,
        'date': DateTime.now().toIso8601String(),
      };

      // ✅ 경로 데이터가 있으면 (체크했으면) 맵에 추가
      if (savedRoute) {
        sessionData['encodedRoute'] = encodedRoute;
        sessionData['nameRoute'] = nameRoute ?? 'Unnamed Route';
        sessionData['pointCount'] = pointCount;
      }

      // ✅ 데이터 저장
      await sessionRef.set(sessionData);

      // ✅ 로그 메시지 수정
      print(
          ' Firebase ${isNavigation ? "네비게이션" : "플로깅"} ${savedRoute ? "(경로 포함)" : "(경로 없음)"} 저장 완료 (${(distanceM / 1000).toStringAsFixed(2)} km)');
    } catch (e, stack) {
      print(' Firebase 저장 중 오류: $e');
      print(stack);
    }
  }

}
